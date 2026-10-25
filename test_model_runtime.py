import unittest
import warnings
from unittest.mock import patch

from sklearn.exceptions import InconsistentVersionWarning
from model_runtime import load_fabric_model


class ModelRuntimeTests(unittest.TestCase):
    def test_matching_runtime_loads_original_file(self):
        model = object()
        with patch("model_runtime.joblib.load", return_value=model) as load:
            self.assertIs(load_fabric_model("unchanged.pkl"), model)
        load.assert_called_once_with("unchanged.pkl")

    def test_mismatched_runtime_fails_instead_of_hiding_warning(self):
        def incompatible(_path):
            warnings.warn(InconsistentVersionWarning(
                estimator_name="DecisionTreeClassifier",
                current_sklearn_version="1.9.0",
                original_sklearn_version="1.6.1",
            ))
        with patch("model_runtime.joblib.load", side_effect=incompatible):
            with self.assertRaisesRegex(RuntimeError, r"needs scikit-learn 1\.6\.1"):
                load_fabric_model("unchanged.pkl")


if __name__ == "__main__":
    unittest.main()
