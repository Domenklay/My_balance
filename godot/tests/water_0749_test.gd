extends SceneTree

const Store = preload("res://src/store.gd")
const Water = preload("res://src/water_tracker.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED WATER 0.7.49: " + message)
    quit(1)

func _run() -> void:
    var day = "2026-11-24"
    var yesterday = "2026-11-23"
    var s = Store.new()
    s.data = s.default_data()
    s.data["notes"][day] = "Старые данные дневника"
    var calorie_total: float = s.day_calories(day)
    if s.water_goal_ml() != 2000 or not Water.valid_goal(2000) or \
            Water.valid_goal(0) or Water.valid_goal(9000):
        _fail("default or goal validation")
        return
    if not s.set_water_goal_ml(2200) or s.water_goal_ml() != 2200:
        _fail("custom hydration goal not saved")
        return
    if not s.add_water(day, 250) or not s.add_water(day, 500) or \
            not s.add_water(yesterday, 150):
        _fail("separate dated portions failed")
        return
    if s.day_water_ml(day) != 750 or s.day_water_ml(yesterday) != 150 or \
            s.day_water_entries(day).size() != 2 or \
            int(s.day_water_summary(day)["remaining"]) != 1450:
        _fail("per-day sums or remaining wrong")
        return
    var week: Dictionary = s.week_water_summary(day)
    if int(week["ml"]) != 900 or int(week["days_logged"]) != 2 or \
            int(week["records"]) != 3:
        _fail("weekly sums wrong")
        return
    if s.add_water(day, 0) or s.add_water(day, 2001) or \
            s.add_water("2026-02-30", 250) or s.set_water_goal_ml(9000) or \
            s.water_goal_ml() != 2200:
        _fail("invalid amount, date or goal accepted")
        return
    if s.day_calories(day) != calorie_total or \
            str(s.data["notes"][day]) != "Старые данные дневника":
        _fail("hydration changed previous journal values")
        return
    var id: String = str(s.day_water_entries(day)[0]["id"])
    if not s.delete_water(id) or s.delete_water(id) or \
            s.day_water_ml(day) != 500 or s.day_water_entries(day).size() != 1:
        _fail("delete specific serving or duplicate delete")
        return
    var loaded = Store.new()
    if loaded.water_goal_ml() != 2200 or loaded.day_water_ml(day) != 500:
        _fail("water data lost after restart")
        return
    var legacy = loaded.data.duplicate(true)
    legacy.erase("water_entries")
    legacy["settings"].erase("water_goal_ml")
    if not loaded.import_json(JSON.stringify(legacy), false) or \
            loaded.water_goal_ml() != 2000 or loaded.day_water_ml(day) != 0 or \
            loaded.data["notes"][day] != "Старые данные дневника":
        _fail("legacy backup migration lost data")
        return
    var invalid = loaded.data.duplicate(true)
    invalid["water_entries"] = [{"id":"bad","date":day,"ml":3000}]
    if loaded.import_json(JSON.stringify(invalid), false):
        _fail("bad hydration backup was accepted")
        return
    invalid["water_entries"] = [{"id":"dup","date":day,"ml":250},
        {"id":"dup","date":day,"ml":250}]
    if loaded.import_json(JSON.stringify(invalid), false):
        _fail("duplicate hydration ids accepted")
        return
    invalid["water_entries"] = []
    invalid["settings"]["water_goal_ml"] = -1
    if loaded.import_json(JSON.stringify(invalid), false):
        _fail("invalid goal accepted in backup")
        return
    var broken = FailingStore.new()
    broken.data = broken.default_data()
    if broken.add_water(day, 250) or \
            not broken.data["water_entries"].is_empty() or \
            broken.set_water_goal_ml(2700) or broken.water_goal_ml() != 2000:
        _fail("failed write did not roll back")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = day
    app.tab = "day"
    app._render()
    await process_frame
    var daily_readout = app.find_child("WaterDailyAmount", true, false) as Label
    if app.APP_VERSION != "0.7.49" or app.tab_buttons.size() != 5 or \
            app.find_child("WaterDailyProgress", true, false) == null or \
            daily_readout == null or daily_readout.custom_minimum_size.x < 140 or \
            not daily_readout.text.contains("2000 мл"):
        _fail("visible water total/goal missing on day or navigation changed")
        return
    var add = app.find_child("WaterQuickAdd_250", true, false) as Button
    if add == null:
        _fail("250 ml shortcut missing")
        return
    add.pressed.emit()
    await process_frame
    if app.store.day_water_ml(day) != 250 or \
            app.find_child("WaterDailyAmount", true, false) == null:
        _fail("water shortcut does not update day")
        return
    var show = app.find_child("WaterDetailsToggle", true, false) as Button
    show.pressed.emit()
    await process_frame
    var amount = app.find_child("WaterCustomAmount", true, false) as SpinBox
    var save = app.find_child("WaterCustomSave", true, false) as Button
    var goal = app.find_child("WaterDailyGoal", true, false) as SpinBox
    var goal_save = app.find_child("WaterSaveGoal", true, false) as Button
    if amount == null or save == null or goal == null or goal_save == null:
        _fail("custom portion or goal controls missing")
        return
    amount.value = 375
    save.pressed.emit()
    await process_frame
    if app.store.day_water_ml(day) != 625:
        _fail("custom water serving not saved")
        return
    goal = app.find_child("WaterDailyGoal", true, false) as SpinBox
    goal_save = app.find_child("WaterSaveGoal", true, false) as Button
    goal.value = 2350
    goal_save.pressed.emit()
    await process_frame
    if app.store.water_goal_ml() != 2350:
        _fail("goal editor not saved")
        return
    var items: Array = app.store.day_water_entries(day)
    var remove = app.find_child("WaterDelete_" + str(items[0]["id"]), true, false) as Button
    if remove == null:
        _fail("delete serving control missing")
        return
    remove.pressed.emit()
    await process_frame
    if app.store.day_water_ml(day) != 375:
        _fail("delete a single serving failed")
        return
    app.store.data["settings"]["theme"] = "dark"
    app._refresh_appearance()
    app._render()
    await process_frame
    if app.find_child("WaterQuickAdd_500", true, false) == null:
        _fail("dark theme lost hydration controls")
        return
    app.date = yesterday
    app._render()
    await process_frame
    if app.store.day_water_ml(yesterday) != 0 or \
            app.store.day_water_ml(day) != 375:
        _fail("water recordings leaked between dates")
        return
    app.queue_free()
    print("PASS WATER 0.7.49: quick add, custom ml, goal, date isolation, history, legacy JSON, rollback, themes")
    quit(0)
