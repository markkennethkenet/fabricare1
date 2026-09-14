from flask import Flask, request, jsonify
from flask_cors import CORS
from pathlib import Path
import tempfile
import json
import joblib
import cv2
import numpy as np
from skimage.feature import graycomatrix, graycoprops
from ultralytics import YOLO

from auth_routes import auth_bp
from database import db_error_message, init_schema, ping_database

app = Flask(__name__)
CORS(app)
app.register_blueprint(auth_bp)

BASE_DIR = Path(__file__).resolve().parent

FABRIC_MODEL_PATH = BASE_DIR / "model" / "fabric_glcm_decision_tree.pkl"
FABRIC_LABELS_PATH = BASE_DIR / "model" / "fabric_labels.json"
DAMAGE_MODEL_PATH = BASE_DIR / "model" / "best.pt"

fabric_model = joblib.load(FABRIC_MODEL_PATH)

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


def classify_fabric(image_path):
    features = extract_glcm_features(image_path)

    prediction = fabric_model.predict(features)[0]
    fabric_type = fabric_labels[prediction]

    confidence = None

    if hasattr(fabric_model, "predict_proba"):
        probabilities = fabric_model.predict_proba(features)[0]
        confidence = float(max(probabilities) * 100)

    return {
        "fabric_type": fabric_type,
        "confidence": confidence,
    }


def get_detection_status(confidence):
    if confidence >= 80:
        return "Detected"
    elif confidence >= 60:
        return "Possible"
    return "Ignored"


def get_severity(confidence):
    if confidence >= 90:
        return "Severe"
    elif confidence >= 80:
        return "Moderate"
    elif confidence >= 60:
        return "Mild"
    return "None"


def detect_damage(image_path):
    results = damage_model.predict(
    source=image_path,
    imgsz=640,
    conf=0.25,
    save=False,
    verbose=False,
)

    result = results[0]

    detections = []

    for box in result.boxes:
        class_id = int(box.cls.item())
        confidence = float(box.conf.item()) * 100
        label = damage_model.names[class_id]

        status = get_detection_status(confidence)

        if status == "Ignored":
            continue

        detections.append({
            "label": label,
            "confidence": round(confidence, 2),
            "status": status,
            "severity": get_severity(confidence),
        })

    return detections


def calculate_health_score(detections):
    score = 100

    deduction_table = {
        "stain": {
            "Mild": 5,
            "Moderate": 10,
            "Severe": 15,
        },
        "pilling": {
            "Mild": 5,
            "Moderate": 10,
            "Severe": 15,
        },
        "needlemark": {
            "Mild": 3,
            "Moderate": 7,
            "Severe": 12,
        },
        "hole": {
            "Mild": 10,
            "Moderate": 20,
            "Severe": 30,
        },
    }

    for detection in detections:
        label = detection["label"]
        severity = detection["severity"]

        if label in deduction_table:
            score -= deduction_table[label].get(severity, 0)

    if score < 0:
        score = 0

    return score


def get_condition_rating(score):
    if score >= 90:
        return "Excellent"
    elif score >= 75:
        return "Good"
    elif score >= 50:
        return "Fair"
    return "Poor"


def get_lifespan(score):
    if score >= 90:
        return "18+ months"
    elif score >= 75:
        return "12–18 months"
    elif score >= 50:
        return "8–14 months"
    return "4–8 months"


def get_care_recommendation(fabric_type):
    fabric_type = fabric_type.lower()

    if fabric_type == "cotton":
        return {
            "laundry_mode": "Normal or gentle wash",
            "care_advice": "Use cold or warm water. Avoid very high heat.",
            "risk_warning": "Cotton may shrink when exposed to high heat.",
        }

    if fabric_type == "denim":
        return {
            "laundry_mode": "Normal wash",
            "care_advice": "Wash inside-out using cold water.",
            "risk_warning": "Denim may fade with frequent washing.",
        }

    if fabric_type == "polyester":
        return {
            "laundry_mode": "Gentle or normal wash",
            "care_advice": "Use cold water and low heat drying.",
            "risk_warning": "Polyester may deform under high heat.",
        }

    return {
        "laundry_mode": "Unknown",
        "care_advice": "No recommendation available.",
        "risk_warning": "No risk warning available.",
    }


@app.route("/analyze", methods=["POST"])
def analyze():
    if "image" not in request.files:
        return jsonify({"error": "No image uploaded."}), 400

    image = request.files["image"]

    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as temp:
        image.save(temp.name)
        image_path = temp.name

    try:
        fabric_result = classify_fabric(image_path)
        detections = detect_damage(image_path)

        health_score = calculate_health_score(detections)
        condition_rating = get_condition_rating(health_score)
        lifespan = get_lifespan(health_score)
        care = get_care_recommendation(fabric_result["fabric_type"])

        return jsonify({
            "fabric_type": fabric_result["fabric_type"],
            "fabric_confidence": fabric_result["confidence"],
            "damages": detections,
            "health_score": health_score,
            "condition_rating": condition_rating,
            "estimated_lifespan": lifespan,
            "care_recommendation": care,
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/", methods=["GET"])
def home():
    db_ok = False
    db_error = None
    try:
        ping_database()
        db_ok = True
    except Exception as e:
        db_error = db_error_message(e)

    return jsonify({
        "message": "FabricCare API is running.",
        "fabric_model": "GLCM + Decision Tree",
        "damage_model": "YOLOv8",
        "database": "MySQL",
        "database_connected": db_ok,
        "database_error": db_error,
    })


if __name__ == "__main__":
    try:
        init_schema()
        print("MySQL schema ready.")
    except Exception as e:
        print(f"MySQL setup failed: {e}")
        print("Check .env (copy from .env.example) and that MySQL is running.")
    app.run(host="0.0.0.0", port=5000, debug=False, use_reloader=False)