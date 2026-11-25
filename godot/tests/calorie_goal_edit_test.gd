extends SceneTree

const StoreScript = preload("res://src/store.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED CALORIE EDIT: " + message)
    quit(1)

func _button(node: Node, text_value: String) -> Button:
    if node is Button and node.text == text_value:
        return node
    for child in node.get_children():
        var found = _button(child, text_value)
        if found != null:
            return found
    return null

func _contains_text(node: Node, phrase: String) -> bool:
    if node is Label and node.text.contains(phrase):
        return true
    for child in node.get_children():
        if _contains_text(child, phrase):
            return true
    return false

func _run() -> void:
    for entry in ["", "  ", "abc", "1800.7", "900", "5001", "-1", "12 00"]:
        if StoreScript.parse_calorie_target(entry) != -1:
            _fail("invalid manual target accepted: " + entry)
            return
    if StoreScript.parse_calorie_target(" 1800 ") != 1800 or \
            StoreScript.parse_calorie_target("1000") != 1000 or \
            StoreScript.parse_calorie_target("5000") != 5000:
        _fail("valid integer target rejected")
        return
    var store = StoreScript.new()
    store.data = store.default_data()
    var details = store.data["settings"].get("personal", {}).duplicate(true)
    var original_weights = store.data["weights"].duplicate(true)
    if not store.set_daily_calorie_goal(1850):
        _fail("valid goal could not be saved")
        return
    var reloaded = StoreScript.new()
    if roundi(float(reloaded.data["settings"]["kcal"])) != 1850:
        _fail("manual kcal value did not survive restart")
        return
    if reloaded.data["settings"].get("personal", {}) != details or \
            reloaded.data["weights"] != original_weights:
        _fail("manual edit changed personal data or weight entries")
        return
    if store.set_daily_calorie_goal(999) or store.set_daily_calorie_goal(5001):
        _fail("invalid manual range was saved")
        return
    var failing = FailingStore.new()
    failing.data = failing.default_data()
    var before = float(failing.data["settings"]["kcal"])
    if failing.set_daily_calorie_goal(1920) or float(failing.data["settings"]["kcal"]) != before:
        _fail("disk-write failure did not roll back the daily target")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.date = "2026-11-21"
    app.tab = "day"
    app._render()
    await process_frame
    var edit = app.find_child("EditDailyCalorieGoal", true, false) as Button
    if edit == null:
        _fail("day overview has no visible manual calorie editor")
        return
    edit.pressed.emit()
    await process_frame
    var sheet = app.get_node_or_null("ProductSheet")
    var input = app.find_child("CalorieGoalEditorInput", true, false) as LineEdit
    if sheet == null or input == null or input.text != str(roundi(float(app.store.data["settings"]["kcal"]))):
        _fail("calorie editor is missing or prefilled incorrectly")
        return
    var save = _button(sheet, "Сохранить")
    if save == null:
        _fail("no explicit save action")
        return
    input.text = "900"
    save.pressed.emit()
    await process_frame
    if float(app.store.data["settings"]["kcal"]) != before or \
            app.get_node_or_null("ProductSheet") == null:
        _fail("invalid manual kcal was saved or editor closed")
        return
    input.text = "1880"
    save.pressed.emit()
    await process_frame
    if int(app.store.data["settings"]["kcal"]) != 1880 or \
            app.get_node_or_null("ProductSheet") != null:
        _fail("new target was not applied to day")
        return
    if not _contains_text(app.body, "0 из 1880 ккал"):
        _fail("daily energy summary did not refresh")
        return
    var breakfast = app.find_child("DailyMeal_0", true, false)
    if breakfast == null or not _contains_text(breakfast, "0 / 470 ккал"):
        _fail("meal targets were not recomputed using manual 1880 kcal")
        return

    app.tab = "profile"
    app._render()
    await process_frame
    var profile_edit = app.find_child("ProfileEditCalorieGoal", true, false) as Button
    if profile_edit == null:
        _fail("profile missing direct calorie edit action")
        return
    profile_edit.pressed.emit()
    await process_frame
    input = app.find_child("CalorieGoalEditorInput", true, false) as LineEdit
    input.text = "1900"
    _button(app.get_node("ProductSheet"), "Сохранить").pressed.emit()
    await process_frame
    if int(app.store.data["settings"]["kcal"]) != 1900:
        _fail("profile edit did not update target")
        return

    app.tab = "settings"
    app.settings_page = "main"
    app._render()
    await process_frame
    var settings_field = app.find_child("DailyCalorieTarget", true, false) as LineEdit
    var preview = app.find_child("MealCaloriePreview", true, false) as Label
    if settings_field == null or preview == null:
        _fail("settings page missing editable numeric text field")
        return
    settings_field.text = "2000"
    settings_field.text_changed.emit(settings_field.text)
    if not preview.text.contains("При 2000 ккал"):
        _fail("meal calorie distribution preview did not update")
        return
    _button(app, "Сохранить настройки").pressed.emit()
    await process_frame
    if int(app.store.data["settings"]["kcal"]) != 2000:
        _fail("settings did not save manually typed target")
        return
    var on_disk = StoreScript.new()
    if int(on_disk.data["settings"]["kcal"]) != 2000:
        _fail("settings goal did not survive an app restart")
        return
    print("PASS CALORIE EDIT: direct day, profile, settings, validation, meal targets, data preservation and persistence")
    app.queue_free()
    quit(0)
