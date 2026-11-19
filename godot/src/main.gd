extends Control

const StoreScript = preload("res://src/store.gd")
const GraphScript = preload("res://src/weight_graph.gd")
const GREEN = Color("#226b55")
const INK = Color("#233c34")
const MUTED = Color("#71877a")
const PALE = Color("#f1f7f3")
const WHITE = Color("#ffffff")

var store = StoreScript.new()
var date: String = Time.get_date_string_from_system()
var tab: String = "day"
var month_shown: String = ""
var shell: VBoxContainer
var body: VBoxContainer
var scroll: ScrollContainer
var food_entry_card: VBoxContainer
var note_save_timer: Timer

func _ready() -> void:
    month_shown = date.substr(0, 7)
    var backdrop = ColorRect.new()
    backdrop.color = Color("#edf4ef")
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)
    shell = VBoxContainer.new()
    shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shell.add_theme_constant_override("separation", 0)
    add_child(shell)
    var title = PanelContainer.new()
    var head_style = StyleBoxFlat.new()
    head_style.bg_color = GREEN
    head_style.content_margin_left = 16
    head_style.content_margin_right = 16
    head_style.content_margin_top = 14
    head_style.content_margin_bottom = 14
    title.add_theme_stylebox_override("panel", head_style)
    shell.add_child(title)
    _label(title, "🌿 Мой баланс", 24, WHITE)
    scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shell.add_child(scroll)
    body = VBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 12)
    scroll.add_child(body)
    note_save_timer = Timer.new()
    note_save_timer.wait_time = 0.6
    note_save_timer.one_shot = true
    note_save_timer.timeout.connect(func(): store.save())
    add_child(note_save_timer)
    _make_tabs()
    _render()

func _exit_tree() -> void:
    if note_save_timer != null and not note_save_timer.is_stopped():
        store.save()

func _label(parent: Node, s: String, size: int = 16, color: Color = INK) -> Label:
    var l = Label.new()
    l.text = s
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(l)
    return l

func _row(parent: Node) -> HBoxContainer:
    var r = HBoxContainer.new()
    r.add_theme_constant_override("separation", 8)
    parent.add_child(r)
    return r

func _button(parent: Node, s: String, call: Callable, secondary: bool = false) -> Button:
    var b = Button.new()
    b.text = s
    b.custom_minimum_size = Vector2(0, 42)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var st = StyleBoxFlat.new()
    st.bg_color = Color("#dbece1") if secondary else GREEN
    st.set_corner_radius_all(11)
    st.content_margin_left = 8
    st.content_margin_right = 8
    st.content_margin_top = 5
    st.content_margin_bottom = 5
    b.add_theme_stylebox_override("normal", st)
    b.add_theme_stylebox_override("hover", st)
    b.add_theme_stylebox_override("pressed", st)
    b.add_theme_color_override("font_color", GREEN if secondary else WHITE)
    b.add_theme_color_override("font_hover_color", GREEN if secondary else WHITE)
    b.add_theme_color_override("font_pressed_color", GREEN if secondary else WHITE)
    b.pressed.connect(call)
    parent.add_child(b)
    return b

func _card(title: String) -> VBoxContainer:
    var panel = PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var style = StyleBoxFlat.new()
    style.bg_color = WHITE
    style.set_corner_radius_all(18)
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 14
    style.content_margin_bottom = 14
    panel.add_theme_stylebox_override("panel", style)
    body.add_child(panel)
    var content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 9)
    panel.add_child(content)
    if not title.is_empty():
        _label(content, title, 20, INK)
    return content

func _number(parent: Node, value: float, minimum: float, maximum: float, step: float = 1.0) -> SpinBox:
    var spin = SpinBox.new()
    spin.min_value = minimum
    spin.max_value = maximum
    spin.step = step
    spin.value = value
    spin.custom_minimum_size.y = 45
    spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(spin)
    return spin

func _text_input(parent: Node, placeholder: String, text: String = "") -> LineEdit:
    var field = LineEdit.new()
    field.placeholder_text = placeholder
    field.text = text
    field.custom_minimum_size.y = 45
    field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(field)
    return field

func _choice(parent: Node, options: Array) -> OptionButton:
    var picker = OptionButton.new()
    picker.custom_minimum_size.y = 46
    picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for name in options:
        picker.add_item(str(name))
    parent.add_child(picker)
    return picker

