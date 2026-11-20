extends Control

const StoreScript = preload("res://src/store.gd")
const GraphScript = preload("res://src/weight_graph.gd")
const RingScript = preload("res://src/calorie_ring.gd")
const RecipeMath = preload("res://src/recipe_math.gd")
const BarcodeScript = preload("res://src/barcode_lookup.gd")
const AppearanceScript = preload("res://src/appearance.gd")
const PatternScript = preload("res://src/theme_pattern.gd")
var GREEN: Color = Color("#195b4a")
var DEEP: Color = Color("#123f36")
var MINT: Color = Color("#cdebd8")
var INK: Color = Color("#263a32")
var MUTED: Color = Color("#678376")
var PALE: Color = Color("#f2f7f2")
var WHITE: Color = Color("#ffffff")
var ACCENT: Color = Color("#bf7e43")
var SOFT_GOLD: Color = Color("#f8e8c9")
var INPUT_BG: Color = Color("#fbfdfb")
var BORDER: Color = Color("#dfeae1")
var SECONDARY: Color = Color("#e8f3e9")

var BACKGROUND: Color = Color("#f0f6f1")
var CARD_BG: Color = Color("#ffffff")
var HERO_BG: Color = Color("#123f36")
var TINT_BG: Color = Color("#eaf5e9")
var ROW_BG: Color = Color("#f4f9f4")
var HEADER_BG: Color = Color("#123f36")
var HEADER_MUTED: Color = Color("#c8e4d4")
var LOGO_BG: Color = Color("#2e7160")
var TEXT_ACCENT: Color = Color("#195b4a")
var HERO_MUTED: Color = Color("#d5e7d9")
var CHIP_BG: Color = Color("#286453")
var CHIP_CAPTION: Color = Color("#cee4d6")
var HERO_TRACK: Color = Color("#3d7967")
var HERO_FILL: Color = Color("#deebbd")
var MACRO_PROTEIN: Color = Color("#d7f4d7")
var MACRO_FAT: Color = Color("#f2d49d")
var MACRO_CARBS: Color = Color("#d3e5fa")
var CHART_GRID: Color = Color("#e2ece5")
var CHART_AREA: Color = Color("#dcefe4")
var PATTERN_COLOR: Color = Color("#6da48b")
var PATTERN_STYLE: String = "leaves"
var PATTERNS: bool = true
var DARK_MODE: bool = false
var current_theme: String = "forest"
var background_rect: ColorRect
var wallpaper_pattern: Control
var header_panel: PanelContainer
var header_pattern: Control
var header_title: Label
var header_subtitle: Label
var emblem_panel: PanelContainer
var emblem_label: Label

var store = StoreScript.new()
var date: String = Time.get_date_string_from_system()
var tab: String = "day"
var month_shown: String = ""
var shell: VBoxContainer
var body: VBoxContainer
var scroll: ScrollContainer
var food_entry_card: VBoxContainer
var note_save_timer: Timer
var note_status_label: Label
var calendar_expanded: bool = false
var food_form_expanded: bool = false
var settings_page: String = "main"
var recipe_editor_open: bool = false
var profile_edit_open: bool = false
var recipe_draft: Dictionary = {}
var recipe_search_text: String = ""
var recipe_list_query: String = ""
var recipe_manual_open: bool = false
var _rendered_view: String = ""
var _scroll_memory: Dictionary = {}
var _render_serial: int = 0
var tab_buttons: Dictionary = {}
var barcode_http: HTTPRequest
var catalog_http: HTTPRequest
var diary_food_card: VBoxContainer
var barcode_scanner: Object = null
var barcode_input: LineEdit
var barcode_message: Label
var pending_barcode: String = ""
var selected_barcode_food: String = ""
var _swipe_target: ScrollContainer = null
var _swipe_index: int = -1
var _swipe_start: Vector2 = Vector2.ZERO
var _swipe_last: Vector2 = Vector2.ZERO
var _swipe_dragging: bool = false
var _swipe_ignore_button_release: bool = false
var toast_panel: PanelContainer
var toast_label: Label
var toast_timer: Timer

func _apply_palette() -> void:
    var config: Dictionary = store.data.get("settings", {})
    current_theme = str(config.get("theme", "forest"))
    if not AppearanceScript.is_valid_theme(current_theme):
        current_theme = "forest"
    PATTERNS = bool(config.get("patterns", true))
    DARK_MODE = current_theme == "dark"
    var palette: Dictionary = AppearanceScript.palette(current_theme)
    GREEN = Color(str(palette["green"]))
    DEEP = Color(str(palette["deep"]))
    INK = Color(str(palette["ink"]))
    MUTED = Color(str(palette["muted"]))
    PALE = Color(str(palette["pale"]))
    ACCENT = Color(str(palette["accent"]))
    SOFT_GOLD = Color(str(palette["gold"]))
    INPUT_BG = Color(str(palette["input"]))
    BORDER = Color(str(palette["border"]))
    SECONDARY = Color(str(palette["secondary"]))
    BACKGROUND = Color(str(palette["background"]))
    CARD_BG = Color(str(palette["surface"]))
    TINT_BG = Color(str(palette["tint"]))
    ROW_BG = Color(str(palette["row"]))
    HEADER_BG = Color(str(palette["header"]))
    HEADER_MUTED = Color(str(palette["head_muted"]))
    LOGO_BG = Color(str(palette["icon"]))
    HERO_BG = Color(str(palette["hero"]))
    HERO_MUTED = Color(str(palette["hero_muted"]))
    CHIP_BG = Color(str(palette["chip"]))
    CHIP_CAPTION = Color(str(palette["hero_muted"]))
    HERO_TRACK = Color(str(palette["track"]))
    HERO_FILL = Color(str(palette["fill"]))
    MINT = HERO_FILL
    TEXT_ACCENT = Color(str(palette["text_accent"]))
    MACRO_PROTEIN = Color(str(palette["protein"]))
    MACRO_FAT = Color(str(palette["fat"]))
    MACRO_CARBS = Color(str(palette["carbs"]))
    CHART_GRID = Color(str(palette["grid"]))
    CHART_AREA = Color(str(palette["area"]))
    PATTERN_STYLE = str(palette["pattern"])
    PATTERN_COLOR = Color(str(palette["pattern_color"]))

func _refresh_appearance() -> void:
    _apply_palette()
    if is_instance_valid(background_rect):
        background_rect.color = BACKGROUND
    if is_instance_valid(wallpaper_pattern):
        wallpaper_pattern.configure(PATTERN_STYLE, PATTERN_COLOR, PATTERNS, 0.11 if DARK_MODE else 0.09)
    if is_instance_valid(header_panel):
        var header_style = header_panel.get_theme_stylebox("panel") as StyleBoxFlat
        if header_style != null:
            header_style.bg_color = HEADER_BG
    if is_instance_valid(header_pattern):
        header_pattern.configure(PATTERN_STYLE, PATTERN_COLOR, PATTERNS, 0.12)
    if is_instance_valid(header_subtitle):
        header_subtitle.add_theme_color_override("font_color", HEADER_MUTED)
    if is_instance_valid(emblem_panel):
        var symbol_style = emblem_panel.get_theme_stylebox("panel") as StyleBoxFlat
        if symbol_style != null:
            symbol_style.bg_color = LOGO_BG
    if is_instance_valid(emblem_label):
        emblem_label.add_theme_color_override("font_color", SOFT_GOLD)
    if is_instance_valid(shell):
        var navigation = shell.get_node_or_null("BottomNavigation") as PanelContainer
        if navigation != null:
            var nav_style = navigation.get_theme_stylebox("panel") as StyleBoxFlat
            if nav_style != null:
                nav_style.bg_color = CARD_BG
                nav_style.border_color = BORDER
    if is_instance_valid(toast_panel):
        var toast_style = toast_panel.get_theme_stylebox("panel") as StyleBoxFlat
        if toast_style != null:
            toast_style.bg_color = GREEN
    _update_tabs()

func _choose_theme(id: String) -> void:
    if not AppearanceScript.is_valid_theme(id):
        return
    var previous = str(store.data["settings"].get("theme", "forest"))
    if previous == id:
        return
    _hide_keyboard_and_focus()
    store.data["settings"]["theme"] = id
    if not store.save():
        store.data["settings"]["theme"] = previous
        _message("Не удалось сохранить тему. Прежнее оформление оставлено.")
        return
    _refresh_appearance()
    _render()
    _notify_saved("Тема: " + AppearanceScript.name_for(id))

func _toggle_patterns() -> void:
    var previous = bool(store.data["settings"].get("patterns", true))
    store.data["settings"]["patterns"] = not previous
    if not store.save():
        store.data["settings"]["patterns"] = previous
        _message("Не удалось сохранить настройку узоров.")
        return
    _refresh_appearance()
    _render()
    _notify_saved("Узоры включены" if not previous else "Узоры выключены")

