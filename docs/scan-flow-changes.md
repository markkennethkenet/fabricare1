# FabriCare scan flow implementation

The scan flow supports one required front image and optional back and close-up
images, server-owned assessments, and persistent history per signed-in account.
Existing model files were neither modified nor retrained. Care-label OCR remains
mocked. Run the updated backend together with the updated app.

## Files changed by phase

Several integration files span phases. This list groups them by responsibility;
it does not imply separate commits were created.

### Phase 1 Backend assessment authority

- `assessment_config.json` added: one policy structure for severity, detection
  thresholds, deductions, multipliers, grades, lifespan, image quality, and care.
- `assessment.py` added: backend-only severity, score, grade, care, and lifespan.
- `fabricare_api.py`: normalized bounding boxes and area-derived severity;
  confidence retained separately; backend assessment returned to clients.
- `lib/services/health_score_calculator.dart`: removed all duplicated calculation
  logic; retained only a comment pointing to the backend policy.
- `lib/screens/profile/profile_screen.dart`: derive the good-condition count
  from backend grades instead of another numeric score cutoff.
- `lib/theme/app_theme.dart`: recognize the canonical `minor` severity in badge
  colors.
- `lib/services/fabricare_api_service.dart`, `lib/models/scan_result.dart`,
  `lib/data/mock_data.dart`, `lib/screens/scan/scan_screen.dart`, and
  `lib/screens/scan/scan_result_screen.dart`: display and save backend assessments
  instead of locally recalculating or using static lifespan values.
- `test_assessment.py` added, then extended in Phase 4.

### Phase 2 Complete detections and persistent history

- `lib/models/damage_detection.dart`: arbitrary detection instances and types,
  bounding boxes, extent, confidence, source index, and view.
- `lib/models/scan_result.dart`: complete API response, image paths, timestamp,
  account ID, inputs, and notes serialized together.
- `lib/services/fabricare_api_service.dart`: retain every returned detection and
  read supported labels from API metadata; removed path-based response caching.
- `lib/services/history_store.dart` added: Hive records and permanent photo
  copies, account filtering, delete-single, and clear-current-account.
- `lib/data/mock_data.dart`, `lib/main.dart`: initialize history and synchronize
  its active account with the existing authentication service.
- `lib/widgets/detection_image.dart` added: normalized box overlays without
  cropping the source image.
- `lib/screens/scan/scan_result_screen.dart`: list all returned detections.
- `lib/screens/history/history_screen.dart`,
  `lib/screens/history/garment_profile_screen.dart`,
  `lib/screens/profile/profile_screen.dart`: persistent history actions, saved
  notes, full-result navigation, and storage-error feedback.
- `pubspec.yaml`, `pubspec.lock`: add Hive 2.2.3.
- `test/history_store_test.dart` added; `test/widget_test.dart` replaced the
  commented-out template with working result and guided-scan tests.

