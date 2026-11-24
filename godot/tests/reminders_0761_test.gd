extends SceneTree
const Reminders = preload("res://src/reminders.gd")
const Store = preload("res://src/store.gd")
const FailingStore = preload("res://tests/failing_store.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("REMINDERS 0.7.61: " + reason)
    quit(1)
func _run() -> void:
    var s = Store.new()
    s.data = s.default_data()
    var schedule = s.reminder_settings()
    if Reminders.enabled_count(schedule) != 0 or Reminders.valid_time("24:00") or Reminders.valid_time("12:60") or not Reminders.valid_time("00:00"):
        _fail("defaults or time validation")
        return
    schedule["water"] = {"enabled":true,"time":"11:30","day":0}
    if not s.set_reminders(schedule) or s.reminder_settings()["water"]["time"] != "11:30":
        _fail("save schedule")
        return
    var broken = FailingStore.new()
    broken.data = broken.default_data()
    if broken.set_reminders(schedule) or Reminders.enabled_count(broken.reminder_settings()) != 0:
        _fail("rollback")
        return
    var legacy = s.data.duplicate(true)
    legacy["settings"].erase("reminders")
    if not s.import_json(JSON.stringify(legacy),false) or Reminders.enabled_count(s.reminder_settings()) != 0:
        _fail("old diary migration")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.tab = "settings"
    app.settings_page = "main"
    app.settings_section_open = "reminders"
    app._render()
    await process_frame
    var toggle = app.find_child("ReminderToggle_water",true,false) as CheckButton
    var time = app.find_child("ReminderTime_water",true,false) as LineEdit
    var day = app.find_child("ReminderDay_water",true,false) as OptionButton
    var save = app.find_child("ReminderSave",true,false) as Button
    if toggle == null or time == null or day == null or save == null:
        _fail("missing editor")
        return
    toggle.button_pressed = true
    time.text = "10:15"
    day.select(3)
    save.pressed.emit()
    await process_frame
    var record = app.store.reminder_settings()["water"]
    if not record["enabled"] or record["time"] != "10:15" or record["day"] != 3:
        _fail("editor save")
        return
    app.queue_free()
    print("PASS REMINDERS: opt-in schedule, time and weekday validation, persistence, migration and editor")
    quit(0)