func _ready() -> void:
    _apply_palette()
    month_shown = date.substr(0, 7)
    barcode_http = HTTPRequest.new()
    barcode_http.timeout = 15.0
    add_child(barcode_http)
    barcode_http.request_completed.connect(_on_barcode_http_completed)
    catalog_http = HTTPRequest.new()
    catalog_http.timeout = 25.0
    add_child(catalog_http)
    catalog_http.request_completed.connect(_on_catalog_http_completed)
    if OS.has_feature("android") and Engine.has_singleton("MyBalanceBarcode"):
        barcode_scanner = Engine.get_singleton("MyBalanceBarcode")
        if barcode_scanner.has_signal("barcode_scanned"):
            barcode_scanner.connect("barcode_scanned", Callable(self, "_on_barcode_scanned"))
        if barcode_scanner.has_signal("barcode_error"):
            barcode_scanner.connect("barcode_error", Callable(self, "_on_barcode_scan_error"))
        if barcode_scanner.has_signal("barcode_cancelled"):
            barcode_scanner.connect("barcode_cancelled", Callable(self, "_on_barcode_scan_cancelled"))
    background_rect = ColorRect.new()
    background_rect.color = BACKGROUND
    background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background_rect)
    wallpaper_pattern = PatternScript.new()
    wallpaper_pattern.name = "WallpaperPattern"
    wallpaper_pattern.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    wallpaper_pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
    wallpaper_pattern.configure(PATTERN_STYLE, PATTERN_COLOR, PATTERNS, 0.11 if DARK_MODE else 0.09)
    add_child(wallpaper_pattern)
    shell = VBoxContainer.new()
    shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shell.add_theme_constant_override("separation", 0)
    add_child(shell)
    header_panel = PanelContainer.new()
    header_panel.name = "AppHeader"
    var head_style = StyleBoxFlat.new()
    head_style.bg_color = HEADER_BG
    head_style.content_margin_left = 21
    head_style.content_margin_right = 19
    head_style.content_margin_top = 14
    head_style.content_margin_bottom = 16
    header_panel.add_theme_stylebox_override("panel", head_style)
    shell.add_child(header_panel)
    header_pattern = PatternScript.new()
    header_pattern.mouse_filter = Control.MOUSE_FILTER_IGNORE
    header_pattern.configure(PATTERN_STYLE, PATTERN_COLOR, PATTERNS, 0.10)
    header_panel.add_child(header_pattern)
    var heading = HBoxContainer.new()
    heading.add_theme_constant_override("separation", 8)
    header_panel.add_child(heading)
    var brand = VBoxContainer.new()
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    brand.add_theme_constant_override("separation", 3)
    heading.add_child(brand)
    header_title = _label(brand, "Мой баланс", 25, WHITE)
    header_subtitle = _label(brand, "Забота о себе каждый день", 12, HEADER_MUTED)
    emblem_panel = PanelContainer.new()
    emblem_panel.custom_minimum_size = Vector2(46, 46)
    var logo_style = StyleBoxFlat.new()
    logo_style.bg_color = LOGO_BG
    logo_style.set_corner_radius_all(15)
    logo_style.content_margin_left = 11
    logo_style.content_margin_right = 11
    logo_style.content_margin_top = 7
    logo_style.content_margin_bottom = 5
    emblem_panel.add_theme_stylebox_override("panel", logo_style)
    heading.add_child(emblem_panel)
    emblem_label = _label(emblem_panel, "✦", 26, SOFT_GOLD)
    emblem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    emblem_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.scroll_deadzone = 12
    scroll.follow_focus = true
    scroll.mouse_filter = Control.MOUSE_FILTER_STOP
    shell.add_child(scroll)
    body = VBoxContainer.new()
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 13)
    var margins = MarginContainer.new()
    margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    margins.mouse_filter = Control.MOUSE_FILTER_PASS
    body.mouse_filter = Control.MOUSE_FILTER_PASS
    margins.add_theme_constant_override("margin_left", 14)
    margins.add_theme_constant_override("margin_right", 14)
    margins.add_theme_constant_override("margin_top", 14)
    margins.add_theme_constant_override("margin_bottom", 22)
    scroll.add_child(margins)
    margins.add_child(body)
    note_save_timer = Timer.new()
    note_save_timer.wait_time = 0.6
    note_save_timer.one_shot = true
    note_save_timer.timeout.connect(func():
        if store.save():
            if is_instance_valid(note_status_label):
                note_status_label.text = "✓  Заметка сохранена"
        else:
            if is_instance_valid(note_status_label):
                note_status_label.text = "Не удалось сохранить заметку"
            _message("Не удалось сохранить заметку. Сохрани резервную копию дневника.")
    )
    add_child(note_save_timer)
    _make_tabs()
    _setup_toast()
    _render()

func _setup_toast() -> void:
    toast_panel = PanelContainer.new()
    toast_panel.name = "SaveStatus"
    toast_panel.visible = false
    toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    toast_panel.z_index = 40
    toast_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    toast_panel.offset_left = 18.0
    toast_panel.offset_right = -18.0
    toast_panel.offset_top = 83.0
    toast_panel.offset_bottom = 128.0
    var style = StyleBoxFlat.new()
    style.bg_color = GREEN
    style.set_corner_radius_all(12)
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
    style.shadow_size = 6
    style.content_margin_left = 14
    style.content_margin_right = 14
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    toast_panel.add_theme_stylebox_override("panel", style)
    add_child(toast_panel)
    toast_label = Label.new()
    toast_label.name = "SaveStatusText"
    toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    toast_label.add_theme_color_override("font_color", WHITE)
    toast_label.add_theme_font_size_override("font_size", 14)
    toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_panel.add_child(toast_label)
    toast_timer = Timer.new()
    toast_timer.one_shot = true
    toast_timer.wait_time = 2.7
    toast_timer.timeout.connect(func(): toast_panel.visible = false)
    add_child(toast_timer)

func _notify_saved(value: String) -> void:
    if not is_instance_valid(toast_panel):
        return
    toast_label.text = "✓  " + value
    toast_panel.visible = true
    toast_timer.start()

func _hide_keyboard_and_focus() -> void:
    var focused = get_viewport().gui_get_focus_owner()
    if focused is LineEdit or focused is TextEdit:
        focused.release_focus()
    DisplayServer.virtual_keyboard_hide()

func _ensure_field_visible(field: Control) -> void:
    # Re-measure after Android IME/focus changes the available viewport.
    await get_tree().process_frame
    await get_tree().process_frame
    if not is_instance_valid(field) or not field.is_inside_tree():
        return
    var ancestor = field.get_parent()
    while ancestor != null:
        if ancestor is ScrollContainer:
            ancestor.ensure_control_visible(field)
            return
        ancestor = ancestor.get_parent()

func _bind_field_focus(field: Control) -> void:
    field.focus_entered.connect(func(): _ensure_field_visible(field))

func _navigate_to_tab(target: String) -> void:
    _hide_keyboard_and_focus()
    if target == "settings" and tab == "settings" and settings_page == "foods":
        settings_page = "main"
    tab = target
    _render()

func _input(event: InputEvent) -> void:
    # Android can lose ScrollContainer touch drags when a nested control
    # consumes them (buttons, product selectors, text fields). Capture only
    # genuine vertical swipes, not taps, and scroll the active visible panel.
    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed:
            if _swipe_index >= 0:
                return
            _swipe_target = _scroll_target_at(touch.position)
            _swipe_index = touch.index if _swipe_target != null else -1
            _swipe_start = touch.position
            _swipe_last = touch.position
            _swipe_dragging = false
        elif touch.index == _swipe_index:
            if _swipe_dragging:
                _swipe_ignore_button_release = true
                get_viewport().set_input_as_handled()
                call_deferred("_end_swipe_release_guard")
            _swipe_index = -1
            _swipe_target = null
            _swipe_dragging = false
        return

    if event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event
        if drag.index != _swipe_index or not is_instance_valid(_swipe_target):
            return
        var overall = drag.position - _swipe_start
        if not _swipe_dragging:
            if absf(overall.y) <= 12.0 or absf(overall.y) < absf(overall.x) * 1.2:
                _swipe_last = drag.position
                return
            _swipe_dragging = true
        var delta_y = drag.position.y - _swipe_last.y
        _swipe_last = drag.position
        var max_scroll = _swipe_target.get_v_scroll_bar().max_value - _swipe_target.get_v_scroll_bar().page
        _swipe_target.scroll_vertical = clampi(
            _swipe_target.scroll_vertical - roundi(delta_y),
            0, maxi(0, roundi(max_scroll)))
        get_viewport().set_input_as_handled()

func _end_swipe_release_guard() -> void:
    _swipe_ignore_button_release = false

func _scroll_target_at(point: Vector2) -> ScrollContainer:
    var product_sheet = get_node_or_null("ProductSheet")
    if product_sheet != null:
        var containers = product_sheet.find_children("*", "ScrollContainer", true, false)
        for candidate in containers:
            var popup_scroll: ScrollContainer = candidate
            if popup_scroll.get_global_rect().has_point(point):
                return popup_scroll
        return null
    if not is_instance_valid(scroll) or not scroll.get_global_rect().has_point(point):
        return null
    return scroll

func _exit_tree() -> void:
    if note_save_timer != null and not note_save_timer.is_stopped():
        store.save()

func _label(parent: Node, s: String, size: int = 16, color: Color = Color("#263a32")) -> Label:
    if color == Color("#263a32"):
        color = INK
    var l = Label.new()
    l.text = s
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(l)
    return l

func _nowrap(parent: Node, value: String, font_size: int = 16, color: Color = Color("#263a32")) -> Label:
    var l = _label(parent, value, font_size, color)
    l.autowrap_mode = TextServer.AUTOWRAP_OFF
    l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    return l

func _row(parent: Node) -> HBoxContainer:
    var r = HBoxContainer.new()
    r.mouse_filter = Control.MOUSE_FILTER_PASS
    r.add_theme_constant_override("separation", 8)
    parent.add_child(r)
    return r

func _input_style() -> StyleBoxFlat:
    var st = StyleBoxFlat.new()
    st.bg_color = INPUT_BG
    st.border_color = BORDER
    st.set_border_width_all(1)
    st.set_corner_radius_all(13)
    st.content_margin_left = 12
    st.content_margin_right = 12
    st.content_margin_top = 11
    st.content_margin_bottom = 11
    return st

func _input_focus_style() -> StyleBoxFlat:
    var st = StyleBoxFlat.new()
    st.bg_color = Color(0, 0, 0, 0)
    st.border_color = GREEN
    st.set_border_width_all(2)
    st.set_corner_radius_all(11)
    return st

func _style_field(control: Control) -> void:
    # Preserve native editing but let swipe gestures bubble to the scroll view.
    control.mouse_filter = Control.MOUSE_FILTER_PASS
    control.add_theme_stylebox_override("normal", _input_style())
    control.add_theme_stylebox_override("focus", _input_focus_style())
    control.add_theme_color_override("font_color", INK)
    control.add_theme_color_override("font_placeholder_color", MUTED)
    control.add_theme_color_override("font_selected_color", WHITE)
    control.add_theme_color_override("selection_color", GREEN)

func _button(parent: Node, s: String, call: Callable, secondary: bool = false) -> Button:
    var b = Button.new()
    b.text = s
    # Let a swipe begun over a button reach the parent ScrollContainer.
    b.mouse_filter = Control.MOUSE_FILTER_PASS
    var compact = s in ["◀", "▶", "‹", "›", "✎", "×", "+"]
    b.custom_minimum_size = Vector2(46 if compact else 0, 47)
    b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if compact else Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 14)
    for mode in ["normal", "hover", "pressed"]:
        var st = StyleBoxFlat.new()
        st.bg_color = (SECONDARY if secondary else GREEN)
        if mode == "hover":
            st.bg_color = SECONDARY.lightened(0.06) if secondary else GREEN.lightened(0.09)
        elif mode == "pressed":
            st.bg_color = SECONDARY.darkened(0.05) if secondary else GREEN.darkened(0.07)
        st.set_corner_radius_all(13)
        st.content_margin_left = 10
        st.content_margin_right = 10
        st.content_margin_top = 7
        st.content_margin_bottom = 7
        b.add_theme_stylebox_override(mode, st)
    b.add_theme_color_override("font_color", INK if secondary and DARK_MODE else (TEXT_ACCENT if secondary else WHITE))
    b.add_theme_color_override("font_hover_color", INK if secondary and DARK_MODE else (TEXT_ACCENT if secondary else WHITE))
    b.add_theme_color_override("font_pressed_color", INK if secondary and DARK_MODE else (TEXT_ACCENT if secondary else WHITE))
    b.add_theme_color_override("font_disabled_color", MUTED)
    if call.is_valid():
        b.pressed.connect(func():
            if not _swipe_dragging and not _swipe_ignore_button_release:
                call.call()
        )
    parent.add_child(b)
    return b

