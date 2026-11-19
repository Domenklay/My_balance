"""Inject MyBalance native barcode scanner into Godot's generated Android Gradle template.

Runs on GitHub Actions after --install-android-build-template.
The generated android/build directory is intentionally untracked.
"""
from pathlib import Path
import re
import shutil

source = Path("android_scanner/src/main/java/com/domenklay/mybalance/barcode/MyBalanceBarcode.java")
root = Path("godot/android/build")
if not source.is_file() or not root.is_dir():
    raise SystemExit("Barcode plugin source / Godot Gradle template is missing")

build_candidates = sorted(
    p for p in root.rglob("build.gradle")
    if p.parent.name == "app"
)
if not build_candidates:
    raise SystemExit("Godot Android app/build.gradle not found: " +
                     ", ".join(map(str, root.glob("*/build.gradle"))))
app_build = build_candidates[0]
app_root = app_build.parent
manifest = app_root / "src/main/AndroidManifest.xml"
if not manifest.is_file():
    raise SystemExit(f"Expected Android manifest missing at: {manifest}")

dest = app_root / "src/main/java/com/domenklay/mybalance/barcode/MyBalanceBarcode.java"
dest.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(source, dest)

gradle = app_build.read_text(encoding="utf-8")
scanner_dep = "implementation 'com.google.android.gms:play-services-code-scanner:16.1.0'"
if scanner_dep not in gradle:
    gradle += "\n\ndependencies {\n    " + scanner_dep + "\n}\n"
app_build.write_text(gradle, encoding="utf-8")

manifest_xml = manifest.read_text(encoding="utf-8")
metadata = (
    "\n        <!-- Camera UI delegated to Google Play services; no CAMERA permission. -->\n"
    "        <meta-data android:name=\"org.godotengine.plugin.v2.MyBalanceBarcode\" "
    "android:value=\"com.domenklay.mybalance.barcode.MyBalanceBarcode\" />\n"
    "        <meta-data android:name=\"com.google.mlkit.vision.DEPENDENCIES\" "
    "android:value=\"barcode_ui\" />\n"
)
if "org.godotengine.plugin.v2.MyBalanceBarcode" not in manifest_xml:
    app_tag = re.search(r"<application\b[^>]*>", manifest_xml, re.DOTALL)
    if not app_tag:
        raise SystemExit("Could not find <application> in AndroidManifest.xml")
    manifest_xml = (
        manifest_xml[:app_tag.end()]
        + metadata
        + manifest_xml[app_tag.end():]
    )
    manifest.write_text(manifest_xml, encoding="utf-8")

print(f"PATCH OK: Android Gradle app={app_root}")
print(f"PATCH OK: native Java plugin={dest}")
print(f"PATCH OK: Google Play Code Scanner dependency present={scanner_dep in gradle}")
print(f"PATCH OK: Godot v2 plugin manifest metadata present")
