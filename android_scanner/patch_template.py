"""Inject MyBalance native barcode scanner into Godot's generated Android Gradle template.

Runs on GitHub Actions after --install-android-build-template.
The generated android/build directory is intentionally untracked.
"""
from pathlib import Path
import re
import shutil

source = Path("android_scanner/src/main/java/com/domenklay/mybalance/barcode/MyBalanceBarcode.java")
cloud_source = Path("android_scanner/src/main/java/com/domenklay/mybalance/cloud/MyBalanceGoogleDrive.java")
root = Path("godot/android/build")
if not source.is_file() or not cloud_source.is_file() or not root.is_dir():
    raise SystemExit("Barcode plugin source / Godot Gradle template is missing")

build_candidates = sorted(
    p for p in root.rglob("build.gradle")
    if p.parent.name == "app"
)
# Official Godot android_source.zip packages the :app module at the archive root.
if not build_candidates and (root / "build.gradle").is_file():
    build_candidates = [root / "build.gradle"]
if not build_candidates:
    raise SystemExit("Godot Gradle module not found: " + ", ".join(map(str, root.rglob("build.gradle"))))
app_build = build_candidates[0]
app_root = app_build.parent
manifest = app_root / "src/main/AndroidManifest.xml"
if not manifest.is_file():
    manifest_candidates = list(root.rglob("AndroidManifest.xml"))
    raise SystemExit("No template manifest at " + str(manifest) +
                     "; found " + ", ".join(map(str, manifest_candidates)))

dest = app_root / "src/main/java/com/domenklay/mybalance/barcode/MyBalanceBarcode.java"
dest.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(source, dest)
cloud_dest = app_root / "src/main/java/com/domenklay/mybalance/cloud/MyBalanceGoogleDrive.java"
cloud_dest.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(cloud_source, cloud_dest)
reminder_src = source.parent.parent / "reminders"
reminder_dest = dest.parent.parent / "reminders"
reminder_dest.mkdir(parents=True, exist_ok=True)
for java_file in ("MyBalanceReminders.java", "ReminderReceiver.java"):
    shutil.copy2(reminder_src / java_file, reminder_dest / java_file)

gradle = app_build.read_text(encoding="utf-8")
scanner_dep = "implementation 'com.google.android.gms:play-services-code-scanner:16.1.0'"
if scanner_dep not in gradle:
    gradle += "\n\ndependencies {\n    " + scanner_dep + "\n}\n"
google_auth_dep = "implementation 'com.google.android.gms:play-services-auth:21.5.0'"
if google_auth_dep not in gradle:
    gradle += "\n\ndependencies {\n    " + google_auth_dep + "\n}\n"
app_build.write_text(gradle, encoding="utf-8")

manifest_xml = manifest.read_text(encoding="utf-8")
metadata = (
    "\n        <!-- Camera UI delegated to Google Play services; no CAMERA permission. -->\n"
    "        <meta-data android:name=\"org.godotengine.plugin.v2.MyBalanceBarcode\" "
    "android:value=\"com.domenklay.mybalance.barcode.MyBalanceBarcode\" />\n"
    "        <meta-data android:name=\"org.godotengine.plugin.v2.MyBalanceGoogleDrive\" "
    "android:value=\"com.domenklay.mybalance.cloud.MyBalanceGoogleDrive\" />\n"
    "        <meta-data android:name=\"com.google.mlkit.vision.DEPENDENCIES\" "
    "android:value=\"barcode_ui\" />\n"
)
if "org.godotengine.plugin.v2.MyBalanceGoogleDrive" not in manifest_xml or (
        "org.godotengine.plugin.v2.MyBalanceBarcode" not in manifest_xml):
    app_tag = re.search(r"<application\b[^>]*>", manifest_xml, re.DOTALL)
    if not app_tag:
        raise SystemExit("Could not find <application> in AndroidManifest.xml")
    manifest_xml = (
        manifest_xml[:app_tag.end()]
        + metadata
        + manifest_xml[app_tag.end():]
    )
    if 'android.permission.INTERNET' not in manifest_xml:
        manifest_xml = manifest_xml.replace("<application",
            '<uses-permission android:name="android.permission.INTERNET" />\n    <application', 1)
    manifest.write_text(manifest_xml, encoding="utf-8")

# Independently inject the reminder plugin and system receiver.
manifest_xml = manifest.read_text(encoding="utf-8")
if "org.godotengine.plugin.v2.MyBalanceReminders" not in manifest_xml:
    app_tag = re.search(r"<application\b[^>]*>", manifest_xml, re.DOTALL)
    if not app_tag:
        raise SystemExit("Missing application tag for reminder plugin")
    reminder_nodes = '''
        <meta-data android:name="org.godotengine.plugin.v2.MyBalanceReminders" android:value="com.domenklay.mybalance.reminders.MyBalanceReminders" />
        <receiver android:name="com.domenklay.mybalance.reminders.ReminderReceiver" android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.TIME_SET" />
                <action android:name="android.intent.action.TIMEZONE_CHANGED" />
            </intent-filter>
        </receiver>
'''
    manifest_xml = manifest_xml[:app_tag.end()] + reminder_nodes + manifest_xml[app_tag.end():]
for permission in ("POST_NOTIFICATIONS", "RECEIVE_BOOT_COMPLETED"):
    name = "android.permission." + permission
    if name not in manifest_xml:
        manifest_xml = manifest_xml.replace("<application", '<uses-permission android:name="' + name + '" />\n    <application', 1)
manifest.write_text(manifest_xml, encoding="utf-8")

print(f"PATCH OK: Android Gradle app={app_root}")
print(f"PATCH OK: native Java plugin={dest}")
print(f"PATCH OK: Google Play Code Scanner dependency present={scanner_dep in gradle}")
print(f"PATCH OK: Google Play Auth dependency present={google_auth_dep in gradle}")
print(f"PATCH OK: Google Drive plugin source={cloud_dest}")
print(f"PATCH OK: Godot v2 plugin manifest metadata present")