func _card(title: String, variant: String = "plain") -> VBoxContainer:
    var panel = PanelContainer.new()
    panel.mouse_filter = Control.MOUSE_FILTER_PASS
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var style = StyleBoxFlat.new()
    style.bg_color = HERO_BG if variant == "hero" else (TINT_BG if variant == "tint" else CARD_BG)
    style.set_corner_radius_all(22)
    style.border_color = BORDER if variant == "plain" else style.bg_color
    style.set_border_width_all(1)
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.13 if DARK_MODE else 0.08)
    style.shadow_size = 5 if variant == "hero" else 3
    style.shadow_offset = Vector2(0, 3)
    style.content_margin_left = 17
    style.content_margin_right = 17
    style.content_margin_top = 17
    style.content_margin_bottom = 17
    panel.add_theme_stylebox_override("panel", style)
    body.add_child(panel)
    if PATTERNS and variant in ["hero", "tint"]:
        var ornament = PatternScript.new()
        ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
        ornament.configure(PATTERN_STYLE, PATTERN_COLOR, true, 0.13 if variant == "hero" else 0.07)
        panel.add_child(ornament)
    var content = VBoxContainer.new()
    content.mouse_filter = Control.MOUSE_FILTER_PASS
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 11)
    panel.add_child(content)
    if not title.is_empty():
        _label(content, title, 18, WHITE if variant == "hero" else INK)
    return content

func _macro_chip(parent: Node, caption: String, value: float, tint: Color) -> void:
    var panel = PanelContainer.new()
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var style = StyleBoxFlat.new()
    style.bg_color = CHIP_BG
    style.set_corner_radius_all(12)
    style.content_margin_left = 9
    style.content_margin_right = 7
    style.content_margin_top = 9
    style.content_margin_bottom = 9
    panel.add_theme_stylebox_override("panel", style)
    parent.add_child(panel)
    var content = VBoxContainer.new()
    content.add_theme_constant_override("separation", 3)
    panel.add_child(content)
    _label(content, caption, 11, CHIP_CAPTION)
    _label(content, str(roundi(value)) + " г", 19, tint)


func _soft_list_row(parent: Node) -> HBoxContainer:
    var panel = PanelContainer.new()
    panel.mouse_filter = Control.MOUSE_FILTER_PASS
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var st = StyleBoxFlat.new()
    st.bg_color = ROW_BG
    st.set_corner_radius_all(13)
    st.content_margin_left = 10
    st.content_margin_right = 8
    st.content_margin_top = 8
    st.content_margin_bottom = 8
    panel.add_theme_stylebox_override("panel", st)
    parent.add_child(panel)
    var row = HBoxContainer.new()
    row.mouse_filter = Control.MOUSE_FILTER_PASS
    row.add_theme_constant_override("separation", 7)
    panel.add_child(row)
    return row

func _number(parent: Node, value: float, minimum: float, maximum: float, step: float = 1.0) -> SpinBox:
    var spin = SpinBox.new()
    spin.min_value = minimum
    spin.max_value = maximum
    spin.step = step
    spin.value = value
    spin.custom_minimum_size = Vector2(92, 48)
    spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    spin.mouse_filter = Control.MOUSE_FILTER_PASS
    spin.add_theme_font_size_override("font_size", 16)
    var line_editor = spin.get_line_edit()
    _style_field(line_editor)
    line_editor.text_submitted.connect(func(_text: String): _hide_keyboard_and_focus())
    _bind_field_focus(line_editor)
    parent.add_child(spin)
    return spin

func _text_input(parent: Node, placeholder: String, text: String = "") -> LineEdit:
    var field = LineEdit.new()
    field.placeholder_text = placeholder
    field.text = text
    field.custom_minimum_size = Vector2(100, 48)
    field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    field.mouse_filter = Control.MOUSE_FILTER_PASS
    field.add_theme_font_size_override("font_size", 15)
    _style_field(field)
    field.text_submitted.connect(func(_text: String): _hide_keyboard_and_focus())
    _bind_field_focus(field)
    parent.add_child(field)
    return field

func _choice(parent: Node, options: Array) -> OptionButton:
    var picker = OptionButton.new()
    # Large food catalog entries must never dictate the width of the phone UI.
    picker.fit_to_longest_item = false
    picker.clip_text = true
    picker.custom_minimum_size = Vector2(105, 48)
    picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    picker.mouse_filter = Control.MOUSE_FILTER_PASS
    picker.add_theme_font_size_override("font_size", 15)
    for mode in ["normal", "hover", "pressed"]:
        picker.add_theme_stylebox_override(mode, _input_style())
    picker.add_theme_stylebox_override("focus", _input_focus_style())
    picker.add_theme_color_override("font_color", INK)
    picker.add_theme_color_override("font_hover_color", INK)
    picker.add_theme_color_override("font_pressed_color", INK)
    for name in options:
        picker.add_item(str(name))
    parent.add_child(picker)
    return picker

func _make_tabs() -> void:
    var bar = PanelContainer.new()
    bar.name = "BottomNavigation"
    var st = StyleBoxFlat.new()
    st.bg_color = CARD_BG
    st.border_color = BORDER
    st.border_width_top = 1
    st.content_margin_left = 7
    st.content_margin_right = 7
    st.content_margin_top = 7
    st.content_margin_bottom = 7
    bar.add_theme_stylebox_override("panel", st)
    shell.add_child(bar)
    var row = HBoxContainer.new()
    row.add_theme_constant_override("separation", 2)
    bar.add_child(row)
    var tabs = [
        ["◉", "День", "day"],
        ["♨", "Рецепты", "recipes"],
        ["✦", "Спорт", "activity"],
        ["◇", "Вес", "weight"],
        ["▥", "Итоги", "stats"],
        ["♙", "Профиль", "profile"]
    ]
    for item in tabs:
        var target: String = item[2]
        var b = _button(row, item[0] + "\n" + item[1], func(): _navigate_to_tab(target), true)
        b.custom_minimum_size.y = 59
        b.clip_text = true
        b.add_theme_font_size_override("font_size", 12)
        b.add_theme_constant_override("h_separation", 3)
        tab_buttons[target] = b
    _update_tabs()

func _update_tabs() -> void:
    for key in tab_buttons:
        var b: Button = tab_buttons[key]
        var active = key == tab or (key == "profile" and tab == "settings")
        var box_style = StyleBoxFlat.new()
        box_style.bg_color = GREEN if active else CARD_BG
        box_style.set_corner_radius_all(14)
        for state in ["normal", "hover", "pressed"]:
            b.add_theme_stylebox_override(state, box_style)
        var color = WHITE if active else MUTED
        for state in ["font_color", "font_hover_color", "font_pressed_color"]:
            b.add_theme_color_override(state, color)


func _style_progress(bar: ProgressBar) -> void:
    var track = StyleBoxFlat.new()
    track.bg_color = PALE
    track.set_corner_radius_all(9)
    var fill = StyleBoxFlat.new()
    fill.bg_color = GREEN
    fill.set_corner_radius_all(9)
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bar.add_theme_stylebox_override("background", track)
    bar.add_theme_stylebox_override("fill", fill)
    bar.custom_minimum_size.y = 13
    bar.show_percentage = false

func _metric_tile(parent: Node, value: String, caption: String, tone: Color = Color("#195b4a")) -> void:
    if tone == Color("#195b4a"):
        tone = TEXT_ACCENT
    var panel = PanelContainer.new()
    panel.mouse_filter = Control.MOUSE_FILTER_PASS
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
    inner.mouse_filter = Control.MOUSE_FILTER_PASS
    panel.add_child(inner)
    _label(inner, value, 25, tone)
    _label(inner, caption, 12, MUTED)

func _view_key() -> String:
    return "settings:" + settings_page if tab == "settings" else tab

func _restore_scroll_position(key: String, serial: int, position: int) -> void:
    # Wait until Godot has measured the new cards; otherwise the old scroll
    # range may clamp a valid saved offset to zero during a tab switch.
    await get_tree().process_frame
    if serial != _render_serial or key != _view_key() or not is_instance_valid(scroll):
        return
    var bar = scroll.get_v_scroll_bar()
    var limit = maxi(0, roundi(bar.max_value - bar.page))
    scroll.scroll_vertical = clampi(position, 0, limit)

func _render(reset_position: bool = false) -> void:
    # Preserve scroll state whenever cards are rebuilt after saving or edits.
    # Each tab and the separate own-products screen keep independent offsets.
    var old_key = _rendered_view
    if not old_key.is_empty() and is_instance_valid(scroll):
        _scroll_memory[old_key] = scroll.scroll_vertical
    var new_key = _view_key()
    var desired = 0 if reset_position else int(_scroll_memory.get(new_key, 0))
    if reset_position:
        _scroll_memory[new_key] = 0
    _rendered_view = new_key
    _render_serial += 1
    var current_serial = _render_serial
    _update_tabs()
    for child in body.get_children():
        body.remove_child(child)
        child.queue_free()
    match tab:
        "day": _show_day()
        "recipes": _show_recipes()
        "profile": _show_profile()
        "activity": _show_activity()
        "weight": _show_weight()
        "stats": _show_stats()
        "settings": _show_settings()
    scroll.scroll_vertical = desired
    call_deferred("_restore_scroll_position", new_key, current_serial, desired)


func _date_nav(parent: Node) -> void:
    var r = _row(parent)
    _button(r, "◀", func(): date = store.change_date(date, -1); month_shown = date.substr(0, 7); _render(), true)
    var day_label = _nowrap(r, date.substr(8, 2) + "." + date.substr(5, 2) + "." + date.substr(0, 4), 18, TEXT_ACCENT)
    day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    day_label.custom_minimum_size.y = 45
    _button(r, "▶", func(): date = store.change_date(date, 1); month_shown = date.substr(0, 7); _render(), true)

func _calendar(parent: Node) -> void:
    var top = _row(parent)
    _button(top, "‹", func(): _shift_month(-1), true)
    var month_label = _nowrap(top, month_shown, 16, TEXT_ACCENT)
    month_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    month_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    month_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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

func _avatar_character(id: String) -> String:
    return {"leaf":"❧", "star":"✦", "moon":"☾", "sun":"☀", "flower":"✿", "heart":"♥"}.get(id, "❧")

