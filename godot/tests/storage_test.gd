extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var StoreScript = load("res://src/store.gd")
    var first = StoreScript.new()
    first.data = first.default_data()
    first.data["notes"]["2026-11-19"] = "Первый тест сохранения"
    if not first.save():
        push_error("FAILED: first atomic save")
        quit(1)
        return
    var second = StoreScript.new()
    if str(second.data["notes"].get("2026-11-19", "")) != "Первый тест сохранения":
        push_error("FAILED: reload saved content")
        quit(1)
        return
    second.data["notes"]["2026-11-19"] = "Второй тест сохранения"
    if not second.save():
        push_error("FAILED: subsequent atomic save")
        quit(1)
        return
    if not FileAccess.file_exists("user://my_balance.previous.json"):
        push_error("FAILED: previous backup missing")
        quit(1)
        return
    var third = StoreScript.new()
    if str(third.data["notes"].get("2026-11-19", "")) != "Второй тест сохранения":
        push_error("FAILED: new save cannot be reloaded")
        quit(1)
        return
    if third.import_json('{"broken": true}'):
        push_error("FAILED: invalid JSON accepted")
        quit(1)
        return
    if not third.import_json(first.export_json()):
        push_error("FAILED: valid JSON restore")
        quit(1)
        return
    var restored = StoreScript.new()
    if str(restored.data["notes"].get("2026-11-19", "")) != "Первый тест сохранения":
        push_error("FAILED: restored journal not persisted")
        quit(1)
        return
    # Features introduced in v0.5.3 must preserve the existing 0.5.2 data format.
    var product = restored.all_foods()[0]
    var food_id = str(product["id"])
    if not restored.toggle_favorite(food_id) or not restored.is_favorite(food_id):
        push_error("FAILED: cannot set product favorite")
        quit(1)
        return
    if not restored.toggle_favorite(food_id) or restored.is_favorite(food_id):
        push_error("FAILED: cannot remove product favorite")
        quit(1)
        return
    if not restored.toggle_favorite(food_id):
        push_error("FAILED: cannot restore product favorite")
        quit(1)
        return
    var original = {
        "id": "test-original", "date": "2026-11-18", "food": food_id,
        "nutrition": product.duplicate(true), "grams": 120, "meal": "Завтрак"
    }
    restored.data["entries"].append(original)
    if not restored.repeat_entry(original, "2026-11-19"):
        push_error("FAILED: cannot repeat food entry")
        quit(1)
        return
    var repeats = restored.day_entries("2026-11-19")
    if repeats.size() != 1 or str(repeats[0].get("id", "")) == original["id"] or int(repeats[0].get("grams", 0)) != 120:
        push_error("FAILED: repeated food entry differs or ID collided")
        quit(1)
        return
    if restored.day_entries("2026-11-18").size() != 1:
        push_error("FAILED: original meal was changed")
        quit(1)
        return
    var persisted = StoreScript.new()
    if not persisted.is_favorite(food_id) or persisted.day_entries("2026-11-19").size() != 1:
        push_error("FAILED: favorites or repeated meals were not saved")
        quit(1)
        return
    var legacy = persisted.data.duplicate(true)
    legacy.erase("favorites")
    if not persisted.import_json(JSON.stringify(legacy)):
        push_error("FAILED: 0.5.2 backup format is not compatible")
        quit(1)
        return
    if not persisted.data.has("favorites") or not persisted.data["favorites"].is_empty():
        push_error("FAILED: missing favorites were not migrated")
        quit(1)
        return
    var FailingStore = load("res://tests/failing_store.gd")
    var failed = FailingStore.new()
    failed.data = failed.default_data()
    var food = failed.all_foods()[0]
    if failed.add_food_entry(food, 150.0, "Завтрак", "2026-11-19"):
        push_error("FAILED: food entry reports success despite disk failure")
        quit(1)
        return
    if not failed.data["entries"].is_empty():
        push_error("FAILED: failed food entry remains in memory")
        quit(1)
        return
    if failed.add_custom_food_without_barcode({
        "name": "Тестовый йогурт", "kcal": 105, "p": 7, "f": 4, "c": 10
    }):
        push_error("FAILED: unsaved custom food was reported successful")
        quit(1)
        return
    if not failed.data["foods"].is_empty():
        push_error("FAILED: unsaved custom food remains in memory")
        quit(1)
        return
    var barcode_record = {
        "barcode": "3017624010701", "name": "Йогурт", "kcal": 130.0,
        "p": 5.0, "f": 4.0, "c": 18.0
    }
    if failed.save_barcode_food(barcode_record) != "" or not failed.data["foods"].is_empty():
        push_error("FAILED: unsaved barcode food remains in memory")
        quit(1)
        return
    var saved = barcode_record.duplicate(true)
    saved["id"] = "barcode_test"
    failed.data["foods"].append(saved)
    var edited = barcode_record.duplicate(true)
    edited["kcal"] = 180.0
    if failed.save_barcode_food(edited) != "":
        push_error("FAILED: edited barcode reported saved despite I/O failure")
        quit(1)
        return
    if float(failed.data["foods"][0]["kcal"]) != 130.0:
        push_error("FAILED: edited barcode nutrition not rolled back")
        quit(1)
        return
    if failed.toggle_favorite(str(food.get("id", ""))) or not failed.data["favorites"].is_empty():
        push_error("FAILED: favorite not rolled back after disk failure")
        quit(1)
        return
    var previous = {
        "id": "old-meal", "date": "2026-11-18", "meal": "Обед",
        "food": food["id"], "grams": 100.0, "nutrition": food.duplicate()
    }
    failed.data["entries"].append(previous)
    if failed.repeat_entry(previous, "2026-11-19") or failed.data["entries"].size() != 1:
        push_error("FAILED: repeat meal not rolled back after disk failure")
        quit(1)
        return
    # Updating a scanned barcode is an intentional correction, not a no-op.
    var correcting = StoreScript.new()
    correcting.data = correcting.default_data()
    if correcting.save_barcode_food(barcode_record).is_empty():
        push_error("FAILED: initial barcode save")
        quit(1)
        return
    if correcting.save_barcode_food(edited).is_empty():
        push_error("FAILED: second barcode save")
        quit(1)
        return
    if correcting.data["foods"].size() != 1 or float(correcting.data["foods"][0]["kcal"]) != 180.0:
        push_error("FAILED: rescanned corrected nutrition not applied")
        quit(1)
        return
    var reloaded_barcode = StoreScript.new()
    if float(reloaded_barcode.food_by_barcode("3017624010701").get("kcal", 0.0)) != 180.0:
        push_error("FAILED: corrected barcode nutrition not persisted")
        quit(1)
        return
    print("PASS: failed writes rollback in-memory changes; confirmed barcode corrections persist")
    print("PASS: JSON save, reload, previous backup, import validation, and restore")
    print("PASS: favorites, repeat yesterday, persistence and 0.5.2 legacy import")
    quit(0)
