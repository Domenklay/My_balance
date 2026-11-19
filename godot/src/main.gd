extends Control

const StoreScript = preload("res://src/store.gd")
const GraphScript = preload("res://src/weight_graph.gd")
const GREEN = Color("#226b55")
const INK = Color("#233c34")
const MUTED = Color("#71877a")
const PALE = Color("#f1f7f3")
const WHITE = Color("#ffffff")
const ACCENT = Color("#e7a948")

var store = StoreScript.new()
var date: String = Time.get_date_string_from_system()
var tab: String = "day"
var month_shown: String = ""
var shell: VBoxContainer
var body: VBoxContainer
var scroll: ScrollContainer
var food_entry_card: VBoxContainer
var note_save_timer: Timer
var calendar_expanded: bool = false
var tab_buttons: Dictionary = {}

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
    _label(title, "🌿 Мой баланс   •   личный дневник", 21, WHITE)
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
    if call.is_valid():
        b.pressed.connect(call)
    parent.add_child(b)
    return b

func _card(title: String) -> VBoxContainer:
    var panel = PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var style = StyleBoxFlat.new()
    style.bg_color = WHITE
    style.set_corner_radius_all(18)
    style.shadow_color = Color(0.12, 0.22, 0.16, 0.08)
    style.shadow_size = 3
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
        var b = _button(row, item[0], func(): tab = target; _render(), true)
        b.custom_minimum_size.y = 48
        b.add_theme_font_size_override("font_size", 13)
        tab_buttons[target] = b
    _update_tabs()

func _update_tabs() -> void:
    for key in tab_buttons:
        var b: Button = tab_buttons[key]
        var active = key == tab
        var box_style = StyleBoxFlat.new()
        box_style.bg_color = GREEN if active else WHITE
        box_style.set_corner_radius_all(12)
        for state in ["normal", "hover", "pressed"]:
            b.add_theme_stylebox_override(state, box_style)
        var color = WHITE if active else MUTED
        for state in ["font_color", "font_hover_color", "font_pressed_color"]:
            b.add_theme_color_override(state, color)

func _metric_tile(parent: Node, value: String, caption: String, tone: Color = GREEN) -> void:
    var panel = PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var style = StyleBoxFlat.new()
    style.bg_color = PALE
    style.set_corner_radius_all(13)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 12
    style.content_margin_bottom = 11
    panel.add_theme_stylebox_override("panel", style)
    parent.add_child(panel)
    var inner = VBoxContainer.new()
    panel.add_child(inner)
    _label(inner, value, 25, tone)
    _label(inner, caption, 12, MUTED)

func _render() -> void:
    _update_tabs()
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
    var overview = _card("Мой день")
    _date_nav(overview)
    _button(overview, "▾  Скрыть календарь" if calendar_expanded else "▸  Открыть календарь", func():
        calendar_expanded = not calendar_expanded
        _render()
    , true)
    if calendar_expanded:
        _calendar(overview)
    var total = store.day_calories(date)
    var target = float(store.data["settings"]["kcal"])
    var stats = _row(overview)
    _metric_tile(stats, str(roundi(total)), "Съедено, ккал")
    _metric_tile(stats, str(roundi(maxf(0.0, target - total))), "Осталось, ккал", ACCENT)
    var bar = ProgressBar.new()
    bar.min_value = 0.0
    bar.max_value = maxf(1.0, target)
    bar.value = minf(total, target)
    bar.show_percentage = false
    bar.custom_minimum_size.y = 16
    overview.add_child(bar)
    if total > target:
        _label(overview, "Сверх ориентира: " + str(roundi(total - target)) + " ккал", 14, MUTED)
    _label(overview, "Б: " + str(roundi(store.day_macro(date, "p"))) + " г     Ж: " + str(roundi(store.day_macro(date, "f"))) + " г     У: " + str(roundi(store.day_macro(date, "c"))) + " г", 14, MUTED)
    var walking = 0
    var exercise = 0
    for a in store.day_activities(date):
        if str(a.get("type", "")) == "walk":
            walking += int(a.get("minutes", 0))
        else:
            exercise += int(a.get("minutes", 0))
    var activity_stats = _row(overview)
    _metric_tile(activity_stats, str(walking) + " мин", "Прогулки")
    _metric_tile(activity_stats, str(exercise) + " мин", "Тренировки")
    var shortcuts = _row(overview)
    _button(shortcuts, "+ Еда", func(): _jump_to_food())
    _button(shortcuts, "+ Спорт", func(): tab = "activity"; _render(), true)
    _button(shortcuts, "+ Вес", func(): tab = "weight"; _render(), true)

    var add = _card("Быстро добавить еду")
    food_entry_card = add
    _food_form(add)

    var foods = _card("Дневник питания")
    var existing = store.day_entries(date)
    if existing.is_empty():
        _label(foods, "Сегодня ещё нет записей. Выбери продукт выше или повтори блюдо со вчера.", 14, MUTED)
    for meal in ["Завтрак", "Обед", "Перекус", "Ужин"]:
        var items = existing.filter(func(e): return str(e.get("meal", "")) == meal)
        if items.is_empty():
            continue
        _label(foods, meal, 17, GREEN)
        for entry in items:
            var f: Dictionary = store.entry_food(entry)
            var r = _row(foods)
            var caption = _label(r, str(f.get("name", "Продукт")) + "\n" + str(entry.get("grams", 0)) + " г • " + str(roundi(store.entry_kcal(entry))) + " ккал", 14)
            caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            _button(r, "✎", func(): _edit_entry(entry), true)
            _button(r, "×", func(): _confirm_delete("Удалить запись питания?", func(): store.data["entries"].erase(entry); store.save(); _render()), true)

    var yesterday = store.change_date(date, -1)
    var previous = store.day_entries(yesterday)
    if not previous.is_empty():
        var repeats = _card("Повторить со вчера · " + yesterday)
        _label(repeats, "Нажми «+», чтобы добавить такую же порцию на выбранный день.", 13, MUTED)
        var count = 0
        for old in previous:
            if count >= 8:
                break
            count += 1
            var old_food = store.entry_food(old)
            var rr = _row(repeats)
            var rl = _label(rr, str(old_food.get("name", "Продукт")) + " • " + str(old.get("grams", 0)) + " г", 13)
            rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            _button(rr, "+", func():
                if store.repeat_entry(old, date):
                    _render()
                else:
                    _message("Не удалось повторить запись. Проверь сохранение.")
            )

    var notes_card = _card("Заметка о дне")
    var notes = TextEdit.new()
    notes.custom_minimum_size.y = 92
    notes.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    notes.placeholder_text = "Как прошёл день? Голод, настроение, самочувствие…"
    notes.text = str(store.data["notes"].get(date, ""))
    notes.text_changed.connect(func():
        store.data["notes"][date] = notes.text
        note_save_timer.start()
    )
    notes_card.add_child(notes)

