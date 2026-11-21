extends SceneTree

const Stats = preload("res://src/stats_math.gd")
const Store = preload("res://src/store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED STATS DASHBOARD 0.7.28: " + reason)
    quit(1)

func _fixture(day: String, kcal: float, protein: float = 30.0) -> Dictionary:
    return {"id": day, "date": day, "food": "sample",
        "meal": "Завтрак", "grams": 100.0,
        "nutrition": {"name": "Тест", "kcal": kcal,
            "p": protein, "f": 15.0, "c": 70.0}}

func _run() -> void:
    var store = Store.new()
    store.data = store.default_data()
    if Stats.dates_for(store, "2024-02-16", "month").size() != 29 or \
            Stats.dates_for(store, "2025-02-16", "month").size() != 28 or \
            Stats.dates_for(store, "2026-11-21", "month").size() != 30:
        _fail("calendar month and leap-year boundaries incorrect")
        return
    var days = Stats.dates_for(store, "2026-11-21", "week")
    if days.size() != 7 or str(days[0]) != "2026-11-16" or \
            str(days[6]) != "2026-11-22":
        _fail("week must run from Monday to Sunday")
        return
    var empty = Stats.summarize(store, "2026-11-21", "week")
    if int(empty["recorded"]) != 0 or float(empty["avg_kcal"]) != 0.0 or \
            int(empty["walking"]) != 0:
        _fail("empty week invented nutrition or activity")
        return
    store.data["entries"] = [
        _fixture("2026-11-16", 1000.0, 50.0),
        _fixture("2026-11-19", 500.0, 20.0),
        _fixture("2026-11-23", 800.0, 40.0)
    ]
    store.data["activities"] = [
        {"date":"2026-11-16","type":"walk","minutes":40},
        {"date":"2026-11-19","type":"strength","minutes":25},
        {"date":"2026-11-19","type":"other","minutes":15},
        {"date":"2026-11-23","type":"walk","minutes":120}
    ]
    store.data["weights"] = [
        {"date":"2026-11-16","value":88.0},
        {"date":"2026-11-19","value":87.2},
        {"date":"2026-11-23","value":86.9}
    ]
    var week = Stats.summarize(store, "2026-11-21", "week")
    if int(week["recorded"]) != 2 or week["columns"].size() != 7 or \
            absf(float(week["avg_kcal"]) - 750.0) > 0.01 or \
            absf(float(week["avg_p"]) - 35.0) > 0.01 or \
            absf(float(week["avg_f"]) - 15.0) > 0.01 or \
            int(week["walking"]) != 40 or int(week["exercise"]) != 40 or \
            int(week["workouts"]) != 2 or week["weights"].size() != 2:
        _fail("weekly averages, macros, activities or weights incorrect")
        return
    if bool(week["columns"][1]["recorded"]) or float(week["columns"][1]["kcal"]) != 0.0:
        _fail("empty days must be marked missing, not filled with records")
        return
    var month = Stats.summarize(store, "2026-11-21", "month")
    if int(month["recorded"]) != 3 or month["columns"].size() != 6 or \
            absf(float(month["avg_kcal"]) - (2300.0 / 3.0)) > 0.01 or \
            int(month["walking"]) != 160 or month["weights"].size() != 3:
        _fail("monthly aggregation not scoped to full calendar month")
        return
    if bool(month["columns"][0]["recorded"]) or \
            not bool(month["columns"][3]["recorded"]) or \
            absf(float(month["columns"][3]["kcal"]) - 750.0) > 0.01:
        _fail("calendar-week monthly averages / missing weeks incorrect")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = store.data.duplicate(true)
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-21"
    app.stats_anchor = "2026-11-21"
    app.tab = "stats"
    for theme in ["forest", "botanical", "dark"]:
        app.store.data["settings"]["theme"] = theme
        app._refresh_appearance()
        app._render()
        await process_frame
        var kcal = app.find_child("StatsCalorieChart", true, false)
        var period = app.find_child("StatsPeriodDates", true, false) as Label
        if kcal == null or period == null or \
                kcal.columns.size() != 7 or not period.text.contains("16.11"):
            _fail("weekly nutrition chart or date range missing in " + theme)
            return
        if app.find_child("StatsActivityChart", true, false) != null or \
                app.find_child("StatsWeightGraph", true, false) != null:
            _fail("other charts should not lengthen the page in " + theme)
            return
        (app.find_child("StatsSection_activity", true, false) as Button).pressed.emit()
        await process_frame
        var activity = app.find_child("StatsActivityChart", true, false)
        if activity == null or activity.columns.size() != 7 or \
                app.find_child("StatsCalorieChart", true, false) != null:
            _fail("activity selector not working in " + theme)
            return
        (app.find_child("StatsSection_weight", true, false) as Button).pressed.emit()
        await process_frame
        var weight = app.find_child("StatsWeightGraph", true, false)
        if weight == null or weight.samples.size() != 2 or \
                app.find_child("StatsActivityChart", true, false) != null:
            _fail("weight selector not working in " + theme)
            return
        (app.find_child("StatsSection_nutrition", true, false) as Button).pressed.emit()
        await process_frame
    var change_mode = app.find_child("StatsPeriod_month", true, false) as Button
    if change_mode == null:
        _fail("month control missing")
        return
    change_mode.pressed.emit()
    await process_frame
    if app.stats_period != "month" or \
            app.find_child("StatsCalorieChart", true, false).columns.size() != 6:
        _fail("switching to monthly report did not update nutrition chart")
        return
    (app.find_child("StatsSection_weight", true, false) as Button).pressed.emit()
    await process_frame
    if app.find_child("StatsWeightGraph", true, false).samples.size() != 3:
        _fail("monthly weight chart should cover the full month")
        return
    (app.find_child("StatsSection_nutrition", true, false) as Button).pressed.emit()
    await process_frame
    var previous = app.find_child("StatsPreviousPeriod", true, false) as Button
    previous.pressed.emit()
    await process_frame
    if app.stats_anchor != "2026-10-21" or app.date != "2026-11-21":
        _fail("changing stats month must preserve the selected diary date")
        return
    (app.find_child("StatsNextPeriod", true, false) as Button).pressed.emit()
    await process_frame
    if app.stats_anchor != "2026-11-21":
        _fail("next month did not restore the prior report month")
        return
    (app.find_child("StatsPeriod_week", true, false) as Button).pressed.emit()
    await process_frame
    (app.find_child("StatsPreviousPeriod", true, false) as Button).pressed.emit()
    await process_frame
    if app.stats_anchor != "2026-11-14" or app.date != "2026-11-21":
        _fail("moving back a week must not move the daily journal date")
        return
    print("PASS STATS DASHBOARD: correct periods, sparse-day means, compact graph sections, themes and navigation")
    app.queue_free()
    quit(0)
