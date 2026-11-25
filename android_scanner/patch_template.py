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

# Local OCR. Bundle fixed language models with license; no network is used on the phone.
from urllib.request import urlopen, Request
ocr_source = source.parent.parent / "ocr"
ocr_dest = dest.parent.parent / "ocr"
ocr_dest.mkdir(parents=True, exist_ok=True)
for java_file in ("MyBalanceOcr.java", "LabelFileProvider.java"):
    shutil.copy2(ocr_source / java_file, ocr_dest / java_file)
gradle = app_build.read_text(encoding="utf-8")
ocr_dep = "implementation 'cz.adaptech.tesseract4android:tesseract4android:4.9.0'"
if ocr_dep not in gradle:
    gradle += "\n\ndependencies {\n    " + ocr_dep + "\n}\n"
settings = root / "settings.gradle"
if settings.is_file():
    cfg = settings.read_text(encoding="utf-8")
    if "https://jitpack.io" not in cfg:
        match = re.search(r"dependencyResolutionManagement\s*\{[\s\S]*?repositories\s*\{", cfg)
        if match:
            cfg = cfg[:match.end()] + "\n        maven { url 'https://jitpack.io' }\n" + cfg[match.end():]
        else:
            gradle += "\nrepositories { maven { url 'https://jitpack.io' } }\n"
        settings.write_text(cfg, encoding="utf-8")
else:
    gradle += "\nrepositories { maven { url 'https://jitpack.io' } }\n"
app_build.write_text(gradle,encoding="utf-8")
assets = Path("godot/data/nutrition_ocr")
assets.mkdir(parents=True, exist_ok=True)
revision = "87416418657359cb625c412a48b6e1d6d41c29bd"
for filename in ("rus.traineddata", "eng.traineddata", "pol.traineddata", "LICENSE"):
    url = f"https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/{revision}/{filename}"
    with urlopen(Request(url,headers={"User-Agent":"MyBalance-build"}),timeout=45) as response:
        payload = response.read(20_000_001)
    if not payload or len(payload)>20_000_000 or (filename.endswith(".traineddata") and len(payload)<100_000):
        raise SystemExit("Invalid OCR asset "+filename)
    (assets / filename).write_bytes(payload)
res_xml = app_root / "src/main/res/xml"
res_xml.mkdir(parents=True,exist_ok=True)
(res_xml / "mybalance_ocr_paths.xml").write_text('<paths xmlns:android="http://schemas.android.com/apk/res/android"><cache-path name="label_capture" path="ocr_capture/" /><cache-path name="progress_capture" path="progress_capture/" /></paths>',encoding="utf-8")
manifest_xml = manifest.read_text(encoding="utf-8")
if "org.godotengine.plugin.v2.MyBalanceOcr" not in manifest_xml:
    app_tag = re.search(r"<application\b[^>]*>",manifest_xml,re.DOTALL)
    ocr_nodes = '''
        <meta-data android:name="org.godotengine.plugin.v2.MyBalanceOcr" android:value="com.domenklay.mybalance.ocr.MyBalanceOcr" />
        <provider android:name="com.domenklay.mybalance.ocr.LabelFileProvider" android:authorities="${applicationId}.nutritionocr" android:exported="false" android:grantUriPermissions="true">
            <meta-data android:name="android.support.FILE_PROVIDER_PATHS" android:resource="@xml/mybalance_ocr_paths" />
        </provider>
'''
    manifest_xml = manifest_xml[:app_tag.end()] + ocr_nodes + manifest_xml[app_tag.end():]
manifest.write_text(manifest_xml,encoding="utf-8")
print("PATCH OK: local Russian/English/Polish OCR models and camera provider")

# Optional native step-counter foreground service. No location or network permission.
step_src = source.parent.parent / "steps"
step_dest = dest.parent.parent / "steps"
step_dest.mkdir(parents=True, exist_ok=True)
for java_file in ("MyBalanceSteps.java","StepService.java","StepLedger.java"):
    shutil.copy2(step_src / java_file,step_dest / java_file)
