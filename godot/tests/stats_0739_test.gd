extends SceneTree

const Stats = preload("res://src/stats_math.gd")
const Store = preload("res://src/store.gd")
const WeightGraph = preload("res://src/weight_graph.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED STATS 0.7.39: " + message)
    quit(1)

func _entry(day: String, kcal: float) -> Dictionary:
    return {"id":"e_" + day, "date":day, "food":"snapshot",
        "meal":"Обед", "grams":100.0,
        "nutrition":{"name":"Сохранённое блюдо","kcal":kcal,
            "p":20.0,"f":10.0,"c":30.0}}

func _run() -> void:
    var store = Store.new()
    store.data = store.default_data()
    var jan = Stats.dates_for(store, "2026-01-20", "quarter")
    if jan.size() != 92 or str(jan[0]) != "2025-11-01" or \
            str(jan[jan.size()-1]) != "2026-01-31":
        _fail("three-month period did not cross the calendar year")
        return
    var leap = Stats.dates_for(store, "2024-02-16", "quarter")
    if leap.size() != 91 or str(leap[0]) != "2023-12-01" or \
            str(leap[leap.size()-1]) != "2024-02-29":
        _fail("three-month period omitted leap day")
        return
    if Stats.previous_anchor(store, "2026-01-20", "quarter") != "2025-10-15" or \
            Stats.previous_anchor(store, "2026-01-20", "month") != "2025-12-15" or \
            Stats.previous_anchor(store, "2026-11-21", "week") != "2026-11-14":
        _fail("matching previous period has wrong calendar boundaries")
        return
    store.data["entries"] = [
        _entry("2026-09-01", 1200.0), _entry("2026-09-15", 1600.0),
        _entry("2026-10-03", 2000.0), _entry("2026-11-21", 1000.0),
        _entry("2026-06-12", 800.0), _entry("2026-07-05", 1100.0),
        _entry("2026-08-10", 1400.0)
    ]
    store.data["activities"] = [
        {"date":"2026-09-01","type":"walk","minutes":60},
        {"date":"2026-10-03","type":"strength","minutes":30},
        {"date":"2026-06-12","type":"walk","minutes":15},
        {"date":"2026-07-05","type":"strength","minutes":10}
    ]
    var dates: Array = Stats.dates_for(store, "2026-11-21", "quarter")
    for i in range(dates.size()):
        store.data["weights"].append({
            "date":str(dates[i]),
            "value":88.0 - float(i) * 0.03
        })
    var snapshot: String = JSON.stringify(store.data)
    var report = Stats.summarize(store, "2026-11-21", "quarter")
    var previous = Stats.summarize(store,
        Stats.previous_anchor(store, "2026-11-21", "quarter"), "quarter")
    if report["dates"].size() != 91 or report["columns"].size() != 3 or \
            int(report["recorded"]) != 4 or \
            absf(float(report["avg_kcal"]) - 1450.0) > 0.001 or \
            int(report["walking"]) != 60 or int(report["exercise"]) != 30 or \
            report["weights"].size() != 91:
        _fail("quarter aggregation totals incorrect: " + str(report["recorded"]))
        return
    if str(report["columns"][0]["label"]) != "09.26" or \
            absf(float(report["columns"][0]["kcal"]) - 1400.0) > 0.001 or \
            absf(float(report["columns"][1]["kcal"]) - 2000.0) > 0.001 or \
            absf(float(report["columns"][2]["kcal"]) - 1000.0) > 0.001:
        _fail("monthly bars must average only days actually recorded")
        return
    if int(previous["recorded"]) != 3 or \
            absf(float(previous["avg_kcal"]) - 1100.0) > 0.001 or \
            int(previous["walking"]) != 15:
        _fail("comparison omitted prior three complete months")
        return
    if not Stats.label_for(report["dates"], "quarter").contains("09.2026") or \
            not Stats.label_for(report["dates"], "quarter").contains("11.2026") or \
            JSON.stringify(store.data) != snapshot:
        _fail("stats changed storage or labelled period incorrectly")
        return
    var graph = WeightGraph.new()
    graph.set_points(report["weights"], 68.0, 120)
    if graph.samples.size() != 91 or \
            str(graph.samples[0]["date"]) != "2026-09-01":
        _fail("90+ day weight graph incorrectly trims earliest readings")
        return
    graph.set_points(report["weights"], 68.0)
    if graph.samples.size() != 30:
        _fail("regular charts should preserve their compact 30-point limit")
        return
    graph.free()
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = store.data.duplicate(true)
    app.store.data["settings"]["onboarding_complete"] = true
    app.tab = "stats"
    app.date = "2026-11-21"
    app.stats_period = "quarter"
    app.stats_anchor = "2026-11-21"
    app.stats_detail_tab = "nutrition"
    app._render()
    await process_frame
    var period_button = app.find_child("StatsPeriod_quarter", true, false) as Button
    var calorie_chart = app.find_child("StatsCalorieChart", true, false)
    var comparison = app.find_child("StatsPreviousComparison", true, false) as Label
    if period_button == null or calorie_chart == null or \
            calorie_chart.columns.size() != 3 or comparison == null or \
            not comparison.text.contains("+350") or \
            not comparison.text.contains("4 и 3"):
        _fail("quarter selector/chart/previous comparison missing")
        return
    (app.find_child("StatsSection_activity", true, false) as Button).pressed.emit()
    await process_frame
    var activity_compare = app.find_child("StatsActivityComparison", true, false) as Label
    if activity_compare == null or \
            not activity_compare.text.contains("+45") or \
            not activity_compare.text.contains("+20"):
        _fail("activity prior period comparison is incorrect")
        return
    (app.find_child("StatsSection_weight", true, false) as Button).pressed.emit()
    await process_frame
    var weight_chart = app.find_child("StatsWeightGraph", true, false)
    if weight_chart == null or weight_chart.samples.size() != 91:
        _fail("quarter weight chart lost daily readings")
        return
    (app.find_child("StatsPreviousPeriod", true, false) as Button).pressed.emit()
    await process_frame
    if app.stats_anchor != "2026-08-21" or app.date != "2026-11-21":
        _fail("quarter backward navigation did not shift exactly three months")
        return
    (app.find_child("StatsNextPeriod", true, false) as Button).pressed.emit()
    await process_frame
    if app.stats_anchor != "2026-11-21":
        _fail("quarter forward navigation did not restore November")
        return
    app.stats_anchor = "2026-01-20"
    app._render()
    await process_frame
    (app.find_child("StatsPreviousPeriod", true, false) as Button).pressed.emit()
    await process_frame
    if app.stats_anchor != "2025-10-20":
        _fail("quarter navigation across year boundary incorrect")
        return
    app.stats_anchor = "2026-11-21"
    app.stats_detail_tab = "nutrition"
    app.store.data["entries"] = []
    app._render()
    await process_frame
    comparison = app.find_child("StatsPreviousComparison", true, false) as Label
    if comparison == null or not comparison.text.contains("нужны записи") or \
            comparison.text.contains("+350"):
        _fail("empty periods invented a nutrition trend")
        return
    if JSON.stringify(store.data) != snapshot:
        _fail("displaying and switching reports modified saved diary")
        return
    app.queue_free()
    print("PASS STATS 0.7.39: leap-years, quarter navigation, 3 monthly averages, comparison, activity and 91 weigh-ins")
    quit(0)