func _make_tabs() -> void:
    var bar = PanelContainer.new()
    var st = StyleBoxFlat.new()
    st.bg_color = WHITE
    st.content_margin_left = 5
    st.content_margin_right = 5
    st.content_margin_top = 7
    st.content_margin_bottom = 8
    bar.add_theme_stylebox_override("panel", st)
    shell.add_child(bar)
    var row = HBoxContainer.new()
    bar.add_child(row)
    var tabs = [
        ["День", "day"], ["Спорт", "activity"], ["Вес", "weight"],
        ["Итоги", "stats"], ["Ещё", "settings"]
    ]
    for item in tabs:
        var target: String = item[1]
        _button(row, item[0], func(): tab = target; _render(), true)

func _render() -> void:
    for child in body.get_children():
        body.remove_child(child)
        child.queue_free()
    match tab:
        "day": _show_day()
        "activity": _show_activity()
        "weight": _show_weight()
        "stats": _show_stats()
        "settings": _show_settings()
    scroll.scroll_vertical = 0

func _date_nav(parent: Node) -> void:
    var r = _row(parent)
    _button(r, "◀", func(): date = store.change_date(date, -1); month_shown = date.substr(0, 7); _render(), true)
    _label(r, date, 17)
    _button(r, "▶", func(): date = store.change_date(date, 1); month_shown = date.substr(0, 7); _render(), true)

func _calendar(parent: Node) -> void:
    var top = _row(parent)
    _button(top, "‹", func(): _shift_month(-1), true)
    _label(top, month_shown, 16)
    _button(top, "›", func(): _shift_month(1), true)
    var grid = GridContainer.new()
    grid.columns = 7
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(grid)
    for name in ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]:
        var cell = _label(grid, name, 12, MUTED)
        cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var first = month_shown + "-01"
    var first_info = Time.get_datetime_dict_from_datetime_string(first + "T12:00:00", true)
    var pad = (int(first_info.get("weekday", 1)) + 6) % 7
    for _i in range(pad):
        _label(grid, "")
    var next_month = _month_offset(month_shown, 1)
    var end_unix = Time.get_unix_time_from_datetime_string(next_month + "-01T12:00:00") - 86400
    var end_day = int(Time.get_datetime_dict_from_unix_time(int(end_unix)).get("day", 28))
    for d in range(1, end_day + 1):
        var value = month_shown + "-" + str(d).pad_zeros(2)
        var recorded = not store.day_entries(value).is_empty() or not store.day_activities(value).is_empty()
        for item in store.data["weights"]:
            if item is Dictionary and str(item.get("date", "")) == value:
                recorded = true
                break
        var selected = value == date
        var label = str(d) + ("•" if recorded else "")
        _button(grid, label, func(): date = value; _render(), not selected)

func _month_offset(month: String, amount: int) -> String:
    var year = int(month.substr(0, 4))
    var m = int(month.substr(5, 2)) + amount
    if m > 12:
        m = 1
        year += 1
    elif m < 1:
        m = 12
        year -= 1
    return str(year) + "-" + str(m).pad_zeros(2)

func _shift_month(delta: int) -> void:
    month_shown = _month_offset(month_shown, delta)
    _render()

func _show_day() -> void:
    var overview = _card("Сегодня · мой дневник")
    _date_nav(overview)
    _calendar(overview)
    var total = store.day_calories(date)
    var target = float(store.data["settings"]["kcal"])
    _label(overview, str(roundi(total)) + " / " + str(roundi(target)) + " ккал", 27, GREEN)
    var bar = ProgressBar.new()
    bar.min_value = 0.0
    bar.max_value = maxf(1.0, target)
    bar.value = minf(total, target)
    bar.show_percentage = false
    bar.custom_minimum_size.y = 18
    overview.add_child(bar)
    _label(overview, "Осталось: " + str(roundi(target - total)) + " ккал", 16)
    _label(overview, "Б " + str(roundi(store.day_macro(date, "p"))) + " г  ·  Ж " + str(roundi(store.day_macro(date, "f"))) + " г  ·  У " + str(roundi(store.day_macro(date, "c"))) + " г", 14, MUTED)
    var walk = 0
    var other = 0
    for a in store.day_activities(date):
        if str(a.get("type", "")) == "walk":
            walk += int(a.get("minutes", 0))
        else:
            other += int(a.get("minutes", 0))
    _label(overview, "🚶 " + str(walk) + " мин ходьбы    🏋 " + str(other) + " мин упражнений", 15)
    var quick = _row(overview)
    _button(quick, "+ Еда", func(): _jump_to_food(), true)
    _button(quick, "+ Спорт", func(): tab = "activity"; _render(), true)
    _button(quick, "+ Вес", func(): tab = "weight"; _render(), true)

    var foods = _card("Что я ела")
    var existing = store.day_entries(date)
    if existing.is_empty():
        _label(foods, "Пока нет записей. Добавь завтрак, обед, перекус или ужин.", 14, MUTED)
    for meal in ["Завтрак", "Обед", "Перекус", "Ужин"]:
        var items = existing.filter(func(e): return str(e.get("meal", "")) == meal)
        if items.is_empty():
            continue
        _label(foods, meal, 16, GREEN)
        for entry in items:
            var f: Dictionary = store.entry_food(entry)
            var r = _row(foods)
            var caption = _label(r, str(f.get("name", "Продукт")) + "\n" + str(entry.get("grams", 0)) + " г · " + str(roundi(store.entry_kcal(entry))) + " ккал", 13)
            caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            _button(r, "✎", func(): _edit_entry(entry), true)
            _button(r, "×", func(): _confirm_delete("Удалить запись питания?", func(): store.data["entries"].erase(entry); store.save(); _render()), true)
    var add = _card("Добавить продукт")
    food_entry_card = add
    _food_form(add)
    var notes_card = _card("Как прошёл день?")
    var notes = TextEdit.new()
    notes.custom_minimum_size.y = 92
    notes.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    notes.placeholder_text = "Был ли голод после работы? Что помогло почувствовать сытость?"
    notes.text = str(store.data["notes"].get(date, ""))
    notes.text_changed.connect(func(): store.data["notes"][date] = notes.text; note_save_timer.start())
    notes_card.add_child(notes)

