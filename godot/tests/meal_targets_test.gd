extends SceneTree

const StoreScript = preload("res://src/store.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED MEAL TARGETS: " + reason)
    quit(1)

func _find_button(node: Node, name: String) -> Button:
    if node is Button and node.text == name:
        return node
    for child in node.get_children():
        var found = _find_button(child, name)
        if found != null:
            return found
    return null

func _find_label(node: Node, part: String) -> bool:
    if node is Label and node.text.contains(part):
        return true
    for child in node.get_children():
        if _find_label(child, part):
            return true
    return false

func _run() -> void:
    var store = StoreScript.new()
    store.data = store.default_data()
    if store.meal_shares() != [25, 35, 30, 10]:
        _fail("incorrect default distribution")
        return
    for invalid in [[25, 35, 30], [25, 35, 30, 11], [-5, 45, 40, 20],
            [25, 25, 25, 25.5], ["25", 35, 30, 10], [101, 0, 0, -1]]:
        if store.set_meal_shares(invalid):
            _fail("invalid calorie shares accepted: " + str(invalid))
            return
    if not store.set_meal_shares([20, 40, 30, 10]):
        _fail("valid calorie shares were rejected")
        return
    var readback = StoreScript.new()
    if readback.meal_shares() != [20, 40, 30, 10]:
        _fail("distribution was not saved or loaded")
        return
    var banana: Dictionary = store.food_by_id("d2")
    if banana.is_empty():
        _fail("banana fixture not found")
        return
    if not store.add_food_entry(banana, 200, "Обед", "2026-11-20") or not             store.add_food_entry(banana, 100, "Обед", "2026-11-20") or not             store.add_food_entry(banana, 100, "Завтрак", "2026-11-20"):
        _fail("could not record sample meals")
        return
    var lunch = store.meal_summary("2026-11-20", "Обед")
    var breakfast = store.meal_summary("2026-11-20", "Завтрак")
    if int(lunch["count"]) != 2 or absf(float(lunch["kcal"]) - 267.0) > 0.01:
        _fail("lunch kcal/count incorrect")
        return
    if absf(float(lunch["p"]) - 3.3) > 0.01 or absf(float(lunch["f"]) - 0.9) > 0.01 or             absf(float(lunch["c"]) - 69.0) > 0.01:
        _fail("lunch macros incorrect")
        return
    if int(breakfast["count"]) != 1 or absf(float(breakfast["kcal"]) - 89.0) > 0.01:
        _fail("breakfast contaminated by lunch")
        return
    if float(store.meal_summary("2026-11-19", "Обед")["kcal"]) != 0:
        _fail("wrong date contributed calories to meal")
        return

    var backup = JSON.parse_string(store.export_json())
    backup["settings"].erase("meal_shares")
    if not store.import_json(JSON.stringify(backup)):
        _fail("0.7.5 backup rejected")
        return
    if store.meal_shares() != [25, 35, 30, 10] or             store.day_entries("2026-11-20").size() != 3:
        _fail("legacy migration changed diary records")
        return
    var bad = JSON.parse_string(store.export_json())
    bad["settings"]["meal_shares"] = [25, 20, 20, 20]
    if store.import_json(JSON.stringify(bad)):
        _fail("invalid distribution accepted from backup")
        return

    var failing = FailingStore.new()
    failing.data = failing.default_data()
    if failing.set_meal_shares([20, 40, 30, 10]):
        _fail("write failure reported success")
        return
    if failing.meal_shares() != [25, 35, 30, 10]:
        _fail("failed save did not roll back shares")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.date = "2026-11-20"
    app._navigate_to_tab("day")
    await process_frame
    for i in range(4):
        var card = app.find_child("DailyMeal_" + str(i), true, false)
        if card == null:
            _fail("daily meal card is missing")
            return
        if card.find_child("MealProgress_" + str(i), true, false) == null:
            _fail("meal-target progress bar missing")
            return
        if not _find_label(card, "Ориентир:"):
            _fail("meal-specific kcal target not displayed")
            return
        if not _find_label(card, "БЕЛКИ") or not _find_label(card, "ЖИРЫ") or not _find_label(card, "УГЛЕВОДЫ"):
            _fail("per-meal macro indicators missing")
            return
    app.tab = "settings"
    app.settings_page = "main"
    app._render()
    await process_frame
    if _find_button(app, "Сохранить распределение") == null:
        _fail("meal distribution controls missing in settings")
        return
    if not _find_label(app, "Распределено: 100%"):
        _fail("sum validation hint missing")
        return
    print("PASS MEAL TARGETS: per-meal macros, day isolation, editable shares, migrations and failure rollback")
    app.queue_free()
    quit(0)
