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
    if not app.store.save():
        push_error("FAILED: cannot initialize UI test journal")
        quit(1)
        return
    app._render()
    await process_frame
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
    print("DEBUG UI: catalog=", app.store.all_foods().size(), " picker=", -1 if picker == null else picker.item_count, " search=", search.text, " parent_children=", parent.get_child_count())
    if picker == null or picker.item_count < 20:
        push_error("FAILED: default product catalog not present")
        quit(1)
        return
    search.text = "банан"
    search.text_changed.emit("банан")
    if picker.item_count != 1 or not picker.get_item_text(0).to_lower().contains("банан"):
        push_error("FAILED: food catalog search does not filter products")
        quit(1)
        return
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
    print("PASS: Godot dashboard renders, food search filters, favorites toggle, quick-add works")
    app.queue_free()
    quit(0)
