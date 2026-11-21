extends SceneTree

const AppearanceScript = preload("res://src/appearance.gd")
const StoreScript = preload("res://src/store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED BOTANICAL THEME: " + reason)
    quit(1)

func _has_text(node: Node, phrase: String) -> bool:
    if node is Label and node.text.contains(phrase):
        return true
    for child in node.get_children():
        if _has_text(child, phrase):
            return true
    return false

func _run() -> void:
    if not AppearanceScript.is_valid_theme("botanical") or \
            AppearanceScript.name_for("botanical") != "Ботанический контраст":
        _fail("new theme missing from appearance registry")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.save()
    app.tab = "day"
    app._choose_theme("botanical")
    await process_frame
    await process_frame
    var palette = AppearanceScript.palette("botanical")
    if app.current_theme != "botanical" or app.store.data["settings"]["theme"] != "botanical":
        _fail("theme change not saved")
        return
    if app.PATTERN_STYLE != "botanical" or app.wallpaper_pattern.kind != "botanical" or \
            not app.wallpaper_pattern.enabled or not app.header_pattern.enabled:
        _fail("new corner-leaf motif did not apply to wallpaper and header")
        return
    var hero = app.body.get_child(1) as PanelContainer
    if hero == null or hero.get_theme_stylebox("panel").bg_color != Color(str(palette["hero"])):
        _fail("forest green daily energy panel not applied")
        return
    if hero.size.y > 190:
        _fail("botanical hero grew too tall")
        return
    var art_labels = ["🥣", "🍲", "🥗", "🍓"]
    var colors = ["#FFF2DE", "#E9F5E9", "#E9EEFC", "#FFF0F2"]
    for i in range(4):
        var meal = app.find_child("DailyMeal_" + str(i), true, false) as PanelContainer
        var art = app.find_child("BotanicalMealArt_" + str(i), true, false) as Label
        var plus = app.find_child("MealQuickAdd_" + str(i), true, false) as Button
        var arrow = app.find_child("MealExpand_" + str(i), true, false) as Button
        if meal == null or art == null or plus == null or arrow == null:
            _fail("decorated meal row controls missing: " + str(i))
            return
        if art.text != art_labels[i]:
            _fail("incorrect food icon for meal " + str(i))
            return
        if meal.get_theme_stylebox("panel").bg_color != Color(colors[i]):
            _fail("distinct colored section background missing: " + str(i))
            return
        if meal.size.y > 113:
            _fail("botanical meal card is too tall for compact home: " + str(i) + " " + str(meal.size.y))
            return
    var activity = app.body.get_node_or_null("DailyActivity") as PanelContainer
    if activity == null or activity.get_theme_stylebox("panel").bg_color != app.ACTIVITY_BG:
        _fail("activity panel not themed")
        return
    if not _has_text(activity, "Прогулки:"):
        _fail("activity information obscured by art")
        return
    if activity.find_child("BotanicalActivityLandscape", true, false) == null:
        _fail("mountain scene not shown behind botanical activity card")
        return
    var add = app.find_child("MealQuickAdd_1", true, false) as Button
    add.pressed.emit()
    await process_frame
    if app.get_node_or_null("ProductSheet") == null or app.selected_meal != "Обед":
        _fail("lunch button lost the barcode/search action")
        return
    app.get_node("ProductSheet").queue_free()
    await process_frame
    var stored = StoreScript.new()
    if str(stored.data["settings"]["theme"]) != "botanical":
        _fail("theme did not survive reload")
        return
    app._toggle_high_contrast()
    await process_frame
    if not app.HIGH_CONTRAST or app.BORDER != Color(str(AppearanceScript.palette("botanical", true)["border"])):
        _fail("botanical high-contrast selection not applied")
        return
    app._choose_theme("forest")
    await process_frame
    if app.current_theme != "forest" or app.PATTERN_STYLE == "botanical":
        _fail("botanical pattern leaked into the classic forest theme")
        return
    app._choose_theme("botanical")
    app._toggle_patterns()
    await process_frame
    if app.PATTERNS or app.wallpaper_pattern.enabled:
        _fail("disable-patterns setting does not work on botanical theme")
        return
    app.tab = "settings"
    app._render()
    await process_frame
    if app.find_child("ThemeSwatch_botanical", true, false) == null:
        _fail("new theme not available under profile settings")
        return
    print("PASS BOTANICAL THEME: distinct cream/forest cards, corner foliage, safe compact meal actions, save and contrast")
    app.queue_free()
    quit(0)