func _show_profile() -> void:
    var profile: Dictionary = store.data.get("profile", {})
    var hero = _card("", "hero")
    var intro = _row(hero)
    var badge = PanelContainer.new()
    badge.custom_minimum_size = Vector2(72, 72)
    var badge_style = StyleBoxFlat.new()
    badge_style.bg_color = CHIP_BG
    badge_style.set_corner_radius_all(23)
    badge_style.content_margin_left = 14
    badge_style.content_margin_right = 14
    badge_style.content_margin_top = 10
    badge_style.content_margin_bottom = 10
    badge.add_theme_stylebox_override("panel", badge_style)
    intro.add_child(badge)
    var avatar = _label(badge, _avatar_character(str(profile.get("avatar", "leaf"))), 37, SOFT_GOLD)
    avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    var identity = VBoxContainer.new()
    identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    identity.add_theme_constant_override("separation", 4)
    intro.add_child(identity)
    _label(identity, str(profile.get("name", "Мой профиль")), 23, WHITE)
    _label(identity, str(profile.get("motto", "")), 13, HERO_MUTED)

    var overview = _card("Мои цели")
    var settings: Dictionary = store.data["settings"]
    var latest = float(settings.get("start", 88.0))
    var latest_date = ""
    for w in store.data["weights"]:
        var d = str(w.get("date", ""))
        if d >= latest_date:
            latest_date = d
            latest = float(w.get("value", latest))
    var tiles = _row(overview)
    _metric_tile(tiles, str(snappedf(latest, 0.1)) + " кг", "Текущий вес")
    _metric_tile(tiles, str(snappedf(float(settings["goal"]), 0.1)) + " кг", "Целевой вес")
    _label(overview, "Начало: " + str(settings["start"]) + " кг   •   Изменение: " +
        ("+" if latest - float(settings["start"]) > 0 else "") +
        str(snappedf(latest - float(settings["start"]), 0.1)) + " кг", 13, MUTED)
    _label(overview, "Ориентир питания: " + str(roundi(float(settings["kcal"]))) + " ккал в сутки", 14, TEXT_ACCENT)
    var start_weight = float(settings["start"])
    var goal_weight = float(settings["goal"])
    if not is_equal_approx(start_weight, goal_weight):
        var progress = clampf((start_weight - latest) / (start_weight - goal_weight), 0.0, 1.0)
        _label(overview, "Путь к цели: " + str(roundi(progress * 100.0)) + "%", 14, TEXT_ACCENT)
        var progress_bar = ProgressBar.new()
        progress_bar.min_value = 0.0
        progress_bar.max_value = 100.0
        progress_bar.value = progress * 100.0
        _style_progress(progress_bar)
        overview.add_child(progress_bar)
        _label(overview, "Осталось до цели: " + str(snappedf(absf(latest - goal_weight), 0.1)) + " кг", 13, MUTED)


    var records = _card("Мои достижения")
    var dates = {}
    for entry in store.data["entries"]:
        dates[str(entry.get("date", ""))] = true
    var row = _row(records)
    _metric_tile(row, str(dates.size()), "Дней с дневником")
    _metric_tile(row, str(store.data["recipes"].size()), "Моих рецептов")
    _label(records, "Здесь отображаются только твои записи. Данные хранятся на устройстве.", 12, MUTED)

    var edit = _card("Личная страница")
    if not profile_edit_open:
        _button(edit, "✎ Изменить имя и значок", func():
            profile_edit_open = true
            _render()
        , true)
    else:
        _label(edit, "Как к тебе обращаться", 13, MUTED)
        var name = _text_input(edit, "Имя", str(profile.get("name", "Мой профиль")))
        name.max_length = 45
        _label(edit, "Короткая подпись", 13, MUTED)
        var motto = _text_input(edit, "Небольшая фраза о себе", str(profile.get("motto", "")))
        motto.max_length = 140
        var choices = ["❧ Листок", "✦ Звезда", "☾ Луна", "☀ Солнце", "✿ Цветок", "♥ Сердце"]
        var ids = ["leaf", "star", "moon", "sun", "flower", "heart"]
        _label(edit, "Значок профиля", 13, MUTED)
        var icon_picker = _choice(edit, choices)
        var chosen = ids.find(str(profile.get("avatar", "leaf")))
        icon_picker.select(maxi(0, chosen))
        var actions = _row(edit)
        _button(actions, "Отмена", func():
            profile_edit_open = false
            _render()
        , true)
        _button(actions, "Сохранить профиль", func():
            var changes = {"name": name.text.strip_edges(), "motto": motto.text.strip_edges(),
                "avatar": ids[icon_picker.selected]}
            if store.update_profile(changes):
                profile_edit_open = false
                _hide_keyboard_and_focus()
                _render()
                _notify_saved("Личная страница обновлена")
            else:
                _message("Проверь имя и подпись или свободное место.")
        )
    var shortcuts = _card("Мой баланс")
    _button(shortcuts, "Мои рецепты", func(): _navigate_to_tab("recipes"), true)
    _button(shortcuts, "История веса", func(): _navigate_to_tab("weight"), true)
    _button(shortcuts, "⚙ Настройки, темы и резервные копии", func():
        settings_page = "main"
        _navigate_to_tab("settings")
    , true)

func _begin_recipe_editor(recipe: Dictionary = {}) -> void:
    recipe_editor_open = true
    recipe_search_text = ""
    recipe_manual_open = false
    if recipe.is_empty():
        recipe_draft = {
            "id": "", "name": "", "cooked_weight": 500.0,
            "servings": 4.0, "ingredients": []
        }
    else:
        recipe_draft = recipe.duplicate(true)
    _hide_keyboard_and_focus()
    _render(true)

func _recipe_sync_form(name: LineEdit, cooked: SpinBox, portions: SpinBox) -> void:
    recipe_draft["name"] = name.text.strip_edges()
    recipe_draft["cooked_weight"] = cooked.value
    recipe_draft["servings"] = portions.value

func _refresh_recipe_food_search(search: LineEdit, picker: OptionButton, filtered: Array) -> void:
    var needle = search.text.strip_edges().to_lower()
    filtered.clear()
    picker.clear()
    for food in store.all_foods():
        if needle.is_empty() or str(food.get("name", "")).to_lower().contains(needle):
            filtered.append(food)
            picker.add_item(str(food.get("name", "Продукт")))
            if filtered.size() >= 75:
                break
    picker.disabled = filtered.is_empty()

func _recipe_preview(label: Label, cooked: SpinBox, portions: SpinBox) -> void:
    if not is_instance_valid(label):
        return
    var result = RecipeMath.calculate(recipe_draft.get("ingredients", []), cooked.value)
    if result.is_empty():
        label.text = "Добавь ингредиенты и укажи вес готового блюда."
        return
    var portion_weight = cooked.value / maxf(1.0, portions.value)
    label.text = ("Вес сырых ингредиентов: " + str(roundi(result["raw_weight"])) + " г" +
        "\nВсё блюдо: " + str(roundi(result["total_kcal"])) + " ккал" +
        "\nНа 100 г готового: " + str(roundi(result["kcal"])) + " ккал" +
        " · Б " + str(snappedf(result["p"], 0.1)) +
        " · Ж " + str(snappedf(result["f"], 0.1)) +
        " · У " + str(snappedf(result["c"], 0.1)) +
        "\nПорция ~" + str(roundi(portion_weight)) + " г: " +
        str(roundi(result["total_kcal"] / maxf(1.0, portions.value))) + " ккал")

func _show_recipe_editor() -> void:
    var toolbar = _card("Редактор домашнего блюда")
    _label(toolbar, "КБЖУ ингредиентов берутся на 100 г до приготовления. Вода без калорий не меняет общую калорийность.", 13, MUTED)
    var name = _text_input(toolbar, "Название блюда", str(recipe_draft.get("name", "")))
    name.max_length = 160
    _label(toolbar, "Вес готового блюда, г (без посуды)", 13, MUTED)
    var cooked = _number(toolbar, float(recipe_draft.get("cooked_weight", 500)), 1, 50000, 1)
    _label(toolbar, "На сколько порций разделить", 13, MUTED)
    var portions = _number(toolbar, float(recipe_draft.get("servings", 4)), 1, 100, 1)
    var preview: Label = null
    var info = _card("Ингредиенты", "tint")
    var parts: Array = recipe_draft.get("ingredients", [])
    if parts.is_empty():
        _label(info, "Пока ингредиентов нет. Найди продукт ниже и добавь его вес.", 13, MUTED)
    for i in range(parts.size()):
        var index: int = i
        var ingredient: Dictionary = parts[index]
        var line = _soft_list_row(info)
        var label = _label(line, str(ingredient.get("name", "Ингредиент")), 13, INK)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var grams = _number(line, float(ingredient.get("grams", 100)), 1, 10000, 1)
        grams.custom_minimum_size.x = 83
        grams.size_flags_horizontal = Control.SIZE_SHRINK_END
        grams.value_changed.connect(func(v: float):
            ingredient["grams"] = v
            _recipe_preview(preview, cooked, portions)
        )
        _button(line, "×", func():
            _recipe_sync_form(name, cooked, portions)
            recipe_draft["ingredients"].remove_at(index)
            _render()
        , true)
    var add = _card("Добавить ингредиент")
    var search = _text_input(add, "Название продукта")
    search.text = recipe_search_text
    search.clear_button_enabled = true
    var filtered: Array = []
    var picker = _choice(add, [])
    search.text_changed.connect(func(value: String):
        recipe_search_text = value
        _refresh_recipe_food_search(search, picker, filtered)
    )
    _refresh_recipe_food_search(search, picker, filtered)
    _label(add, "Вес сырого ингредиента, г", 13, MUTED)
    var weight = _number(add, 100, 1, 10000, 1)
    _button(add, "+ Добавить ингредиент", func():
        if picker.selected < 0 or picker.selected >= filtered.size():
            _message("Сначала выбери ингредиент.")
            return
        if recipe_draft["ingredients"].size() >= 40:
            _message("В одном рецепте допускается до 40 ингредиентов.")
            return
        _recipe_sync_form(name, cooked, portions)
        var food: Dictionary = filtered[picker.selected]
        var item = {
            "id": str(food.get("id", "")), "name": str(food.get("name", "")),
            "grams": weight.value, "kcal": float(food.get("kcal", 0)),
            "p": float(food.get("p", 0)), "f": float(food.get("f", 0)),
            "c": float(food.get("c", 0))
        }
        recipe_draft["ingredients"].append(item)
        _render()
    )
    var manual = _card("Нет ингредиента в каталоге?")
    _button(manual, "▴ Свернуть ручной ввод" if recipe_manual_open else "+ Ввести ингредиент вручную", func():
        _recipe_sync_form(name, cooked, portions)
        recipe_manual_open = not recipe_manual_open
        _render()
    , true)
    if recipe_manual_open:
        var manual_name = _text_input(manual, "Название ингредиента")
        _label(manual, "Сырой вес, г", 13, MUTED)
        var manual_grams = _number(manual, 100, 1, 10000, 1)
        _label(manual, "Калории на 100 г", 13, MUTED)
        var manual_kcal = _number(manual, 100, 0, 1000, 0.1)
        _label(manual, "Белки / Жиры / Углеводы на 100 г", 13, MUTED)
        var manual_row = _row(manual)
        var manual_p = _number(manual_row, 0, 0, 100, 0.1)
        var manual_f = _number(manual_row, 0, 0, 100, 0.1)
        var manual_c = _number(manual_row, 0, 0, 100, 0.1)
        _button(manual, "Добавить в состав", func():
            if manual_name.text.strip_edges().is_empty():
                _message("Введи название ингредиента.")
                return
            if recipe_draft["ingredients"].size() >= 40:
                _message("Слишком много ингредиентов для одного рецепта.")
                return
            _recipe_sync_form(name, cooked, portions)
            recipe_draft["ingredients"].append({
                "id": "", "name": manual_name.text.strip_edges(),
                "grams": manual_grams.value, "kcal": manual_kcal.value,
                "p": manual_p.value, "f": manual_f.value, "c": manual_c.value
            })
            recipe_manual_open = false
            _render()
        )
    var preview_card = _card("Расчёт КБЖУ")
    preview = _label(preview_card, "", 14, INK)
    cooked.value_changed.connect(func(_value: float): _recipe_preview(preview, cooked, portions))
    portions.value_changed.connect(func(_value: float): _recipe_preview(preview, cooked, portions))
    _recipe_preview(preview, cooked, portions)
    _label(preview_card, "На 100 г учитывается фактический вес готового блюда. Если часть соуса осталась в кастрюле, учти только съедобную массу и ингредиенты в ней.", 12, MUTED)
    var buttons = _row(preview_card)
    _button(buttons, "Отмена", func():
        recipe_editor_open = false
        recipe_draft = {}
        recipe_search_text = ""
        _render(true)
    , true)
    _button(buttons, "Сохранить рецепт", func():
        _recipe_sync_form(name, cooked, portions)
        var saved = store.save_recipe(recipe_draft)
        if saved.is_empty():
            _message("Не удалось сохранить рецепт. Проверь название, состав и вес готового блюда.")
            return
        recipe_editor_open = false
        recipe_draft = {}
        recipe_search_text = ""
        _render(true)
        _notify_saved("Рецепт сохранён")
    )

