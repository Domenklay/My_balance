extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED MEAL VISUAL STYLE: " + reason)
    quit(1)

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-21"
    app.tab = "day"
    var titles = ["Завтрак", "Обед", "Ужин", "Перекус"]
    var expected_bg = ["#423046", "#3B354F", "#40334F", "#503348"]
    var themes = ["forest", "mint", "sand", "dark", "botanical"]
    for theme in themes:
        app.store.data["settings"]["theme"] = theme
        app.store.data["settings"]["high_contrast"] = false
        app._refresh_appearance()
        app._render()
        await process_frame
        await process_frame
        for i in range(4):
            var card = app.find_child("DailyMeal_" + str(i), true, false) as PanelContainer
            var icon = app.find_child("MealArt_" + str(i), true, false) as TextureRect
            var title = app.find_child("MealHeader_" + str(i), true, false) as Button
            var add = app.find_child("MealQuickAdd_" + str(i), true, false) as Button
            var expand = app.find_child("MealExpand_" + str(i), true, false) as Button
            if card == null or icon == null or title == null or add == null or expand == null:
                _fail("missing themed meal components: " + theme + " " + str(i))
                return
            if icon.texture == null or icon.texture.get_width() < 32 or \
                    icon.mouse_filter != Control.MOUSE_FILTER_IGNORE:
                _fail("missing SVG or icon intercepts touch: " + theme + " " + str(i))
                return
            if title.text != titles[i]:
                _fail("emoji or wrong heading remains: " + theme + " " + str(i))
                return
            if card.size.y > 113 or icon.size.y > 37:
                _fail("redesigned card is not compact: " + theme + " " + str(i))
                return
            if theme == "botanical":
                var style = card.get_theme_stylebox("panel") as StyleBoxFlat
                if style.bg_color != Color(expected_bg[i]) or style.border_width_left != 1:
                    _fail("pastel theme card palette or soft outline changed: " + str(i))
                    return
                if style.shadow_size > 2:
                    _fail("card shadows remain too heavy: " + str(i))
                    return
            if add.text != "+" or expand.text != "⌄":
                _fail("meal action controls missing: " + theme + " " + str(i))
                return
    app.store.data["settings"]["theme"] = "botanical"
    app.store.data["settings"]["high_contrast"] = true
    app._refresh_appearance()
    app._render()
    await process_frame
    var high_style = (app.find_child("DailyMeal_0", true, false) as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
    if high_style.border_width_left < 2:
        _fail("contrast mode should preserve stronger border")
        return
    app.store.data["settings"]["high_contrast"] = false
    app._refresh_appearance()
    app._render()
    await process_frame
    var landscape = app.find_child("BotanicalActivityLandscape", true, false)
    if landscape == null or landscape.kind != "hills" or landscape.opacity > 0.15:
        _fail("subtle botanical landscape missing")
        return
    (app.find_child("MealHeader_1", true, false) as Button).pressed.emit()
    await process_frame
    if app.tab != "search" or app.get_node_or_null("ProductSheet") != null or \
            app.selected_meal != "Обед" or not app._meal_entry_locked or \
            app.find_child("FoodNameSearch", true, false) == null:
        _fail("lunch title did not open direct meal-locked search")
        return
    print("PASS MEAL VISUAL STYLE: vector icons, five themes, pastel cards, subdued shadows, contrast and meal actions")
    app.queue_free()
    quit(0)
