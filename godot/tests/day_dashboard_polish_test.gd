extends SceneTree

# Dashboard polish must save vertical space without losing daily controls.
func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED DAY DASHBOARD POLISH: " + message)
    quit(1)

func _find_label(node: Node, needle: String) -> bool:
    if node is Label and node.text.contains(needle):
        return true
    for child in node.get_children():
        if _find_label(child, needle):
            return true
    return false

func _button_named(node: Node, title: String) -> Button:
    if node is Button and node.text == title:
        return node
    for child in node.get_children():
        var found: Button = _button_named(child, title)
        if found != null:
            return found
    return null

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["theme"] = "botanical"
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-21"
    app.month_shown = "2026-11"
    app._refresh_appearance()
    app.tab = "day"
    app._render()
    await process_frame
    await process_frame

    var date_bar = app.body.get_node_or_null("DayDateNavigation") as PanelContainer
    var movement = app.body.get_node_or_null("DailyActivity") as PanelContainer
    var note_panel = app.body.get_node_or_null("DailyNote") as PanelContainer
    var editor = app.find_child("EditDailyCalorieGoal", true, false) as Button
    if date_bar == null or movement == null or note_panel == null or editor == null:
        _fail("one of the compact day controls is absent")
        return
    if date_bar.size.y > 67 or movement.size.y > 142 or note_panel.size.y > 82:
        _fail("dashboard cards are not compact: date=" + str(date_bar.size.y) +
            " movement=" + str(movement.size.y) + " note=" + str(note_panel.size.y))
        return
    if editor.text != "Норма" or editor.size.y > 48:
        _fail("calorie goal editor is not a compact and readable button")
        return
    if not _find_label(movement, "Прогулки: 0 мин") or \
            not _find_label(movement, "Тренировки: 0 мин"):
        _fail("activity totals disappeared")
        return
    if movement.find_child("BotanicalActivityLandscape", true, false) == null:
        _fail("botanical mountains should remain")
        return
    if _button_named(note_panel, "▾ Открыть заметку") == null:
        _fail("collapsed note opener is missing")
        return

    editor.pressed.emit()
    await process_frame
    if app.find_child("CalorieGoalEditorInput", true, false) == null:
        _fail("calorie editor button no longer opens the form")
        return
    var sheet = app.get_node_or_null("ProductSheet")
    if sheet != null:
        sheet.queue_free()
        await process_frame

    var open_note = _button_named(note_panel, "▾ Открыть заметку")
    open_note.pressed.emit()
    await process_frame
    var text_fields: Array = []
    for child in app.body.get_node("DailyNote").get_children():
        for grandchild in child.get_children():
            if grandchild is TextEdit:
                text_fields.append(grandchild)
    if text_fields.is_empty():
        _fail("expanded note textarea is missing")
        return
    var notes: TextEdit = text_fields[0]
    notes.text = "Сохранить запись дня"
    notes.text_changed.emit()
    var close_note = _button_named(app.body.get_node("DailyNote"), "▴ Скрыть заметку")
    if close_note == null:
        _fail("expanded note cannot close")
        return
    close_note.pressed.emit()
    await process_frame
    if str(app.store.data["notes"].get(app.date, "")) != "Сохранить запись дня":
        _fail("closing the note discarded text")
        return
    if not _find_label(app.body.get_node("DailyNote"), "Заметка сохранена"):
        _fail("saved note indicator missing from the compact row")
        return

    var today = app.date
    if _button_named(date_bar, "◀") == null:
        _fail("date arrow missing")
        return
    # Find the live date bar after the note rerender.
    _button_named(app.body.get_node("DayDateNavigation"), "◀").pressed.emit()
    await process_frame
    if app.date == today:
        _fail("date arrow stopped working")
        return
    app.tab = "day"
    app._render()
    await process_frame
    _button_named(app.body.get_node("DailyActivity"), "+ Спорт").pressed.emit()
    await process_frame
    if app.tab != "activity":
        _fail("sport quick action did not navigate")
        return
    app.tab = "day"
    app._render()
    await process_frame
    _button_named(app.body.get_node("DailyActivity"), "+ Вес").pressed.emit()
    await process_frame
    if app.tab != "weight":
        _fail("weight quick action did not navigate")
        return
    print("PASS DAY DASHBOARD POLISH: small date/activity/note, calorie goal, note saving and sport/weight navigation")
    app.queue_free()
    quit(0)
