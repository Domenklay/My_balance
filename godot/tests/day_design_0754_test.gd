extends SceneTree
const Appearance = preload("res://src/appearance.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("DAY DESIGN 0.7.54: " + reason)
    quit(1)
func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.tab = "day"
    app.date = "2026-11-24"
    var food = app.store.food_by_id("d16")
    if not app.store.add_food_entry(food, 100, "Завтрак", app.date):
        _fail("fixture")
        return
    var total: float = app.store.day_calories(app.date)
    for id in Appearance.ORDER:
        app.store.data["settings"]["theme"] = id
        app._refresh_appearance()
        app._render()
        await process_frame
        await process_frame
        var energy = app.find_child("DailyEnergyValue", true, false) as Label
        var consumed = app.find_child("DailyConsumedValue", true, false) as Label
        if energy == null or consumed == null or energy.get_theme_font_size("font_size") < 27 or not consumed.text.contains(str(roundi(total))):
            _fail("energy display " + id)
            return
        var shares: float = 0.0
        for key in ["p", "f", "c"]:
            var bar = app.find_child("DayMacroShare_" + key, true, false) as ProgressBar
            if bar == null:
                _fail("macro share missing")
                return
            shares += bar.value
        if absf(shares - 100.0) > 2.0:
            _fail("macro energy shares not normalized")
            return
        var colors: Array = []
        for i in range(4):
            var meal = app.find_child("DailyMeal_" + str(i), true, false) as PanelContainer
            if meal == null:
                _fail("missing meal")
                return
            var color: Color = meal.get_theme_stylebox("panel").bg_color
            if colors.has(color):
                _fail("meal colors not distinct: " + id)
                return
            colors.append(color)
        if app.find_child("WaterQuickAdd_250", true, false) == null or app.store.day_calories(app.date) != total:
            _fail("day actions or totals lost")
            return
    app.queue_free()
    print("PASS DAY DESIGN 0.7.54: calories, energy share, colored meals and water across five themes")
    quit(0)
