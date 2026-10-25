# Model compatible API runtime

Use the isolated CPython 3.12 environment at `.venv-api` for the API. The old
parent `.venv` uses Python 3.14 and scikit-learn 1.9.0; it is preserved, but it
must not be used to serve the existing classifier.

The saved Decision Tree requires scikit-learn 1.6.1. This matches the model's
embedded version without re-saving, converting, modifying, or retraining it.
Python 3.12 has an official 1.6.1 Windows wheel in the
[release metadata](https://pypi.org/project/scikit-learn/1.6.1/#files).
Scikit-learn recommends loading persisted models with the same package version;
cross-version loading is unsupported. See its
[model persistence documentation](https://scikit-learn.org/stable/model_persistence.html).

## Setup and start

Run these PowerShell commands from the `fabricare` repository:

```powershell
.\scripts\setup_api.ps1
.\.venv-api\Scripts\python.exe .\fabricare_api.py
```

For a USB-connected Android phone, the existing startup command now uses the
same environment:

```powershell
.\scripts\start_dev.ps1
```

The setup script accepts `-Python312 'C:\path\to\python.exe'` if Python 3.12 is
installed elsewhere. It validates the interpreter, installs binary wheels, and
runs `pip check`. It uses `requirements-api.lock.txt` when present, with
`requirements.txt` as the initial-resolution fallback. The environment is ignored
by Git. The existing `.env` remains unchanged.

`requirements.txt` pins scikit-learn 1.6.1, NumPy 2.2.6, and SciPy 1.15.3 for
the compatible numerical stack. The core Flask, YOLO, PyTorch, image-processing,
and database-client versions are pinned to the versions already used by the
previous API smoke test. The lock file also pins the resolved transitive
dependencies for repeatable Windows/Python 3.12 installs.

## Runtime protection and verification

`model_runtime.py` treats `InconsistentVersionWarning` as a startup error and
points to the correct setup command. It neither suppresses the warning nor
changes the serialized estimator to claim another version. `GET /` includes
`runtime.python` and `runtime.scikit_learn` so the running service can be checked.

```powershell
.\.venv-api\Scripts\python.exe -m pip check
.\.venv-api\Scripts\python.exe -m unittest test_assessment test_image_processing test_api_contract test_model_runtime -v
.\.venv-api\Scripts\python.exe .\scripts\check_api.py
```

For a predeployment gate that also requires the configured database to be
reachable, add `--require-database`. The script exits with an error if the
analysis checks pass but MySQL health is false.

The HTTP check starts a temporary loopback server with the real unchanged
models, then checks health/runtime metadata, legacy single-image analysis,
three-view analysis and garment inputs, quality warnings, explicit override,
and missing-image rejection. It verifies model hashes did not change and shuts
down the server afterward. It only reads database connectivity through the
health route; it does not create users, update garments, or initialize schemas.

Synthetic smoke-test photos verify runtime wiring and response contracts. They
do not establish model accuracy on garments or replace physical-phone testing.

## Verified results on October 20 2026

- Python 3.12.6, scikit-learn 1.6.1, NumPy 2.2.6, and SciPy 1.15.3.
- `pip check`: no broken requirements.
- All 19 backend tests passed, including the new model-version guard tests.
- Real HTTP checks with the existing models passed: health returned 200,
  legacy single-image and three-view analysis returned 200, quality preflight
  returned 200, unconfirmed low-quality input returned 422, explicit override
  returned 200, and missing images returned 400.
- No sklearn version warning occurred during real model loading or inference.
- Model and label hashes matched before and after inference; no retraining or
  model serialization was performed.
- `scripts/setup_api.ps1` was rerun against the generated lock and completed
  successfully with no dependency changes needed.
- `scripts/check_api.py --require-database` completed the same successful model
  and HTTP checks, then exited with status 1 because MySQL health was false.

Full predeployment readiness remains blocked by the local MySQL connection.
The configured loopback port is 3307 and connection fails with error 2003.
The running MySQL80 service listens on port 3306, but a read-only attempt there
with the existing credentials is rejected with error 1045. The configuration and
credentials were not changed. Confirm the intended instance and update its local
`.env` connection details; do not put passwords in chat, reports, or Git. The HTTP
test reports `database_connected: false` and `predeployment_ready: false` until
that is resolved. No database data or schema was modified by these checks.