func _recipe_portion_sheet(recipe: Dictionary) -> void:
    var values = RecipeMath.calculate(recipe.get("ingredients", []), float(recipe.get("cooked_weight", 0)))
    if values.is_empty():
        _message("Не удалось рассчитать пищевую ценность рецепта.")
        return
    var sheet = _mobile_sheet(str(recipe.get("name", "Рецепт")),
        "Выбери вес съеденной порции и приём пищи. БЖУ сохраняются в дневнике.", "Добавить порцию", 425.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, "Вес порции, г", 13, MUTED)
    var weight = _number(fields, minf(5000.0, float(recipe["cooked_weight"]) / maxf(1.0, float(recipe["servings"]))), 1, 5000, 1)
    _label(fields, "Приём пищи", 13, MUTED)
    var meal = _choice(fields, ["Завтрак", "Обед", "Перекус", "Ужин"])
    var portion_text = _label(fields, "", 14, TEXT_ACCENT)
    var refresh = func(v: float):
        var portions = RecipeMath.portion(str(recipe["name"]), values, v)
        portion_text.text = str(roundi(float(portions.get("kcal", 0)))) + " ккал  ·  Б " + str(snappedf(float(portions.get("p", 0)), 0.1)) + "  Ж " + str(snappedf(float(portions.get("f", 0)), 0.1)) + "  У " + str(snappedf(float(portions.get("c", 0)), 0.1))
    weight.value_changed.connect(refresh)
    refresh.call(weight.value)
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        if store.add_recipe_portion(str(recipe["id"]), weight.value, meal.get_item_text(meal.selected), date):
            sheet["root"].queue_free()
            tab = "day"
            _render()
            _notify_saved("Порция блюда добавлена")
            call_deferred("_jump_to_diary")
        else:
            _sheet_error(sheet, "Не удалось добавить порцию. Проверь доступную память.")
    )

func _show_recipes() -> void:
    if recipe_editor_open:
        _show_recipe_editor()
        return
    var intro = _card("Мои рецепты", "hero")
    _label(intro, "Сохраняй домашние блюда и быстро добавляй порции в дневник.", 14, HERO_MUTED)
    _button(intro, "+ Создать рецепт", func(): _begin_recipe_editor(), true)
    var recipes: Array = store.data.get("recipes", [])
    if not recipes.is_empty():
        var filter_card = _card("Поиск по рецептам")
        var query_field = _text_input(filter_card, "Название блюда", recipe_list_query)
        query_field.clear_button_enabled = true
        _button(filter_card, "Найти", func():
            recipe_list_query = query_field.text.strip_edges()
            _hide_keyboard_and_focus()
            _render()
        , true)
        if not recipe_list_query.is_empty():
            _button(filter_card, "Показать все рецепты", func():
                recipe_list_query = ""
                _render()
            , true)
    if recipes.is_empty():
        var empty = _card("Пока нет рецептов")
        _label(empty, "Добавь ингредиенты с их сырым весом, взвесь готовое блюдо — и приложение рассчитает КБЖУ на 100 г.", 14, MUTED)
    var matched = 0
    for saved in recipes:
        var recipe: Dictionary = saved
        if not recipe_list_query.is_empty() and not str(recipe.get("name", "")).to_lower().contains(recipe_list_query.to_lower()):
            continue
        matched += 1
        var details = RecipeMath.calculate(recipe["ingredients"], float(recipe["cooked_weight"]))
        if details.is_empty():
            continue
        var card = _card(str(recipe.get("name", "Блюдо")))
        _label(card, str(roundi(details["kcal"])) + " ккал / 100 г   ·   " + str(roundi(details["total_kcal"])) + " ккал во всём блюде", 15, TEXT_ACCENT)
        _label(card, "Готовый вес: " + str(roundi(float(recipe["cooked_weight"]))) + " г   •   Порций: " + str(roundi(float(recipe["servings"]))) + "   •   Ингредиентов: " + str(recipe["ingredients"].size()), 12, MUTED)
        _label(card, "Б " + str(snappedf(details["p"], 0.1)) + " г   Ж " + str(snappedf(details["f"], 0.1)) + " г   У " + str(snappedf(details["c"], 0.1)) + " г  / 100 г", 13, INK)
        _button(card, "+ Добавить порцию в дневник", func(): _recipe_portion_sheet(recipe))
        var actions = _row(card)
        _button(actions, "✎ Изменить", func(): _begin_recipe_editor(recipe), true)
        _button(actions, "Удалить", func():
            _confirm_delete("Удалить рецепт «" + str(recipe["name"]) + "»? Уже записанные порции останутся в дневнике.", func():
                if store.delete_recipe(str(recipe["id"])):
                    _render()
                    _notify_saved("Рецепт удалён")
                else:
                    _message("Не удалось удалить рецепт.")
            )
        , true)
    if matched == 0 and not recipes.is_empty():
        var no_results = _card("Ничего не найдено")
        _label(no_results, "Попробуй другое название или очисти поиск.", 13, MUTED)

func _show_day() -> void:
    var overview = _card("Обзор дня")
    _date_nav(overview)
    _button(overview, "▾  Скрыть календарь" if calendar_expanded else "▸  Открыть календарь", func():
        calendar_expanded = not calendar_expanded
        _render()
    , true)
    if calendar_expanded:
        _calendar(overview)

    var total = store.day_calories(date)
    var target = float(store.data["settings"]["kcal"])
    var hero = _card("Энергия дня", "hero")
    _label(hero, "Твой ежедневный ориентир", 13, HERO_MUTED)
    var hero_content = _row(hero)
    var numbers = VBoxContainer.new()
    numbers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    numbers.add_theme_constant_override("separation", 2)
    hero_content.add_child(numbers)
    _label(numbers, str(roundi(total)), 39, WHITE)
    _label(numbers, "из " + str(roundi(target)) + " ккал", 15, HERO_MUTED)
    var ring = RingScript.new()
    ring.name = "DailyCalorieRing"
    ring.custom_minimum_size = Vector2(112, 112)
    ring.set_palette(HERO_TRACK, HERO_FILL, WHITE)
    ring.set_value(total, target)
    hero_content.add_child(ring)
    var track = ProgressBar.new()
    track.min_value = 0
    track.max_value = maxf(1.0, target)
    track.value = minf(total, target)
    _style_progress(track)
    var track_bg = StyleBoxFlat.new()
    track_bg.bg_color = HERO_TRACK
    track_bg.set_corner_radius_all(8)
    var track_fg = StyleBoxFlat.new()
    track_fg.bg_color = HERO_FILL
    track_fg.set_corner_radius_all(8)
    track.add_theme_stylebox_override("background", track_bg)
    track.add_theme_stylebox_override("fill", track_fg)
    hero.add_child(track)
    var remaining = target - total
    if remaining >= 0.0:
        _label(hero, "До дневного ориентира — " + str(roundi(remaining)) + " ккал", 13, HERO_MUTED)
    else:
        _label(hero, "Сверх ориентира — " + str(roundi(-remaining)) + " ккал", 13, SOFT_GOLD)
    var macros = _row(hero)
    _macro_chip(macros, "БЕЛКИ", store.day_macro(date, "p"), MACRO_PROTEIN)
    _macro_chip(macros, "ЖИРЫ", store.day_macro(date, "f"), MACRO_FAT)
    _macro_chip(macros, "УГЛЕВОДЫ", store.day_macro(date, "c"), MACRO_CARBS)

    var activity = _card("Движение сегодня")
    var walking = 0
    var exercise = 0
    for a in store.day_activities(date):
        if str(a.get("type", "")) == "walk":
            walking += int(a.get("minutes", 0))
        else:
            exercise += int(a.get("minutes", 0))
    var activity_stats = _row(activity)
    _metric_tile(activity_stats, str(walking) + " мин", "Прогулки")
    _metric_tile(activity_stats, str(exercise) + " мин", "Тренировки")
    var shortcuts = _row(activity)
    _button(shortcuts, "+ Еда", func(): _jump_to_food())
    _button(shortcuts, "+ Спорт", func(): _navigate_to_tab("activity"), true)
    _button(shortcuts, "+ Вес", func(): _navigate_to_tab("weight"), true)

    var quick_recent: Array = store.recent_foods(5)
    if not quick_recent.is_empty():
        var recent_card = _card("Недавно добавляли")
        _label(recent_card, "Любую запись можно быстро повторить с новым весом.", 12, MUTED)
        for recent in quick_recent:
            var recent_item: Dictionary = recent
            _button(recent_card, str(recent_item.get("name", "Продукт")) + "  ·  +" ,
                func(): _quick_food_sheet(recent_item), true)

    var add = _card("Добавить еду", "tint")
    food_entry_card = add
    if food_form_expanded:
        _button(add, "▴ Свернуть поиск продуктов", func():
            food_form_expanded = false
            _render()
        , true)
        _food_form(add)
    else:
        _button(add, "▣  Сканировать штрихкод", func():
            if barcode_scanner != null:
                barcode_scanner.scanBarcode()
            else:
                food_form_expanded = true
                _render()
                call_deferred("_jump_to_food")
        )
        _button(add, "Найти продукт или ввести штрихкод", func():
            food_form_expanded = true
            _render()
            call_deferred("_jump_to_food")
        , true)

    var foods = _card("Дневник питания")
    diary_food_card = foods
    var existing = store.day_entries(date)
    if existing.is_empty():
        _label(foods, "Сегодня ещё нет записей. Выбери продукт выше или повтори блюдо со вчера.", 14, MUTED)
    for meal in ["Завтрак", "Обед", "Перекус", "Ужин"]:
        var items = existing.filter(func(e): return str(e.get("meal", "")) == meal)
        if items.is_empty():
            continue
        _label(foods, meal, 17, TEXT_ACCENT)
        for entry in items:
            var f: Dictionary = store.entry_food(entry)
            var r = _soft_list_row(foods)
            var caption = _label(r, str(f.get("name", "Продукт")) + "\n" + str(entry.get("grams", 0)) + " г • " + str(roundi(store.entry_kcal(entry))) + " ккал", 14)
            caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            _button(r, "✎", func(): _edit_entry(entry), true)
            _button(r, "×", func(): _confirm_delete("Удалить запись питания?", func():
                if store.delete_saved_record("entries", entry):
                    _render()
                    _notify_saved("Запись питания удалена")
                else:
                    _message("Не удалось удалить запись питания.")
            ), true)

    var yesterday = store.change_date(date, -1)
    var previous = store.day_entries(yesterday)
    if not previous.is_empty():
        var repeats = _card("Повторить со вчера · " + yesterday)
        _label(repeats, "Нажми «+», чтобы добавить такую же порцию на выбранный день.", 13, MUTED)
        for prior_meal in ["Завтрак", "Обед", "Перекус", "Ужин"]:
            var meal_count = previous.filter(func(e): return str(e.get("meal", "")) == prior_meal).size()
            if meal_count == 0:
                continue
            _button(repeats, "Повторить весь " + prior_meal.to_lower() + " (" + str(meal_count) + ")", func():
                var copied = store.repeat_meal(yesterday, prior_meal, date)
                if copied > 0:
                    _render()
                    _notify_saved("Добавлено записей: " + str(copied))
                else:
                    _message("Не удалось скопировать приём пищи.")
            , true)
        var count = 0
        for old in previous:
            if count >= 8:
                break
            count += 1
            var old_food = store.entry_food(old)
            var rr = _soft_list_row(repeats)
            var rl = _label(rr, str(old_food.get("name", "Продукт")) + " • " + str(old.get("grams", 0)) + " г", 13)
            rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            _button(rr, "+", func():
                if store.repeat_entry(old, date):
                    _render()
                    _notify_saved("Блюдо повторено")
                else:
                    _message("Не удалось повторить запись. Проверь сохранение.")
            )

    var notes_card = _card("Заметка о дне")
    var notes = TextEdit.new()
    notes.custom_minimum_size.y = 110
    _style_field(notes)
    notes.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    notes.placeholder_text = "Как прошёл день? Голод, настроение, самочувствие…"
    notes.text = str(store.data["notes"].get(date, ""))
    _bind_field_focus(notes)
    notes.text_changed.connect(func():
        store.data["notes"][date] = notes.text
        if is_instance_valid(note_status_label):
            note_status_label.text = "Сохранение…"
        note_save_timer.start()
    )
    notes_card.add_child(notes)
    note_status_label = _label(notes_card, "Заметка сохраняется автоматически", 12, MUTED)

