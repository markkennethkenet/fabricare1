from flask import Flask, request, jsonify
from flask_cors import CORS
from pathlib import Path
import tempfile
import json
import platform
import sklearn
import cv2
import numpy as np
from skimage.feature import graycomatrix, graycoprops
from ultralytics import YOLO
from werkzeug.exceptions import RequestEntityTooLarge

from assessment import CONFIG, assess, severity_for, normalize_user_inputs
from image_processing import quality_for, merge_detections, aggregate_fabrics
from auth_routes import auth_bp
from database import init_schema, ping_database
from model_runtime import load_fabric_model

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = CONFIG["input"]["maximum_upload_bytes"]
CORS(app)
app.register_blueprint(auth_bp)

BASE_DIR = Path(__file__).resolve().parent

FABRIC_MODEL_PATH = BASE_DIR / "model" / "fabric_glcm_decision_tree.pkl"
FABRIC_LABELS_PATH = BASE_DIR / "model" / "fabric_labels.json"
DAMAGE_MODEL_PATH = BASE_DIR / "model" / "best.pt"

fabric_model = load_fabric_model(FABRIC_MODEL_PATH)

with open(FABRIC_LABELS_PATH, "r", encoding="utf-8") as f:
    fabric_labels = json.load(f)

damage_model = YOLO(str(DAMAGE_MODEL_PATH))


def extract_glcm_features(image_path):
    image = cv2.imread(image_path)

    if image is None:
        raise ValueError("Cannot read image.")

    image = cv2.resize(image, (128, 128))
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    gray = (gray / 32).astype(np.uint8)

    glcm = graycomatrix(
        gray,
        distances=[1, 2, 4],
        angles=[0, np.pi / 4, np.pi / 2, 3 * np.pi / 4],
        levels=8,
        symmetric=True,
        normed=True,
    )

    features = []

    properties = [
        "contrast",
        "dissimilarity",
        "homogeneity",
        "energy",
        "correlation",
        "ASM",
    ]

    for prop in properties:
        values = graycoprops(glcm, prop)
        features.extend(values.flatten())

    features.append(np.mean(gray))
    features.append(np.std(gray))

    return np.array(features).reshape(1, -1)


def fabric_label(value):
    if isinstance(value, (str, np.str_)) and value in fabric_labels:
        return str(value)
    return fabric_labels[int(value)]


def classify_fabric(image_path):
    features = extract_glcm_features(image_path)
    prediction = fabric_model.predict(features)[0]
    label = fabric_label(prediction)
    if hasattr(fabric_model, "predict_proba"):
        probabilities = fabric_model.predict_proba(features)[0]
        classes = getattr(fabric_model, "classes_", range(len(probabilities)))
        scores = {fabric_label(value): float(probability)
                  for value, probability in zip(classes, probabilities)}
    else:
        scores = {label: 1.0}
    return {"fabric_type": label, "confidence": scores[label] * 100, "probabilities": scores}


def detect_damage(image_path, image_index=0, view="front"):
    policy = CONFIG["detection"]
    result = damage_model.predict(source=image_path, imgsz=policy["image_size"],
                                  conf=policy["minimum_confidence"], save=False, verbose=False)[0]
    image_height, image_width = result.orig_shape
    detections = []
    for index, box in enumerate(result.boxes):
        x1, y1, x2, y2 = box.xyxy[0].tolist()
        x1, x2 = sorted((max(0, min(image_width, x1)), max(0, min(image_width, x2))))
        y1, y2 = sorted((max(0, min(image_height, y1)), max(0, min(image_height, y2))))
        bbox = [x1 / image_width, y1 / image_height,
                (x2 - x1) / image_width, (y2 - y1) / image_height]
        area_ratio = bbox[2] * bbox[3]
        confidence = float(box.conf.item()) * 100
        label = damage_model.names[int(box.cls.item())]
        detections.append({
            "id": f"{image_index}:{index}", "type": label, "label": label,
            "confidence": round(confidence, 2),
            "status": "Detected" if confidence >= policy["detected_percent"] else "Possible",
            "severity": severity_for(area_ratio), "area_ratio": area_ratio,
            "bbox": bbox, "image_index": image_index, "view": view,
        })
    return detections