Hive was chosen because nested scan records fit its local key-value storage and
it supports the app's mobile and desktop targets without native database setup.
See the [package documentation](https://pub.dev/packages/hive).

### Phase 3 Guided multiple images and quality checks

- `image_processing.py` added: Laplacian variance, grayscale brightness,
  same-image/type overlap suppression, and prediction aggregation.
- `fabricare_api.py`: legacy and repeated-file request parsing, `/quality`,
  `/analyze`, upload limits, temporary-file cleanup, per-image results, and
  combined assessment.
- `assessment_config.json`: quality thresholds and upload/view limits.
- `lib/services/fabricare_api_service.dart`: single-image compatibility wrapper,
  multi-image upload, quality preflight, and explicit quality override.
- `lib/screens/scan/scan_screen.dart`: guided capture, gallery, retake and optional
  view removal, lighting/distance guidance, quality review, and loading/errors.
- `lib/screens/scan/scan_result_screen.dart`,
  `lib/widgets/detection_image.dart`: source views, individual predictions,
  quality status, boxes, and combined result.
- `test_image_processing.py`, `test_api_contract.py` added.

### Phase 4 Garment history and lifespan estimates

- `assessment.py`, `assessment_config.json`: input validation, age and wear
  factors, remaining months, six-month projected score/grade, and actual usage
  descriptions.
- `fabricare_api.py`: accepts and echoes normalized garment history.
- `lib/screens/scan/scan_screen.dart`: condition, purchase-date knowledge/date,
  frequency of use, and washing frequency.
- `lib/services/fabricare_api_service.dart`, `lib/models/scan_result.dart`,
  `lib/data/mock_data.dart`: preserve normalized inputs in the saved scan.
- `lib/screens/scan/scan_result_screen.dart`: clearly labeled rule-based estimates.
- `test_assessment.py`, `test_api_contract.py`: added date/input validation,
  monotonic wear effects, bounds, and input round-trip coverage.

## API compatibility and contract

### Original request remains supported

`POST /analyze`, multipart form, with `image=<file>`.

Original response keys remain: `fabric_type`, `fabric_confidence`, `damages`,
`health_score`, `condition_rating`, `estimated_lifespan`, and
`care_recommendation`. Damage `label` and `status` aliases also remain. Severity
now intentionally uses the canonical lowercase extent labels instead of the old
confidence-derived values. Legacy requests receive quality warnings but are not
blocked by the new confirmation requirement.

### Multiple-image request

`POST /analyze`, multipart form:

- Repeated `images` file parts, at most three.
- `views`: JSON array matching file order, such as
  `["front", "back", "close_up"]`. Front is required; views must be unique.
- `user_inputs`: optional JSON object.
- `allow_low_quality`: `"true"` only when the user explicitly continues after a
  quality warning. Default false for the new request format.

Example garment input:

```json
{
  "condition": "previously_used",
  "purchase_date_known": true,
  "purchase_date": "2026-01-20",
  "use_frequency": "several_times_a_week",
  "washing_frequency": "weekly"
}
```

Conditions are `new` or `previously_used`. Use frequencies are `rarely`, `weekly`,
`several_times_a_week`, or `daily`. Wash frequencies are `rarely`, `monthly`,
`weekly`, or `multiple_per_week`. Missing legacy inputs use `unspecified` neutral
defaults, which the response describes. Purchase date is optional; it is required
when a previously-used garment's purchase date is marked known. Future dates
and invalid values return HTTP 400. Date calculations use UTC+8 by configuration.

Each item in `damages` contains:

```json
{
  "id": "0:0",
  "type": "class name from model metadata",
  "label": "class name from model metadata",
  "confidence": 91.5,
  "status": "Detected",
  "severity": "moderate",
  "area_ratio": 0.04,
  "bbox": [0.1, 0.2, 0.2, 0.2],
  "image_index": 0,
  "view": "front"
}
```

Coordinates are normalized top-left x, top-left y, width, and height. Confidence
is a percentage, independent of severity. Detections meeting the configured
YOLO inference threshold are retained; lower-confidence retained boxes are
marked `Possible`, not silently dropped by the app. The overall score uses all
retained, deduplicated boxes, including those marked possible.

Added response fields include `schema_version: 2`, `fabric_probabilities`,
`per_image`, `quality_override`, normalized `user_inputs`, `usage_status`,
`estimated_remaining_months`, `projected_condition_after_6_months`,
`estimate_method`, and `estimate_details`.

Each `per_image` record contains its index/view, dimensions, fabric prediction,
confidence, class probabilities, raw detections, and quality:

```json
{
  "blur_score": 100.0,
  "brightness": 125.0,
  "passed": true,
  "reason": ""
}
```

`POST /quality` accepts the same file/view format and returns `per_image` records
without running model inference. The app calls it before analysis. A failing
new-format `/analyze` request without override returns HTTP 422 with
`quality_requires_confirmation: true` and per-image quality records. Invalid
inputs return JSON HTTP 400; excessive uploads return JSON HTTP 413. The default
total request limit is 20 MiB. Server temporary upload paths are never returned.

`GET /` retains existing health metadata and adds `fabric_labels` from the
existing label config and `damage_labels` from YOLO metadata. Neither client
parsing nor result rendering depends on a fixed class list.

## Assessment rules

Severity uses bbox area divided by full image area: below 2% is `minor`, 2–8%
inclusive is `moderate`, and above 8% is `severe`. These values are configurable.

Score starts at 100 and subtracts per-instance type deductions times severity
multipliers, clamped to 0–100. Unknown damage types use the configured default
deduction. One backend grade scale is used everywhere: Excellent at 90, Good at
75, Fair at 50, and Poor below 50. Flutter never recomputes these values.

Fabric probabilities are averaged equally across images. Without probability
support, one-hot per-image votes are averaged. Exact ties resolve by sorted label
order. Overlapping same-type boxes are suppressed at configurable IoU >= 0.5
within the same image, retaining the highest-confidence box and its geometry.
Different views remain separate; matching coordinates across views cannot
establish that they show the same physical defect. Original raw boxes remain
available in each image's `raw_detections` field.

Lifespan is explicitly an unvalidated rule-based estimate. The heuristic is:

```text
wear = use factor × wash factor × garment-condition factor × highest severity factor
budget = max(0, base fabric months × score / 100 − calendar age months × 0.5)
remaining months = budget / wear, bounded to 0 through 1.5 × base fabric months
six month score = max(0, score − (100 / base fabric months) × wear × 6)
```

The six-month grade uses the same backend grade scale. Half-age adjustment is a
configurable heuristic to limit counting age already reflected in visible
condition. Fabric baselines, unknown-class defaults, wear factors, bounds, and
projection interval are all in `assessment_config.json`. No calibration or
validation study is claimed. Current configured baseline months are cotton 24,
denim 36, polyester 24, and unknown classes 24.

## Verification actually performed

- `dart pub get`: passed; added only Hive as a dependency. Initial sandboxed run
  failed on network/telemetry access; approved rerun succeeded.
- `python -m unittest test_assessment test_image_processing test_api_contract -v`
  using `C:/flutter-project/.venv/Scripts/python.exe`: all 17 tests passed.
  Contract tests mock model construction/inference and use real Flask/OpenCV
  upload processing. Initial sandbox upload tests failed due to temporary-file
  permissions; approved rerun passed.
- `flutter test --no-pub`: all 3 tests passed with a 55-second process limit.
  Tests cover persistent record/photo reopen, account isolation, delete/clear,
  repeated/future detection classes, backend grade display, and guided scan UI.
- `flutter analyze` with a 45-second process limit: printed `No issues found!
  (ran in 41.1s)` but the process wrapper reached its timeout. This is not
  reported as a clean command exit. The requested fallback was run.
- Final `dart analyze lib` and `dart analyze test`: both completed successfully
  with no issues. Intermediate brace lint findings were fixed before rerunning.
- Dart formatter: completed successfully on updated files. An initial run
  formatted files but exited on telemetry permissions; approved rerun succeeded.
- Real-model smoke test: existing Decision Tree and YOLO loaded and `/analyze`
  returned HTTP 200/schema version 2 for a synthetic image. This verifies runtime
  wiring, not accuracy on real garments.
- `git diff --check`: passed. Model/config label SHA-256 hashes matched the
  values recorded during the work; Git shows no model changes.

## Remaining limitations and predeployment checks

- Care-label OCR is still mocked and untouched.
- Mixed fabrics and stain subtypes still need suitable training data and model
  retraining/evaluation. Dynamic class handling does not add those capabilities
  to the existing weights.
- Severity measures image extent, not physical garment damage area. Framing and
  distance affect it; close-ups may produce larger severity ratios.
- Different views can show the same defect and cause multiple deductions. This
  intentional cross-view policy avoids claiming identity from unrelated 2D boxes.
- Texture and lighting affect blur/brightness checks. Thresholds and lifespan
  factors require validation with your target garments and devices.
- The quality preflight and analysis upload the same photos twice; no model work
  happens during preflight.
- History is local to the device and scoped by the existing MySQL-auth account
  ID. Logout hides that account's records; it does not delete them. There is no
  cloud synchronization. The old in-memory records cannot be recovered after an
  earlier process has already exited.
- The initial scikit-learn version mismatch has since been fixed using an
  isolated Python 3.12/scikit-learn 1.6.1 environment without changing the model.
  See [API runtime setup and verification](api-runtime.md) for the new startup
  command, pinned dependencies, 19 passing tests, real HTTP checks, and the
  remaining local MySQL connectivity blocker.
- Physical-phone camera permissions, real-garment image accuracy, live MySQL
  login, and an installed app's restart/navigation flow were not manually tested.
  Hive reopen and account filtering were verified in automated tests.
