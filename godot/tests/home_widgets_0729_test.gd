extends SceneTree

const StoreScript = preload("res://src/store.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED HOME WIDGETS 0.7.29: " + reason)
    quit(1)

func _run() -> void:
    var store = StoreScript.new()
    store.data = store.default_data()
    if store.home_widgets() != {"week":false, "weight":false}:
        _fail("extra widgets must default hidden for a compact diary")
        return
    if store.set_home_widget("unknown", true):
        _fail("arbitrary widget keys must not be persisted")
        return
    var backup = store.data.duplicate(true)
    backup["settings"].erase("home_widgets")
    if not store.import_json(JSON.stringify(backup)):
        _fail("0.7.28 backup without widgets was rejected")
        return
    if store.home_widgets() != {"week":false, "weight":false}:
        _fail("old backup should receive hidden widgets")
        return
    var malformed = store.data.duplicate(true)
    malformed["settings"]["home_widgets"] = {"week":"yes","weight":false}
    if store.import_json(JSON.stringify(malformed), false):
        _fail("invalid widget flags in JSON accepted")
        return
    var failing = FailingStore.new()
    failing.data = failing.default_data()
    if failing.set_home_widget("week", true) or bool(failing.home_widgets()["week"]):
        _fail("storage write failure did not roll back widget choice")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.store.data["settings"]["start"] = 88.0
    app.store.data["settings"]["goal"] = 68.0
    app.date = "2026-11-20"
    app.tab = "day"
    app._render()
    await process_frame
    if app.find_child("HomeWeekWidget", true, false) != null or \
            app.find_child("HomeWeightWidget", true, false) != null:
        _fail("initial diary must not be stretched by optional widgets")
        return
    var toggle = app.find_child("HomeWidgetSettingsToggle", true, false) as Button
    if toggle == null:
        _fail("main screen does not expose its widget preferences")
        return
    toggle.pressed.emit()
    await process_frame
    var week = app.find_child("HomeWidgetChoice_week", true, false) as Button
    var weight = app.find_child("HomeWidgetChoice_weight", true, false) as Button
    if week == null or weight == null or not week.text.contains("График"):
        _fail("both optional choices must be accessible from the diary")
        return

    week.pressed.emit()
    await process_frame
    if not bool(app.store.home_widgets()["week"]) or \
            app.find_child("HomeWeekWidget", true, false) == null or \
            app.find_child("HomeWeightWidget", true, false) != null:
        _fail("week cannot be independently enabled")
        return
    var first_chart = app.find_child("HomeWeekChart", true, false)
    if first_chart == null or first_chart.columns.size() != 7:
        _fail("enabled week chart is not a seven-day graph")
        return
    weight = app.find_child("HomeWidgetChoice_weight", true, false) as Button
    weight.pressed.emit()
    await process_frame
    if not bool(app.store.home_widgets()["weight"]) or \
            app.find_child("HomeWeightWidget", true, false) == null:
        _fail("weight widget cannot be enabled")
        return

    var persisted = StoreScript.new()
    if not bool(persisted.home_widgets()["week"]) or not bool(persisted.home_widgets()["weight"]):
        _fail("widget flags not saved across app restart")
        return

    app.store.data["entries"] = [
        {"id":"a", "date":"2026-11-19", "food":"one", "grams":100.0,
            "meal":"Завтрак", "nutrition":{"kcal":1200.0,"p":60.0,"f":20.0,"c":130.0}},
        {"id":"b", "date":"2026-11-20", "food":"two", "grams":100.0,
            "meal":"Обед", "nutrition":{"kcal":1800.0,"p":90.0,"f":30.0,"c":150.0}}
    ]
    app.store.data["weights"] = [{"date":"2026-11-19","value":78.0}]
    for theme in ["forest", "botanical", "dark"]:
        app.store.data["settings"]["theme"] = theme
        app._refresh_appearance()
        app._render()
        await process_frame
        var summary = app.find_child("HomeWeekSummary", true, false) as Label
        var weight_summary = app.find_child("HomeWeightSummary", true, false) as Label
        var progress = app.find_child("HomeWeightGoalProgress", true, false) as ProgressBar
        if summary == null or weight_summary == null or progress == null:
            _fail("a theme dropped an enabled widget: " + theme)
            return
        if not summary.text.contains("1500 ккал") or \
                not weight_summary.text.contains("78.0 кг") or \
                absf(progress.value - 50.0) > 0.1:
            _fail("widget shows incorrect calorie/weight snapshot: " + theme)
            return
    (app.find_child("HomeWeekOpenStats", true, false) as Button).pressed.emit()
    await process_frame
    if app.tab != "stats" or app.stats_period != "week" or \
            app.stats_anchor != "2026-11-20":
        _fail("weekly shortcut does not open selected date in stats")
        return
    app._navigate_to_tab("day")
    await process_frame
    (app.find_child("HomeWeightOpenHistory", true, false) as Button).pressed.emit()
    await process_frame
    if app.tab != "weight":
        _fail("weight shortcut does not open the weight page")
        return
    app._navigate_to_tab("day")
    await process_frame
    (app.find_child("HomeWidgetChoice_week", true, false) as Button).pressed.emit()
    await process_frame
    if app.find_child("HomeWeekWidget", true, false) != null or \
            app.find_child("HomeWeightWidget", true, false) == null:
        _fail("hiding week must keep enabled weight widget")
        return
    (app.find_child("HomeWidgetChoice_weight", true, false) as Button).pressed.emit()
    await process_frame
    if app.find_child("HomeWeightWidget", true, false) != null:
        _fail("weight widget did not disappear when disabled")
        return
    if store.day_entries("2026-11-19").size() != 0 or app.store.day_entries("2026-11-19").size() != 1:
        _fail("changing widgets corrupted food diary records")
        return
    print("PASS HOME WIDGETS: defaults, legacy import, rollback, independent toggles, three themes, quick links and saved choices")
    app.queue_free()
    quit(0)