func _jump_to_food() -> void:
    # Follow any pending card-rebuild and saved scroll restoration.
    await get_tree().process_frame
    await get_tree().process_frame
    if tab == "day" and is_instance_valid(food_entry_card):
        scroll.ensure_control_visible(food_entry_card)

func _jump_to_diary() -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    if tab == "day" and is_instance_valid(diary_food_card):
        scroll.ensure_control_visible(diary_food_card)

func _barcode_add_success() -> void:
    tab = "day"
    _render()
    _notify_saved("Порция добавлена в дневник")
    call_deferred("_jump_to_diary")

func _barcode_message(value: String) -> void:
    if is_instance_valid(barcode_message):
        barcode_message.text = value

func _on_barcode_scanned(code: String) -> void:
    if is_instance_valid(barcode_input):
        barcode_input.text = code
    _lookup_barcode(code)

func _on_barcode_scan_error(reason: String) -> void:
    _barcode_message("Не удалось открыть сканер: " + reason + ". Введи код вручную.")

func _on_barcode_scan_cancelled() -> void:
    _barcode_message("Сканирование отменено. Можно ввести цифры под штрихкодом.")

func _lookup_barcode(raw: String) -> void:
    var code = BarcodeScript.normalize_code(raw)
    if code.is_empty():
        _barcode_message("Неверный штрихкод: проверь число цифр и контрольную цифру EAN/UPC.")
        return
    if barcode_http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        _barcode_message("Дождись завершения предыдущего поиска.")
        return
    var cached = store.food_by_barcode(code)
    if not cached.is_empty():
        _barcode_message("Найден товар: " + str(cached.get("name", "")))
        _show_barcode_portion(cached)
        return
    pending_barcode = code
    _barcode_message("Поиск товара " + code + " в Open Food Facts…")
    var headers = PackedStringArray([
        "User-Agent: MyBalance/0.5.7 (+https://github.com/Domenklay/My_balance)",
        "Accept: application/json"
    ])
    var error = barcode_http.request(BarcodeScript.product_url(code), headers, HTTPClient.METHOD_GET)
    if error != OK:
        pending_barcode = ""
        _barcode_message("Не удалось начать поиск. Проверь подключение к интернету.")

func _on_barcode_http_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
        var code = pending_barcode
        pending_barcode = ""
        _barcode_message("Интернет недоступен или товар не найден. Введи данные с упаковки.")
        if not code.is_empty():
            _confirm_barcode_product(_manual_barcode_product(code), true)
        return
    if body.size() > 1000000:
        var code = pending_barcode
        pending_barcode = ""
        _barcode_message("Сервис прислал слишком большой ответ. Введи товар вручную.")
        if not code.is_empty():
            _confirm_barcode_product(_manual_barcode_product(code), true)
        return
    var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
    var searched_code = pending_barcode
    var outcome: Dictionary = BarcodeScript.parse_product(parsed, searched_code)
    pending_barcode = ""
    if outcome.has("error"):
        _barcode_message(str(outcome["error"]) + " Можно внести товар с упаковки.")
        _confirm_barcode_product(_manual_barcode_product(searched_code), true)
        return
    _confirm_barcode_product(outcome)

func _manual_barcode_product(code: String) -> Dictionary:
    return {"barcode": code, "name": "", "kcal": 0.0,
        "p": 0.0, "f": 0.0, "c": 0.0, "source": "Пользователь"}

func _mobile_sheet(title: String, description: String, accept_label: String, requested_height: float = 530.0) -> Dictionary:
    # Draw a real in-app card rather than a native dark ConfirmationDialog.
    # Header and action buttons stay visible while lengthy inputs scroll.
    var veil = Control.new()
    veil.name = "ProductSheet"
    veil.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(veil)
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var shade = ColorRect.new()
    shade.color = Color(0.07, 0.13, 0.10, 0.50)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    veil.add_child(shade)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var centering = CenterContainer.new()
    veil.add_child(centering)
    centering.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var panel = PanelContainer.new()
    panel.custom_minimum_size = Vector2(
        minf(396.0, maxf(270.0, get_viewport_rect().size.x - 32.0)),
        minf(requested_height, maxf(300.0, get_viewport_rect().size.y - 76.0))
    )
    var style = StyleBoxFlat.new()
    style.bg_color = CARD_BG
    style.border_color = BORDER
    style.set_border_width_all(1)
    style.set_corner_radius_all(20)
    style.shadow_color = Color(0.08, 0.15, 0.10, 0.22)
    style.shadow_size = 12
    style.content_margin_left = 18
    style.content_margin_right = 18
    style.content_margin_top = 18
    style.content_margin_bottom = 18
    panel.mouse_filter = Control.MOUSE_FILTER_PASS
    panel.add_theme_stylebox_override("panel", style)
    centering.add_child(panel)

    var column = VBoxContainer.new()
    column.mouse_filter = Control.MOUSE_FILTER_PASS
    column.add_theme_constant_override("separation", 10)
    panel.add_child(column)
    _label(column, title, 20, TEXT_ACCENT)
    if not description.is_empty():
        _label(column, description, 12, MUTED)

    var scroller = ScrollContainer.new()
    scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroller.scroll_deadzone = 12
    scroller.follow_focus = true
    scroller.mouse_filter = Control.MOUSE_FILTER_STOP
    column.add_child(scroller)
    var fields = VBoxContainer.new()
    fields.mouse_filter = Control.MOUSE_FILTER_PASS
    fields.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    fields.add_theme_constant_override("separation", 10)
    scroller.add_child(fields)

    var message = _label(column, "", 12, ACCENT)
    message.visible = false
    var actions = _row(column)
    var cancel = _button(actions, "Отмена", func():
        _hide_keyboard_and_focus()
        veil.queue_free()
    , true)
    cancel.name = "ProductSheetCancel"
    var confirm = _button(actions, accept_label, Callable())
    confirm.name = "ProductSheetConfirm"
    confirm.clip_text = true
    return {"root": veil, "fields": fields, "confirm": confirm,
        "cancel": cancel, "message": message}

func _sheet_error(sheet: Dictionary, message: String) -> void:
    var label: Label = sheet["message"]
    label.text = message
    label.visible = true

func _show_barcode_portion(food: Dictionary) -> void:
    var sheet = _mobile_sheet("Продукт найден", "Проверь данные с упаковки перед добавлением.", "Добавить", 485.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, str(food.get("name", "Продукт")), 18, INK)
    _label(fields, str(food.get("barcode", "")) + " • " + str(food.get("source", "Каталог")), 12, MUTED)
    _label(fields, "На 100 г: " + str(food.get("kcal", 0)) + " ккал", 16, TEXT_ACCENT)
    _label(fields, "Белки " + str(food.get("p", 0)) + " г  •  Жиры " +
        str(food.get("f", 0)) + " г  •  Углеводы " + str(food.get("c", 0)) + " г", 13, INK)
    var warning = BarcodeScript.nutrition_warning(food)
    if not warning.is_empty():
        _label(fields, "Проверь этикетку: " + warning, 13, ACCENT)
    _label(fields, "Вес порции, г", 14, MUTED)
    var grams = _number(fields, 100, 1, 5000)
    _label(fields, "Приём пищи", 14, MUTED)
    var meal = _choice(fields, ["Завтрак", "Обед", "Перекус", "Ужин"])
    var calculated = _label(fields, "", 16, TEXT_ACCENT)
    var refresh = func(): calculated.text = str(roundi(float(food.get("kcal", 0)) * grams.value / 100.0)) + " ккал за порцию"
    grams.value_changed.connect(func(_v: float): refresh.call())
    refresh.call()
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        if store.add_food_entry(food, grams.value, meal.get_item_text(meal.selected), date):
            var root_control: Control = sheet["root"]
            root_control.queue_free()
            _barcode_add_success()
        else:
            _sheet_error(sheet, "Не удалось сохранить порцию. Проверь память устройства.")
    )

