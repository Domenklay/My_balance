extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("PROGRESS DESIGN 0.7.56: " + reason)
    quit(1)
func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-24"
    app.store.data["weights"] = [{"date":"2026-11-01","value":88.0},{"date":"2026-11-24","value":86.5}]
    app.store.data["body_measurements"] = [{"date":"2026-11-01","values":{"waist":95.0}},{"date":"2026-11-24","values":{"waist":92.0}}]
    var snapshot = JSON.stringify(app.store.data)
    app.tab = "progress"
    app.progress_section = "weight"
    app._render()
    await process_frame
    var plot = app.find_child("WeightProgressGraph", true, false)
    var readout = app.find_child("WeightProgressGraphReadout", true, false) as Label
    if plot == null or readout == null or not plot.select_point(0) or not readout.text.contains("88"):
        _fail("graph selection failed")
        return
    if plot.select_point(-1) or plot.select_point(100):
        _fail("invalid graph index")
        return
    app.progress_section = "body"
    app._render()
    await process_frame
    var map = app.find_child("BodyMeasurementMap", true, false)
    var pin = app.find_child("BodyMap_waist", true, false) as Button
    if map == null or pin == null or not pin.text.contains("92"):
        _fail("latest body values missing")
        return
    var old_color: Color = map.figure_color
    app.store.data["settings"]["theme"] = "dark"
    app._refresh_appearance()
    app._render()
    await process_frame
    map = app.find_child("BodyMeasurementMap", true, false)
    if map.figure_color == old_color:
        _fail("body illustration did not change theme")
        return
    app.store.data["settings"]["theme"] = JSON.parse_string(snapshot)["settings"]["theme"]
    if JSON.stringify(app.store.data) != snapshot:
        _fail("viewing progress changed records")
        return
    app.queue_free()
    print("PASS PROGRESS DESIGN 0.7.56: selected graph point, actual body values, themed vector and read-only data")
    quit(0)
