extends SceneTree

const Store = preload("res://src/store.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED SMART DIARY 0.7.40: " + message)
    quit(1)

func _find_button(node: Node, text_value: String) -> Button:
    if node is Button and node.text == text_value:
        return node
    for child in node.get_children():
        var found: Button = _find_button(child, text_value)
        if found != null:
            return found
    return null

func _entry(day: String, meal: String, grams: float, kcal: float, identity: String) -> Dictionary:
    return {"id":identity, "date":day, "food":"custom_removed",
        "meal":meal, "grams":grams, "unit":"г",
        "nutrition":{"name":"Исторический продукт", "kcal":kcal,
            "p":12.0,"f":7.0,"c":23.0}}

func _run() -> void:
    var s = Store.new()
    s.data = s.default_data()
    if not Store.valid_diary_date("2024-02-29") or \
            Store.valid_diary_date("2025-02-29") or \
            Store.valid_diary_date("2026-13-05") or \
            Store.valid_diary_date("2026-11-31") or \
            Store.valid_diary_date("2026-11-2"):
        _fail("invalid dates or leap days in day copy")
        return
    s.data["entries"] = [
        _entry("2026-11-19","Завтрак",120,200,"source_one"),
        _entry("2026-11-19","Обед",150,90,"source_two"),
        _entry("2026-11-20","Ужин",100,50,"existing")
    ]
    s.data["activities"] = [
        {"date":"2026-11-20","type":"walk","minutes":40}
    ]
    s.data["weights"] = [{"date":"2026-11-20","value":86.0}]
    s.data["notes"]["2026-11-20"] = "Моя заметка"
    var preserved_act: Array = s.data["activities"].duplicate(true)
    var preserved_weight: Array = s.data["weights"].duplicate(true)
    var preserved_notes: Dictionary = s.data["notes"].duplicate(true)
    var source_json: String = JSON.stringify(s.day_entries("2026-11-19"))
    var no_copy: int = s.copy_day("2026-11-19","2026-11-19",true)
    if no_copy != 0 or s.copy_day("2026-11-18","2026-11-20",true) != 0 or \
            s.copy_day("wrong","2026-11-20",true) != 0:
        _fail("invalid/empty/same-day copy was accepted")
        return
    if s.copy_day("2026-11-19","2026-11-20") != 2:
        _fail("add mode failed to copy both meals")
        return
    var after_add: Array = s.day_entries("2026-11-20")
    if after_add.size() != 3 or \
            absf(s.day_calories("2026-11-20") - 425.0) > 0.01 or \
            str(after_add[1]["nutrition"]["name"]) != "Исторический продукт" or \
            after_add[1]["id"] == "source_one" or \
            JSON.stringify(s.day_entries("2026-11-19")) != source_json:
        _fail("add copied incorrect calories, name or ID")
        return
    if s.copy_day("2026-11-19","2026-11-20",true) != 2:
        _fail("replace mode failed")
        return
    if s.day_entries("2026-11-20").size() != 2 or \
            absf(s.day_calories("2026-11-20") - 375.0) > 0.01 or \
            s.data["activities"] != preserved_act or s.data["weights"] != preserved_weight or \
            s.data["notes"] != preserved_notes:
        _fail("replace mode destroyed sports, notes, weights or got calories wrong")
        return
    var persisted = Store.new()
    if persisted.day_entries("2026-11-20").size() != 2:
        _fail("copied entries were not persisted")
        return
    var old_json: Dictionary = JSON.parse_string(s.export_json())
    old_json.erase("meal_templates")
    if not s.import_json(JSON.stringify(old_json)) or \
            not s.data.has("meal_templates") or s.data["meal_templates"].size() != 0:
        _fail("legacy JSON without templates could not be restored")
        return
    if not s.save_meal_template("2026-11-19", "Завтрак", "Мой завтрак"):
        _fail("template save failed")
        return
    var template: Dictionary = s.data["meal_templates"][0]
    if not is_equal_approx(float(template["items"][0]["nutrition"]["kcal"]), 200):
        _fail("saved template did not snapshot historical nutrients")
        return
    if s.apply_meal_template(str(template["id"]), "2026-11-21") != 1 or \
            absf(s.day_calories("2026-11-21") - 240.0) > 0.01:
        _fail("applying a template changed nutrition snapshot")
        return
    if not s.delete_meal_template(str(template["id"])) or \
            not s.data["meal_templates"].is_empty():
        _fail("deleting template failed")
        return
    var broken = FailingStore.new()
    broken.data = broken.default_data()
    broken.data["entries"] = [
        _entry("2026-11-19","Завтрак",120,200,"test_source"),
        _entry("2026-11-20","Обед",130,80,"keep_me")
    ]
    var before: String = JSON.stringify(broken.data)
    if broken.copy_day("2026-11-19","2026-11-20",true) != 0 or \
            JSON.stringify(broken.data) != before:
        _fail("atomic failed write did not restore previous diary")
        return
    if broken.repeat_meal("2026-11-19","Завтрак","2026-11-20") != 0 or \
            JSON.stringify(broken.data) != before:
        _fail("meal repeat failed to roll back")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.store.data["entries"] = [
        _entry("2026-11-19","Завтрак",120,200,"source1"),
        _entry("2026-11-19","Обед",150,90,"source2"),
        _entry("2026-11-20","Ужин",100,50,"current")
    ]
    app.date = "2026-11-20"
    app.tab = "day"
    app._render()
    await process_frame
    if app.find_child("DayCopyOpen", true, false) != null:
        _fail("copy tools should be hidden by default")
        return
    var toggle = app.find_child("DayToolsToggle", true, false) as Button
    if toggle == null or toggle.custom_minimum_size.y > 40:
        _fail("compact day tools toggle missing")
        return
    toggle.pressed.emit()
    await process_frame
    var start_copy = app.find_child("DayCopyOpen", true, false) as Button
    var templates = app.find_child("DayTemplatesOpen", true, false) as Button
    if start_copy == null or templates == null:
        _fail("compact copy/templates menu missing")
        return
    start_copy.pressed.emit()
    await process_frame
    var sheet = app.get_node_or_null("ProductSheet")
    var source = sheet.find_child("DayCopySource", true, false) as LineEdit if sheet != null else null
    var mode = sheet.find_child("DayCopyMode", true, false) as OptionButton if sheet != null else null
    var preview = sheet.find_child("DayCopyPreview", true, false) as Label if sheet != null else null
    if source == null or mode == null or preview == null or \
            source.text != "2026-11-19" or not preview.text.contains("375 ккал"):
        _fail("copy sheet has no correct date, mode or nutrition preview")
        return
    var confirm = sheet.find_child("ProductSheetConfirm", true, false) as Button
    confirm.pressed.emit()
    await process_frame
    var dialog = app.get_node_or_null("DayCopyConfirmation") as ConfirmationDialog
    if dialog == null or app.store.day_entries("2026-11-20").size() != 1:
        _fail("copy wrote data before explicit final confirmation")
        return
    dialog.canceled.emit()
    await process_frame
    if app.store.day_entries("2026-11-20").size() != 1:
        _fail("cancelled copy changed data")
        return
    mode.select(1)
    mode.item_selected.emit(1)
    confirm.pressed.emit()
    await process_frame
    dialog = app.get_node_or_null("DayCopyConfirmation") as ConfirmationDialog
    if dialog == null or dialog.ok_button_text != "Заменить":
        _fail("replace destination has no explicit destructive confirmation")
        return
    dialog.confirmed.emit()
    await process_frame
    if app.store.day_entries("2026-11-20").size() != 2 or \
            absf(app.store.day_calories("2026-11-20") - 375.0) > 0.01:
        _fail("confirmed day replacement incorrect")
        return
    app.tab = "day"
    app._render()
    await process_frame
    templates = app.find_child("DayTemplatesOpen", true, false) as Button
    templates.pressed.emit()
    await process_frame
    sheet = app.get_node_or_null("ProductSheet")
    if sheet == null or not (sheet.find_child("ProductSheetConfirm", true, false) is Button):
        _fail("empty templates menu missing or unclosable")
        return
    sheet.queue_free()
    app.queue_free()
    print("PASS SMART DIARY 0.7.40: copy add/replace, snapshots, JSON migration, templates, rollback and UI confirmation")
    quit(0)
