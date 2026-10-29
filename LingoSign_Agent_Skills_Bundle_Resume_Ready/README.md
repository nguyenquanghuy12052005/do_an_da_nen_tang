# LingoSign AI

Flutter Android app for an offline-first sign recognition capstone. The current
implementation has navigation, Material 3 light/dark themes, a Drift SQLite
schema and local repositories, plus an opt-in camera preview with permission
handling. The supplied PCA/Random Forest now runs offline for a 42-value
landmark vector. The camera now runs on-device hand landmark detection and
shows an experimental model prediction when a hand is detected.

The implementation plan and acceptance criteria are in [PLAN.md](PLAN.md).
Agent handoff status is in [docs/agent/PROGRESS.md](docs/agent/PROGRESS.md).
The received model artifacts and remaining contract questions are in
[docs/research/model_contract.md](docs/research/model_contract.md).

## Development

History now shows 10 records per page with previous/next controls. Each
one-second recognition window saves its maximum-confidence label and attempts
to capture a 240-pixel-wide thumbnail at the end of that window. Photos remain
in app-private storage; deleting a history row also removes its photo. Older
rows and capture failures display an image placeholder. Schema v3 migrates
existing history without wiping it. Camera capture while streaming still needs
physical-device validation.

From this directory, with Flutter 3.47.5 or a compatible stable SDK:

```text
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

The Android application ID is `com.lingosign.lingosign_ai` and the camera plugin
requires Android API 24+. No catalog content is bundled until its source and
license are verified. The provided scikit-learn pickle files are exported to
portable assets; no Python runtime or pickle loader is bundled in the app.
The original training artifacts in the Git-root `model/` folder are kept local
and are not part of this repository; the app uses the exported assets above.

## Offline model runtime

`OfflineForestModel.load()` in
`lib/features/recognition/data/model/offline_forest_model.dart` loads the bundled
scaler, PCA, labels and forest. Call `predict(features)` with 42 finite values in
`[x0, y0, ..., x20, y20]` order to get a label and class probabilities. The
camera pipeline in `camera_plugin_gateway.dart` detects 21 hand landmarks;
`hand_feature_extractor.dart` converts them to 42 values. The original CSV
capture code was not supplied, so the wrist/rotation/scale mapping is inferred
and recognition accuracy on real signs is unverified. To reproduce the portable assets from the trusted model
files at the Git root, run `python -W ignore tool/export_sklearn_model.py`; it
requires NumPy, scikit-learn and joblib on the development machine only and
does not train a model. `test/fixtures/model_parity_vectors.json` contains
synthetic Python outputs used for port parity tests, not accuracy evidence.

CI is configured at the Git repository root in
[ci.yml](../.github/workflows/ci.yml). The separate
[Android release workflow](../.github/workflows/release_android.yml) requires
upload-key secrets and has not produced a signed build yet; setup and device
verification steps are in [ANDROID_RELEASE_SETUP.md](docs/agent/ANDROID_RELEASE_SETUP.md).
