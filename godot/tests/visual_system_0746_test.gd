extends SceneTree

const Appearance = preload("res://src/appearance.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED VISUAL SYSTEM 0.7.46: " + reason)
    quit(1)

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.tab = "day"
    for id in Appearance.ORDER:
        app.store.data["settings"]["theme"] = id
        app._refresh_appearance()
        app._render()
        await process_frame
        var colors: Dictionary = Appearance.palette(id)
        if app.BACKGROUND != Color(str(colors["background"])) or \
                app.NAV_ACTIVE != Color(str(colors["nav_active"])):
            _fail("selected theme lost its color tokens: " + id)
            return
        if app.tab_buttons.size() != 5 or app.nav_icons.size() != 5:
            _fail("navigation controls missing: " + id)
            return
        var hero = app.body.get_child(1) as PanelContainer
        var motion = app.body.get_node_or_null("DayDateNavigation") as PanelContainer
        if hero == null or motion == null or app.body.get_node_or_null("DailyActivity") != null:
            _fail("daily summary cards disappeared: " + id)
            return
        var hero_style: StyleBoxFlat = hero.get_theme_stylebox("panel") as StyleBoxFlat
        var motion_style: StyleBoxFlat = motion.get_theme_stylebox("panel") as StyleBoxFlat
        if hero_style.bg_color == motion_style.bg_color or \
                hero_style.shadow_size > 3 or motion_style.shadow_size > 2:
            _fail("main kcal card is not visually distinguished: " + id)
            return
        if id not in ["dark", "botanical"] and motion_style.bg_color.get_luminance() < 0.5:
            _fail("date card competes with dark calorie hero: " + id)
            return
        var energy = app.find_child("DailyEnergyValue", true, false) as Label
        if energy == null or energy.get_theme_font_size("font_size") < 22:
            _fail("important energy number is not prominent: " + id)
            return
        for meal in range(4):
            if app.find_child("MealQuickAdd_" + str(meal), true, false) == null or \
                    app.find_child("MealExpand_" + str(meal), true, false) == null:
                _fail("visual refresh removed a meal action: " + id)
                return
        var secondary = app._button(app.body, "Вторичная", Callable(), true)
        var primary = app._button(app.body, "Основная", Callable(), false)
        var secondary_style: StyleBoxFlat = secondary.get_theme_stylebox("normal") as StyleBoxFlat
        var primary_style: StyleBoxFlat = primary.get_theme_stylebox("normal") as StyleBoxFlat
        if secondary_style.border_width_left < 1 or \
                primary_style.bg_color == secondary_style.bg_color:
            _fail("primary and secondary buttons look identical: " + id)
            return
        secondary.queue_free()
        primary.queue_free()
    app.store.data["settings"]["theme"] = "botanical"
    app.store.data["settings"]["high_contrast"] = true
    app._refresh_appearance()
    app._render()
    await process_frame
    var hc = (app.body.get_child(1) as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
    if hc.border_width_left < 2:
        _fail("high contrast mode lost stronger borders")
        return
    app.tab = "progress"
    app.progress_section = "body"
    app._render()
    await process_frame
    if app.find_child("BodyMeasurementsGrid", true, false) == null:
        _fail("body measurements disappeared from progress")
        return
    app.tab = "search"
    app._render()
    await process_frame
    if app.find_child("FoodNameSearch", true, false) == null:
        _fail("product search disappeared")
        return
    print("PASS VISUAL SYSTEM 0.7.46: all five themes, calm surfaces, primary/secondary buttons, compact meals, body and search")
    app.queue_free()
    quit(0)
