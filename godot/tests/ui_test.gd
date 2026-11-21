extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _find_search(node: Node) -> LineEdit:
    if node is LineEdit and node.placeholder_text == "Поиск продукта по названию":
        return node
    for child in node.get_children():
        var found = _find_search(child)
        if found != null:
            return found
    return null

func _find_button(node: Node, label: String) -> Button:
    if node is Button and node.text == label:
        return node
    for child in node.get_children():
        var found = _find_button(child, label)
        if found != null:
            return found
    return null

func _run() -> void:
    var scene = load("res://main.tscn")
    if scene == null:
        push_error("FAILED: main scene missing")
        quit(1)
        return
    var app: Variant = scene.instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    # This test targets the classic emoji-headed layout, not botanical art.
    app._refresh_appearance()
    app.tab = "day"
    if not app.store.save():
        push_error("FAILED: cannot initialize UI test journal")
        quit(1)
        return
    app._render()
    await process_frame
    # The full screen including five bottom tabs must not exceed 420 px.
    if app.shell.size.x > 421.0 or app.shell.size.x < 415.0:
        push_error("FAILED: mobile layout overflows 420px: " + str(app.shell.size.x))
        quit(1)
        return
    if app.tab_buttons.size() != 6 or not app.tab_buttons.has("recipes") or not app.tab_buttons.has("profile"):
        push_error("FAILED: mobile navigation missing Recipes or Profile")
        quit(1)
        return
    var expand_button: Button = app.find_child("MealQuickAdd_0", true, false) as Button
    if expand_button == null:
        push_error("FAILED: breakfast card has no direct add-food action")
        quit(1)
        return
    expand_button.pressed.emit()
    await process_frame
    var search_from_meal = _find_button(app, "⌕ Найти продукт")
    if search_from_meal == null:
        push_error("FAILED: meal chooser is missing product search")
        quit(1)
        return
    search_from_meal.pressed.emit()
    await process_frame
    if app.tab != "search" or app.selected_meal != "Завтрак" or not app._meal_entry_locked:
        push_error("FAILED: meal-specific catalog failed to lock breakfast")
        quit(1)
        return
    var search: LineEdit = _find_search(app)
    if search == null:
        push_error("FAILED: food search input missing")
        quit(1)
        return
    var parent = search.get_parent()
    var picker: OptionButton = null
    for child in parent.get_children():
        if child is OptionButton:
            picker = child
            break
    if picker == null or picker.item_count < 20:
        push_error("FAILED: default product catalog not present")
        quit(1)
        return
    # Keyboard-focused fields must be visible and release focus on IME Done.
    search.grab_focus()
    await process_frame
    await process_frame
    await process_frame
    if app.get_viewport().gui_get_focus_owner() != search:
        push_error("FAILED: search field did not acquire keyboard focus")
        quit(1)
        return
    search.text_submitted.emit("банан")
    if app.get_viewport().gui_get_focus_owner() == search:
        push_error("FAILED: IME Done did not release field focus")
        quit(1)
        return
    search.text = "банан"
    search.text_changed.emit("банан")
    if picker.item_count < 1:
        push_error("FAILED: no banana found in food catalog")
        quit(1)
        return
    var builtin_index = -1
    for i in range(picker.item_count):
        var label = picker.get_item_text(i).strip_edges()
        if not label.to_lower().contains("банан"):
            push_error("FAILED: search returned unrelated food: " + label)
            quit(1)
            return
        if label == "Банан":
            builtin_index = i
    if builtin_index < 0:
        push_error("FAILED: default banana missing from search results")
        quit(1)
        return
    picker.select(builtin_index)
    picker.item_selected.emit(builtin_index)
    var favorite_button = _find_button(parent, "☆ В избранное")
    if favorite_button == null:
        push_error("FAILED: favorite button missing")
        quit(1)
        return
    favorite_button.pressed.emit()
    if not app.store.is_favorite("d2"):
        push_error("FAILED: UI cannot set a favorite")
        quit(1)
        return
    var add_button = _find_button(parent, "+ Добавить")
    if add_button == null:
        push_error("FAILED: quick-add button missing")
        quit(1)
        return
    add_button.pressed.emit()
    if app.store.day_entries(app.date).size() != 1:
        push_error("FAILED: quick add did not create food entry")
        quit(1)
        return
    if str(app.store.day_entries(app.date)[0].get("food", "")) != "d2":
        push_error("FAILED: wrong product added from filtered search")
        quit(1)
        return
    # Scan result must select the precise ID, not a matching display name.
    var scanned_food: Dictionary = app.store.bundled_foods[0]
    var target_id = str(scanned_food["id"])
    app._show_barcode_portion(scanned_food)
    await process_frame
    var scanned_sheet: Control = app.get_node_or_null("ProductSheet")
    if scanned_sheet == null:
        push_error("FAILED: light product card missing")
        quit(1)
        return
    var confirm_button: Button = scanned_sheet.find_child("ProductSheetConfirm", true, false)
    if confirm_button == null or confirm_button.text != "Добавить":
        push_error("FAILED: barcode product card has no visible add button")
        quit(1)
        return
    var button_rect = confirm_button.get_global_rect()
    var screen = app.get_viewport_rect().size
    if button_rect.position.x < 0 or button_rect.position.y < 0 or button_rect.end.x > screen.x + 1.0 or button_rect.end.y > screen.y + 1.0:
        push_error("FAILED: barcode action button is clipped by mobile viewport")
        quit(1)
        return
    confirm_button.pressed.emit()
    await process_frame
    var after_scan = app.store.day_entries(app.date)
    if after_scan.size() != 2 or str(after_scan[1].get("food", "")) != target_id:
        push_error("FAILED: barcode product dialog did not add the exact selected item")
        quit(1)
        return
    # Nonblocking status banner remains usable after UI rerenders.
    var toast: PanelContainer = app.get_node_or_null("SaveStatus")
    if toast == null or not toast.visible or toast.mouse_filter != Control.MOUSE_FILTER_IGNORE:
        push_error("FAILED: saved confirmation is absent or intercepts taps")
        quit(1)
        return
    var toast_text: Label = toast.get_node("SaveStatusText")
    if not toast_text.text.contains("Порция добавлена"):
        push_error("FAILED: meal addition did not confirm success")
        quit(1)
        return
    # Catalog now opens from a specific meal instead of a duplicate day panel.
    app._navigate_to_tab("day")
    await process_frame
    var catalog_button = _find_button(app, "🍲 Обед")
    if catalog_button == null:
        push_error("FAILED: tapping lunch heading must be available")
        quit(1)
        return
    catalog_button.pressed.emit()
    await process_frame
    var lunch_search = _find_button(app, "⌕ Найти продукт")
    if lunch_search == null:
        push_error("FAILED: lunch heading has no product search option")
        quit(1)
        return
    lunch_search.pressed.emit()
    await process_frame
    if app.selected_meal != "Обед" or not app._meal_entry_locked:
        push_error("FAILED: tapping lunch heading did not select lunch")
        quit(1)
        return
    if app.tab != "search":
        push_error("FAILED: full catalog did not open")
        quit(1)
        return
    var results = app.find_child("FoodSearchResults", true, false)
    if results == null or _find_button(results, "+") == null:
        push_error("FAILED: catalog nutrition cards or quick add missing")
        quit(1)
        return
    var count_before = app.store.day_entries(app.date).size()
    var add_from_result = _find_button(results, "+")
    add_from_result.pressed.emit()
    await process_frame
    if app.store.day_entries(app.date).size() != count_before + 1 or app.tab != "search":
        push_error("FAILED: result quick add must keep catalog open")
        quit(1)
        return
    add_from_result.pressed.emit()
    await process_frame
    if app.store.day_entries(app.date).size() != count_before + 2:
        push_error("FAILED: catalog must allow adding several items in sequence")
        quit(1)
        return
    app._navigate_to_tab("day")
    app.settings_page = "foods"
    app._navigate_to_tab("settings")
    if app.tab != "settings" or app.settings_page != "foods":
        push_error("FAILED: cannot open dedicated food management tab")
        quit(1)
        return
    app._navigate_to_tab("settings")
    if app.settings_page != "main":
        push_error("FAILED: tapping More while in own-products did not return to main settings")
        quit(1)
        return
    print("PASS: keyboard focus/IME Done, status notification and settings navigation")
    print("PASS: barcode result card adds the exact product and selected portion to journal")
    print("PASS: Godot dashboard renders, food search filters, favorites toggle, quick-add works")
    print("PASS: Full food catalog results allow consecutive adds without closing search")
    app.queue_free()
    quit(0)
