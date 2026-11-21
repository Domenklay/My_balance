extends SceneTree

const ProfileProgress = preload("res://src/profile_progress.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED PROFILE DASHBOARD: " + reason)
    quit(1)

func _find_button(node: Node, caption: String) -> Button:
    if node is Button and node.text == caption:
        return node
    for child in node.get_children():
        var found: Button = _find_button(child, caption)
        if found != null:
            return found
    return null

func _run() -> void:
    var loss = ProfileProgress.summarize({"start":88.0,"goal":68.0}, [
        {"date":"2026-11-20","value":78.0}, {"date":"2026-11-01","value":81.0}
    ])
    if absf(float(loss["progress"]) - 50.0) > 0.01 or \
            absf(float(loss["latest"]) - 78.0) > 0.01 or \
            absf(float(loss["remaining"]) - 10.0) > 0.01:
        _fail("progress should be half for 10 of 20 kilograms")
        return
    var gain = ProfileProgress.summarize({"start":55.0,"goal":65.0}, [
        {"date":"2026-11-20","value":60.0}])
    if absf(float(gain["progress"]) - 50.0) > 0.01:
        _fail("weight gain progress incorrect")
        return
    var reverse = ProfileProgress.summarize({"start":88.0,"goal":68.0}, [
        {"date":"2026-11-20","value":90.0}])
    if float(reverse["progress"]) != 0.0 or bool(reverse["reached"]):
        _fail("moving away must not produce a negative or complete progress")
        return
    var beyond = ProfileProgress.summarize({"start":88.0,"goal":68.0}, [
        {"date":"2026-11-20","value":65.0}])
    if float(beyond["progress"]) != 100.0 or not bool(beyond["reached"]) or \
            float(beyond["remaining"]) != 0.0:
        _fail("exceeding the target must cap at 100 percent")
        return
    var initial = ProfileProgress.summarize({"start":88.0,"goal":68.0}, [])
    if bool(initial["has_records"]) or float(initial["latest"]) != 88.0 or \
            float(initial["progress"]) != 0.0:
        _fail("empty weight history must not invent data")
        return
    var equal = ProfileProgress.summarize({"start":70.0,"goal":70.0}, [])
    if float(equal["progress"]) != 100.0:
        _fail("goal already equal to start must read as reached")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.store.data["settings"]["start"] = 88.0
    app.store.data["settings"]["goal"] = 68.0
    app.tab = "profile"
    for theme in ["forest", "botanical", "dark"]:
        app.store.data["settings"]["theme"] = theme
        app._refresh_appearance()
        app._render()
        await process_frame
        var hero = app.find_child("ProfileHero", true, false)
        var current = app.find_child("ProfileCurrentWeight", true, false) as Label
        var target = app.find_child("ProfileTargetWeight", true, false) as Label
        var progress = app.find_child("ProfileGoalProgress", true, false) as ProgressBar
        var percent = app.find_child("ProfileGoalPercent", true, false) as Label
        if hero == null or current == null or target == null or \
                progress == null or percent == null:
            _fail("header, weight, or progress missing in " + theme)
            return
        if current.text != "88.0 кг" or target.text != "68.0 кг" or \
                progress.value != 0.0 or percent.text != "0%":
            _fail("initial profile summary incorrect in " + theme)
            return
        for caption in ["＋ Записать вес", "✎ Изменить норму калорий",
                "⚙ Настройки и анкета", "📷 Выбрать фото для аватара"]:
            if _find_button(app, caption) == null:
                _fail("important profile action missing: " + caption + " in " + theme)
                return
    app.store.data["weights"] = [
        {"id":"w1","date":"2026-11-10","value":80.0},
        {"id":"w2","date":"2026-11-15","value":78.0}
    ]
    app._render()
    await process_frame
    var bar = app.find_child("ProfileGoalProgress", true, false) as ProgressBar
    var current_weight = app.find_child("ProfileCurrentWeight", true, false) as Label
    if bar == null or absf(bar.value - 50.0) > 0.1 or current_weight.text != "78.0 кг":
        _fail("latest weight not reflected in profile")
        return
    _find_button(app, "＋ Записать вес").pressed.emit()
    await process_frame
    if app.tab != "weight" or _find_button(app, "Записать вес") == null:
        _fail("quick weight action stopped navigating")
        return
    app._navigate_to_tab("profile")
    await process_frame
    _find_button(app, "⚙ Настройки и анкета").pressed.emit()
    await process_frame
    if app.tab != "settings" or \
            _find_button(app, "Моя анкета · пересчитать норму") == null:
        _fail("profile did not retain settings and questionnaire")
        return
    print("PASS PROFILE DASHBOARD: progress directions, target cap, blank history, themes and quick actions")
    app.queue_free()
    quit(0)
