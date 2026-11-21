extends SceneTree

const StoreScript = preload("res://src/store.gd")
const PortionMath = preload("res://src/portion_math.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED 0.7.35 PORTIONS: " + reason)
    quit(1)

func _find_button(node: Node, caption: String) -> Button:
    if node is Button and node.text == caption:
        return node
    for child in node.get_children():
        var found: Button = _find_button(child, caption)
        if found != null:
            return found
    return null

func _run() -> void:
    var store = StoreScript.new()
    store.data = store.default_data()
    var egg: Dictionary = store.food_by_id("d16")
    if not store.save_food_portion("d16", "1 шт.", 55.0):
        _fail("custom 55g egg piece not saved")
        return
    var options: Array = store.portion_options(egg)
    if options.size() != 2:
        _fail("saved measure should appear beside the gram base")
        return
    var piece: Dictionary = options[1]
    var half: float = PortionMath.quantity_to_base(piece, 0.5)
    var two: float = PortionMath.quantity_to_base(piece, 2.0)
    var macros: Dictionary = PortionMath.nutrients(egg, two)
    if absf(half - 27.5) > 0.0001 or absf(two - 110.0) > 0.0001 or \
            absf(float(macros["kcal"]) - 157.3) > 0.001 or \
            absf(float(macros["p"]) - float(egg["p"]) * 1.1) > 0.0001 or \
            absf(float(macros["f"]) - float(egg["f"]) * 1.1) > 0.0001 or \
            absf(float(macros["c"]) - float(egg["c"]) * 1.1) > 0.0001:
        _fail("half and two piece conversions changed macros or calorie math")
        return
    if not store.add_food_entry(egg, half, "Завтрак", "2026-11-20",
            "1 шт.", 0.5, str(piece["id"])):
        _fail("could not save a fractional serving")
        return
    var saved: Dictionary = store.day_entries("2026-11-20")[0]
    if absf(float(saved.get("portion_count", 0.0)) - 0.5) > 0.00001 or \
            str(saved.get("portion_id", "")) != str(piece["id"]):
        _fail("serving count / id missing from journal snapshot")
        return
    var last: Dictionary = store.last_food_portion(egg)
    var restored: Dictionary = PortionMath.recalled_choice(store.portion_options(egg), last)
    if int(restored["index"]) != 1 or absf(float(restored["quantity"]) - 0.5) > 0.00001:
        _fail("fractional last serving did not restore")
        return
    var reloaded = StoreScript.new()
    if not reloaded.portion_options(egg).size() == 2 or \
            int(PortionMath.recalled_choice(reloaded.portion_options(egg),
                reloaded.last_food_portion(egg))["index"]) != 1:
        _fail("portion and last choice not preserved on restart")
        return
    var legacy: Dictionary = JSON.parse_string(store.export_json())
    legacy["entries"][0].erase("portion_count")
    legacy["entries"][0].erase("portion_id")
    if not store.import_json(JSON.stringify(legacy)):
        _fail("legacy diary without serving metadata is not accepted")
        return
    restored = PortionMath.recalled_choice(store.portion_options(egg), store.last_food_portion(egg))
    if int(restored["index"]) != 1 or absf(float(restored["quantity"]) - 0.5) > 0.00001:
        _fail("old accurate 0.5 serving was not reconstructed")
        return
    var invalid: Dictionary = store.data.duplicate(true)
    invalid["entries"][0]["portion_count"] = -2.0
    if store.import_json(JSON.stringify(invalid)):
        _fail("negative serving count accepted in backup")
        return
    invalid = store.data.duplicate(true)
    invalid["entries"][0]["portion_count"] = "two"
    if store.import_json(JSON.stringify(invalid)):
        _fail("string serving count accepted in backup")
        return

    # Saved counts are never inferred from a changed or deleted measure.
    if not store.delete_food_portion(str(piece["id"])):
        _fail("could not delete the custom measure")
        return
    restored = PortionMath.recalled_choice(store.portion_options(egg), store.last_food_portion(egg))
    if int(restored["index"]) != 0 or absf(float(restored["quantity"]) - 27.5) > 0.0001 or \
            absf(store.day_calories("2026-11-20") - float(egg["kcal"]) * 0.275) > 0.001:
        _fail("deleted measure must fall back to exact grams, preserving old diary")
        return
    var milk = {"name":"Milk by volume", "kcal":64.0, "p":3.0, "f":3.4, "c":4.6,
        "nutrition_unit":"мл"}
    if not store.add_custom_food_without_barcode(milk):
        _fail("could not create volume-based milk")
        return
    var milk_record: Dictionary = store.data["foods"][0]
    if not store.save_food_portion(str(milk_record["id"]), "1 чашка", 250.0):
        _fail("could not create exact 250ml cup")
        return
    var cup: Dictionary = store.portion_options(milk_record)[1]
    if absf(PortionMath.quantity_to_base(cup, 0.5) - 125.0) > 0.001 or \
            absf(float(PortionMath.nutrients(milk_record, 125.0)["kcal"]) - 80.0) > 0.001:
        _fail("ml cup was incorrectly converted to grams or kcal")
        return
    var failer = FailingStore.new()
    failer.data = failer.default_data()
    if failer.add_food_entry(egg, 55.0, "Обед", "2026-11-21", "1 шт.", 1.0, "unknown"):
        _fail("failed storage incorrectly accepted a portion record")
        return
    if not failer.data["entries"].is_empty():
        _fail("failed write should roll back portion metadata with the entry")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    if not app.store.save_food_portion("d16", "1 шт.", 55.0):
        _fail("UI test serving could not be prepared")
        return
    var app_piece: Dictionary = app.store.portion_options(egg)[1]
    if not app.store.add_food_entry(egg, 55.0, "Завтрак", "2026-11-20",
            "1 шт.", 1.0, str(app_piece["id"])):
        _fail("UI test diary could not be prepared")
        return
    app.date = "2026-11-21"
    app.selected_meal = "Обед"
    app._meal_entry_locked = true
    app._meal_entry_date = "2026-11-21"
    app._quick_food_sheet(egg)
    await process_frame
    var sheet = app.get_node_or_null("ProductSheet")
    var selected: OptionButton = sheet.find_child("QuickPortionMeasure", true, false) if sheet != null else null
    var quantity: SpinBox = sheet.find_child("QuickPortionQuantity", true, false) if sheet != null else null
    var presets = sheet.find_child("QuickPortionPresets", true, false) if sheet != null else null
    var editor = sheet.find_child("QuickCustomPortionFields", true, false) if sheet != null else null
    var memo = sheet.find_child("QuickLastPortion", true, false) if sheet != null else null
    if selected == null or quantity == null or presets == null or editor == null or memo == null or \
            selected.selected != 1 or absf(quantity.value - 1.0) > 0.001 or \
            editor.visible or _find_button(presets, "½") == null:
        _fail("selected measure, history and compact half/one/two/three presets missing")
        return
    _find_button(presets, "2").pressed.emit()
    await process_frame
    if absf(quantity.value - 2.0) > 0.001:
        _fail("two-piece quick amount did not update quantity")
        return
    var preview = sheet.find_child("QuickPortionPreview", true, false) as Label
    if preview == null or not preview.text.contains("110") or not preview.text.contains("157"):
        _fail("two-piece preview did not calculate 110g and 157kcal")
        return
    var confirm = sheet.find_child("ProductSheetConfirm", true, false) as Button
    confirm.pressed.emit()
    await process_frame
    var entries: Array = app.store.day_entries("2026-11-21")
    if entries.size() != 1 or entries[0]["meal"] != "Обед" or \
            absf(float(entries[0]["grams"]) - 110.0) > 0.001 or \
            absf(float(entries[0].get("portion_count", 0)) - 2.0) > 0.001:
        _fail("quick portion did not save the chosen meal, base weight and count")
        return

    app._quick_food_sheet(egg)
    await process_frame
    sheet = app.get_node_or_null("ProductSheet")
    selected = sheet.find_child("QuickPortionMeasure", true, false) as OptionButton
    quantity = sheet.find_child("QuickPortionQuantity", true, false) as SpinBox
    if selected.selected != 1 or absf(quantity.value - 2.0) > 0.001:
        _fail("last two-piece serving not restored on reopening")
        return
    var toggle = sheet.find_child("QuickCustomPortionToggle", true, false) as Button
    toggle.pressed.emit()
    await process_frame
    editor = sheet.find_child("QuickCustomPortionFields", true, false)
    var templates = sheet.find_child("QuickCustomMeasureTemplates", true, false) as OptionButton
    var custom_name = sheet.find_child("QuickCustomMeasureLabel", true, false) as LineEdit
    var custom_weight = sheet.find_child("QuickCustomMeasureAmount", true, false) as SpinBox
    if not editor.visible or templates == null or custom_name == null or custom_weight == null:
        _fail("custom serving editor cannot be opened")
        return
    templates.select(4)
    templates.item_selected.emit(4)
    custom_weight.value = 250.0
    if custom_name.text != "1 стакан":
        _fail("serving name template not filled")
        return
    var save_button = sheet.find_child("QuickCustomMeasureSave", true, false) as Button
    save_button.pressed.emit()
    await process_frame
    sheet = app.get_node_or_null("ProductSheet")
    if sheet == null:
        _fail("new sheet must keep its original node name after custom measure save")
        return
    selected = sheet.find_child("QuickPortionMeasure", true, false) as OptionButton
    quantity = sheet.find_child("QuickPortionQuantity", true, false) as SpinBox
    if selected == null or quantity == null:
        _fail("replacement sheet is missing the portion selector")
        return
    if app.store.portion_options(egg).size() != 3 or selected.selected != 2 or \
            absf(quantity.value - 1.0) > 0.001:
        _fail("newly saved measure should immediately be selected at count 1")
        return
    sheet.queue_free()
    app.queue_free()
    print("PASS PORTIONS 0.7.35: half/two, last serving restore, custom templates, ml, exact diary snapshots and safe import")
    quit(0)
