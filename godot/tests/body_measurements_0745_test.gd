extends SceneTree

const Store = preload("res://src/store.gd")
const Body = preload("res://src/body_measurements.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_test")

func _fail(message: String) -> void:
    push_error("FAILED BODY MEASUREMENTS 0.7.45: " + message)
    quit(1)

func _test() -> void:
    var s = Store.new()
    s.data = s.default_data()
    var day = "2026-11-23"
    if not Body.valid_date("2024-02-29") or Body.valid_date("2025-02-29") or \
            Body.valid_date("2026-13-01"):
        _fail("calendar validation is incorrect")
        return
    if s.save_body_measurements(day, {}) or \
            s.save_body_measurements(day, {"waist": -50}) or \
            s.save_body_measurements(day, {"invalid": 90}):
        _fail("invalid or empty measurements were accepted")
        return
    if not s.save_body_measurements("2026-11-01", {
            "waist": 91.5, "hips": 113.0, "upper_arm": 35.0
        }) or not s.save_body_measurements(day, {
            "waist": 87.2, "hips": 110.0
        }):
        _fail("failed to save valid body measurements")
        return
    if s.body_measurements_on(day).size() != 2 or \
            s.body_metric_history("waist").size() != 2:
        _fail("partial snapshots or graph series invalid")
        return
    var details: Dictionary = s.body_metric_summary("waist")
    if absf(float(details["change"]) - (-4.3)) > 0.01 or \
            details["latest_date"] != day or details["count"] != 2:
        _fail("progress delta calculation is incorrect")
        return
    if s.body_metric_summary("waist", "2026-11-10")["latest_date"] != "2026-11-01" or \
            not s.body_metric_summary("calf").is_empty() or \
            not s.body_metric_history("waist", "2026-10-01").is_empty():
        _fail("nonfuture or missing metric handling failed")
        return
    if not s.save_body_measurements(day, {"hips": 109.5, "neck": 35.0}) or \
            s.body_measurements_on(day).has("waist") or \
            s.data["body_measurements"].size() != 2:
        _fail("editing a date must replace the prior snapshot, never duplicate it")
        return
    var loaded = Store.new()
    if absf(float(loaded.body_measurements_on(day).get("hips", 0.0)) - 109.5) > 0.01:
        _fail("measurements do not survive app restart")
        return
    var legacy: Dictionary = loaded.data.duplicate(true)
    legacy.erase("body_measurements")
    if not loaded.import_json(JSON.stringify(legacy), false) or \
            not loaded.data["body_measurements"].is_empty():
        _fail("legacy backup does not migrate cleanly")
        return
    var malformed: Dictionary = loaded.data.duplicate(true)
    malformed["body_measurements"] = [{"date": day, "values": {"waist": -1}}]
    if loaded.import_json(JSON.stringify(malformed), false):
        _fail("invalid backup was imported")
        return
    var broken = FailingStore.new()
    broken.data = broken.default_data()
    if broken.save_body_measurements(day, {"waist": 82.0}) or \
            not broken.data["body_measurements"].is_empty():
        _fail("disk save failure did not roll back changes")
        return
    if not s.delete_body_measurements(day) or \
            s.body_measurements_on(day).size() != 0 or \
            s.data["body_measurements"].size() != 1:
        _fail("deletion changed the wrong dates")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = day
    app.tab = "progress"
    app.progress_section = "body"
    app._render()
    await process_frame
    var field = app.find_child("BodyField_waist", true, false) as LineEdit
    var save_button = app.find_child("BodyMeasurementsSave", true, false) as Button
    if field == null or save_button == null or \
            app.find_child("BodyMeasurementsGrid", true, false) == null:
        _fail("measurements form missing inside Progress")
        return
    field.text = "82,5"
    save_button.pressed.emit()
    await process_frame
    if absf(float(app.store.body_measurements_on(day).get("waist", 0)) - 82.5) > 0.01:
        _fail("decimal comma or UI save did not work")
        return
    if app.find_child("BodyMeasurementsGraph", true, false) == null or \
            app.find_child("BodyMeasurementMetricPicker", true, false) == null:
        _fail("graph missing after first measurement")
        return
    app.tab = "profile"
    app._render()
    await process_frame
    var shortcut = app.find_child("ProfileBodyMeasurements", true, false) as Button
    if shortcut == null:
        _fail("profile shortcut is missing")
        return
    shortcut.pressed.emit()
    await process_frame
    if app.tab != "progress" or app.progress_section != "body":
        _fail("profile shortcut did not open body measurements")
        return
    if app.tab_buttons.size() != 5:
        _fail("body measurements unexpectedly altered bottom navigation")
        return
    app.queue_free()
    print("PASS BODY MEASUREMENTS 0.7.45: partial dates, trend, graph, UI, migration, rollback, delete")
    quit(0)
