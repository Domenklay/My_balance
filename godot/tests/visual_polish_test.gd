extends SceneTree

# Layout regression: keep a legible compact day without sacrificing
# individual meal actions, theme contrast, or item editing.
func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED VISUAL POLISH: " + message)
    quit(1)

func _has_text(root_node: Node, needle: String) -> bool:
    if root_node is Label and root_node.text.contains(needle):
        return true
    for child in root_node.get_children():
        if _has_text(child, needle):
            return true
    return false

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    # Exercise the classic forest layout explicitly. The app now starts with
    # botanical by default, so replacing the test store alone is not enough.
    app._refresh_appearance()
    app.tab = "day"
    app.date = "2026-11-21"
    app.month_shown = "2026-11"
    app._render()
    await process_frame
    await process_frame
    var logo: PanelContainer = app.emblem_panel
    if logo == null or absf(logo.size.x - logo.size.y) > 6:
        _fail("header symbol must be a compact square, found " + str(logo.size if logo != null else "null"))
        return
    if logo.size.y > 58.0:
        _fail("header symbol is oversized")
        return
    if not app.wallpaper_pattern.enabled:
        _fail("decorative wallpaper theme was accidentally removed")
        return
    var hero = app.body.get_child(1) as PanelContainer
    if hero == null or hero.get_child_count() != 1:
        _fail("day hero should have no pattern overlay behind nutrition data")
        return
    if hero.size.y > 190:
        _fail("day energy panel is too tall: " + str(hero.size.y) + ", likely text wrapping in calorie editor layout")
        return
    var kcal_edit = app.find_child("EditDailyCalorieGoal", true, false) as Button
    if kcal_edit == null or kcal_edit.size.y > 48:
        _fail("compact manual-calorie edit button is missing or oversized")
        return
    if not _has_text(hero, "Белки") or not _has_text(hero, "Жиры") or \
            not _has_text(hero, "Углеводы"):
        _fail("three meaningful macro captions must remain visible")
        return
    for i in range(4):
        var card = app.find_child("DailyMeal_" + str(i), true, false) as PanelContainer
        var row = app.find_child("MealCompactRow_" + str(i), true, false)
        var add = app.find_child("MealQuickAdd_" + str(i), true, false) as Button
        var expand = app.find_child("MealExpand_" + str(i), true, false) as Button
        var heading = app.find_child("MealHeader_" + str(i), true, false) as Button
        var amount = app.find_child("MealCalorieSummary_" + str(i), true, false) as Label
        if card == null or row == null or add == null or expand == null or heading == null or amount == null:
            _fail("missing compact controls on meal " + str(i))
            return
        if card.size.y > 105:
            _fail("collapsed meal is too tall: " + str(i) + " height " + str(card.size.y))
            return
        if add.text != "+" or expand.text != "⌄":
            _fail("expected tiny + and expand chevron on meal " + str(i))
            return
        if not amount.text.contains("/") or not amount.text.contains("ккал"):
            _fail("expected meal consumed/target counter on meal " + str(i))
            return
        var correct_titles = ["Завтрак", "Обед", "Ужин", "Перекус"]
        var art = app.find_child("MealArt_" + str(i), true, false) as TextureRect
        if heading.text != correct_titles[i] or art == null or art.texture == null:
            _fail("meal has missing name or illustrated icon: " + str(i))
            return
        if art.custom_minimum_size.x > 26 or art.size.y > 36:
            _fail("meal illustration is not compact: " + str(i))
            return
        if amount.size.y > 43:
            _fail("counter wraps vertically on meal " + str(i))
            return
    var first = app.find_child("MealQuickAdd_0", true, false) as Button
    first.pressed.emit()
    await process_frame
    if app.get_node_or_null("ProductSheet") == null:
        _fail("compact plus control no longer opens meal-specific search/scan menu")
        return
    app.get_node("ProductSheet").queue_free()
    app.find_child("MealExpand_1", true, false).pressed.emit()
    await process_frame
    if app.find_child("MealDetails_1", true, false) == null:
        _fail("expanding compact meal does not show details")
        return
    print("PASS VISUAL POLISH: square logo, uncluttered hero, four compact meals and preserved actions")
    app.queue_free()
    quit(0)
