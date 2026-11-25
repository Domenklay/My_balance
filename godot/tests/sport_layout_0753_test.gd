extends SceneTree

const Appearance = preload("res://src/appearance.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("SPORT LAYOUT 0.7.53: " + reason)
    quit(1)

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.tab = "activity"
    for id in Appearance.ORDER:
        app.store.data["settings"]["theme"] = id
        app._refresh_appearance()
        app._render()
        await process_frame
        await process_frame
        var automatic = app.find_child("AutoStepControls", true, false)
        var manual = app.find_child("SportManualCard", true, false)
        var toggle = app.find_child("AutoStepToggle", true, false)
        var auto = app.find_child("AutoStepUse", true, false)
        if automatic == null or manual == null or toggle == null or auto == null or toggle.get_parent() != automatic or auto.get_parent() != automatic:
            _fail("step actions must be full-width in a separate card")
            return
        var metrics = app.find_child("ActivityOverview", true, false)
        var row = app.find_child("SportStepsRow", true, false)
        var field = app.find_child("ActivitySteps", true, false) as SpinBox
        var save = app.find_child("ActivitySaveSteps", true, false) as Button
        var caption = app.find_child("SportStepsCaption", true, false) as Label
        if metrics == null or metrics.get_child_count() != 3 or row == null or field == null or save == null or caption == null:
            _fail("missing controls: " + id)
            return
        if caption.get_parent() != manual or save.get_parent() != manual or row.get_parent() != manual or row.get_child_count() != 3:
            _fail("step caption or save button still squeezes input")
            return
        var colors: Array = []
        for panel in metrics.get_children():
            var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
            if style == null or colors.has(style.bg_color):
                _fail("metric cards not visually distinct")
                return
            colors.append(style.bg_color)
        field.value = 1234
        var plus = app.find_child("SportStepsPlus", true, false) as Button
        plus.pressed.emit()
        if field.value != 1734:
            _fail("quick step increment failed")
            return
    app.queue_free()
    print("PASS SPORT 0.7.53: separate step controls and distinct metric cards in five themes")
    quit(0)