func _jump_to_food() -> void:
    if is_instance_valid(food_entry_card):
        scroll.ensure_control_visible(food_entry_card)

func _food_form(parent: VBoxContainer) -> void:
    _label(parent, "Продукт")
    var available = store.all_foods()
    var picker = _choice(parent, available.map(func(f): return f.get("name", "")))
    var quantities = _row(parent)
    var grams = _number(quantities, 100, 1, 5000, 1)
    var meal = _choice(quantities, ["Завтрак", "Обед", "Перекус", "Ужин"])
    _button(parent, "Добавить в дневник", func():
        var f: Dictionary = available[picker.selected]
        var snap = {"name": f["name"], "kcal": f["kcal"], "p": f["p"], "f": f["f"], "c": f["c"]}
        store.data["entries"].append({
            "id": str(Time.get_ticks_usec()), "date": date, "food": f["id"],
            "nutrition": snap, "grams": grams.value, "meal": meal.get_item_text(meal.selected)
        })
        store.save()
        _render()
    )

func _edit_entry(entry: Dictionary) -> void:
    var dialog = ConfirmationDialog.new()
    dialog.title = "Изменить запись питания"
    add_child(dialog)
    var fields = VBoxContainer.new()
    dialog.add_child(fields)
    _label(fields, "Продукт")
    var available = store.all_foods()
    var selector = _choice(fields, available.map(func(f): return f.get("name", "")))
    var old_id = str(entry.get("food", ""))
    for i in range(available.size()):
        if str(available[i].get("id", "")) == old_id:
            selector.select(i)
            break
    _label(fields, "Количество, г")
    var grams = _number(fields, float(entry.get("grams", 100)), 1, 5000)
    _label(fields, "Приём пищи")
    var meals = ["Завтрак", "Обед", "Перекус", "Ужин"]
    var meal = _choice(fields, meals)
    var meal_index = meals.find(str(entry.get("meal", "")))
    if meal_index >= 0:
        meal.select(meal_index)
    dialog.confirmed.connect(func():
        var f: Dictionary = available[selector.selected]
        entry["food"] = f["id"]
        entry["nutrition"] = {"name": f["name"], "kcal": f["kcal"], "p": f["p"], "f": f["f"], "c": f["c"]}
        entry["grams"] = grams.value
        entry["meal"] = meals[meal.selected]
        store.save()
        dialog.queue_free()
        _render()
    )
    dialog.canceled.connect(func(): dialog.queue_free())
    dialog.popup_centered(Vector2i(380, 370))

