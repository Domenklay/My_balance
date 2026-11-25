extends SceneTree

const FoodSearch = preload("res://src/food_search.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED SORT / FREQUENCY: " + reason)
    quit(1)

func _button(node: Node, label: String) -> Button:
    if node is Button and node.text == label:
        return node
    for child in node.get_children():
        var found: Button = _button(child, label)
        if found != null:
            return found
    return null

func _row_name(node: Node) -> String:
    if node is Label and node.text.begins_with("Тестосорт "):
        return node.text
    for child in node.get_children():
        var result: String = _row_name(child)
        if not result.is_empty():
            return result
    return ""

func _first_result(results: Node) -> String:
    var row = results.find_child("FoodSearchRow_0", true, false)
    if row == null:
        return ""
    return _row_name(row)

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-21"
    var foods: Array = [
        {"id":"sort_a", "name":"Тестосорт Абрикос", "kcal":130.0},
        {"id":"sort_b", "name":"Тестосорт Банан", "kcal":70.0},
        {"id":"sort_c", "name":"Тестосорт Вишня", "kcal":280.0}
    ]
    for record in foods:
        app.store.data["foods"].append({
            "id":record["id"], "name":record["name"],
            "kcal":record["kcal"], "p":2.0, "f":1.0, "c":20.0,
            "nutrition_unit":"г", "source":"Пользователь"
        })
    # Add one product three times, another twice, one only once.
    for item_id in ["sort_c", "sort_c", "sort_c", "sort_b", "sort_b", "sort_a"]:
        var food: Dictionary = app.store.food_by_id(item_id)
        if not app.store.add_food_entry(food, 100, "Завтрак", "2026-11-20"):
            _fail("could not save test food history")
            return
    if int(app.store.food_usage_counts().get("sort_c", 0)) != 3 or \
            app.store.frequent_foods(2, 2).size() != 2 or \
            str(app.store.frequent_foods(2, 2)[0]["id"]) != "sort_c" or \
            str(app.store.frequent_foods(2, 2)[1]["id"]) != "sort_b" or \
            not app.store.frequent_foods(0, 2).is_empty():
        _fail("frequency counts, threshold, or zero limit are wrong")
        return
    var base = {"id":"test", "name":"Молоко 2,5%", "brand":"Ёлка", "barcode":"1234567890123"}
    for query in ["молоко елка", "moloko", "vjkjrj", "1234567890123", "", "неизвестно"]:
        var expected: bool = query != "неизвестно"
        if FoodSearch.matches_prepared(base, FoodSearch.prepare(query)) != expected or FoodSearch.matches(base, query) != expected:
            _fail("prepared search changed Cyrillic, transliteration, keyboard or barcode matching: " + query)
            return
    var sample_foods = [app.store.food_by_id("sort_a"), app.store.food_by_id("sort_b"), app.store.food_by_id("sort_c")]
    var portions = app.store.last_food_portions(sample_foods)
    if portions.size() != 3 or float(portions["sort_c|г"]["grams"]) != 100.0:
        _fail("batch portion lookup lost existing history")
        return
    for food in app.store.all_foods():
        if app.store.food_by_id(str(food["id"])) != food:
            _fail("direct lookup disagrees with catalog")
            return
    var favorites: Dictionary = {"sort_a":true}
    if not FoodSearch.sort_before(foods[0], foods[1], "тестосорт абрикос", 0, {}, favorites):
        _fail("exact title match must outrank a shorter unrelated match")
        return
    app._open_meal_catalog("Обед")
    await process_frame
    var search = app.find_child("FoodNameSearch", true, false) as LineEdit
    var sorter = app.find_child("FoodSortOrder", true, false) as OptionButton
    var sorting = app.find_child("FoodSorting", true, false)
    var common = app.find_child("FrequentFoodShortcuts", true, false)
    var filters = app.find_child("FoodQuickFilters", true, false)
    var results = app.find_child("FoodSearchResults", true, false)
    if search == null or sorter == null or sorting == null or \
            common == null or filters == null or results == null:
        _fail("catalog sorter, frequent shortcuts or filters are missing")
        return
    if common.get_child_count() != 2 or _button(filters, "Частые") == null:
        _fail("frequency shortcuts/filter must show only repeated products")
        return
    if sorting.visible:
        _fail("sorter must stay hidden until results are shown")
        return
    search.text = "тестосорт"
    search.text_changed.emit(search.text)
    await process_frame
    if not sorting.visible or not _first_result(results).begins_with("Тестосорт Вишня"):
        _fail("relevance mode must rank most frequent matching product first")
        return
    sorter.select(2)
    sorter.item_selected.emit(2)
    await process_frame
    if not _first_result(results).begins_with("Тестосорт Абрикос"):
        _fail("name sorting did not put Apricot first")
        return
    sorter.select(3)
    sorter.item_selected.emit(3)
    await process_frame
    if not _first_result(results).begins_with("Тестосорт Банан"):
        _fail("ascending calorie sorting did not put Banana first")
        return
    sorter.select(4)
    sorter.item_selected.emit(4)
    await process_frame
    if not _first_result(results).begins_with("Тестосорт Вишня"):
        _fail("descending calorie sorting did not put Cherry first")
        return
    var row = results.find_child("FoodSearchRow_0", true, false)
    var add: Button = _button(row, "＋ Порция") if row != null else null
    if add == null:
        _fail("sorted result has no add button")
        return
    add.pressed.emit()
    await process_frame
    var chooser = app.get_node_or_null("ProductSheet")
    var confirm = chooser.find_child("ProductSheetConfirm", true, false) as Button if chooser != null else null
    if confirm == null or not app.store.day_entries("2026-11-21").is_empty():
        _fail("sorted result must request confirmation of the chosen portion")
        return
    confirm.pressed.emit()
    await process_frame
    var today: Array = app.store.day_entries("2026-11-21")
    if today.size() != 1 or str(today[0].get("food", "")) != "sort_c" or \
            str(today[0].get("meal", "")) != "Обед":
        _fail("sort mode changed the selected product, date or meal")
        return
    # The confirmed sheet rerenders the catalog.
    search = app.find_child("FoodNameSearch", true, false) as LineEdit
    results = app.find_child("FoodSearchResults", true, false)
    filters = app.find_child("FoodQuickFilters", true, false)
    search.text = ""
    search.text_changed.emit("")
    _button(filters, "Частые").pressed.emit()
    await process_frame
    if not results.visible or _first_result(results).is_empty():
        _fail("frequent quick filter did not display saved repeated products")
        return
    print("PASS SORT / FREQUENCY: usage counts, shortcut chips, five sort modes, meal locking")
    app.queue_free()
    quit(0)
