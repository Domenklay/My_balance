"""Bundle explicitly selected Commons photographs; skip unverified/unavailable files.
The APK never contacts Commons. Credits accompany each successfully bundled photo.
"""
import concurrent.futures
import html
import json
import re
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "godot/assets/recipe_covers"
CREDITS = ROOT / "godot/data/recipe_photo_credits.json"
FILES = {
    "catalog_oats": "Oatmeal porridge with fruits.jpg",
    "catalog_omelet": "Omelette with butter and tomatoes.jpg",
    "catalog_fresh_salad": "Tomato Cucumber Salad.jpg",
    "catalog_cucumber_salad": "Cucumber salad green onions dill.jpg",
    "catalog_vinaigrette": "Vinaigrette salad.jpg",
    "catalog_syrniki": "Syrniki.jpg",
    "catalog_buckwheat": "Roasted buckwheat Kasha (cooked).jpg",
    "catalog_snezhanka": "Snezhanka Salad.jpg",
    "catalog_shopska": "Shopska Salad.JPG",
    "catalog_fattoush": "Fattoush mixed-salad.jpg",
    "catalog_onion_soup": "French Onion Soup..JPG",
    "catalog_vinaigrette_sauce": "Making vinaigrette.jpg",
    "catalog_chicken_rice": "Chicken and rice.jpg",
    "catalog_lentil_soup": "Lentil soup in a bowl.jpg",
    "catalog_banana_pancakes": "BananaPancakes.JPG",
    "catalog_apple_muffins": "Allison's Fine Baked Goods Apple Muffin 2010.jpg",
    "catalog_berry_yogurt": "Yogurt fruit bowl.jpg",
}
UA = "MyBalance/0.7.69 (https://github.com/Domenklay/My_balance; offline recipe photo attribution)"
def get(url, max_bytes=12_000_000):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=12) as response:
        content = response.read(max_bytes + 1)
        if len(content) > max_bytes:
            raise ValueError("file too large")
        return content
def clean(value):
    return " ".join(html.unescape(re.sub(r"<[^>]+>", " ", value)).split())
def work(item):
    key, title = item
    try:
        params = urllib.parse.urlencode({"action":"query", "format":"json", "titles":"File:"+title,
            "prop":"imageinfo", "iiprop":"url|mime|extmetadata", "iiurlwidth":"640"})
        doc = json.loads(get("https://commons.wikimedia.org/w/api.php?"+params, 2_000_000))
        page = next(iter(doc["query"]["pages"].values()))
        info = page["imageinfo"][0]
        meta = info["extmetadata"]
        def val(k): return clean(meta.get(k, {}).get("value", ""))
        license_name, license_url = val("LicenseShortName"), val("LicenseUrl")
        author = val("Artist") or val("Credit")
        if not license_url and license_name == "Public domain":
            license_url = "https://creativecommons.org/publicdomain/mark/1.0/"
        if not license_url.startswith(("https://creativecommons.org/licenses/by/", "https://creativecommons.org/licenses/by-sa/", "https://creativecommons.org/publicdomain/", "http://creativecommons.org/licenses/by/", "http://creativecommons.org/licenses/by-sa/", "http://creativecommons.org/publicdomain/")):
            raise ValueError("unsupported or missing license")
        if not author or info.get("mime") != "image/jpeg":
            raise ValueError("missing author or not JPEG")
        url = info.get("thumburl", info["url"])
        if not url.startswith("https://upload.wikimedia.org/"):
            raise ValueError("unexpected host")
        try:
            raw = get(url)
        except Exception:
            raw = get(info["url"])
        if not raw.startswith(b"\xff\xd8") or not raw.endswith(b"\xff\xd9"):
            raise ValueError("not a complete JPEG")
        (OUT / (key + ".jpg")).write_bytes(raw)
        print("PHOTO", key, license_name, flush=True)
        return key, {"author": author, "license": license_name, "license_url":license_url.replace("http://","https://",1), "source":info["descriptionurl"], "title":title}
    except Exception as exc:
        print("PHOTO FALLBACK", key, str(exc), flush=True)
        return key, None
def main():
    OUT.mkdir(parents=True, exist_ok=True)
    CREDITS.parent.mkdir(parents=True, exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        credits = {key:credit for key,credit in pool.map(work, FILES.items()) if credit}
    CREDITS.write_text(json.dumps(credits, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Bundled {len(credits)}/{len(FILES)} licensed images")
if __name__ == "__main__":
    main()
