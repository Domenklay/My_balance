extends SceneTree

const BodyMap = preload("res://src/body_map.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED BODY MAP 0.7.48: " + message)
    quit(1)

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-23"
    app.store.data["body_measurements"] = [
        {"date": "2026-10-25", "values": {"waist": 93.0, "hips": 111.0, "chest": 102.0}},
        {"date": "2026-11-23", "values": {"waist": 89.0, "hips": 107.0, "chest": 99.0}}
    ]
    var before = JSON.stringify(app.store.data)
    app.tab = "progress"
    app.progress_section = "body"
    app._render()
    await process_frame
    var map = app.find_child("BodyMeasurementMap", true, false) as BodyMap
    var first_delta = app.find_child("GraphPeriodDelta", true, false) as Label
    if first_delta == null or first_delta.autowrap_mode != TextServer.AUTOWRAP_OFF or \
            first_delta.custom_minimum_size.x < 90 or first_delta.size.y > 42:
        _fail("small-screen progress delta wraps vertically")
        return
    if map == null or map.metric_buttons.size() != 8 or map.selected_metric != "waist":
        _fail("eight interactive areas or initial metric missing")
        return
    if map.custom_minimum_size.y > 345 or map.size.x < 240:
        _fail("body illustration does not fit mobile card")
        return
    for key in ["neck","chest","abdomen","waist","hips","upper_arm","thigh","calf"]:
        var pin = map.find_child("BodyMap_" + key, true, false) as Button
        if pin == null or pin.custom_minimum_size.y < 38 or not pin.visible:
            _fail("unreachable labelled body area: " + key)
            return
    var draft = app.find_child("BodyField_calf", true, false) as LineEdit
    if draft == null:
        _fail("body entry form missing")
        return
    draft.text = "37,5"
    (map.find_child("BodyMap_hips", true, false) as Button).pressed.emit()
    await process_frame
    map = app.find_child("BodyMeasurementMap", true, false) as BodyMap
    var picker = app.find_child("BodyMeasurementMetricPicker", true, false) as OptionButton
    var chart = app.find_child("BodyMeasurementsGraph", true, false)
    draft = app.find_child("BodyField_calf", true, false) as LineEdit
    if app.selected_body_metric != "hips" or map.selected_metric != "hips" or \
            picker.selected != 3 or chart.samples.size() != 2 or draft.text != "37,5":
        _fail("tap did not switch graph and preserve unsaved calf value")
        return
    (app.find_child("BodyPeriod_month", true, false) as Button).pressed.emit()
    await process_frame
    draft = app.find_child("BodyField_calf", true, false) as LineEdit
    if draft == null or draft.text != "37,5":
        _fail("changing the period discarded the draft")
        return
    var picker2 = app.find_child("BodyMeasurementMetricPicker", true, false) as OptionButton
    picker2.select(7)
    picker2.item_selected.emit(7)
    await process_frame
    map = app.find_child("BodyMeasurementMap", true, false) as BodyMap
    draft = app.find_child("BodyField_calf", true, false) as LineEdit
    if map.selected_metric != "neck" or draft.text != "37,5":
        _fail("dropdown metric selection not synchronized with silhouette")
        return
    chart = app.find_child("BodyMeasurementsGraph", true, false)
    if chart == null or not chart.samples.is_empty():
        _fail("unrecorded metric should show an empty graph")
        return
    if JSON.stringify(app.store.data) != before:
        _fail("body map selection modified saved health data")
        return
    app.store.data["settings"]["theme"] = "dark"
    app._refresh_appearance()
    app._render()
    await process_frame
    map = app.find_child("BodyMeasurementMap", true, false) as BodyMap
    if map == null or not map.dark_mode or map.metric_buttons.size() != 8:
        _fail("body map not styled for dark theme")
        return
    app.queue_free()
    print("PASS BODY MAP 0.7.48: interactive targets, synchronized graph, preserved drafts, empty metric and dark mode")
    quit(0)