func _jump_to_food() -> void:
    if is_instance_valid(food_entry_card):
        scroll.ensure_control_visible(food_entry_card)

func _food_form(parent: VBoxContainer) -> void:
    var filtered: Array = []
    var search = _text_input(parent, "Поиск продукта по названию")
    search.clear_button_enabled = true
    var favorite_only = CheckButton.new()
    favorite_only.text = "Только избранные"
    parent.add_child(favorite_only)
    var picker = _choice(parent, [])
    var values = _row(parent)
    _label(values, "Граммы", 13, MUTED)
    var grams = _number(values, 100, 1, 5000)
    var meal = _choice(parent, ["Завтрак", "Обед", "Перекус", "Ужин"])
    var preview = _label(parent, "", 14, MUTED)
    var controls = _row(parent)
    var star = _button(controls, "☆ В избранное", Callable(), true)
    star.pressed.connect(func():
        if picker.selected < 0 or picker.selected >= filtered.size():
            return
        var food: Dictionary = filtered[picker.selected]
        if store.toggle_favorite(str(food.get("id", ""))):
            _refresh_food_picker(picker, search, favorite_only, filtered, grams, preview, star)
        else:
            _message("Не удалось сохранить избранное.")
    )
    _button(controls, "+ Добавить", func():
        if picker.selected < 0 or picker.selected >= filtered.size():
            _message("Выбери продукт. При необходимости отключи фильтр избранного.")
            return
        var f: Dictionary = filtered[picker.selected]
        var snap = {"name": f["name"], "kcal": f["kcal"], "p": f["p"], "f": f["f"], "c": f["c"]}
        store.data["entries"].append({
            "id": str(Time.get_ticks_usec()) + "_" + str(store.data["entries"].size()),
            "date": date, "food": f["id"], "nutrition": snap,
            "grams": grams.value, "meal": meal.get_item_text(meal.selected)
        })
        if not store.save():
            _message("Ошибка сохранения. Проверь свободное место на устройстве.")
        _render()
    )
    search.text_changed.connect(func(_value: String):
        _refresh_food_picker(picker, search, favorite_only, filtered, grams, preview, star)
    )
    favorite_only.toggled.connect(func(_value: bool):
        _refresh_food_picker(picker, search, favorite_only, filtered, grams, preview, star)
    )
    picker.item_selected.connect(func(_value: int):
        _update_food_preview(picker, filtered, grams, preview, star)
    )
    grams.value_changed.connect(func(_value: float):
        _update_food_preview(picker, filtered, grams, preview, star)
    )
    _refresh_food_picker(picker, search, favorite_only, filtered, grams, preview, star)

