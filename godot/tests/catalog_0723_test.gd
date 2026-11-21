extends SceneTree

const Barcode = preload("res://src/barcode_lookup.gd")
const Store = preload("res://src/store.gd")
const Portion = preload("res://src/portion_math.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED CATALOG 0.7.23: " + reason)
    quit(1)

func _find_button(node: Node, caption: String) -> Button:
    if node is Button and node.text == caption:
        return node
    for child in node.get_children():
        var found: Button = _find_button(child, caption)
        if found != null:
            return found
    return null

func _payload(quantity: String, unit: String, serving: String = "") -> Dictionary:
    return {"status": 1, "product": {
        "product_name_ru": "Тестовый напиток",
        "quantity": quantity,
        "product_quantity_unit": unit,
        "serving_size": serving,
        "nutriments": {
            "energy-kcal_100g": 50.0, "proteins_100g": 3.0,
            "fat_100g": 2.0, "carbohydrates_100g": 5.0
        }
    }}

func _run() -> void:
    if not Barcode.OFF_FIELDS.contains("product_quantity_unit"):
        _fail("remote API request does not fetch package basis")
        return
    for case in [
        {"quantity":"1 l", "unit":"l", "expected":"мл"},
        {"quantity":"330 мл", "unit":"", "expected":"мл"},
        {"quantity":"500 ml", "unit":"", "expected":"мл"},
        {"quantity":"200 g", "unit":"", "expected":"г"},
        {"quantity":"1 kg", "unit":"kg", "expected":"г"},
        {"quantity":"", "unit":"", "expected":"г"}
    ]:
        var record = Barcode.parse_product(
            _payload(str(case["quantity"]), str(case["unit"])), "3017624010701")
        if record.has("error") or str(record.get("nutrition_unit", "")) != str(case["expected"]):
            _fail("incorrect unit detection for " + str(case))
            return
    var unknown = Barcode.parse_product(_payload("", ""), "3017624010701")
    if str(unknown.get("unit_certainty", "")) != "unknown":
        _fail("unspecified nutrition basis must be marked uncertain")
        return
    var milk = Barcode.parse_product(_payload("1 l", "l"), "3017624010701")
    var cup = Portion.nutrients(milk, 250.0)
    if Portion.base_unit(milk) != "мл" or absf(float(cup["kcal"]) - 125.0) > 0.01:
        _fail("250 ml drink must use 100 ml nutrition basis")
        return
    var store = Store.new()
    store.data = store.default_data()
    var saved = store.save_barcode_food(milk)
    if saved.is_empty() or str(store.food_by_id(saved).get("nutrition_unit", "")) != "мл":
        _fail("saving online drink lost its liquid basis")
        return
    if not store.add_food_entry(store.food_by_id(saved), 250.0, "Обед", "2026-11-21"):
        _fail("cannot save drink to journal")
        return
    if absf(store.day_calories("2026-11-21") - 125.0) > 0.01 or \
            str(store.day_entries("2026-11-21")[0].get("unit", "")) != "мл":
        _fail("journal calories or unit wrong for online drink")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.tab = "search"
    app._render()
    await process_frame
    var barcode_panel = app.find_child("FoodBarcodePanel", true, false) as VBoxContainer
    var advance = app.find_child("FoodAdvancedToggle", true, false) as Button
    var picker = app.find_child("FoodQuantityUnitHint", true, false) as Label
    var results = app.find_child("FoodSearchResults", true, false) as VBoxContainer
    if barcode_panel == null or advance == null or picker == null or results == null:
        _fail("compact catalog controls or results missing")
        return
    if barcode_panel.visible or picker.visible:
        _fail("advanced fields should start collapsed")
        return
    advance.pressed.emit()
    await process_frame
    if not picker.visible:
        _fail("advanced settings cannot open")
        return
    advance.pressed.emit()
    if picker.visible:
        _fail("advanced settings cannot close")
        return
    var toggle = _find_button(app, "▣ Штрихкод")
    if toggle == null:
        _fail("barcode scanner / manual input entry point missing")
        return
    toggle.pressed.emit()
    await process_frame
    if not barcode_panel.visible or not is_instance_valid(app.barcode_input):
        _fail("barcode entry does not expand")
        return
    app._show_online_search_results([milk])
    await process_frame
    var online = app.find_child("OnlineFoodSearchResults", true, false) as VBoxContainer
    if online == null or not online.visible:
        _fail("online result not shown")
        return
    var choose = _find_button(online, "Выбрать")
    if choose == null:
        _fail("online result cannot be selected")
        return
    choose.pressed.emit()
    await process_frame
    var basis = app.find_child("BarcodeNutritionBasis", true, false) as OptionButton
    if basis == null or basis.selected != 1:
        _fail("liquid must default to 100 ml in review form")
        return
    if app.find_child("ProductSheetConfirm", true, false) == null:
        _fail("review form lost save action")
        return
    print("PASS CATALOG 0.7.23: volume/mass detection, history, compact search, barcode reveal and review")
    app.queue_free()
    quit(0)
