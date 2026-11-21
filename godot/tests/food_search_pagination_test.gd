extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED FOOD SEARCH PAGINATION: " + reason)
    quit(1)

func _row_count(parent: Node) -> int:
    var count: int = 0
    for child in parent.get_children():
        if str(child.name).begins_with("FoodSearchRow_"):
            count += 1
    return count

func _find_button(node: Node, label: String) -> Button:
    if node is Button and node.text == label:
        return node
    for child in node.get_children():
        var found: Button = _find_button(child, label)
        if found != null:
            return found
    return null

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-21"
    for i in range(30):
        app.store.data["foods"].append({
            "id": "paging_" + str(i),
            "name": "Листопродукт " + str(i).pad_zeros(2),
            "brand": "Проверка",
            "kcal": 100.0 + float(i),
            "p": 3.0, "f": 2.0, "c": 17.0,
            "nutrition_unit": "г", "source": "Пользователь"
        })
    app._open_meal_catalog("Обед")
    await process_frame
    var search: LineEdit = app.find_child("FoodNameSearch", true, false) as LineEdit
    var results: VBoxContainer = app.find_child("FoodSearchResults", true, false) as VBoxContainer
    if search == null or results == null:
        _fail("catalog search field and results must exist")
        return
    search.text = "листопродукт"
    search.text_changed.emit(search.text)
    await process_frame
    if not results.visible or _row_count(results) != 12 or \
            _find_button(results, "Показать ещё 12") == null:
        _fail("first page must show 12 of 30 results")
        return
    _find_button(results, "Показать ещё 12").pressed.emit()
    await process_frame
    if _row_count(results) != 24 or _find_button(results, "Показать ещё 6") == null:
        _fail("second page must show 24 of 30 results")
        return
    _find_button(results, "Показать ещё 6").pressed.emit()
    await process_frame
    if _row_count(results) != 30 or results.find_child("FoodLoadMore", true, false) != null:
        _fail("third page must reveal all 30 results")
        return
    var row: Node = results.find_child("FoodSearchRow_25", true, false)
    var add: Button = _find_button(row, "+") if row != null else null
    if add == null:
        _fail("third page results must have a functional add action")
        return
    add.pressed.emit()
    await process_frame
    var added: Array = app.store.day_entries("2026-11-21")
    if added.size() != 1 or str(added[0].get("food", "")) != "paging_25" or \
            str(added[0].get("meal", "")) != "Обед":
        _fail("third page added the wrong product or changed the chosen meal")
        return
    search.text = "листопродукт 2"
    search.text_changed.emit(search.text)
    await process_frame
    if _row_count(results) != 10 or results.find_child("FoodLoadMore", true, false) != null:
        _fail("new query should reset pagination and show only matching items")
        return
    search.text = "несуществующий тестовый продукт 123"
    search.text_changed.emit(search.text)
    await process_frame
    if _row_count(results) != 0 or results.find_child("FoodLoadMore", true, false) != null:
        _fail("empty result set should have no product rows or load-more action")
        return
    print("PASS FOOD SEARCH PAGINATION: 12/24/30, search reset, third-page add and meal lock")
    app.queue_free()
    quit(0)