func _confirm_barcode_product(product: Dictionary, manual: bool = false) -> void:
    var description = "Внеси КБЖУ с этикетки на 100 г / мл." if manual else "Open Food Facts: сравни КБЖУ с этикеткой."
    var sheet = _mobile_sheet(
        "Новый товар" if manual else "Найденный товар",
        description, "Сохранить и добавить", 690.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, "Название", 13, MUTED)
    var name = _text_input(fields, "Название продукта", str(product.get("name", "")))
    _label(fields, "Калории • на 100 г", 13, MUTED)
    var kcal = _number(fields, float(product.get("kcal", 0)), 0, 1000, 0.1)
    _label(fields, "Белки • Жиры • Углеводы на 100 г", 13, MUTED)
    var nutrition_row = _row(fields)
    var protein = _number(nutrition_row, float(product.get("p", 0)), 0, 100, 0.1)
    var fat = _number(nutrition_row, float(product.get("f", 0)), 0, 100, 0.1)
    var carbs = _number(nutrition_row, float(product.get("c", 0)), 0, 100, 0.1)
    _label(fields, "Вес порции, г", 13, MUTED)
    var grams = _number(fields, 100, 1, 5000, 1)
    _label(fields, "Приём пищи", 13, MUTED)
    var meal = _choice(fields, ["Завтрак", "Обед", "Перекус", "Ужин"])
    var note = BarcodeScript.nutrition_warning(product)
    if not note.is_empty() and not manual:
        _label(fields, "Внимание: " + note, 12, ACCENT)
    _label(fields, "Сохранённый товар будет доступен без интернета.", 12, MUTED)

    var commit_record = func(add_to_diary: bool):
        var record: Dictionary = product.duplicate(true)
        record["name"] = name.text.strip_edges()
        record["kcal"] = kcal.value
        record["p"] = protein.value
        record["f"] = fat.value
        record["c"] = carbs.value
        if record["name"].is_empty():
            _sheet_error(sheet, "Укажи название товара.")
            return
        if manual and kcal.value == 0.0 and protein.value == 0.0 and fat.value == 0.0 and carbs.value == 0.0:
            _sheet_error(sheet, "Внеси пищевую ценность с упаковки.")
            return
        var saved_id = store.save_barcode_food(record)
        if saved_id.is_empty():
            _sheet_error(sheet, "Не удалось сохранить товар. Проверь штрихкод или память устройства.")
            return
        var saved_food = store.food_by_id(saved_id)
        if add_to_diary:
            if not store.add_food_entry(saved_food, grams.value, meal.get_item_text(meal.selected), date):
                _sheet_error(sheet, "Товар сохранён, но порция не записана. Попробуй снова.")
                return
            var root_control: Control = sheet["root"]
            root_control.queue_free()
            _barcode_add_success()
        else:
            var root_control: Control = sheet["root"]
            root_control.queue_free()
            _render()
            _notify_saved("Продукт сохранён в каталоге")

    var save_only = _button(fields, "Сохранить без записи в дневник", func(): commit_record.call(false), true)
    save_only.custom_minimum_size.y = 43
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func(): commit_record.call(true))

func _on_catalog_http_completed(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS or status != 200:
        _message("Не удалось получить обновление каталога. Проверь интернет.")
        return
    if body.size() > 4000000:
        _message("Обновление каталога слишком большое.")
        return
    if store.update_catalog_json(body.get_string_from_utf8()):
        _render()
        _notify_saved("Каталог обновлён: " + str(store.bundled_foods.size()) + " товаров")
    else:
        _message("Недостоверный или повреждённый каталог. Старые данные сохранены.")

func _request_catalog_update() -> void:
    if catalog_http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        _message("Каталог уже обновляется.")
        return
    var url = "https://raw.githubusercontent.com/Domenklay/My_balance/main/godot/data/barcode_catalog.json"
    var headers = PackedStringArray(["User-Agent: MyBalance/0.5.7", "Accept: application/json"])
    if catalog_http.request(url, headers) != OK:
        _message("Не удалось начать обновление. Проверь интернет.")
    else:
        _message("Загрузка проверенного каталога из GitHub запущена.")


func _quick_food_sheet(food: Dictionary) -> void:
    var sheet = _mobile_sheet(str(food.get("name", "Продукт")), "Выбери количество и приём пищи.", "Добавить в дневник", 490.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, "Количество, г", 14, MUTED)
    var grams = _number(fields, 100, 1, 5000, 1)
    var presets = _row(fields)
    for option in [50, 100, 150, 200]:
        var value: int = option
        _button(presets, str(value) + " г", func(): grams.value = value, true)
    _label(fields, "Приём пищи", 14, MUTED)
    var meal = _choice(fields, ["Завтрак", "Обед", "Перекус", "Ужин"])
    var preview = _label(fields, "", 14, TEXT_ACCENT)
    var update_preview = func(_v: float):
        preview.text = str(roundi(float(food.get("kcal", 0)) * grams.value / 100.0)) + " ккал"
    grams.value_changed.connect(update_preview)
    update_preview.call(grams.value)
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        if store.add_food_entry(food, grams.value, meal.get_item_text(meal.selected), date):
            sheet["root"].queue_free()
            _render()
            _notify_saved("Продукт добавлен")
        else:
            _sheet_error(sheet, "Не удалось сохранить запись.")
    )

func _food_form(parent: VBoxContainer) -> void:
    var barcode_panel = VBoxContainer.new()
    barcode_panel.add_theme_constant_override("separation", 6)
    parent.add_child(barcode_panel)
    _label(barcode_panel, "Найти продукт по штрихкоду", 17, TEXT_ACCENT)
    var camera_button = _button(barcode_panel, "▣  Сканировать штрихкод", func():
        if barcode_scanner != null:
            _barcode_message("Открываю сканер штрихкодов…")
            barcode_scanner.scanBarcode()
        else:
            _barcode_message("Сканер камеры работает на Android с Google Play Services. Введи номер ниже.")
    )
    camera_button.custom_minimum_size.y = 60
    camera_button.add_theme_font_size_override("font_size", 17)
    if barcode_scanner == null:
        camera_button.tooltip_text = "Сканер камеры доступен при запуске Android APK"
    _label(barcode_panel, "Или введи номер с упаковки", 13, MUTED)
    var barcode_controls = _row(barcode_panel)
    barcode_input = _text_input(barcode_controls, "EAN / UPC — 8–14 цифр")
    barcode_input.max_length = 14
    barcode_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
    var barcode_find = _button(barcode_controls, "Найти", func(): _lookup_barcode(barcode_input.text), true)
    barcode_find.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    barcode_find.custom_minimum_size.x = 74
    barcode_message = _label(barcode_panel, "Встроено " + str(store.bundled_foods.size()) + " товаров с кодами. Другие ищем через интернет.", 12, MUTED)
    parent.add_child(HSeparator.new())
    var frequent: Array = store.frequent_foods(6)
    if not frequent.is_empty():
        _label(parent, "Часто используемые", 16, TEXT_ACCENT)
        for frequent_food in frequent:
            var item: Dictionary = frequent_food
            _button(parent, "＋ " + str(item.get("name", "Продукт")),
                func(): _quick_food_sheet(item), true)
    _label(parent, "Или найди в сохранённых продуктах", 16, TEXT_ACCENT)
    var filtered: Array = []
    var search = _text_input(parent, "Поиск продукта по названию")
    if not selected_barcode_food.is_empty():
        search.text = selected_barcode_food
        selected_barcode_food = ""
    search.clear_button_enabled = true
    var favorite_only = CheckButton.new()
    favorite_only.text = "Только избранные"
    favorite_only.add_theme_color_override("font_color", GREEN)
    favorite_only.add_theme_font_size_override("font_size", 13)
    parent.add_child(favorite_only)
    var picker = _choice(parent, [])
    _label(parent, "Вес порции, г", 14, MUTED)
    var values = _row(parent)
    var grams = _number(values, 100, 1, 5000)
    grams.custom_minimum_size.x = 160
    var grams_presets = _row(parent)
    for option in [50, 100, 150, 200]:
        var value: int = option
        _button(grams_presets, str(value) + " г", func(): grams.value = value, true)
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
        if store.add_food_entry(f, grams.value, meal.get_item_text(meal.selected), date):
            _render()
            _notify_saved("Продукт добавлен в дневник")
        else:
            _message("Ошибка сохранения. Запись не добавлена; проверь свободное место.")
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
        var searchable = str(item.get("name", "")) + " " + str(item.get("brand", ""))
        if not query.is_empty() and not searchable.to_lower().contains(query):
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
        var brand = str(f.get("brand", "")).strip_edges()
        if not brand.is_empty() and not label.to_lower().contains(brand.to_lower()):
            label += " · " + brand
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
    var sheet = _mobile_sheet("Изменить запись питания", "Изменения затронут выбранную запись.", "Сохранить", 505.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, "Продукт", 13, MUTED)
    var available = store.all_foods()
    var selector = _choice(fields, available.map(func(food): return food.get("name", "")))
    var current_id = str(entry.get("food", ""))
    for i in range(available.size()):
        if str(available[i].get("id", "")) == current_id:
            selector.select(i)
            break
    _label(fields, "Количество, г", 13, MUTED)
    var grams = _number(fields, float(entry.get("grams", 100)), 1, 5000)
    _label(fields, "Приём пищи", 13, MUTED)
    var meals = ["Завтрак", "Обед", "Перекус", "Ужин"]
    var meal = _choice(fields, meals)
    var selected = meals.find(str(entry.get("meal", "")))
    if selected >= 0:
        meal.select(selected)
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        if selector.selected < 0 or selector.selected >= available.size():
            _sheet_error(sheet, "Выбери продукт.")
            return
        var previous = entry.duplicate(true)
        var product: Dictionary = available[selector.selected]
        entry["food"] = product["id"]
        entry["nutrition"] = {"name": product["name"], "kcal": product["kcal"],
            "p": product["p"], "f": product["f"], "c": product["c"]}
        entry["grams"] = grams.value
        entry["meal"] = meals[meal.selected]
        if not store.save():
            entry.clear()
            entry.merge(previous, true)
            _sheet_error(sheet, "Ошибка сохранения. Проверь свободное место.")
            return
        var root_control: Control = sheet["root"]
        root_control.queue_free()
        _render()
        _notify_saved("Запись питания изменена")
    )

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
        var activity = {
            "id": str(Time.get_ticks_usec()), "date": date, "type": activity_kind,
            "minutes": minutes.value, "distance": distance.value, "detail": detail.text
        }
        store.data["activities"].append(activity)
        if store.save():
            _render()
            _notify_saved("Активность сохранена")
        else:
            store.data["activities"].erase(activity)
            _message("Не удалось сохранить активность. Проверь память устройства.")
    )
    var saved = _card("Активность за день")
    var items = store.day_activities(date)
    if items.is_empty():
        _label(saved, "Пока не было записей.", 14, MUTED)
    for a in items:
        var r = _soft_list_row(saved)
        var type_name = {"walk":"🚶 Ходьба", "strength":"🏋 Гантели", "other":"Активность"}.get(a.get("type", ""), "Активность")
        var text = str(type_name) + " · " + str(a.get("minutes", 0)) + " мин"
        if str(a.get("detail", "")) != "":
            text += "\n" + str(a.get("detail", ""))
        if str(a.get("type", "")) == "walk" and float(a.get("distance", 0)) > 0:
            text += " · " + str(a.get("distance", 0)) + " км"
        var l = _label(r, text, 14)
        l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _button(r, "✎", func(): _edit_activity(a), true)
        _button(r, "×", func(): _confirm_delete("Удалить активность?", func():
            if store.delete_saved_record("activities", a):
                _render()
                _notify_saved("Активность удалена")
            else:
                _message("Не удалось удалить активность.")
        ), true)

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
        var previous_activity = activity.duplicate(true)
        activity["type"] = types[kind.selected]
        activity["minutes"] = minutes.value
        activity["distance"] = distance.value
        activity["detail"] = detail.text
        if store.save():
            dialog.queue_free()
            _render()
            _notify_saved("Активность изменена")
        else:
            activity.clear()
            activity.merge(previous_activity, true)
            dialog.queue_free()
            _message("Не удалось сохранить изменения активности.")
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
        var previous_weights = store.data["weights"].duplicate(true)
        store.data["weights"] = store.data["weights"].filter(func(w): return str(w.get("date", "")) != date)
        store.data["weights"].append({"id": "w" + date, "date": date, "value": value.value})
        if store.save():
            _render()
            _notify_saved("Вес записан")
        else:
            store.data["weights"] = previous_weights
            _message("Не удалось сохранить вес. Предыдущие данные восстановлены.")
    )
    var chart = _card("Как меняется вес")
    var g = GraphScript.new()
    g.custom_minimum_size = Vector2(0, 210)
    g.set_palette(TEXT_ACCENT, CHART_GRID, MUTED, ACCENT, CHART_AREA, SECONDARY)
    g.set_points(store.data["weights"], float(settings["goal"]))
    chart.add_child(g)
    var history = store.data["weights"].duplicate()
    history.sort_custom(func(a,b): return str(a.get("date", "")) > str(b.get("date", "")))
    for w in history:
        var r = _soft_list_row(chart)
        var l = _label(r, str(w.get("date", "")) + " · " + str(w.get("value", 0)) + " кг", 14)
        l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _button(r, "×", func(): _confirm_delete("Удалить запись веса?", func():
            if store.delete_saved_record("weights", w):
                _render()
                _notify_saved("Запись веса удалена")
            else:
                _message("Не удалось удалить запись веса.")
        ), true)

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
    _label(card, "Среднее за записанные дни: " + avg, 19, TEXT_ACCENT)
    _label(card, "Дней с питанием: " + str(recorded) + " из 7", 15)
    _label(card, "Прогулки: " + str(walking) + " мин    Силовые: " + str(workouts), 15)
    _label(card, "Калории по дням", 16)
    for d in days:
        var line = _row(card)
        var l = _nowrap(line, d.substr(8, 2) + "." + d.substr(5, 2), 13)
        l.custom_minimum_size.x = 54
        var bar = ProgressBar.new()
        bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        bar.min_value = 0
        bar.max_value = float(store.data["settings"]["kcal"]) * 1.5
        bar.value = store.day_calories(d)
        _style_progress(bar)
        bar.custom_minimum_size.y = 11
        line.add_child(bar)
        var daily_value = _nowrap(line, str(roundi(store.day_calories(d))) if not store.day_entries(d).is_empty() else "—", 13)
        daily_value.custom_minimum_size.x = 35
        daily_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _label(card, "Пустые дни не входят в среднее. Оценивай тенденцию, а не один день.", 13, MUTED)
    var chart = _card("Вес")
    var g = GraphScript.new()
    g.custom_minimum_size.y = 210
    g.set_points(store.data["weights"], float(store.data["settings"]["goal"]))
    chart.add_child(g)

