extends SceneTree

# Each selected day owns four separate, visible meal sections. The + button
# must open catalog with the correct meal and preserve the selected date.
func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED DAILY MEALS: " + message)
    quit(1)

func _find_button(node: Node, label: String) -> Button:
    if node is Button and node.text == label:
        return node
    for child in node.get_children():
        var found = _find_button(child, label)
        if found != null:
            return found
    return null

func _find_label(node: Node, label: String) -> bool:
    if node is Label and node.text.contains(label):
        return true
    for child in node.get_children():
        if _find_label(child, label):
            return true
    return false

func _find_meal_choice(node: Node) -> OptionButton:
    if node is OptionButton and node.item_count == 4:
        if node.get_item_text(0) == "Завтрак" and node.get_item_text(1) == "Обед" and node.get_item_text(2) == "Перекус" and node.get_item_text(3) == "Ужин":
            return node
    for child in node.get_children():
        var result = _find_meal_choice(child)
        if result != null:
            return result
    return null

func _run() -> void:
    var packed = load("res://main.tscn")
    if packed == null:
        _fail("main scene missing")
        return
    var app = packed.instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.date = "2026-11-20"
    app.month_shown = "2026-11"
    app._navigate_to_tab("day")
    await process_frame

    var meal_names = ["Завтрак", "Обед", "Ужин", "Перекус"]
    for i in range(meal_names.size()):
        var card = app.find_child("DailyMeal_" + str(i), true, false)
        if card == null:
            _fail("missing empty meal card: " + meal_names[i])
            return
        if not _find_label(card, "0 / "):
            _fail("zero daily total missing from " + meal_names[i])
            return
        if app.find_child("MealQuickAdd_" + str(i), true, false) == null:
            _fail("targeted add button missing from " + meal_names[i])
            return
    if app.store.day_entries(app.date).size() != 0:
        _fail("new day must have no entries")
        return

    var lunch = app.find_child("MealQuickAdd_1", true, false) as Button
    lunch.pressed.emit()
    await process_frame
    if app.tab != "day" or app.selected_meal != "Обед":
        _fail("lunch add button did not preserve the selected meal")
        return
    var options = app.get_node_or_null("ProductSheet")
    if options == null or _find_button(options, "▣ Сканировать штрихкод") == null:
        _fail("lunch sheet has no barcode scanner option")
        return
    var choose_search = _find_button(options, "⌕ Найти продукт")
    if choose_search == null:
        _fail("lunch sheet has no product search option")
        return
    choose_search.pressed.emit()
    await process_frame
    if app.tab != "search" or app.selected_meal != "Обед" or app.date != "2026-11-20":
        _fail("lunch action did not open catalog for selected day")
        return
    if not app._meal_entry_locked or app._selected_food_date() != "2026-11-20":
        _fail("meal/date were not locked after choosing lunch")
        return
    var meal = _find_meal_choice(app)
    if meal == null or meal.get_item_text(meal.selected) != "Обед" or not meal.disabled:
        _fail("food catalog did not lock the lunch destination")
        return
    var results = app.find_child("FoodSearchResults", true, false)
    var add_button = _find_button(results, "＋ Порция") if results != null else null
    if add_button == null:
        _fail("food catalog has no portion action")
        return
    add_button.pressed.emit()
    await process_frame
    var chooser = app.get_node_or_null("ProductSheet")
    var confirm = chooser.find_child("ProductSheetConfirm", true, false) as Button if chooser != null else null
    if chooser == null or confirm == null or not app.store.day_entries("2026-11-20").is_empty():
        _fail("catalog wrote a food record without portion confirmation")
        return
    confirm.pressed.emit()
    await process_frame
    var saved = app.store.day_entries("2026-11-20")
    if saved.size() != 1 or str(saved[0]["meal"]) != "Обед":
        _fail("food added to wrong meal or day")
        return

    app._navigate_to_tab("day")
    await process_frame
    var lunch_card = app.find_child("DailyMeal_1", true, false)
    if lunch_card == null or _find_label(lunch_card, "0 / "):
        _fail("recorded lunch still displayed as empty")
        return
    var breakfast_card = app.find_child("DailyMeal_0", true, false)
    if breakfast_card == null or not _find_label(breakfast_card, "0 / "):
        _fail("lunch contaminated the breakfast section")
        return

    var previous = _find_button(app, "◀")
    if previous == null:
        _fail("previous-day navigation missing")
        return
    previous.pressed.emit()
    await process_frame
    if app.date != "2026-11-19" or app.store.day_entries(app.date).size() != 0:
        _fail("switching to previous day exposed today's lunch")
        return
    for i in range(meal_names.size()):
        if app.find_child("DailyMeal_" + str(i), true, false) == null:
            _fail("previous day lost an empty meal card")
            return
    var next_day = _find_button(app, "▶")
    next_day.pressed.emit()
    await process_frame
    if app.date != "2026-11-20" or app.store.day_entries(app.date).size() != 1:
        _fail("meal was lost after switching back to the selected day")
        return

    print("PASS DAILY MEALS: four permanent sections, targeted meal add and independent daily history")
    app.queue_free()
    quit(0)
