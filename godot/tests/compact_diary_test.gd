extends SceneTree

# Regression for the 0.7.7 compact daily journal, per-day expand state,
# over-goal warning, repeat confirmation, live goal preview and g/ml labels.
func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED COMPACT DIARY: " + message)
    quit(1)

func _find_button(node: Node, label: String) -> Button:
    if node == null:
        return null
    if node is Button and node.text == label:
        return node
    for child in node.get_children():
        var found = _find_button(child, label)
        if found != null:
            return found
    return null

func _has_text(node: Node, part: String) -> bool:
    if node == null:
        return false
    if node is Label and node.text.contains(part):
        return true
    for child in node.get_children():
        if _has_text(child, part):
            return true
    return false

func _find_search(node: Node) -> LineEdit:
    if node is LineEdit and node.placeholder_text == "Поиск продукта по названию":
        return node
    for child in node.get_children():
        var found = _find_search(child)
        if found != null:
            return found
    return null

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.date = "2026-11-20"
    app.month_shown = "2026-11"
    var egg = app.store.food_by_id("d16")
    if egg.is_empty() or not app.store.add_food_entry(egg, 500.0, "Завтрак", app.date):
        _fail("cannot create over-target breakfast")
        return
    app._navigate_to_tab("day")
    await process_frame
    for i in range(4):
        var card = app.find_child("DailyMeal_" + str(i), true, false)
        if card == null or card.find_child("MealDetails_" + str(i), true, false) != null:
            _fail("all daily meals should default to compact mode")
            return
        if _find_button(card, "⌄") == null:
            _fail("compact section has no expansion control")
            return
    var breakfast = app.find_child("DailyMeal_0", true, false)
    if not _has_text(breakfast, "Превышение: +265 ккал"):
        _fail("over-target kcal not displayed")
        return
    var progress = breakfast.find_child("MealProgress_0", true, false)
    if progress == null or absf(progress.value - progress.max_value) > 0.01:
        _fail("over-target progress should saturate at 100% without losing the excess label")
        return
    var toggle = _find_button(breakfast, "⌄")
    toggle.pressed.emit()
    await process_frame
    breakfast = app.find_child("DailyMeal_0", true, false)
    if breakfast.find_child("MealDetails_0", true, false) == null or \
            _find_button(breakfast, "⌃") == null:
        _fail("expanded breakfast lost product rows")
        return
    app._navigate_to_tab("search")
    app._navigate_to_tab("day")
    await process_frame
    if app.find_child("MealDetails_0", true, false) == null:
        _fail("expanded meal state lost on navigation")
        return

    if not app.store.add_food_entry(egg, 100.0, "Завтрак", "2026-11-19"):
        _fail("cannot seed yesterday breakfast")
        return
    app._render()
    await process_frame
    var repeat_button = _find_button(app.find_child("DailyMeal_0", true, false), "↻ Повторить со вчера")
    if repeat_button == null:
        _fail("expanded section has no quick repeat")
        return
    repeat_button.pressed.emit()
    await process_frame
    if app.store.day_entries("2026-11-20").size() != 1:
        _fail("repeat executed without confirmation")
        return
    var dialog = app.find_children("*", "ConfirmationDialog", true, false)
    if dialog.is_empty() or str(dialog[0].ok_button_text) != "Повторить":
        _fail("repeat confirmation missing")
        return
    dialog[0].confirmed.emit()
    await process_frame
    if app.store.day_entries("2026-11-20").size() != 2:
        _fail("confirmed repeat failed")
        return

    app.date = "2026-11-19"
    app._render()
    await process_frame
    if app.find_child("MealDetails_0", true, false) != null:
        _fail("open state of one date leaked into previous date")
        return
    app.date = "2026-11-20"
    app._render()
    await process_frame
    if app.find_child("MealDetails_0", true, false) == null:
        _fail("returning to a date forgot its expanded section")
        return

    app.tab = "settings"
    app.settings_page = "main"
    app._render()
    await process_frame
    var preview = app.find_child("MealCaloriePreview", true, false) as Label
    var first = app.find_child("MealShareField_0", true, false) as SpinBox
    var third = app.find_child("MealShareField_2", true, false) as SpinBox
    var daily = app.find_child("DailyCalorieTarget", true, false) as SpinBox
    if preview == null or first == null or third == null or daily == null:
        _fail("live distribution editor missing controls")
        return
    first.value = 30
    if not _has_text(app, "Распределено: 105%"):
        _fail("distribution sum did not refresh")
        return
    third.value = 25
    daily.value = 2000
    if not preview.text.contains("При 2000 ккал") or not preview.text.contains("Завтрак 600"):
        _fail("calorie breakdown did not respond to new daily target and shares")
        return

    var drink = {"name":"Проверочный напиток", "kcal":52.0, "p":3.0, "f":2.0, "c":5.0,
        "nutrition_unit":"мл"}
    if not app.store.add_custom_food_without_barcode(drink):
        _fail("cannot create 100ml based product")
        return
    app._navigate_to_tab("search")
    await process_frame
    var search = _find_search(app)
    if search == null:
        _fail("catalog search missing")
        return
    search.text = "Проверочный напиток"
    search.text_changed.emit(search.text)
    await process_frame
    var unit_hint = app.find_child("FoodQuantityUnitHint", true, false) as Label
    var buttons = app.find_child("FoodQuantityPresets", true, false) as HBoxContainer
    var results = app.find_child("FoodSearchResults", true, false)
    if unit_hint == null or unit_hint.text != "Количество, мл":
        _fail("milliliter hint not applied to selected drink")
        return
    if buttons == null or buttons.get_child_count() == 0 or \
            str(buttons.get_child(0).text) != "50 мл":
        _fail("milliliter preset still says grams")
        return
    if not _has_text(results, "100 мл"):
        _fail("food search result still says 100g for liquid products")
        return
    print("PASS COMPACT DIARY: four collapsed meals, expansion, overage, safe repeat, live shares and ml search")
    app.queue_free()
    quit(0)