func _show_activity() -> void:
    var card = _card("Прогулки и домашние тренировки")
    _date_nav(card)
    _label(card, "Занятия записываются по датам. Калории тренировок не вычитаются автоматически из питания.", 13, MUTED)
    var kind = _choice(card, ["Ходьба", "Гантели", "Другая активность"])
    _label(card, "Минуты")
    var minutes = _number(card, 30, 1, 1440)
    _label(card, "Километры (для ходьбы, необязательно)")
    var distance = _number(card, 0, 0, 100, 0.1)
    var detail = _text_input(card, "Упражнения, подходы и вес гантелей")
    _button(card, "Сохранить активность", func():
        var activity_kind = ["walk", "strength", "other"][kind.selected]
        store.data["activities"].append({
            "id": str(Time.get_ticks_usec()), "date": date, "type": activity_kind,
            "minutes": minutes.value, "distance": distance.value, "detail": detail.text
        })
        store.save()
        _render()
    )
    var saved = _card("Активность за день")
    var items = store.day_activities(date)
    if items.is_empty():
        _label(saved, "Пока не было записей.", 14, MUTED)
    for a in items:
        var r = _row(saved)
        var type_name = {"walk":"🚶 Ходьба", "strength":"🏋 Гантели", "other":"Активность"}.get(a.get("type", ""), "Активность")
        var text = str(type_name) + " · " + str(a.get("minutes", 0)) + " мин"
        if str(a.get("detail", "")) != "":
            text += "\n" + str(a.get("detail", ""))
        if str(a.get("type", "")) == "walk" and float(a.get("distance", 0)) > 0:
            text += " · " + str(a.get("distance", 0)) + " км"
        var l = _label(r, text, 14)
        l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _button(r, "✎", func(): _edit_activity(a), true)
        _button(r, "×", func(): _confirm_delete("Удалить активность?", func(): store.data["activities"].erase(a); store.save(); _render()), true)

func _edit_activity(activity: Dictionary) -> void:
    var dialog = ConfirmationDialog.new()
    dialog.title = "Изменить активность"
    add_child(dialog)
    var fields = VBoxContainer.new()
    dialog.add_child(fields)
    var kinds = ["Ходьба", "Гантели", "Другая активность"]
    var types = ["walk", "strength", "other"]
    _label(fields, "Вид активности")
    var kind = _choice(fields, kinds)
    var old_kind = types.find(str(activity.get("type", "other")))
    if old_kind >= 0:
        kind.select(old_kind)
    _label(fields, "Продолжительность, мин")
    var minutes = _number(fields, float(activity.get("minutes", 30)), 1, 1440)
    _label(fields, "Расстояние, км")
    var distance = _number(fields, float(activity.get("distance", 0)), 0, 100, 0.1)
    _label(fields, "Заметки")
    var detail = _text_input(fields, "Упражнения и нагрузка", str(activity.get("detail", "")))
    dialog.confirmed.connect(func():
        activity["type"] = types[kind.selected]
        activity["minutes"] = minutes.value
        activity["distance"] = distance.value
        activity["detail"] = detail.text
        store.save()
        dialog.queue_free()
        _render()
    )
    dialog.canceled.connect(func(): dialog.queue_free())
    dialog.popup_centered(Vector2i(390, 440))

func _show_weight() -> void:
    var card = _card("История веса")
    _date_nav(card)
    var settings: Dictionary = store.data["settings"]
    _label(card, "Старт: " + str(settings["start"]) + " кг     Цель: " + str(settings["goal"]) + " кг", 15, MUTED)
    var value = _number(card, float(settings["start"]), 20, 400, 0.1)
    for w in store.data["weights"]:
        if str(w.get("date", "")) == date:
            value.value = float(w.get("value", settings["start"]))
    _button(card, "Записать вес", func():
        store.data["weights"] = store.data["weights"].filter(func(w): return str(w.get("date", "")) != date)
        store.data["weights"].append({"id": "w" + date, "date": date, "value": value.value})
        store.save()
        _render()
    )
    var chart = _card("Как меняется вес")
    var g = GraphScript.new()
    g.custom_minimum_size = Vector2(0, 210)
    g.set_points(store.data["weights"], float(settings["goal"]))
    chart.add_child(g)
    var history = store.data["weights"].duplicate()
    history.sort_custom(func(a,b): return str(a.get("date", "")) > str(b.get("date", "")))
    for w in history:
        var r = _row(chart)
        var l = _label(r, str(w.get("date", "")) + " · " + str(w.get("value", 0)) + " кг", 14)
        l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _button(r, "×", func(): _confirm_delete("Удалить запись веса?", func(): store.data["weights"].erase(w); store.save(); _render()), true)

