extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED COMPACT LAYOUT: " + reason)
    quit(1)

func _button(node: Node, needle: String) -> Button:
    if node is Button and node.text == needle:
        return node
    for c in node.get_children():
        var result = _button(c, needle)
        if result != null:
            return result
    return null

func _label_exists(node: Node, part: String) -> bool:
    if node is Label and node.text.contains(part):
        return true
    for c in node.get_children():
        if _label_exists(c, part):
            return true
    return false

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.date = Time.get_date_string_from_system()
    var egg = app.store.food_by_id("d16")
    if not app.store.add_food_entry(egg, 55.0, "Обед", app.date):
        _fail("could not create recent product fixture")
        return
    app.tab = "day"
    app._render()
    await process_frame
    if app.body.get_child_count() > 10:
        _fail("day still contains redundant always-open cards")
        return
    if _label_exists(app.body, "Недавно добавляли"):
        _fail("recent-products duplicate card was not removed from day")
        return
    # Guard against accidentally forcing the kcal counter into a 1-character
    # column: it used to make an empty meal taller than the full phone screen.
    for index in range(4):
        var meal_card = app.find_child("DailyMeal_" + str(index), true, false) as PanelContainer
        if meal_card == null or meal_card.size.y > 160:
            _fail("meal section exceeds compact height at index " + str(index))
            return
    var daily_ring = app.find_child("DailyCalorieRing", true, false)
    if daily_ring == null or daily_ring.size.y > 80:
        _fail("daily calorie ring too tall for compact header")
        return
    if _button(app, "▾ Открыть заметку") == null:
        _fail("day notes are not collapsed by default")
        return
    var note_button = _button(app, "▾ Открыть заметку")
    note_button.pressed.emit()
    await process_frame
    if _button(app, "▴ Скрыть заметку") == null:
        _fail("day note cannot be opened")
        return
    var note_text = app.body.find_children("*", "TextEdit", true, false)
    if note_text.is_empty():
        _fail("no editable day note when expanded")
        return
    note_text[0].text = "Небольшая заметка"
    note_text[0].text_changed.emit()
    _button(app, "▴ Скрыть заметку").pressed.emit()
    await process_frame
    if str(app.store.data["notes"].get(app.date, "")) != "Небольшая заметка":
        _fail("collapsing note lost its contents")
        return
    if not _label_exists(app.body, "Заметка сохранена"):
        _fail("collapsed saved note has no indication")
        return

    app.tab = "profile"
    app._render()
    await process_frame
    if app.body.get_child_count() > 5:
        _fail("profile still has excess permanent cards")
        return
    if _button(app, "▾ Показать все достижения") == null:
        _fail("achievements summary control missing")
        return
    if _button(app, "▾ Выбрать рамку") != null:
        _fail("avatar frames should be in expanded achievements only")
        return
    if _button(app, "📷 Выбрать фото для аватара") == null or \
            _button(app, "⚙ Настройки") == null:
        _fail("important profile actions hidden by compact layout")
        return
    _button(app, "▾ Показать все достижения").pressed.emit()
    await process_frame
    if _button(app, "▾ Выбрать рамку") == null:
        _fail("expanded achievements cannot reveal avatar frames")
        return
    _button(app, "⚙ Настройки").pressed.emit()
    await process_frame
    if _button(app, "Моя анкета · пересчитать норму") == null:
        _fail("existing users cannot edit questionnaire from settings")
        return
    print("PASS COMPACT LAYOUT: fewer cards, notes preserved, awards hidden by default and setup accessible")
    app.queue_free()
    quit(0)