func _show_settings() -> void:
    if settings_page == "foods":
        var nav = _card("Мои продукты")
        _button(nav, "← Назад к настройкам", func():
            settings_page = "main"
            _render()
        , true)
        _show_my_foods()
        return
    var back_to_profile = _card("Настройки приложения")
    _button(back_to_profile, "← К личной странице", func(): _navigate_to_tab("profile"), true)
    var card = _card("Личные настройки")
    _label(card, "Калории в сутки")
    var kcal = _number(card, float(store.data["settings"]["kcal"]), 1000, 5000)
    _label(card, "Вес на старте")
    var start = _number(card, float(store.data["settings"]["start"]), 20, 400, 0.1)
    _label(card, "Моя цель")
    var goal = _number(card, float(store.data["settings"]["goal"]), 20, 400, 0.1)
    _button(card, "Сохранить настройки", func():
        var previous_settings = store.data["settings"].duplicate(true)
        var next_settings = previous_settings.duplicate(true)
        next_settings["kcal"] = kcal.value
        next_settings["start"] = start.value
        next_settings["goal"] = goal.value
        store.data["settings"] = next_settings
        if store.save():
            _render()
            _notify_saved("Настройки сохранены")
        else:
            store.data["settings"] = previous_settings
            _message("Не удалось сохранить настройки. Прежние значения оставлены.")
    )
    var appearance = _card("Оформление")
    _label(appearance, "Выбери тему — она сразу применится ко всем экранам.", 13, MUTED)
    _label(appearance, "Активная: " + AppearanceScript.name_for(current_theme), 14, TEXT_ACCENT)
    for id in AppearanceScript.ORDER:
        var theme_id: String = str(id)
        var sample: Dictionary = AppearanceScript.palette(theme_id)
        var sample_row = _soft_list_row(appearance)
        var color_preview = ColorRect.new()
        color_preview.name = "ThemeSwatch_" + theme_id
        color_preview.color = Color(str(sample["hero"]))
        color_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
        color_preview.custom_minimum_size = Vector2(34, 34)
        sample_row.add_child(color_preview)
        var name_label = _label(sample_row, AppearanceScript.name_for(theme_id), 13, INK)
        name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _button(sample_row, "✓" if current_theme == theme_id else "Выбрать",
            func(): _choose_theme(theme_id), true)
    _button(appearance, "Узоры: включены" if PATTERNS else "Узоры: выключены",
        func(): _toggle_patterns(), true)
    _label(appearance, "Тонкий рисунок на фоне и карточках. Если отключить, останется чистый минимализм.", 12, MUTED)

    var my_foods_link = _card("Мои продукты и штрихкоды")
    _label(my_foods_link, "Создание и редактирование продуктов, привязка штрихкодов, обновление каталога.", 13, MUTED)
    _button(my_foods_link, "Открыть мои продукты", func():
        settings_page = "foods"
        _render()
    , true)
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
            _render()
            _notify_saved("Дневник восстановлен")
        else:
            _message("Неверная резервная копия JSON.")
    )
    _label(backup, "Записи хранятся в памяти приложения без регистрации и интернета. При удалении приложения данные могут исчезнуть.", 13, MUTED)

func _show_my_foods() -> void:
    var foods_card = _card("Добавить свой продукт · на 100 г")
    _label(foods_card, "Штрихкод поможет найти свой продукт повторно, даже без интернета.", 13, MUTED)
    var name = _text_input(foods_card, "Название продукта")
    var custom_barcode = _text_input(foods_card, "Штрихкод, 8–14 цифр (необязательно)")
    custom_barcode.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
    custom_barcode.max_length = 14
    _label(foods_card, "Калории на 100 г / мл", 13, MUTED)
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
        var barcode = custom_barcode.text.strip_edges()
        var record = {
            "id": "u" + str(Time.get_ticks_usec()), "name": name.text.strip_edges(),
            "kcal": k.value, "p": p.value, "f": f.value, "c": c.value,
            "source": "Пользователь"
        }
        if not barcode.is_empty():
            if BarcodeScript.normalize_code(barcode).is_empty():
                _message("Штрихкод должен содержать 8–14 цифр.")
                return
            record["barcode"] = barcode
            if store.save_barcode_food(record).is_empty():
                _message("Не удалось сохранить продукт или штрихкод.")
                return
        else:
            if not store.add_custom_food_without_barcode(record):
                _message("Не удалось сохранить продукт. Проверь введённые КБЖУ и место на устройстве.")
                return
        _render()
        _notify_saved("Продукт сохранён")
    )
    var custom_foods: Array = store.data["foods"].filter(func(item): return item is Dictionary)
    if not custom_foods.is_empty():
        var link_card = _card("Привязать штрихкод к своему продукту")
        _label(link_card, "Если продукт уже добавлен, выбери его и введи цифры с упаковки.", 13, MUTED)
        var custom_picker = _choice(link_card, custom_foods.map(func(item): return str(item.get("name", "Продукт"))))
        var link_code = _text_input(link_card, "Штрихкод из упаковки")
        link_code.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
        link_code.max_length = 14
        _button(link_card, "Привязать штрихкод", func():
            if custom_picker.selected < 0:
                return
            var item: Dictionary = custom_foods[custom_picker.selected]
            if BarcodeScript.normalize_code(link_code.text).is_empty():
                _message("Штрихкод должен содержать 8–14 цифр.")
                return
            if store.link_barcode_to_food(str(item.get("id", "")), link_code.text.strip_edges()):
                _render()
                _notify_saved("Штрихкод привязан к продукту")
            else:
                _message("Не удалось привязать код. Возможно, он уже принадлежит другому продукту.")
        , true)
    if not custom_foods.is_empty():
        var manage = _card("Мои продукты · изменить или удалить")
        _label(manage, "Правки не изменят уже сохранённые дневные записи.", 13, MUTED)
        for saved_food in custom_foods:
            var food: Dictionary = saved_food
            var line = _soft_list_row(manage)
            var caption = _nowrap(line, str(food.get("name", "Продукт")), 13, INK)
            caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            _button(line, "✎", func(): _edit_custom_food(food), true)
            _button(line, "×", func():
                _confirm_delete("Удалить свой продукт «" + str(food.get("name", "")) + "» из каталога? История питания останется.", func():
                    if store.delete_custom_food(str(food.get("id", ""))):
                        _render()
                        _notify_saved("Продукт удалён")
                    else:
                        _message("Не удалось удалить продукт.")
                )
            , true)
    var catalog_card = _card("Каталог продуктов")
    _label(catalog_card, "Встроено " + str(store.bundled_foods.size()) + " проверенных штрихкодов из Open Food Facts.", 14, INK)
    _button(catalog_card, "Обновить список товаров через интернет", func(): _request_catalog_update(), true)
    _label(catalog_card, "Обновление загружается из публичного GitHub-репозитория и не затрагивает личные записи. Новые товары появляются только после публикации проверенного списка.", 12, MUTED)
    _label(foods_card, "Сведения Open Food Facts: © contributors, Open Database License (ODbL). Проверяй КБЖУ на упаковке.", 12, MUTED)


func _edit_custom_food(food: Dictionary) -> void:
    var sheet = _mobile_sheet("Редактировать продукт", "На 100 г. Ранее внесённые блюда сохранят свои КБЖУ.", "Сохранить", 540.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, "Название", 13, MUTED)
    var name = _text_input(fields, "Название", str(food.get("name", "")))
    _label(fields, "Штрихкод (необязательно)", 13, MUTED)
    var code = _text_input(fields, "EAN / UPC", str(food.get("barcode", "")))
    code.max_length = 14
    code.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
    _label(fields, "Калории на 100 г", 13, MUTED)
    var kcal = _number(fields, float(food.get("kcal", 0)), 0, 1000, 0.1)
    _label(fields, "Белки • Жиры • Углеводы на 100 г", 13, MUTED)
    var nutrition_row = _row(fields)
    var p = _number(nutrition_row, float(food.get("p", 0)), 0, 100, 0.1)
    var f = _number(nutrition_row, float(food.get("f", 0)), 0, 100, 0.1)
    var c = _number(nutrition_row, float(food.get("c", 0)), 0, 100, 0.1)
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        var changes = {"name": name.text.strip_edges(), "barcode": code.text.strip_edges(),
            "kcal": kcal.value, "p": p.value, "f": f.value, "c": c.value}
        if store.update_custom_food(str(food.get("id", "")), changes):
            var root_control: Control = sheet["root"]
            root_control.queue_free()
            _render()
            _notify_saved("Продукт обновлён")
        else:
            _sheet_error(sheet, "Проверь название, штрихкод и пищевую ценность.")
    )

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
        _notify_saved("Резервная копия сохранена")
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
            _notify_saved("Дневник восстановлен из JSON")
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
