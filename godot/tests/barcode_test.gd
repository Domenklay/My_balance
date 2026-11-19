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
    for invalid in ["", "123", "123456789012345", "1234567A90123", " 123 456 78 "]:
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
    print("PASS: barcode validation, Open Food Facts parser, macro completeness, local cache, JSON migration")
    quit(0)
