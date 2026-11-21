extends SceneTree

const Store = preload("res://src/store.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_test")

func _fail(message: String) -> void:
    push_error("FAILED SMART DIARY 0.7.41: " + message)
    quit(1)

func _entry(day: String, meal: String, identity: String,
        grams: float = 120.0, kcal: float = 200.0) -> Dictionary:
    return {"id":identity, "date":day, "food":"d0", "meal":meal,
        "grams":grams, "unit":"г",
        "nutrition":{"name":"Овсянка", "kcal":kcal,
            "p":13.0, "f":7.0, "c":62.0, "nutrition_unit":"г"}}

func _test() -> void:
    var store = Store.new()
    store.data = store.default_data()
    var source = _entry("2026-11-19", "Завтрак", "source")
    var other = _entry("2026-11-19", "Обед", "other", 80.0, 90.0)
    var existing = _entry("2026-11-20", "Завтрак", "existing")
    store.data["entries"] = [source, other, existing]
    store.data["notes"]["2026-11-20"] = "Частная запись"
    store.data["weights"] = [{"date":"2026-11-20", "value":87.0}]
    store.data["activities"] = [{"date":"2026-11-20", "type":"walk", "minutes":40}]
    var plan = store.day_copy_plan("2026-11-19", "2026-11-20", false, true)
    if plan["entries"].size() != 1 or int(plan["duplicates"]) != 1:
        _fail("duplicate skip plan does not detect existing portions")
        return
    if store.copy_day("2026-11-19", "2026-11-20", false, true) != 1 or \
            store.day_entries("2026-11-20").size() != 2 or \
            not store.can_undo_day_copy("2026-11-20"):
        _fail("duplicate-aware copy or undo tracking failed")
        return
    if store.copy_day("2026-11-19", "2026-11-20", false, true) != 0:
        _fail("copying the same source twice added duplicates")
        return
    var restarted = Store.new()
    if not restarted.can_undo_day_copy("2026-11-20") or \
            not restarted.undo_day_copy() or \
            restarted.day_entries("2026-11-20").size() != 1:
        _fail("undo should survive restart and restore previous food")
        return
    if restarted.data["notes"]["2026-11-20"] != "Частная запись" or \
            restarted.data["weights"].size() != 1 or \
            restarted.data["activities"].size() != 1:
        _fail("undo destroyed notes, exercise or weight records")
        return
    if restarted.copy_day("2026-11-19", "2026-11-20", true) != 2:
        _fail("replace mode failed")
        return
    restarted.data["entries"].append(_entry("2026-11-20", "Перекус", "manually_added"))
    if restarted.can_undo_day_copy() or restarted.undo_day_copy():
        _fail("undo may not remove food logged after the copy")
        return
    restarted.data["entries"].pop_back()
    if not restarted.can_undo_day_copy():
        _fail("undo tracking lost the previous expected state")
        return
    var legacy = JSON.parse_string(restarted.export_json())
    legacy.erase("day_copy_undo")
    if not restarted.import_json(JSON.stringify(legacy), false) or \
            not restarted.data["day_copy_undo"].is_empty():
        _fail("legacy JSON cannot be restored without undo field")
        return
    var corrupted = JSON.parse_string(restarted.export_json())
    corrupted["day_copy_undo"] = {"date":"2026-11-20", "before":"bad", "after":[]}
    if restarted.import_json(JSON.stringify(corrupted), false):
        _fail("invalid undo snapshots must fail import")
        return
    store.data["entries"] = [source.duplicate(true)]
    store.data["entries"][0]["portion_count"] = 2.0
    store.data["entries"][0]["portion_id"] = "bowl"
    store.data["entries"][0]["portion_label"] = "Миска"
    if not store.save_meal_template("2026-11-19", "Завтрак", "Любимый завтрак"):
        _fail("save template failed")
        return
    var template = store.data["meal_templates"][0]
    var tid: String = str(template["id"])
    if float(template["items"][0].get("portion_count", 0)) != 2.0 or \
            str(template["items"][0].get("portion_id", "")) != "bowl" or \
            store.apply_meal_template(tid, "2026-11-21") != 1:
        _fail("template lost serving metadata")
        return
    var applied = store.day_entries("2026-11-21")[0]
    if float(applied.get("portion_count", 0)) != 2.0 or \
            str(applied.get("portion_id", "")) != "bowl":
        _fail("applied template lost original measure")
        return
    var new_items: Array = template["items"].duplicate(true)
    new_items[0]["grams"] = 160.0
    new_items[0].erase("portion_count")
    new_items[0].erase("portion_id")
    if not store.update_meal_template(tid, "Новый завтрак", new_items) or \
            store.update_meal_template(tid, "", new_items) or \
            store.update_meal_template(tid, "Пустой", []):
        _fail("template edit/save validation failed")
        return
    var broken = FailingStore.new()
    broken.data = broken.default_data()
    broken.data["entries"] = [source.duplicate(true), existing.duplicate(true)]
    var snapshot: String = JSON.stringify(broken.data)
    if broken.copy_day("2026-11-19", "2026-11-20", true) != 0 or \
            JSON.stringify(broken.data) != snapshot:
        _fail("failed save did not roll back copy and undo metadata")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.store.data["entries"] = [source.duplicate(true), other.duplicate(true),
        existing.duplicate(true)]
    app.store.data["meal_templates"] = [{
        "id":"editor_test", "name":"Старый набор",
        "items":[template["items"][0].duplicate(true)]
    }]
    app.date = "2026-11-20"
    app.tab = "day"
    app.day_tools_expanded = true
    app._render()
    await process_frame
    (app.find_child("DayCopyOpen", true, false) as Button).pressed.emit()
    await process_frame
    var sheet = app.get_node_or_null("ProductSheet")
    var calendar_toggle = sheet.find_child("DayCopyCalendarToggle", true, false) as Button
    if calendar_toggle == null:
        _fail("copy-day calendar toggle missing")
        return
    calendar_toggle.pressed.emit()
    await process_frame
    var chosen = sheet.find_child("DayCopyCalendar_2026-11-19", true, false) as Button
    var blank = sheet.find_child("DayCopyCalendar_2026-11-18", true, false) as Button
    if chosen == null or chosen.disabled or blank == null or not blank.disabled:
        _fail("calendar should enable only days containing meals")
        return
    chosen.pressed.emit()
    await process_frame
    var preview = sheet.find_child("DayCopyPreview", true, false) as Label
    if preview == null or not preview.text.contains("Совпадений: 1"):
        _fail("copy preview should warn about duplicate records")
        return
    sheet.queue_free()
    await process_frame
    (app.find_child("DayTemplatesOpen", true, false) as Button).pressed.emit()
    await process_frame
    sheet = app.get_node_or_null("ProductSheet")
    var edit = sheet.find_child("TemplateEdit_editor_test", true, false) as Button
    if edit == null:
        _fail("template edit button missing")
        return
    edit.pressed.emit()
    await process_frame
    sheet = app.get_node_or_null("ProductSheet")
    var title = sheet.find_child("TemplateEditName", true, false) as LineEdit
    var grams = sheet.find_child("TemplateEditAmount_0", true, false) as SpinBox
    var meal = sheet.find_child("TemplateEditMeal", true, false) as OptionButton
    if title == null or grams == null or meal == null:
        _fail("template editor fields missing")
        return
    title.text = "Изменённый набор"
    grams.value = 150.0
    meal.select(1)
    if str(app.store.data["meal_templates"][0]["name"]) != "Старый набор":
        _fail("editing draft changed saved template before Save")
        return
    (sheet.find_child("ProductSheetConfirm", true, false) as Button).pressed.emit()
    await process_frame
    if str(app.store.data["meal_templates"][0]["name"]) != "Изменённый набор" or \
            absf(float(app.store.data["meal_templates"][0]["items"][0]["grams"]) - 150.0) > 0.001 or \
            str(app.store.data["meal_templates"][0]["items"][0]["meal"]) != "Обед" or \
            app.store.data["meal_templates"][0]["items"][0].has("portion_id"):
        _fail("template editor did not save the draft and reset old serving count")
        return
    app.queue_free()
    print("PASS SMART DIARY 0.7.41: calendar, deduplication, persistent undo, template editing and migration")
    quit(0)