func _show_stats() -> void:
    var card = _card("Итоги недели")
    _date_nav(card)
    var days = store.week_dates(date)
    var recorded = 0
    var total = 0.0
    var walking = 0
    var workouts = 0
    for d in days:
        if not store.day_entries(d).is_empty():
            recorded += 1
            total += store.day_calories(d)
        for a in store.day_activities(d):
            if a.get("type", "") == "walk":
                walking += int(a.get("minutes", 0))
            elif a.get("type", "") == "strength":
                workouts += 1
    var avg = "—" if recorded == 0 else str(roundi(total / recorded)) + " ккал"
    _label(card, "Среднее за записанные дни: " + avg, 19, GREEN)
    _label(card, "Дней с питанием: " + str(recorded) + " из 7", 15)
    _label(card, "Прогулки: " + str(walking) + " мин    Силовые: " + str(workouts), 15)
    _label(card, "Калории по дням", 16)
    for d in days:
        var line = _row(card)
        var l = _label(line, d.substr(5, 5), 13)
        l.custom_minimum_size.x = 50
        var bar = ProgressBar.new()
        bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        bar.min_value = 0
        bar.max_value = float(store.data["settings"]["kcal"]) * 1.5
        bar.value = store.day_calories(d)
        bar.show_percentage = false
        line.add_child(bar)
        _label(line, str(roundi(store.day_calories(d))) if not store.day_entries(d).is_empty() else "—", 13)
    _label(card, "Пустые дни не входят в среднее. Оценивай тенденцию, а не один день.", 13, MUTED)
    var chart = _card("Вес")
    var g = GraphScript.new()
    g.custom_minimum_size.y = 210
    g.set_points(store.data["weights"], float(store.data["settings"]["goal"]))
    chart.add_child(g)

func _show_settings() -> void:
    var card = _card("Личные настройки")
    _label(card, "Калории в сутки")
    var kcal = _number(card, float(store.data["settings"]["kcal"]), 1000, 5000)
    _label(card, "Вес на старте")
    var start = _number(card, float(store.data["settings"]["start"]), 20, 400, 0.1)
    _label(card, "Моя цель")
    var goal = _number(card, float(store.data["settings"]["goal"]), 20, 400, 0.1)
    _button(card, "Сохранить настройки", func():
        store.data["settings"] = {"kcal": kcal.value, "start": start.value, "goal": goal.value}
        store.save()
        _render()
    )
    var foods_card = _card("Добавить свой продукт · на 100 г")
    var name = _text_input(foods_card, "Название продукта")
    var k = _number(foods_card, 100, 0, 1000, 0.1)
    _label(foods_card, "Белки · Жиры · Углеводы", 13, MUTED)
    var r = _row(foods_card)
    var p = _number(r, 0, 0, 100, 0.1)
    var f = _number(r, 0, 0, 100, 0.1)
    var c = _number(r, 0, 0, 100, 0.1)
    _button(foods_card, "Сохранить продукт", func():
        if name.text.strip_edges().is_empty():
            _message("Введи название продукта")
            return
        store.data["foods"].append({
            "id": "u" + str(Time.get_ticks_usec()), "name": name.text.strip_edges(),
            "kcal": k.value, "p": p.value, "f": f.value, "c": c.value
        })
        store.save()
        _render()
    )
    var backup = _card("Резервная копия и перенос")
    _label(backup, "Можно скопировать JSON в буфер обмена и восстановить его позже. Буфер обмена может быть доступен другим приложениям: не оставляй в нём личные данные.", 13, MUTED)
    _button(backup, "Скопировать резервную копию", func():
        DisplayServer.clipboard_set(store.export_json())
        _message("JSON скопирован. Сохрани его в надёжном месте.")
    )
    _button(backup, "Восстановить JSON из буфера", func():
        var text = DisplayServer.clipboard_get()
        if store.import_json(text):
            date = Time.get_date_string_from_system()
            month_shown = date.substr(0, 7)
            _message("Данные восстановлены")
            _render()
        else:
            _message("Неверная резервная копия JSON.")
    )
    _label(backup, "Записи хранятся в памяти приложения без регистрации и интернета. При удалении приложения данные могут исчезнуть.", 13, MUTED)

func _confirm_delete(prompt: String, action: Callable) -> void:
    var dialog = ConfirmationDialog.new()
    dialog.title = "Подтверждение удаления"
    dialog.dialog_text = prompt
    dialog.ok_button_text = "Удалить"
    add_child(dialog)
    dialog.confirmed.connect(func(): action.call(); dialog.queue_free())
    dialog.canceled.connect(func(): dialog.queue_free())
    dialog.popup_centered(Vector2i(345, 175))

func _message(s: String) -> void:
    var dialog = AcceptDialog.new()
    dialog.title = "Мой баланс"
    dialog.dialog_text = s
    add_child(dialog)
    dialog.confirmed.connect(func(): dialog.queue_free())
    dialog.popup_centered(Vector2i(350, 190))
