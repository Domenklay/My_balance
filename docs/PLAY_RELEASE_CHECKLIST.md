# Google Play release checklist — MyBalance

## 0.7.87: Android technical checks
- Godot 4.6.3 already defaults to target API 36. Explicitly pin it in the Android export preset; install Android SDK 36 and Build Tools 36.1.0 in CI.
- Preserve application ID, existing test signing key and arm64-v8a architecture.
- Validate the *actual* APK target API and package using aapt, APK signature using apksigner, ZIP alignment with zipalign -c -P 16 and each 64-bit ELF PT_LOAD using the repository checker.
- Existing OCR, widgets, step service, diary and UI regression tests remain required.
- These checks do not replace runtime testing on a 16 KB Android 15/16 device or emulator (adb shell getconf PAGE_SIZE must return 16384).
- Test camera/scanner, OCR, notification permission, background step recording, widgets, keyboard/safe area, app update and backup restoration on real Android.
- Existing test APK is not a production release. Do not upload it to production.

## Before publishing
- Signed AAB with private upload key and Play App Signing. Keep keys out of Git and logs; configure protected repository secrets only.
- Check generated bundle with bundletool dump config (PAGE_ALIGNMENT_16K) and generated APKs; test installation from the Play internal track.
- Verify Google OAuth for actual signing certificate(s), and register test accounts.
- Public privacy policy, in-app access, data deletion, Data safety and Health apps declarations; check foreground service and photo permissions.
- Audit data/photo/recipe licenses and attribution; review community feature availability and moderation.
- Store listing assets and support contact. Developer account identity/device checks, then any required closed testing.
- If upgrading from a debug-signed APK to the Play-signed application, signatures normally differ. Export and verify a local backup before uninstalling; never promise an in-place update across signing keys.

Official references:
- https://developer.android.com/google/play/requirements/target-sdk
- https://developer.android.com/guide/practices/page-sizes
- https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html
