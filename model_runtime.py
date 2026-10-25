"""Load the existing classifier without accepting a sklearn version mismatch."""
import warnings

import joblib
from sklearn.exceptions import InconsistentVersionWarning


def load_fabric_model(path):
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", InconsistentVersionWarning)
            return joblib.load(path)
    except InconsistentVersionWarning as error:
        raise RuntimeError(
            f"Fabric model needs scikit-learn {error.original_sklearn_version}; "
            f"this interpreter has {error.current_sklearn_version}. "
            "Run scripts/setup_api.ps1 and start with .venv-api/Scripts/python.exe. "
            "Do not re-save or retrain the model to fix the environment."
        ) from error
