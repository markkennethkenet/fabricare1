"""Real HTTP smoke checks with unchanged models and synthetic photos.

No training, model reserialization, auth changes, or database writes. An ephemeral
loopback server is shut down at the end. Synthetic images do not validate accuracy.
"""
import hashlib
import argparse
import io
import json
from pathlib import Path
import sys
from threading import Thread

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import cv2
import numpy as np
import requests
from werkzeug.serving import make_server


def hashes():
    return {path.name: hashlib.sha256(path.read_bytes()).hexdigest()
            for path in (ROOT / "model").iterdir() if path.is_file()}


def main(require_database=False):
    before = hashes()
    # The application's loader treats InconsistentVersionWarning as an error.
    import fabricare_api as api

    server = make_server("127.0.0.1", 0, api.app, threaded=True)
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()
    session = requests.Session()
    session.trust_env = False
    base = f"http://127.0.0.1:{server.server_port}"
    checks = {}

    def photo(seed=7, dark=False):
        image = np.zeros((128, 128, 3), dtype=np.uint8) if dark else np.random.default_rng(seed).integers(
            50, 200, (128, 128, 3), dtype=np.uint8)
        return cv2.imencode(".png", image)[1].tobytes()

    def multi(dark=False, count=3):
        return [("images", (f"view_{i}.png", io.BytesIO(photo(7 + i, dark)), "image/png"))
                for i in range(count)]

    def validate(body, count):
        assert body["schema_version"] == 2
        assert body["fabric_type"] in api.fabric_labels
        assert 0 <= body["health_score"] <= 100
        assert len(body["per_image"]) == count
        assert body["estimate_method"] == "rule_based_not_validated"
        assert "projected_condition_after_6_months" in body
        for detection in body["damages"]:
            assert detection["severity"] in {"minor", "moderate", "severe"}
            assert 0 <= detection["area_ratio"] <= 1
            assert all(0 <= coordinate <= 1 for coordinate in detection["bbox"])
            assert detection["view"] == body["per_image"][detection["image_index"]]["view"]

    try:
        response = session.get(base + "/", timeout=15)
        response.raise_for_status()
        health = response.json()
        assert health["runtime"]["scikit_learn"] == "1.6.1"
        checks["health"] = response.status_code
        checks["database_connected"] = health["database_connected"]
        checks["runtime"] = health["runtime"]

        response = session.post(base + "/analyze", files={"image": ("front.png", photo())}, timeout=90)
        assert response.status_code == 200, response.text
        validate(response.json(), 1)
        checks["legacy_single_image"] = response.status_code

        inputs = {"condition": "previously_used", "purchase_date_known": False,
                  "use_frequency": "daily", "washing_frequency": "weekly"}
        response = session.post(base + "/analyze", files=multi(), data={
            "views": '["front", "back", "close_up"]', "user_inputs": json.dumps(inputs)}, timeout=120)
        assert response.status_code == 200, response.text
        validate(response.json(), 3)
        assert response.json()["user_inputs"]["use_frequency"] == "daily"
        checks["three_views_and_garment_history"] = response.status_code

        response = session.post(base + "/quality", files=multi(dark=True, count=1),
                                data={"views": '["front"]'}, timeout=30)
        assert response.status_code == 200, response.text
        assert not response.json()["per_image"][0]["quality"]["passed"]
        checks["quality_warning"] = response.status_code

        response = session.post(base + "/analyze", files=multi(dark=True, count=1),
                                data={"views": '["front"]'}, timeout=30)
        assert response.status_code == 422, response.text
        checks["quality_confirmation_required"] = response.status_code

        response = session.post(base + "/analyze", files=multi(dark=True, count=1),
                                data={"views": '["front"]', "allow_low_quality": "true"}, timeout=90)
        assert response.status_code == 200, response.text
        validate(response.json(), 1)
        checks["quality_override"] = response.status_code

        response = session.post(base + "/analyze", timeout=15)
        assert response.status_code == 400, response.text
        checks["missing_image_rejected"] = response.status_code
        assert hashes() == before, "Model files changed during inference"
        checks["models_unchanged"] = True
        checks["predeployment_ready"] = bool(checks["database_connected"])
        print(json.dumps(checks, indent=2))
        if require_database and not checks["database_connected"]:
            raise SystemExit("MySQL health failed. Correct the local database connection before predeployment.")
    finally:
        session.close()
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--require-database", action="store_true",
                        help="Fail the readiness check when MySQL health is false")
    main(require_database=parser.parse_args().require_database)