func _refresh_food_picker(picker: OptionButton, search: LineEdit, favorite_only: CheckButton,
        filtered: Array, grams: SpinBox, preview: Label, star: Button) -> void:
    var previous_id = ""
    if picker.selected >= 0 and picker.selected < filtered.size():
        previous_id = str(filtered[picker.selected].get("id", ""))
    filtered.clear()
    var all = store.all_foods()
    all.sort_custom(func(a, b):
        var a_favorite = store.is_favorite(str(a.get("id", "")))
        var b_favorite = store.is_favorite(str(b.get("id", "")))
        if a_favorite != b_favorite:
            return a_favorite
        return str(a.get("name", "")).nocasecmp_to(str(b.get("name", ""))) < 0
    )
    var query = search.text.strip_edges().to_lower()
    for item in all:
        if not query.is_empty() and not str(item.get("name", "")).to_lower().contains(query):
            continue
        if favorite_only.button_pressed and not store.is_favorite(str(item.get("id", ""))):
            continue
        filtered.append(item)
    picker.clear()
    var selection = 0
    for i in range(filtered.size()):
        var f: Dictionary = filtered[i]
        var id = str(f.get("id", ""))
        var label = ("★ " if store.is_favorite(id) else "") + str(f.get("name", "Продукт"))
        picker.add_item(label)
        if id == previous_id:
            selection = i
    if not filtered.is_empty():
        picker.select(selection)
    _update_food_preview(picker, filtered, grams, preview, star)

func _update_food_preview(picker: OptionButton, filtered: Array, grams: SpinBox,
        preview: Label, star: Button) -> void:
    if picker.selected < 0 or picker.selected >= filtered.size():
        preview.text = "Нет подходящих продуктов."
        star.text = "☆ В избранное"
        star.disabled = true
        return
    var f: Dictionary = filtered[picker.selected]
    var amount = grams.value / 100.0
    preview.text = str(roundi(float(f.get("kcal", 0)) * amount)) + " ккал  •  Б " + str(snappedf(float(f.get("p", 0)) * amount, 0.1)) + "  Ж " + str(snappedf(float(f.get("f", 0)) * amount, 0.1)) + "  У " + str(snappedf(float(f.get("c", 0)) * amount, 0.1))
    star.disabled = false
    star.text = "★ В избранном" if store.is_favorite(str(f.get("id", ""))) else "☆ В избранное"

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
    _label(backup, "Сохрани файл JSON вне приложения, чтобы восстановить данные после удаления или переустановки.", 13, MUTED)
    _button(backup, "Сохранить JSON в файл", func(): _pick_backup_file(true))
    _button(backup, "Импортировать JSON из файла", func(): _pick_backup_file(false), true)
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

func _pick_backup_file(exporting: bool) -> void:
    var picker = FileDialog.new()
    picker.use_native_dialog = true
    picker.access = FileDialog.ACCESS_FILESYSTEM
    picker.file_mode = FileDialog.FILE_MODE_SAVE_FILE if exporting else FileDialog.FILE_MODE_OPEN_FILE
    picker.filters = PackedStringArray(["*.json;Резервная копия;application/json"])
    if exporting:
        picker.current_file = "MyBalance-" + Time.get_date_string_from_system() + ".json"
    add_child(picker)
    picker.file_selected.connect(func(path: String):
        if exporting:
            _write_backup_file(path)
        else:
            _read_backup_file(path)
        picker.queue_free()
    )
    picker.canceled.connect(func(): picker.queue_free())
    picker.popup_file_dialog()

func _write_backup_file(path: String) -> void:
    var file = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        _message("Не удалось открыть файл для сохранения. Выбери другое расположение.")
        return
    file.store_string(store.export_json())
    file.flush()
    var status = file.get_error()
    file.close()
    if status == OK:
        _message("Резервная копия сохранена. Храни её вне приложения.")
    else:
        _message("Ошибка записи резервной копии: " + str(status))

func _read_backup_file(path: String) -> void:
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        _message("Не удалось открыть JSON-файл.")
        return
    if file.get_length() > 5000000:
        file.close()
        _message("Размер резервной копии превышает 5 МБ.")
        return
    var raw = file.get_as_text()
    file.close()
    var confirmation = ConfirmationDialog.new()
    confirmation.title = "Восстановление данных"
    confirmation.dialog_text = "Заменить текущие записи данными из файла? Перед импортом сохрани резервную копию."
    add_child(confirmation)
    confirmation.confirmed.connect(func():
        if store.import_json(raw):
            date = Time.get_date_string_from_system()
            month_shown = date.substr(0, 7)
            _render()
            _message("Дневник восстановлен из JSON.")
        else:
            _message("Файл повреждён или несовместим.")
        confirmation.queue_free()
    )
    confirmation.canceled.connect(func(): confirmation.queue_free())
    confirmation.popup_centered(Vector2i(365, 210))

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
