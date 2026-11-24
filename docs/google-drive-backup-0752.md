# MyBalance 0.7.52 — Google Drive backup verification

This feature in the Godot Android app (package `com.domenklay.mybalance.godot`) is **manual backup**, not automatic multi-device synchronization.

1. Connect to Google Drive in Settings. The app requests the `drive.appdata` scope for its private `appDataFolder`, not full Drive access.
2. Check the remote backup. Upload, download and delete accept both the checked file ID and MD5 digest. If the remote file changes, the operation stops and requires checking again. Downloads are checked against the digest before the restore confirmation is shown.
3. Restoration replaces the local journal only after confirmation. Export a local JSON copy first. Offline journaling continues to work without Google.
4. Configure Google Cloud with Drive API enabled, OAuth consent and an Android OAuth client for `com.domenklay.mybalance.godot`, registering the SHA-1 of the actual signing certificate. Debug, upload and Google Play App Signing keys may differ. Never commit signing keys or tokens.
5. QA: verify two devices (check on A, modify backup on B, then attempt upload/download/delete on A), corrupt backup handling, expired OAuth token, 5 MB limit, app reinstall and upgrades preserving data.

A debug APK is not a production signed AAB. Publish only after OAuth and release signing are tested on a real Android device.

References: https://developers.google.com/workspace/drive/api/reference/rest/v3/files/update ; https://developers.google.com/android/reference/com/google/android/gms/auth/api/identity/AuthorizationResult
