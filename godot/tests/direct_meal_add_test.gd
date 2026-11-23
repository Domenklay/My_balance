extends SceneTree

# Main day contains only direct meal-specific actions. Searching, barcode
# scanning and manual EAN input all preserve the selected date and meal.
func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED MEAL ADD: " + reason)
    quit(1)

func _button(root_node: Node, caption: String) -> Button:
    if root_node == null:
        return null
    if root_node is Button and root_node.text == caption:
        return root_node
    for child in root_node.get_children():
        var found = _button(child, caption)
        if found != null:
            return found
    return null

func _check_locked(app: Node, meal: String, day: String) -> bool:
    return app.tab == "search" and app._meal_entry_locked and app.selected_meal == meal and \
        app._selected_food_date() == day

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    # The same four icon-and-title meal actions must work in every theme.
    app._refresh_appearance()
    app.tab = "day"
    app.date = "2026-11-20"
    app.month_shown = "2026-11"
    app._render()
    await process_frame
    if _button(app, "⌕ Открыть полный каталог продуктов") != null or \
            _button(app, "▣  Сканировать штрихкод") != null or \
            _button(app, "Найти продукт или ввести штрихкод") != null:
        _fail("duplicate standalone add-food controls still shown")
        return
    var names = ["Завтрак", "Обед", "Ужин", "Перекус"]
    var titles = ["Завтрак", "Обед", "Ужин", "Перекус"]
    var code = str(app.store.bundled_foods[0].get("barcode", ""))
    if code.is_empty():
        _fail("offline barcode catalog missing test food")
        return
    for i in range(4):
        app.tab = "day"
        app._render()
        await process_frame
        var header = _button(app, titles[i])
        var add = app.find_child("MealQuickAdd_" + str(i), true, false) as Button
        if header == null or add == null:
            _fail("meal header or add button missing: " + names[i])
            return
        if i % 2 == 0:
            header.pressed.emit()
        else:
            add.pressed.emit()
        await process_frame
        var sheet = app.get_node_or_null("ProductSheet")
        if i % 2 == 0:
            # Meal headings jump straight to search, without a chooser.
            if sheet != null or not _check_locked(app, names[i], "2026-11-20"):
                _fail("meal heading did not open direct search: " + names[i])
                return
        else:
            # Plus retains the extra scan/quick-repeat actions.
            if sheet == null or app.selected_meal != names[i] or \
                    _button(sheet, "▣ Сканировать штрихкод") == null or \
                    _button(sheet, "Ввести штрихкод вручную") == null or \
                    _button(sheet, "⌕ Найти продукт") == null:
                _fail("quick-add chooser missing: " + names[i])
                return
        if i == 0 or i == 3:
            if sheet != null:
                _button(sheet, "⌕ Найти продукт").pressed.emit()
                await process_frame
            if not _check_locked(app, names[i], "2026-11-20"):
                _fail("search did not preserve meal/date: " + names[i])
                return
            var results = app.find_child("FoodSearchResults", true, false)
            if results == null or _button(results, "＋ Порция") == null:
                _fail("catalog does not contain a portion picker action")
                return
            var before_count: int = app.store.day_entries("2026-11-20").size()
            _button(results, "＋ Порция").pressed.emit()
            await process_frame
            var portion_sheet = app.get_node_or_null("ProductSheet")
            var accept = portion_sheet.find_child("ProductSheetConfirm", true, false) as Button if portion_sheet != null else null
            if accept == null or app.store.day_entries("2026-11-20").size() != before_count:
                _fail("catalog must not write a meal until the portion is confirmed")
                return
            accept.pressed.emit()
            await process_frame
        elif i == 1:
            # Desktop test has no scanner, so button opens manual EAN search.
            _button(sheet, "▣ Сканировать штрихкод").pressed.emit()
            await process_frame
            if not _check_locked(app, names[i], "2026-11-20"):
                _fail("camera fallback did not keep lunch context")
                return
            app._on_barcode_scanned(code)
            await process_frame
            var product = app.get_node_or_null("ProductSheet")
            var meal_choice = _meal_choice(product)
            if product == null or meal_choice == null or not meal_choice.disabled or \
                    meal_choice.get_item_text(meal_choice.selected) != names[i]:
                _fail("scanned barcode portion does not lock lunch")
                return
            _button(product, "Добавить").pressed.emit()
            await process_frame
        else:
            # Dinner was opened by its title: the direct catalog still
            # exposes manual EAN in the optional barcode panel.
            app._reveal_barcode_section()
            await process_frame
            if not _check_locked(app, names[i], "2026-11-20") or \
                    not is_instance_valid(app.barcode_input):
                _fail("manual EAN flow did not keep dinner context")
                return
            app._lookup_barcode(code)
            await process_frame
            var product = app.get_node_or_null("ProductSheet")
            if product == null or _button(product, "Добавить") == null:
                _fail("manual EAN failed to display food portion")
                return
            _button(product, "Добавить").pressed.emit()
            await process_frame
        var entries: Array = app.store.day_entries("2026-11-20").filter(
            func(e): return str(e.get("meal", "")) == names[i])
        if entries.size() != 1:
            _fail("search/barcode did not save exactly one item to " + names[i])
            return
    var saved: Array = app.store.day_entries("2026-11-20")
    if saved.size() != 4 or app.store.day_entries("2026-11-19").size() != 0:
        _fail("meal-specific actions contaminated another date")
        return
    print("PASS MEAL ADD 0.7.44: direct meal search, quick-add extras, camera and manual EAN preserve date/meal")
    app.queue_free()
    quit(0)

func _meal_choice(node: Node) -> OptionButton:
    if node == null:
        return null
    if node is OptionButton and node.item_count == 4 and node.get_item_text(0) == "Завтрак":
        return node
    for child in node.get_children():
        var found = _meal_choice(child)
        if found != null:
            return found
    return null
