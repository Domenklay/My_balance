extends SceneTree

const StoreScript = preload("res://src/store.gd")
const PortionMath = preload("res://src/portion_math.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED PORTIONS: " + message)
    quit(1)

func _run() -> void:
    var store = StoreScript.new()
    store.data = store.default_data()
    var egg: Dictionary = store.food_by_id("d16")
    if str(egg.get("name", "")) != "Яйцо":
        _fail("built-in test egg missing")
        return
    var options: Array = store.portion_options(egg)
    if options.size() != 1 or str(options[0]["unit"]) != "г":
        _fail("grams should be the only default for a food with 100g nutrients")
        return
    if not store.save_food_portion("d16", "1 шт.", 55.0):
        _fail("cannot save a custom piece-size portion")
        return
    if store.save_food_portion("d16", "1 ШТ.", 55.0):
        _fail("duplicate portion label was accepted")
        return
    options = store.portion_options(egg)
    if options.size() != 2 or str(options[1]["label"]) != "1 шт.":
        _fail("stored portion missing from available measures")
        return
    var actual_amount: float = PortionMath.quantity_to_base(options[1], 2.0)
    if absf(actual_amount - 110.0) > 0.01:
        _fail("two pieces do not convert to 110g")
        return
    var nutrients = PortionMath.nutrients(egg, actual_amount)
    if absf(float(nutrients["kcal"]) - 157.3) > 0.01:
        _fail("piece conversion changed calories")
        return
    if PortionMath.quantity_to_base(options[1], 100.0) != 0.0:
        _fail("more than 5000g passed validation")
        return
    if not store.add_food_entry(egg, actual_amount, "Завтрак", "2026-11-20", "1 шт."):
        _fail("could not add a weighed portion")
        return
    var original = store.day_entries("2026-11-20")[0]
    if str(original["portion_label"]) != "1 шт." or str(original["unit"]) != "г":
        _fail("food diary lost portion description")
        return
    if absf(store.day_calories("2026-11-20") - 157.3) > 0.01:
        _fail("food diary miscalculated piece calories")
        return
    var reloaded = StoreScript.new()
    if reloaded.portion_options(egg).size() != 2:
        _fail("user portion was not persisted on restart")
        return
    if str(reloaded.day_entries("2026-11-20")[0]["portion_label"]) != "1 шт.":
        _fail("portion label was not persisted in diary")
        return
    if not store.delete_food_portion(str(options[1]["id"])):
        _fail("saved portion cannot be deleted")
        return
    if not store.portion_options(egg).size() == 1 or absf(store.day_calories("2026-11-20") - 157.3) > 0.01:
        _fail("deleting a portion corrupted historic diary")
        return

    var milk = {"name":"Напиток 100 мл", "kcal":50.0, "p":3.0, "f":2.0, "c":5.0,
        "nutrition_unit":"мл"}
    if not store.add_custom_food_without_barcode(milk):
        _fail("cannot create 100ml-based product")
        return
    var local: Dictionary = store.data["foods"][0]
    if PortionMath.base_unit(local) != "мл":
        _fail("milliliters are not selected for the user product")
        return
    if not store.save_food_portion(str(local["id"]), "1 стакан", 250.0):
        _fail("could not define 250ml cup")
        return
    var cup = store.portion_options(local)[1]
    var volume: float = PortionMath.quantity_to_base(cup, 1.0)
    if absf(volume - 250.0) > 0.01 or absf(float(PortionMath.nutrients(local, volume)["kcal"]) - 125.0) > 0.01:
        _fail("cup volume or energy incorrect")
        return
    if not store.add_food_entry(local, volume, "Перекус", "2026-11-20", "1 стакан"):
        _fail("cup could not be added to diary")
        return
    var entry = store.day_entries("2026-11-20")[1]
    if str(entry["unit"]) != "мл" or str(entry["nutrition"]["nutrition_unit"]) != "мл":
        _fail("100ml basis was not preserved in diary")
        return
    var legacy = store.export_json()
    var imported = JSON.parse_string(legacy)
    imported.erase("food_portions")
    if not store.import_json(JSON.stringify(imported)):
        _fail("old backup missing portions rejected")
        return
    if not store.data["food_portions"].is_empty() or store.day_entries("2026-11-20").size() != 2:
        _fail("migration did not preserve older food diary")
        return
    var invalid = store.data.duplicate(true)
    invalid["food_portions"] = [{"id":"bad", "food_id":"d16", "label":"1 шт.", "unit":"г", "amount":0.0}]
    if store.import_json(JSON.stringify(invalid)):
        _fail("invalid amount in backup was accepted")
        return

    var failing = FailingStore.new()
    failing.data = failing.default_data()
    if failing.save_food_portion("d16", "1 яйцо", 55.0):
        _fail("write failure should not save custom portion")
        return
    if not failing.data["food_portions"].is_empty():
        _fail("unsaved portion was not rolled back")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app._quick_food_sheet(app.store.food_by_id("d16"))
    await process_frame
    var sheet = app.get_node_or_null("ProductSheet")
    if sheet == null or sheet.find_child("ProductSheetConfirm", true, false) == null:
        _fail("portion editor not available on mobile")
        return
    var custom_input: LineEdit = null
    for node in sheet.find_children("*", "LineEdit", true, false):
        if node is LineEdit and node.placeholder_text == "Название меры (например, 1 упаковка)":
            custom_input = node
            break
    if custom_input == null:
        _fail("custom portion label field is missing from UI")
        return
    sheet.queue_free()
    app.queue_free()
    print("PASS PORTIONS: 100g, 100ml, custom counts, nutrition, snapshots, backup migration and UI")
    quit(0)