manifest_xml = manifest.read_text(encoding="utf-8")
if "org.godotengine.plugin.v2.MyBalanceSteps" not in manifest_xml:
    app_tag = re.search(r"<application\b[^>]*>",manifest_xml,re.DOTALL)
    step_nodes = '''
        <meta-data android:name="org.godotengine.plugin.v2.MyBalanceSteps" android:value="com.domenklay.mybalance.steps.MyBalanceSteps" />
        <service android:name="com.domenklay.mybalance.steps.StepService" android:exported="false" android:foregroundServiceType="health" />
'''
    manifest_xml = manifest_xml[:app_tag.end()] + step_nodes + manifest_xml[app_tag.end():]
for permission in ("ACTIVITY_RECOGNITION","FOREGROUND_SERVICE","FOREGROUND_SERVICE_HEALTH"):
    name = "android.permission." + permission
    if name not in manifest_xml:
        manifest_xml = manifest_xml.replace("<application", '<uses-permission android:name="' + name + '" />\n    <application', 1)
manifest.write_text(manifest_xml,encoding="utf-8")
print("PATCH OK: optional step counter service")

# Progress photos are stored in Android noBackupFilesDir, never in diary JSON.
photo_src = source.parent.parent / "photos"
photo_dest = dest.parent.parent / "photos"
photo_dest.mkdir(parents=True,exist_ok=True)
shutil.copy2(photo_src / "MyBalancePhotos.java",photo_dest / "MyBalancePhotos.java")
manifest_xml = manifest.read_text(encoding="utf-8")
if "org.godotengine.plugin.v2.MyBalancePhotos" not in manifest_xml:
    app_tag = re.search(r"<application\b[^>]*>",manifest_xml,re.DOTALL)
    photo_nodes = '\n        <meta-data android:name="org.godotengine.plugin.v2.MyBalancePhotos" android:value="com.domenklay.mybalance.photos.MyBalancePhotos" />\n'
    manifest_xml = manifest_xml[:app_tag.end()] + photo_nodes + manifest_xml[app_tag.end():]
manifest.write_text(manifest_xml,encoding="utf-8")
print("PATCH OK: private progress photo picker")

# Android home-screen widgets. Resources use stable, unique names.
widget_src = source.parent.parent / "widgets"
widget_dest = dest.parent.parent / "widgets"
widget_dest.mkdir(parents=True,exist_ok=True)
for java_file in widget_src.glob("*.java"):
    shutil.copy2(java_file,widget_dest / java_file.name)
for kind in ("layout","xml","drawable"):
    target = app_root / "src/main/res" / kind
    target.mkdir(parents=True,exist_ok=True)
    for resource in (Path("android_scanner/src/main/res") / kind).glob("*.xml"):
        shutil.copy2(resource,target / resource.name)
manifest_xml = manifest.read_text(encoding="utf-8")
if "org.godotengine.plugin.v2.MyBalanceWidgets" not in manifest_xml:
    app_tag = re.search(r"<application\b[^>]*>",manifest_xml,re.DOTALL)
    widget_nodes = '''
        <meta-data android:name="org.godotengine.plugin.v2.MyBalanceWidgets" android:value="com.domenklay.mybalance.widgets.MyBalanceWidgets" />
        <activity android:name="com.domenklay.mybalance.widgets.WidgetOpenActivity" android:exported="false" android:theme="@android:style/Theme.NoDisplay" />
'''
    for kind, cls, label in (("compact","CompactWidget","Мой баланс — калории"),("expanded","ExpandedWidget","Мой баланс — день")):
        widget_nodes += f'''
        <receiver android:name="com.domenklay.mybalance.widgets.{cls}" android:label="{label}" android:exported="false">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
                <action android:name="android.intent.action.DATE_CHANGED" />
                <action android:name="android.intent.action.TIME_SET" />
                <action android:name="android.intent.action.TIMEZONE_CHANGED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.BOOT_COMPLETED" />
            </intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/mybalance_widget_{kind}" />
        </receiver>
'''
    manifest_xml = manifest_xml[:app_tag.end()] + widget_nodes + manifest_xml[app_tag.end():]
manifest.write_text(manifest_xml,encoding="utf-8")
print("PATCH OK: two Android home-screen widgets")
