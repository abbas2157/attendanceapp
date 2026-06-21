# bams_app

Flutter mobile app for the BAMS attendance system.

## Current role

This app serves two product areas:

1. **Public attendance station flow**
   - verify device location against warehouse geofence
   - enter employee code or attendance code
   - precheck the submitted code before opening the camera
   - capture live face frame
   - submit attendance request to the Django backend

2. **HR/admin employee enrollment**
   - login required
   - capture three live enrollment samples
   - submit employee profile and `photos[]` to the Django backend

## Backend contract

The app integrates with the Django/DRF backend in `D:\BAMS`.

Important current API rules:

- attendance is public, but requires:
  - `currentlocation`
  - `frame`
  - `employeecode` or `attendancecode`
- employee enrollment is protected and requires:
  - `photos[]`
  - minimum 3 samples
  - optional `angle_labels`
  - optional `capture_session_id`

## Important notes

- This app no longer follows the older Laravel/TFLite-on-device design.
- Face embeddings are generated on the backend.
- Local ML Kit is used only for lightweight face presence checks before upload.
- Recent successful employee/attendance codes are stored locally to speed up daily punching.
- Real device metadata is sent with attendance attempts for audit review.

## Development

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter run
```
