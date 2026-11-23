extends SceneTree

const Maths = preload("res://src/progress_graph_math.gd")
const Graph = preload("res://src/weight_graph.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED GRAPH 0.7.47: " + message)
    quit(1)

func _run() -> void:
    if Maths.window_start("2024-03-01", "month") != "2024-02-01" or \
            Maths.window_start("2024-03-01", "quarter") != "2023-12-03":
        _fail("date boundaries or leap day calculation incorrect")
        return
    var original: Array = [
        {"date":"2026-11-23","value":84.0},
        {"date":"2026-08-26","value":87.0},
        {"date":"2026-11-22","value":84.7},
        {"date":"2026-11-24","value":70.0},
        {"date":"2026-10-24","value":86.0},
        {"date":"2026-11-01","value":85.5},
        {"date":"2025-12-01","value":95.0}
    ]
    var snapshot: String = JSON.stringify(original)
    var month: Array = Maths.filter_records(original, "2026-11-23", "month")
    var quarter: Array = Maths.filter_records(original, "2026-11-23", "quarter")
    var all_time: Array = Maths.filter_records(original, "2026-11-23", "all")
    if month.size() != 3 or quarter.size() != 5 or all_time.size() != 6 or \
            month[0]["date"] != "2026-11-01" or \
            quarter[0]["date"] != "2026-08-26" or \
            all_time[0]["date"] != "2025-12-01":
        _fail("period filtering excludes valid data or includes future records")
        return
    if absf(float(Maths.summarize(month)["change"]) + 1.5) > 0.01 or \
            Maths.summarize(month)["latest_date"] != "2026-11-23" or \
            Maths.format_delta(2.2, "см") != "+2.2 см" or \
            not Maths.summarize([]).is_empty() or JSON.stringify(original) != snapshot:
        _fail("delta, empty state or read-only filtering incorrect")
        return
    var dense: Array = []
    for i in range(400):
        dense.append({"date": "2026-01-01", "value": 85.0 - float(i) * 0.01})
    dense[0]["date"] = "2020-01-01"
    dense[399]["date"] = "2026-11-23"
    var chart = Graph.new()
    chart.set_overview_points(dense, 65.0)
    if chart.samples.size() != 120 or \
            chart.samples[0]["date"] != "2020-01-01" or \
            chart.samples[119]["date"] != "2026-11-23":
        _fail("all-time history sampling dropped first/last measurement")
        return
    chart.set_points(dense, 65.0)
    if chart.samples.size() != 30:
        _fail("legacy 30-point graph behavior was broken")
        return
    chart.set_overview_points([{"date":"2026-11-23","value":18.0}], -1.0)
    if chart.samples.size() != 1:
        _fail("small circumference values are not accepted")
        return
    chart.free()

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-23"
    app.store.data["weights"] = original.duplicate(true)
    app.store.data["body_measurements"] = [
        {"date":"2026-10-24", "values":{"waist":94.0, "hips":110.0}},
        {"date":"2026-11-23", "values":{"waist":90.0, "hips":108.0}}
    ]
    var pristine: String = JSON.stringify(app.store.data)
    app.tab = "progress"
    app.progress_section = "weight"
    app._render()
    await process_frame
    if app.find_child("WeightPeriod_month", true, false) == null or \
            app.find_child("WeightPeriod_quarter", true, false) == null or \
            app.find_child("WeightPeriod_all", true, false) == null:
        _fail("weight range selector missing")
        return
    var overview = app.find_child("WeightProgressGraph", true, false)
    if overview == null or overview.samples.size() != 5:
        _fail("weight chart did not apply 90-day default range")
        return
    var month_button = app.find_child("WeightPeriod_month", true, false) as Button
    month_button.pressed.emit()
    await process_frame
    overview = app.find_child("WeightProgressGraph", true, false)
    var delta = app.find_child("GraphPeriodDelta", true, false) as Label
    if overview == null or overview.samples.size() != 3 or delta == null or \
            not delta.text.contains("-1.5"):
        _fail("30-day weight chart and comparison did not update")
        return
    (app.find_child("WeightPeriod_all", true, false) as Button).pressed.emit()
    await process_frame
    overview = app.find_child("WeightProgressGraph", true, false)
    if overview == null or overview.samples.size() != 6:
        _fail("all-time weight chart was truncated")
        return
    app.progress_section = "body"
    app._render()
    await process_frame
    if app.find_child("BodyPeriod_month", true, false) == null or \
            app.find_child("BodyMeasurementsGraph", true, false) == null:
        _fail("body measurement period selector or chart missing")
        return
    var waist_chart = app.find_child("BodyMeasurementsGraph", true, false)
    if waist_chart.samples.size() != 2:
        _fail("body measurements did not show the 90-day window")
        return
    (app.find_child("BodyPeriod_month", true, false) as Button).pressed.emit()
    await process_frame
    waist_chart = app.find_child("BodyMeasurementsGraph", true, false)
    delta = app.find_child("GraphPeriodDelta", true, false) as Label
    if waist_chart.samples.size() != 2 or not delta.text.contains("-4"):
        _fail("body chart or progress delta incorrect after changing range")
        return
    if JSON.stringify(app.store.data) != pristine or app.tab_buttons.size() != 5:
        _fail("chart viewing changed saved diary or navigation")
        return
    app.queue_free()
    print("PASS GRAPH 0.7.47: date-aware periods, all-time plots, weight/body UI, history and read-only data")
    quit(0)
