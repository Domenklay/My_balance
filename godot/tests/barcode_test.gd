extends SceneTree

const Lookup = preload("res://src/barcode_lookup.gd")
const Store = preload("res://src/store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED BARCODE: " + message)
    quit(1)

func _run() -> void:
    if Lookup.normalize_code("3017624010701") != "3017624010701":
        _fail("valid EAN-13 not accepted")
        return
    for invalid in ["", "123", "123456789012345", "1234567A90123", " 123 456 78 ", "3017624010702", "123456789", "4600494693336"]:
        if not Lookup.normalize_code(invalid).is_empty():
            _fail("invalid barcode accepted: " + invalid)
            return
    var payload = {
        "status": 1,
        "product": {
            "product_name_ru": "Тестовый продукт",
            "brands": "Тест",
            "nutriments": {
                "energy-kcal_100g": 250.0,
                "proteins_100g": 9.5,
                "fat_100g": 12.0,
                "carbohydrates_100g": 23.0
            }
        }
    }
    var result: Dictionary = Lookup.parse_product(payload, "3017624010701")
    if result.has("error") or float(result.get("kcal", 0)) != 250.0:
        _fail("valid nutritional values not parsed")
        return
    if not str(result.get("name", "")).contains("Тестовый продукт"):
        _fail("Russian product name missing")
        return
    var sample = Store.new()
    sample.data = sample.default_data()
    var id = sample.save_barcode_food(result)
    if id != "barcode_3017624010701":
        _fail("barcode product not saved")
        return
    if sample.save_barcode_food(result) != id or sample.data["foods"].size() != 1:
        _fail("duplicate barcode product was created")
        return
    var reloaded = Store.new()
    if reloaded.food_by_barcode("3017624010701").get("name", "") != result["name"]:
        _fail("barcode cache not persisted")
        return
    var snapshot = reloaded.export_json()
    var imported = Store.new()
    if not imported.import_json(snapshot) or imported.food_by_barcode("3017624010701").is_empty():
        _fail("barcode product not retained through JSON export/import")
        return
    var bad = payload.duplicate(true)
    bad["product"]["nutriments"].erase("proteins_100g")
    if not Lookup.parse_product(bad, "3017624010701").has("error"):
        _fail("incomplete macros silently accepted")
        return
    var missing = {"status": 0}
    if not Lookup.parse_product(missing, "3017624010701").has("error"):
        _fail("missing product accepted")
        return
    var kj = payload.duplicate(true)
    kj["product"]["nutriments"].erase("energy-kcal_100g")
    kj["product"]["nutriments"]["energy-kj_100g"] = 418.4
    var converted = Lookup.parse_product(kj, "3017624010701")
    if converted.has("error") or absf(float(converted["kcal"]) - 100.0) > 0.1:
        _fail("kJ to kcal fallback incorrect")
        return
    # Verify the bundled catalog has real codes, and local products override them.
    var bundled = Store.new()
    if bundled.bundled_foods.size() < 50:
        _fail("verified offline barcode catalog is missing or too small")
        return
    var regional: Dictionary = bundled.bundled_foods[0]
    var actual_code = str(regional.get("barcode", ""))
    if bundled.food_by_barcode(actual_code).get("id", "") != regional["id"]:
        _fail("offline barcode not searchable")
        return
    var custom_food = {"id": "my_favorite", "name": "Свой продукт",
        "kcal": 125.0, "p": 8.0, "f": 3.0, "c": 15.0}
    bundled.data["foods"].append(custom_food)
    if not bundled.link_barcode_to_food("my_favorite", actual_code):
        _fail("cannot link regional barcode to custom food")
        return
    if bundled.food_by_barcode(actual_code).get("id", "") != "my_favorite":
        _fail("saved food does not take priority over bundled catalog")
        return
    var found = bundled.all_foods().filter(func(item): return str(item.get("barcode", "")) == actual_code)
    if found.size() != 1:
        _fail("bundled and saved food with same code are both listed")
        return
    var after_reload = Store.new()
    if after_reload.food_by_barcode(actual_code).get("id", "") != "my_favorite":
        _fail("custom barcode link was not saved")
        return
    if bundled.link_barcode_to_food("my_favorite", "12invalid"):
        _fail("invalid barcode was linked")
        return
    var good = bundled.bundled_foods[0]
    if Lookup.nutrition_warning(good) != "":
        _fail("curated catalog contains an implausible food")
        return
    var known_bad = {"kcal": 0, "p": 20, "f": 0, "c": 0}
    if Lookup.nutrition_warning(known_bad).is_empty():
        _fail("zero-calorie protein anomaly not detected")
        return
    var report = FileAccess.get_file_as_string("res://data/barcode_catalog.json")
    var audit: Variant = JSON.parse_string(report)
    if not (audit is Dictionary and audit.get("products") is Array):
        _fail("bundled JSON is not valid")
        return
    for entry in audit["products"]:
        if not Lookup.nutrition_warning(entry).is_empty():
            _fail("implausible entry remains in bundled catalog: " + str(entry.get("barcode", "")))
            return
    if not bundled.update_catalog_json(report) or bundled.bundled_foods.size() < 100:
        _fail("manual catalog refresh rejected valid data")
        return
    if bundled.update_catalog_json('{"source":"Open Food Facts","products":[{"barcode":"123"}]}'):
        _fail("malformed update replaced valid catalog")
        return
    if bundled.bundled_foods.size() < 100:
        _fail("bad catalog update erased the last known-good catalog")
        return
    var saved_id = "my_favorite"
    var changed = {"name": "Йогурт с упаковки", "barcode": actual_code, "kcal": 150.0,
        "p": 5.5, "f": 4.5, "c": 20.0}
    if not bundled.update_custom_food(saved_id, changed):
        _fail("cannot edit custom food")
        return
    if str(bundled.food_by_barcode(actual_code).get("name", "")) != "Йогурт с упаковки":
        _fail("edited custom food is not searchable")
        return
    if not bundled.add_food_entry(bundled.food_by_barcode(actual_code), 180.0, "Обед", "2026-11-19"):
        _fail("cannot save an exact barcode-based portion")
        return
    var entries_before = bundled.day_entries("2026-11-19").size()
    if not bundled.delete_custom_food(saved_id):
        _fail("cannot delete own product")
        return
    if bundled.day_entries("2026-11-19").size() != entries_before:
        _fail("removing catalog product changed historical diary")
        return
    print("PASS: GTIN checksum, catalog validation, safe refresh, own-product edits and exact portion") 
    print("PASS: bundled catalog, manual barcode linking, local override and persistence")
    print("PASS: barcode validation, Open Food Facts parser, macro completeness, local cache, JSON migration")
    quit(0)