def uploaded_views():
    """Legacy: image=<file>. New: images=<repeated files>, views=<JSON array>."""
    legacy = "image" in request.files and "images" not in request.files
    if legacy:
        return [("front", request.files["image"])], True
    files = request.files.getlist("images")
    try:
        views = json.loads(request.form.get("views", "[]"))
    except (ValueError, TypeError):
        raise ValueError("views must be a JSON array")
    if not isinstance(views, list) or len(files) != len(views) or not files:
        raise ValueError("Provide images and a matching views array")
    if len(files) > CONFIG["input"]["maximum_images"]:
        raise ValueError("At most three images are supported")
    if any(not isinstance(view, str) or view not in CONFIG["input"]["views"] for view in views):
        raise ValueError("Unsupported image view")
    if len(set(views)) != len(views) or "front" not in views:
        raise ValueError("Front is required and each view must be unique")
    return list(zip(views, files)), False


def prepare_images(uploads, directory):
    records = []
    for index, (view, upload) in enumerate(uploads):
        path = str(Path(directory) / f"image_{index}.jpg")
        upload.save(path)
        image = cv2.imread(path)
        if image is None:
            raise ValueError(f"Cannot read {view} image. Upload a valid photo.")
        height, width = image.shape[:2]
        records.append({"image_index": index, "view": view, "width": width,
                        "height": height, "quality": quality_for(image), "path": path})
    return records


def public_image(record):
    return {key: value for key, value in record.items() if key != "path"}


@app.errorhandler(413)
def upload_too_large(_error):
    return jsonify({"error": "Images exceed the upload limit. Use smaller photos."}), 413


@app.route("/quality", methods=["POST"])
def check_quality():
    try:
        uploads, _ = uploaded_views()
        with tempfile.TemporaryDirectory() as directory:
            records = prepare_images(uploads, directory)
            return jsonify({"per_image": [public_image(r) for r in records]})
    except RequestEntityTooLarge:
        raise
    except ValueError as error:
        return jsonify({"error": str(error)}), 400
    except Exception:
        app.logger.exception("Quality check failed")
        return jsonify({"error": "Could not check image quality. Try again."}), 500


@app.route("/analyze", methods=["POST"])
def analyze():
    try:
        uploads, legacy = uploaded_views()
        try:
            user_inputs = normalize_user_inputs(json.loads(request.form.get("user_inputs", "{}")))
        except (ValueError, TypeError) as error:
            raise ValueError(f"Invalid garment history: {error}")
        with tempfile.TemporaryDirectory() as directory:
            records = prepare_images(uploads, directory)
            failed_quality = any(not r["quality"]["passed"] for r in records)
            if failed_quality and not legacy and request.form.get("allow_low_quality") != "true":
                return jsonify({"error": "Review image quality and retake or continue anyway.",
                                "quality_requires_confirmation": True,
                                "per_image": [public_image(r) for r in records]}), 422
            predictions = []
            detections = []
            for record in records:
                prediction = classify_fabric(record["path"])
                record.update(prediction)
                predictions.append(prediction)
                raw = detect_damage(record["path"], record["image_index"], record["view"])
                record["raw_detections"] = raw
                detections.extend(raw)
            fabric = aggregate_fabrics(predictions)
            merged = merge_detections(detections)
            return jsonify({
                "schema_version": 2, **fabric, "damages": merged,
                "per_image": [public_image(r) for r in records],
                "quality_override": failed_quality,
                **assess(fabric["fabric_type"], merged, user_inputs),
            })
    except RequestEntityTooLarge:
        raise
    except ValueError as error:
        return jsonify({"error": str(error)}), 400
    except Exception:
        app.logger.exception("Analysis failed")
        return jsonify({"error": "Analysis failed. Please try another image."}), 500


@app.route("/", methods=["GET"])
def home():
    db_ok = False
    db_error = None
    try:
        ping_database()
        db_ok = True
    except Exception:
        db_error = "Database unavailable."

    return jsonify({
        "message": "FabricCare API is running.",
        "fabric_model": "GLCM + Decision Tree",
        "damage_model": "YOLOv8",
        "fabric_labels": fabric_labels,
        "damage_labels": list(damage_model.names.values()),
        "runtime": {"python": platform.python_version(), "scikit_learn": sklearn.__version__},
        "database": "MySQL",
        "database_connected": db_ok,
        "database_error": db_error,
    })


@app.route("/health/ready", methods=["GET"])
def readiness():
    try:
        ping_database()
    except Exception:
        return jsonify({"ready": False, "database_connected": False}), 503
    return jsonify({"ready": True, "database_connected": True})


if __name__ == "__main__":
    try:
        init_schema()
        print("MySQL schema ready.")
    except Exception as e:
        print(f"MySQL setup failed: {e}")
        print("Check .env (copy from .env.example) and that MySQL is running.")
    app.run(host="0.0.0.0", port=5000, debug=False, use_reloader=False)
