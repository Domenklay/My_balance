extends SceneTree

const Store = preload("res://src/store.gd")
const Activity = preload("res://src/activity_math.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED ACTIVITY 0.7.43: " + reason)
    quit(1)

func _run() -> void:
    var s = Store.new()
    s.data = s.default_data()
    var date = "2026-11-23"
    s.data["entries"].append({
        "id": "meal", "date": date, "meal": "Завтрак",
        "food": "test", "grams": 100,
        "nutrition": {"name": "test", "kcal": 250, "p": 10, "f": 10, "c": 30}
    })
    var calories_before = s.day_calories(date)
    if s.day_steps(date) != 0 or not s.set_day_steps(date, 7100):
        _fail("steps cannot be saved")
        return
    if not s.add_activity(date, "walk", 40.0, 3.2, "Парк") or             not s.add_activity(date, "strength", 20.0):
        _fail("workouts cannot be saved")
        return
    var summary = s.day_activity_summary(date)
    if summary["steps"] != 7100 or summary["minutes"] != 60 or summary["count"] != 2 or             summary["estimated_kcal"] <= 0 or s.day_calories(date) != calories_before:
        _fail("summary or isolated food target is incorrect")
        return
    if s.week_activity_summary(date)["count"] != 2 or             s.week_activity_summary(date)["steps"] != 7100:
        _fail("week aggregation lost entries or steps")
        return
    var record: Dictionary = s.day_activities(date)[0]
    if not s.update_activity(record, {"type": "run", "minutes": 15.0}):
        _fail("activity editing failed")
        return
    if record["type"] != "run" or float(record["minutes"]) != 15.0:
        _fail("activity edit not applied")
        return
    var previous = record.duplicate(true)
    if s.update_activity(record, {"minutes": -10.0}) or record != previous:
        _fail("invalid edit was accepted or not rolled back")
        return
    if s.add_activity(date, "none", 5) or s.add_activity(date, "walk", 0):
        _fail("unsupported activity or invalid duration accepted")
        return
    if s.set_day_steps(date, -1) or s.set_day_steps(date, 100001):
        _fail("out-of-range steps accepted")
        return
    var persisted = Store.new()
    if persisted.day_steps(date) != 7100 or persisted.day_activities(date).size() != 2:
        _fail("saved activities do not survive restart")
        return
    if persisted.day_calories(date) != calories_before:
        _fail("nutrition entries modified by sports feature")
        return
    var legacy = persisted.data.duplicate(true)
    legacy.erase("steps")
    if not persisted.import_json(JSON.stringify(legacy)) or persisted.day_steps(date) != 0 or             persisted.day_activities(date).size() != 2:
        _fail("older diary backup fails migration")
        return
    var corrupted = persisted.data.duplicate(true)
    corrupted["steps"] = {"2026-11-23": -17}
    if persisted.import_json(JSON.stringify(corrupted)):
        _fail("malformed step backup accepted")
        return
    var failed = FailingStore.new()
    failed.data = failed.default_data()
    if failed.set_day_steps(date, 9000) or failed.day_steps(date) != 0:
        _fail("failed disk save retained steps")
        return
    if failed.add_activity(date, "walk", 30) or not failed.day_activities(date).is_empty():
        _fail("failed disk save retained new training")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = date
    app.tab = "activity"
    app._render()
    await process_frame
    var step_box = app.find_child("ActivitySteps", true, false) as SpinBox
    var step_button = app.find_child("ActivitySaveSteps", true, false) as Button
    var kind_box = app.find_child("ActivityKind", true, false) as OptionButton
    var duration_box = app.find_child("ActivityMinutes", true, false) as SpinBox
    var save_button = app.find_child("ActivitySaveWorkout", true, false) as Button
    if step_box == null or step_button == null or kind_box == null or             duration_box == null or save_button == null:
        _fail("activity screen is missing data entry controls")
        return
    step_box.value = 4200
    step_button.pressed.emit()
    await process_frame
    if app.store.day_steps(date) != 4200:
        _fail("activity steps button did not save")
        return
    # Saving steps rebuilds the page. Obtain fresh controls: previous buttons
    # belong to the queued-for-deletion view and must not receive events.
    kind_box = app.find_child("ActivityKind", true, false) as OptionButton
    duration_box = app.find_child("ActivityMinutes", true, false) as SpinBox
    save_button = app.find_child("ActivitySaveWorkout", true, false) as Button
    if kind_box == null or duration_box == null or save_button == null:
        _fail("workout controls missing after saving steps")
        return
    kind_box.select(1)
    duration_box.value = 25
    save_button.pressed.emit()
    await process_frame
    if app.store.day_activities(date).size() != 1 or             str(app.store.day_activities(date)[0]["type"]) != "run":
        _fail("activity save button did not add selected workout")
        return
    app.tab = "day"
    app._render()
    await process_frame
    if app.find_child("DayActivitySummary", true, false) == null or             app.store.day_calories(date) != 0.0:
        _fail("day integration missing or calories were inflated")
        return
    app.queue_free()
    print("PASS ACTIVITY 0.7.43: steps, editing, MET estimate, weekly totals, food independence, legacy import, rollback and UI")
    quit(0)
