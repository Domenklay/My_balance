#!/usr/bin/env python3
"""Fetch a small attributed offline barcode catalog from Open Food Facts.

No invented barcodes or nutrition values. Fetching runs only when explicitly triggered.
Open Food Facts database: ODbL, https://openfoodfacts.org/terms-of-use
"""
import json
import os
import re
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

BASE = "https://world.openfoodfacts.org/api/v2/search"
FIELDS = "code,product_name,product_name_ru,brands,nutriments,countries_tags"
COUNTRIES = ("en:finland", "en:russia", "en:poland")
OUTPUT = Path("godot/data/barcode_catalog.json")
MAX_PER_COUNTRY = 120

def valid_food(raw):
    if not isinstance(raw, dict):
        return None
    code = str(raw.get("code", "")).strip()
    if not re.fullmatch(r"\d{8,14}", code):
        return None
    name = str(raw.get("product_name_ru") or raw.get("product_name") or "").strip()
    if len(name) < 3 or len(name) > 160:
        return None
    nutr = raw.get("nutriments")
    if not isinstance(nutr, dict):
        return None
    kcal = nutr.get("energy-kcal_100g")
    if not isinstance(kcal, (int, float)):
        kj = nutr.get("energy-kj_100g")
        if not isinstance(kj, (int, float)):
            return None
        kcal = kj / 4.184
    values = [kcal, nutr.get("proteins_100g"), nutr.get("fat_100g"), nutr.get("carbohydrates_100g")]
    if not all(isinstance(v, (float, int)) and v == v for v in values):
        return None
    if not (0 <= kcal <= 1000 and all(0 <= x <= 100 for x in values[1:])):
        return None
    brand = str(raw.get("brands", "")).strip()[:55]
    if brand and brand.lower() not in name.lower():
        name = f"{name} ({brand})"
    return {
        "id": "offline_" + code,
        "barcode": code,
        "name": name[:160],
        "kcal": round(float(values[0]), 1),
        "p": round(float(values[1]), 1),
        "f": round(float(values[2]), 1),
        "c": round(float(values[3]), 1),
        "source": "Open Food Facts"
    }

def fetch(country):
    params = urllib.parse.urlencode({
        "countries_tags": country,
        "sort_by": "popularity_key",
        "page_size": MAX_PER_COUNTRY,
        "fields": FIELDS
    })
    req = urllib.request.Request(
        BASE + "?" + params,
        headers={
            "User-Agent": "MyBalance/0.5.6 (public project https://github.com/Domenklay/My_balance; noncommercial catalog prototype)",
            "Accept": "application/json"
        }
    )
    with urllib.request.urlopen(req, timeout=45) as response:
        body = response.read(3_000_000)
        return json.loads(body)["products"]

def main():
    products = {}
    successes = 0
    for country in COUNTRIES:
        try:
            raw = fetch(country)
            accepted = 0
            for item in raw:
                product = valid_food(item)
                if product and product["barcode"] not in products:
                    products[product["barcode"]] = product
                    accepted += 1
            print(f"{country}: {len(raw)} products returned, {accepted} validated and added")
            successes += 1
        except Exception as exc:
            print(f"WARNING: {country} source unavailable: {type(exc).__name__}: {exc}")
        time.sleep(1)
    if successes == 0 or len(products) < 15:
        raise SystemExit(f"Too few verified Open Food Facts products: {len(products)}")
    catalog = {
        "source": "Open Food Facts",
        "license": "ODbL-1.0",
        "attribution_url": "https://world.openfoodfacts.org",
        "retrieved_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "countries": list(COUNTRIES),
        "products": sorted(products.values(), key=lambda p: p["name"].casefold())
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(catalog, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"CATALOG OK: {len(products)} verified items; {OUTPUT.stat().st_size} bytes")

if __name__ == "__main__":
    main()
