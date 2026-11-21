extends SceneTree

const StoreScript = preload("res://src/store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED RECENT PRODUCT SEARCH: " + message)
    quit(1)

func _button(node: Node, title: String) -> Button:
    if node is Button and node.text == title:
        return node
    for child in node.get_children():
        var match_button: Button = _button(child, title)
        if match_button != null:
            return match_button
    return null

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-21"
    app.month_shown = "2026-11"
    var first: Dictionary = app.store.all_foods()[0]
    var second: Dictionary = app.store.all_foods()[2]
    if not app.store.add_food_entry(first, 80, "Завтрак", "2026-11-19") or \
            not app.store.add_food_entry(second, 120, "Перекус", "2026-11-20") or \
            not app.store.add_food_entry(first, 150, "Ужин", "2026-11-20"):
        _fail("could not prepare past diary entries")
        return
    var recents: Array = app.store.recent_food_entries(3)
    if recents.size() != 2 or str(recents[0]["food"]["id"]) != str(first["id"]) or \
            roundi(float(recents[0]["grams"])) != 150 or \
            str(recents[1]["food"]["id"]) != str(second["id"]):
        _fail("recents must be unique and ordered by last logged portion")
        return
    if not app.store.recent_food_entries(0).is_empty():
        _fail("zero limit must not return a recent item")
        return
    if not app.store.toggle_favorite(str(second["id"])):
        _fail("cannot save favorite")
        return
    app.tab = "day"
    app._refresh_appearance()
    app._render()
    await process_frame
    var plus = app.find_child("MealQuickAdd_1", true, false) as Button
    plus.pressed.emit()
    await process_frame
    var sheet = app.get_node_or_null("ProductSheet")
    if sheet == null or _button(sheet, "↻ 150 г") == null or \
            _button(sheet, "★ " + str(second["name"])) == null or \
            _button(sheet, "⌕ Найти продукт") == null or \
            _button(sheet, "▣ Сканировать штрихкод") == null:
        _fail("meal sheet missing recents, favorites or original catalog and barcode actions")
        return
    _button(sheet, "↻ 150 г").pressed.emit()
    await process_frame
    var entries = app.store.day_entries("2026-11-21")
    if entries.size() != 1 or str(entries[0]["meal"]) != "Обед" or \
            float(entries[0]["grams"]) != 150 or str(entries[0]["food"]) != str(first["id"]):
        _fail("quick repeat was not saved to the chosen lunch and date")
        return
    if app.tab != "day" or app._meal_entry_locked:
        _fail("repeat should return to diary and unlock meal selection")
        return
    app._open_meal_catalog("Ужин")
    await process_frame
    var search: LineEdit = _find_search(app)
    var quick = app.find_child("FoodRecentFavorites", true, false)
    var filters = app.find_child("FoodQuickFilters", true, false)
    var results = app.find_child("FoodSearchResults", true, false)
    if search == null or quick == null or filters == null or results == null:
        _fail("search, recents, shortcuts or results are missing")
        return
    if search.get_parent().get_child(2) != search or not quick.visible:
        _fail("search is not first in catalog or recent section not shown")
        return
    if _button(filters, "Недавние") == null or \
            _button(filters, "★ Избранное") == null or _button(filters, "Все") == null:
        _fail("catalog quick filters missing")
        return
    _button(filters, "Недавние").pressed.emit()
    await process_frame
    if not results.visible:
        _fail("recent filter did not show matching products")
        return
    _button(filters, "★ Избранное").pressed.emit()
    await process_frame
    if not results.visible:
        _fail("favorite filter did not show results")
        return
    _button(filters, "Все").pressed.emit()
    search.text = "банан"
    search.text_changed.emit(search.text)
    await process_frame
    if quick.visible or not results.visible:
        _fail("typing search must show results instead of recent shortcut list")
        return
    if not app._meal_entry_locked or app.selected_meal != "Ужин" or \
            app._selected_food_date() != "2026-11-21":
        _fail("search lost meal/day lock")
        return
    var restored = StoreScript.new()
    if restored.recent_food_entries(3).is_empty() or \
            roundi(float(restored.recent_food_entries(1)[0]["grams"])) != 150:
        _fail("recent portion history was not persisted")
        return
    print("PASS RECENT PRODUCT SEARCH: search first, recent/favorite filters, logged grams, quick repeat and day/meal")
    app.queue_free()
    quit(0)

func _find_search(node: Node) -> LineEdit:
    if node is LineEdit and node.placeholder_text == "Поиск продукта по названию":
        return node
    for child in node.get_children():
        var field: LineEdit = _find_search(child)
        if field != null:
            return field
    return null
