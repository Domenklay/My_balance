extends SceneTree

# End-to-end navigation regression for the 0.7.44 compact UI.
# Existing diary and recipe content must remain intact across tab changes.

func _initialize() -> void:
    call_deferred("_test")

func _fail(message: String) -> void:
    push_error("FAILED SIMPLE UI 0.7.44: " + message)
    quit(1)

func _test() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-23"
    app.store.data["notes"][app.date] = "Не менять"
    app.store.data["activities"].append({
        "date": app.date, "type": "walk", "minutes": 20.0
    })
    app.tab = "day"
    app._render()
    await process_frame
    # This regression covers the five-tab navigation from 0.7.44 onward.
    # Later releases may add features without changing this layout.
    if str(app.APP_VERSION).is_empty():
        _fail("application version missing")
        return
    if app.tab_buttons.size() != 5 or app.tab_buttons.has("weight") or \
            app.tab_buttons.has("stats") or app.tab_buttons.has("recipes"):
        _fail("bottom navigation still exposes redundant tabs")
        return
    var meal = app.find_child("MealHeader_1", true, false) as Button
    var quick = app.find_child("MealQuickAdd_1", true, false) as Button
    if meal == null or quick == null:
        _fail("daily meal shortcuts missing")
        return
    meal.pressed.emit()
    await process_frame
    if app.tab != "search" or app.selected_meal != "Обед" or \
            not app._meal_entry_locked or app._selected_food_date() != "2026-11-23":
        _fail("meal heading did not jump straight to meal-locked product search")
        return
    if app.get_node_or_null("ProductSheet") != null:
        _fail("meal heading still opens an unnecessary intermediate popup")
        return
    if app.find_child("FoodNameSearch", true, false) == null:
        _fail("direct meal search is missing")
        return
    var recipes = app.find_child("ProductsOpenRecipes", true, false) as Button
    if recipes == null:
        _fail("saved recipes are no longer reachable from Products")
        return
    recipes.pressed.emit()
    await process_frame
    if app.tab != "recipes" or not app._meal_entry_locked or \
            app.nav_icons["search"].modulate != app.WHITE:
        _fail("recipe shortcut lost selected meal or product-navigation highlight")
        return
    app._navigate_to_tab("day")
    await process_frame
    var plus = app.find_child("MealQuickAdd_1", true, false) as Button
    if plus == null:
        _fail("quick-repeat action missing after returning to day")
        return
    plus.pressed.emit()
    await process_frame
    if app.tab != "day" or app.get_node_or_null("ProductSheet") == null:
        _fail("plus button stopped offering fast repeats")
        return
    var sheet: Node = app.get_node_or_null("ProductSheet")
    sheet.queue_free()
    await process_frame
    app.tab_buttons["search"].pressed.emit()
    await process_frame
    if app.tab != "search" or app._meal_entry_locked:
        _fail("main Products navigation retained a locked meal")
        return
    if app.find_child("ProductsOpenMyFoods", true, false) == null:
        _fail("my-products management is inaccessible")
        return
    app.tab_buttons["progress"].pressed.emit()
    await process_frame
    if app.tab != "progress" or app.find_child("WeightEntryValue", true, false) == null:
        _fail("combined Progress did not show the weight history")
        return
    var stats = app.find_child("ProgressSection_stats", true, false) as Button
    if stats == null:
        _fail("switch to statistical reports is missing")
        return
    stats.pressed.emit()
    await process_frame
    if app.tab != "progress" or app.progress_section != "stats" or \
            app.find_child("StatsPeriodSelector", true, false) == null:
        _fail("combined Progress did not show existing statistical reports")
        return
    var weight = app.find_child("ProgressSection_weight", true, false) as Button
    if weight == null:
        _fail("weight switch missing after showing statistics")
        return
    weight.pressed.emit()
    await process_frame
    if app.find_child("WeightEntryValue", true, false) == null:
        _fail("weight switch did not restore weight entry UI")
        return
    if app.store.data["notes"][app.date] != "Не менять" or \
            app.store.day_activities(app.date).size() != 1 or \
            app.store.data["entries"].size() != 0:
        _fail("navigation modified existing diary data")
        return
    for theme in ["forest", "botanical", "dark"]:
        app.store.data["settings"]["theme"] = theme
        app._refresh_appearance()
        app.tab = "progress"
        app._render()
        await process_frame
        if app.nav_icons["progress"].modulate != app.WHITE:
            _fail("selected Progress icon is not legible with theme " + theme)
            return
    app.queue_free()
    print("PASS SIMPLE UI 0.7.44: five tabs, direct meal search, recipes, quick repeat, combined progress, themes and data")
    quit(0)
