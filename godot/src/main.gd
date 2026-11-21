extends Control

const StoreScript = preload("res://src/store.gd")
const GraphScript = preload("res://src/weight_graph.gd")
const StatsMathScript = preload("res://src/stats_math.gd")
const StatsChartScript = preload("res://src/stats_chart.gd")
const RingScript = preload("res://src/calorie_ring.gd")
const RecipeMath = preload("res://src/recipe_math.gd")
const PortionMath = preload("res://src/portion_math.gd")
const RewardsScript = preload("res://src/rewards.gd")
const ProfilePhotoScript = preload("res://src/profile_photo.gd")
const ProfileProgressScript = preload("res://src/profile_progress.gd")
const OnboardingMath = preload("res://src/onboarding_math.gd")
const BarcodeScript = preload("res://src/barcode_lookup.gd")
const FoodSearchScript = preload("res://src/food_search.gd")
const AppearanceScript = preload("res://src/appearance.gd")
const PatternScript = preload("res://src/theme_pattern.gd")
const MEAL_TEXTURES = [
    preload("res://assets/meals/breakfast.svg"),
    preload("res://assets/meals/lunch.svg"),
    preload("res://assets/meals/dinner.svg"),
    preload("res://assets/meals/snack.svg")
]
const NAV_TEXTURES = {
    "day": preload("res://assets/nav/day.svg"),
    "recipes": preload("res://assets/nav/recipes.svg"),
    "activity": preload("res://assets/nav/activity.svg"),
    "weight": preload("res://assets/nav/weight.svg"),
    "stats": preload("res://assets/nav/stats.svg"),
    "profile": preload("res://assets/nav/profile.svg")
}
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
var OVERVIEW_BG: Color = Color("#fffaf0")
var ACTIVITY_BG: Color = Color("#e9effc")
var TILE_BG: Color = Color("#f2f5fc")
var NAV_ACTIVE: Color = Color("#42628a")
var ACTIVITY_TEXT: Color = Color("#344a87")
var PROTEIN_BG: Color = Color("#d9f0e5")
var FAT_BG: Color = Color("#ffead0")
var CARBS_BG: Color = Color("#e5e1fc")
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
var HIGH_CONTRAST: bool = false
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
var selected_meal: String = "Завтрак"
# A date/meal chosen from a daily card stays fixed through search and scanning.
var _meal_entry_locked: bool = false
var _meal_entry_date: String = ""
var _expanded_meals: Dictionary = {}
var tab: String = "day"
var stats_period: String = "week"
var stats_anchor: String = ""
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
var rewards_expanded: bool = false
var frames_expanded: bool = false
var profile_more_expanded: bool = false
var day_more_expanded: bool = false
var onboarding_step: int = 0
var onboarding_edit: bool = false
var onboarding_draft: Dictionary = {}
var recipe_draft: Dictionary = {}
var recipe_search_text: String = ""
var recipe_list_query: String = ""
var recipe_manual_open: bool = false
var recipe_actions_expanded: Dictionary = {}
var _rendered_view: String = ""
var _scroll_memory: Dictionary = {}
var _render_serial: int = 0
var tab_buttons: Dictionary = {}
var nav_icons: Dictionary = {}
var nav_labels: Dictionary = {}
var barcode_http: HTTPRequest
var catalog_http: HTTPRequest
var search_http: HTTPRequest
var online_search_field: LineEdit
var online_results_box: VBoxContainer
var online_search_label: Label
var online_request_query: String = ""
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
    HIGH_CONTRAST = bool(config.get("high_contrast", false))
    DARK_MODE = current_theme == "dark"
    var palette: Dictionary = AppearanceScript.palette(current_theme, HIGH_CONTRAST)
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
    OVERVIEW_BG = Color(str(palette["overview"]))
    ACTIVITY_BG = Color(str(palette["activity"]))
    TILE_BG = Color(str(palette["tile"]))
    NAV_ACTIVE = Color(str(palette["nav_active"]))
    ACTIVITY_TEXT = Color(str(palette["activity_text"]))
    PROTEIN_BG = Color(str(palette["protein_bg"]))
    FAT_BG = Color(str(palette["fat_bg"]))
    CARBS_BG = Color(str(palette["carbs_bg"]))
    HERO_MUTED = Color(str(palette["hero_muted"]))
    CHIP_BG = Color(str(palette["chip"]))
    CHIP_CAPTION = Color(str(palette["hero_muted"]))
    HERO_TRACK = Color(str(palette["track"]))
    HERO_FILL = Color(str(palette["fill"]))
    MINT = HERO_FILL
    TEXT_ACCENT = Color(str(palette["text_accent"]))
    MACRO_PROTEIN = Color(str(palette["protein_text"]))
    MACRO_FAT = Color(str(palette["fat_text"]))
    MACRO_CARBS = Color(str(palette["carbs_text"]))
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

func _toggle_high_contrast() -> void:
    var previous = bool(store.data["settings"].get("high_contrast", false))
    store.data["settings"]["high_contrast"] = not previous
    if not store.save():
        store.data["settings"]["high_contrast"] = previous
        _message("Не удалось сохранить режим контрастности.")
        return
    _refresh_appearance()
    _render()
    _notify_saved("Повышенная контрастность включена" if not previous else "Обычная контрастность")

# v0.7.18: show the selected third design on the first launch after
# upgrading a standard-theme diary. Do not overwrite the journal, calorie
# goals, theme choices other than "forest", or the user's pattern preference.
# A durable marker prevents switching back after a manual theme change.
func _activate_botanical_default_once() -> void:
    var settings: Dictionary = store.data.get("settings", {})
    if bool(settings.get("botanical_default_applied", false)):
        return
    var previous: Dictionary = settings.duplicate(true)
    settings["botanical_default_applied"] = true
    if str(settings.get("theme", "forest")) == "forest":
        settings["theme"] = "botanical"
    store.data["settings"] = settings
    if not store.save():
        store.data["settings"] = previous


func _ready() -> void:
    _activate_botanical_default_once()
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
    search_http = HTTPRequest.new()
    search_http.timeout = 18.0
    add_child(search_http)
    search_http.request_completed.connect(_on_online_search_completed)
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
    head_style.content_margin_left = 16
    head_style.content_margin_right = 16
    head_style.content_margin_top = 6
    head_style.content_margin_bottom = 6
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
    header_title = _label(brand, "Мой баланс", 20, WHITE)
    header_subtitle = _label(brand, "Забота о себе каждый день", 10, HEADER_MUTED)
    emblem_panel = PanelContainer.new()
    emblem_panel.custom_minimum_size = Vector2(42, 42)
    emblem_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
    emblem_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    var logo_style = StyleBoxFlat.new()
    logo_style.bg_color = LOGO_BG
    logo_style.set_corner_radius_all(13)
    logo_style.content_margin_left = 5
    logo_style.content_margin_right = 5
    logo_style.content_margin_top = 5
    logo_style.content_margin_bottom = 5
    emblem_panel.add_theme_stylebox_override("panel", logo_style)
    heading.add_child(emblem_panel)
    emblem_label = _label(emblem_panel, "✦", 21, SOFT_GOLD)
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
    body.add_theme_constant_override("separation", 9)
    var margins = MarginContainer.new()
    margins.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    margins.mouse_filter = Control.MOUSE_FILTER_PASS
    body.mouse_filter = Control.MOUSE_FILTER_PASS
    margins.add_theme_constant_override("margin_left", 14)
    margins.add_theme_constant_override("margin_right", 14)
    margins.add_theme_constant_override("margin_top", 9)
    margins.add_theme_constant_override("margin_bottom", 15)
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
    if store.needs_onboarding():
        tab = "onboarding"
        onboarding_step = 0
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
    if target != "search":
        _meal_entry_locked = false
        _meal_entry_date = ""
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
    st.set_border_width_all(2 if HIGH_CONTRAST else 1)
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
    st.set_border_width_all(3 if HIGH_CONTRAST else 2)
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
    var compact = s in ["◀", "▶", "‹", "›", "▦", "✎", "×", "+"]
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
        if HIGH_CONTRAST:
            st.border_color = BORDER if secondary else GREEN.darkened(0.16)
            st.set_border_width_all(1)
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
    match variant:
        "hero":
            style.bg_color = HERO_BG
        "tint":
            style.bg_color = TINT_BG
        "overview":
            style.bg_color = OVERVIEW_BG
        "activity":
            style.bg_color = ACTIVITY_BG
        _:
            style.bg_color = CARD_BG
    style.set_corner_radius_all(22)
    style.border_color = BORDER if variant == "plain" or HIGH_CONTRAST else style.bg_color
    if current_theme == "botanical":
        style.border_color = Color("#D9BF8C") if variant == "hero" else BORDER
    style.set_border_width_all(2 if HIGH_CONTRAST else 1)
    # Pastel cards rely on their colored stripe, not a heavy border/shadow.
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.11 if DARK_MODE else 0.065)
    style.shadow_size = 4 if variant == "hero" else (3 if current_theme == "botanical" else 2)
    style.shadow_offset = Vector2(0, 2)
    style.content_margin_left = 17
    style.content_margin_right = 17
    style.content_margin_top = 17
    style.content_margin_bottom = 17
    panel.add_theme_stylebox_override("panel", style)
    body.add_child(panel)
    # Do not place foliage behind calorie totals or macro labels on the day tab.
    # Keep botanical motifs on the wallpaper/header; other tabs retain ornaments.
    if PATTERNS and variant in ["hero", "tint"] and tab != "day":
        var ornament = PatternScript.new()
        ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
        ornament.configure(PATTERN_STYLE, PATTERN_COLOR, true, 0.13 if variant == "hero" else 0.07)
        panel.add_child(ornament)
    if PATTERNS and variant == "activity" and current_theme == "botanical" and tab == "day":
        var mountain_art = PatternScript.new()
        mountain_art.name = "BotanicalActivityLandscape"
        mountain_art.configure("hills", Color("#A7D9BB"), true, 0.13)
        panel.add_child(mountain_art)
    var content = VBoxContainer.new()
    content.mouse_filter = Control.MOUSE_FILTER_PASS
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 11)
    panel.add_child(content)
    if not title.is_empty():
        _label(content, title, 18, WHITE if variant == "hero" or (variant == "activity" and current_theme == "botanical") else INK)
    return content

# Per-day compact cards retain the same colors and contrast but reduce
# vertical padding. This is intentionally scoped to the journal only.
func _compact_card(content: VBoxContainer, margin: int = 9, spacing: int = 5) -> void:
    var panel = content.get_parent() as PanelContainer
    if panel != null:
        var style = panel.get_theme_stylebox("panel") as StyleBoxFlat
        if style != null:
            style.set_corner_radius_all(16)
            style.content_margin_left = margin
            style.content_margin_right = margin
            style.content_margin_top = margin
            style.content_margin_bottom = margin
            style.shadow_size = 2 if current_theme == "botanical" else 1
            style.shadow_offset = Vector2(0, 1)
    content.add_theme_constant_override("separation", spacing)


func _compact_macro(parent: Node, name: String, value: float,
        background: Color, foreground: Color) -> void:
    var panel = PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style = StyleBoxFlat.new()
    style.bg_color = background
    style.set_corner_radius_all(9)
    style.content_margin_left = 5
    style.content_margin_right = 5
    style.content_margin_top = 5
    style.content_margin_bottom = 5
    panel.add_theme_stylebox_override("panel", style)
    parent.add_child(panel)
    var label = _label(panel, name + " " + str(roundi(value)) + " г", 11, foreground)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_OFF
    label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _macro_chip(parent: Node, caption: String, value: float, tint: Color) -> void:
    var panel = PanelContainer.new()
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var style = StyleBoxFlat.new()
    match caption:
        "БЕЛКИ":
            style.bg_color = PROTEIN_BG
        "ЖИРЫ":
            style.bg_color = FAT_BG
        "УГЛЕВОДЫ":
            style.bg_color = CARBS_BG
        _:
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
    _label(content, caption, 11, tint)
    _label(content, str(roundi(value)) + " г", 19, tint)


func _soft_list_row(parent: Node) -> HBoxContainer:
    var panel = PanelContainer.new()
    panel.mouse_filter = Control.MOUSE_FILTER_PASS
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var st = StyleBoxFlat.new()
    st.bg_color = ROW_BG
    if HIGH_CONTRAST:
        st.border_color = BORDER
        st.set_border_width_all(1)
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
    st.content_margin_left = 5
    st.content_margin_right = 5
    st.content_margin_top = 6
    st.content_margin_bottom = 6
    bar.add_theme_stylebox_override("panel", st)
    shell.add_child(bar)
    var row = HBoxContainer.new()
    row.add_theme_constant_override("separation", 2)
    bar.add_child(row)
    var tabs = [
        ["День", "day"], ["Рецепты", "recipes"], ["Спорт", "activity"],
        ["Вес", "weight"], ["Итоги", "stats"], ["Профиль", "profile"]
    ]
    for item in tabs:
        var target: String = item[1]
        var title: String = item[0]
        var button = _button(row, "", func(): _navigate_to_tab(target), true)
        button.name = "NavTab_" + target
        button.tooltip_text = title
        button.custom_minimum_size = Vector2(0, 66)
        button.focus_mode = Control.FOCUS_ALL
        # A full-width tap target contains a centered icon and Russian label.
        var content = VBoxContainer.new()
        content.name = "NavContent"
        content.mouse_filter = Control.MOUSE_FILTER_IGNORE
        content.alignment = BoxContainer.ALIGNMENT_CENTER
        content.add_theme_constant_override("separation", 2)
        button.add_child(content)
        content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        var icon = TextureRect.new()
        icon.name = "NavIcon_" + target
        icon.texture = NAV_TEXTURES[target]
        icon.custom_minimum_size = Vector2(27, 27)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
        content.add_child(icon)
        var caption = Label.new()
        caption.name = "NavLabel_" + target
        caption.text = title
        caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        caption.clip_text = true
        caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        caption.add_theme_font_size_override("font_size", 11)
        caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
        content.add_child(caption)
        tab_buttons[target] = button
        nav_icons[target] = icon
        nav_labels[target] = caption
    _update_tabs()

func _update_tabs() -> void:
    for key in tab_buttons:
        var button: Button = tab_buttons[key]
        var active = key == tab or (key == "profile" and tab == "settings")
        var style = StyleBoxFlat.new()
        style.bg_color = NAV_ACTIVE if active else CARD_BG
        if HIGH_CONTRAST and active:
            style.border_color = SOFT_GOLD
            style.set_border_width_all(2)
        style.set_corner_radius_all(14)
        for state in ["normal", "hover", "pressed"]:
            button.add_theme_stylebox_override(state, style)
        var color = WHITE if active else (MUTED.lightened(0.12) if DARK_MODE else MUTED.darkened(0.12))
        for state in ["font_color", "font_hover_color", "font_pressed_color"]:
            button.add_theme_color_override(state, color)
        if nav_icons.has(key) and is_instance_valid(nav_icons[key]):
            var icon: TextureRect = nav_icons[key]
            icon.modulate = color
        if nav_labels.has(key) and is_instance_valid(nav_labels[key]):
            var caption: Label = nav_labels[key]
            caption.add_theme_color_override("font_color", color)


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
    style.bg_color = TILE_BG
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
    var navigation = shell.get_node_or_null("BottomNavigation") as PanelContainer
    if navigation != null:
        navigation.visible = tab != "onboarding"
    var desired = 0 if reset_position else int(_scroll_memory.get(new_key, 0))
    if reset_position:
        _scroll_memory[new_key] = 0
    _rendered_view = new_key
    _render_serial += 1
    var current_serial = _render_serial
    _update_tabs()
    if is_instance_valid(header_subtitle):
        header_subtitle.visible = true
    # Botanical texture belongs on the wallpaper, not behind nutrition values.
    if is_instance_valid(wallpaper_pattern):
        wallpaper_pattern.configure(PATTERN_STYLE, PATTERN_COLOR, PATTERNS,
            0.085 if current_theme == "botanical" else (
            0.055 if tab == "day" else (0.11 if DARK_MODE else 0.09)))
    if is_instance_valid(header_pattern):
        header_pattern.configure(PATTERN_STYLE, PATTERN_COLOR,
            PATTERNS and (tab != "day" or current_theme == "botanical"),
            0.12 if current_theme == "botanical" else 0.065)
    body.add_theme_constant_override("separation", 7 if tab == "day" else 9)
    for child in body.get_children():
        body.remove_child(child)
        child.queue_free()
    match tab:
        "day": _show_day()
        "onboarding": _show_onboarding()
        "search": _show_food_search()
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
    day_label.custom_minimum_size.y = 36
    _button(r, "▶", func(): date = store.change_date(date, 1); month_shown = date.substr(0, 7); _render(), true)
    _button(r, "▦", func():
        calendar_expanded = not calendar_expanded
        _render()
    , true)

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

func _begin_onboarding(from_settings: bool = false) -> void:
    onboarding_edit = from_settings
    onboarding_step = 0
    var previous = store.data["settings"].get("personal", {})
    if previous is Dictionary and not previous.is_empty():
        onboarding_draft = previous.duplicate(true)
    else:
        var saved_name = str(store.data.get("profile", {}).get("name", ""))
        # Unknown age/height/weight must never be silently pre-filled from examples.
        var initial_weight: float = float(store.data["settings"]["start"]) if from_settings else 0.0
        onboarding_draft = {
            "name": "" if saved_name == "Мой профиль" else saved_name,
            "age":0, "height":0.0,
            "weight":initial_weight,
            "goal_weight":float(store.data["settings"]["goal"]) if from_settings else 0.0,
            "formula":"female", "activity":0, "goal":0
        }
    tab = "onboarding"
    _render(true)

func _show_onboarding() -> void:
    var intro = _card("Мой баланс · знакомство", "hero")
    _label(intro, "Два коротких шага для личного ориентира по калориям.", 14, HERO_MUTED)
    _label(intro, "Шаг " + str(onboarding_step + 1) + " из 2", 13, SOFT_GOLD)
    if onboarding_edit:
        _button(intro, "← Отмена и назад к настройкам", func():
            tab = "settings"
            _render(true)
        , true)
    if onboarding_draft.is_empty():
        _begin_onboarding(onboarding_edit)
        return
    if onboarding_step == 0:
        var personal = _card("О тебе")
        _label(personal, "Возраст, рост и текущий вес обязательно введи сама. Примерные числа больше не подставляются.", 12, MUTED)
        _label(personal, "Имя", 14, MUTED)
        var name = _text_input(personal, "Как к тебе обращаться", str(onboarding_draft.get("name", "")))
        name.name = "OnboardingName"
        name.max_length = 45
        var fields = _row(personal)
        var age_col = VBoxContainer.new()
        age_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        fields.add_child(age_col)
        _label(age_col, "Возраст, лет", 13, MUTED)
        var stored_age: int = int(onboarding_draft.get("age", 0))
        var age = _text_input(age_col, "Возраст", "" if stored_age <= 0 else str(stored_age))
        age.name = "OnboardingAge"
        age.max_length = 3
        var height_col = VBoxContainer.new()
        height_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        fields.add_child(height_col)
        _label(height_col, "Рост, см", 13, MUTED)
        var stored_height: float = float(onboarding_draft.get("height", 0))
        var height = _text_input(height_col, "Рост", "" if stored_height <= 0 else str(snappedf(stored_height, 0.1)))
        height.name = "OnboardingHeight"
        height.max_length = 6
        _label(personal, "Текущий вес, кг", 13, MUTED)
        var stored_weight: float = float(onboarding_draft.get("weight", 0))
        var weight = _text_input(personal, "Текущий вес (не желаемый)", "" if stored_weight <= 0 else str(snappedf(stored_weight, 0.1)))
        weight.name = "OnboardingWeight"
        weight.max_length = 6
        _label(personal, "Вариант формулы расчёта", 13, MUTED)
        var formula = _choice(personal, OnboardingMath.SEX_LABELS)
        formula.name = "OnboardingFormula"
        var options = ["female", "male", "manual"]
        formula.select(maxi(0, options.find(str(onboarding_draft.get("formula", "female")))))
        _label(personal, "В расчёте используются разные коэффициенты. Можно отказаться от формулы и ввести норму вручную.", 12, MUTED)
        _button(personal, "Дальше →", func():
            var next = onboarding_draft.duplicate(true)
            var age_value = age.text.strip_edges()
            var height_value = height.text.strip_edges().replace(",", ".")
            var weight_value = weight.text.strip_edges().replace(",", ".")
            if not age_value.is_valid_int() or not height_value.is_valid_float() or not weight_value.is_valid_float():
                _message("Введи возраст, рост и текущий вес цифрами.")
                return
            next["name"] = name.text.strip_edges()
            next["age"] = age_value.to_int()
            next["height"] = height_value.to_float()
            next["weight"] = weight_value.to_float()
            next["formula"] = options[formula.selected]
            if float(next.get("goal_weight", 0)) <= 0:
                next["goal_weight"] = next["weight"]
            if str(next["name"]).is_empty():
                _message("Введи имя для профиля.")
                return
            if not OnboardingMath.valid_details(next):
                _message("Проверь возраст, рост и вес. Анкета рассчитана на взрослых от 18 лет.")
                return
            onboarding_draft = next
            onboarding_step = 1
            _hide_keyboard_and_focus()
            _render(true)
        )
    else:
        var choices = _card("Активность и цель")
        var formula_name = {
            "female":"Женская формула", "male":"Мужская формула", "manual":"Ручная норма"
        }.get(str(onboarding_draft.get("formula", "female")), "Ручная норма")
        _label(choices, "Проверь исходные данные: " +
            str(onboarding_draft["age"]) + " лет · " +
            str(roundi(float(onboarding_draft["height"]))) + " см · " +
            str(snappedf(float(onboarding_draft["weight"]), 0.1)) + " кг\n" +
            str(formula_name) + ". Если вес неверный — вернись на первый шаг.", 13, TEXT_ACCENT)
        _label(choices, "Твой обычный уровень активности", 13, MUTED)
        var activity = _choice(choices, OnboardingMath.ACTIVITY_LABELS)
        activity.name = "OnboardingActivity"
        activity.select(clampi(int(onboarding_draft.get("activity", 0)), 0, 3))
        _label(choices, "Что хочешь изменить?", 13, MUTED)
        var goal = _choice(choices, OnboardingMath.GOALS)
        goal.name = "OnboardingGoal"
        goal.select(clampi(int(onboarding_draft.get("goal", 0)), 0, 2))
        _label(choices, "Желаемый вес, кг (можно оставить текущий)", 13, MUTED)
        var goal_weight = _number(choices, float(onboarding_draft.get("goal_weight", onboarding_draft["weight"])), 25, 350, 0.1)
        goal_weight.name = "OnboardingGoalWeight"
        var estimate_label = _label(choices, "", 13, MUTED)
        estimate_label.name = "OnboardingEstimate"
        _label(choices, "Мой ориентир, ккал в день", 14, TEXT_ACCENT)
        var calories = _text_input(choices, "Например, 1800", str(roundi(float(store.data["settings"]["kcal"]))))
        calories.name = "OnboardingCalories"
        calories.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
        calories.max_length = 4
        _label(choices, "Можешь заменить рассчитанную цифру своей нормой и сохранить её.", 12, MUTED)
        var compute_preview = func(_index: int):
            var details = onboarding_draft.duplicate(true)
            details["activity"] = activity.selected
            details["goal"] = goal.selected
            details["goal_weight"] = goal_weight.value
            var calculation: Dictionary = OnboardingMath.estimate(details)
            if calculation.is_empty():
                estimate_label.text = "Не удалось рассчитать: проверь анкету."
                return
            if bool(calculation["automatic"]):
                calories.text = str(roundi(float(calculation["kcal"])))
                estimate_label.text = "Оценка поддержания: " + str(roundi(float(calculation["maintenance"]))) + " ккал.\n" + str(calculation["message"])
            else:
                estimate_label.text = str(calculation["message"])
        activity.item_selected.connect(compute_preview)
        goal.item_selected.connect(compute_preview)
        compute_preview.call(0)
        var action_buttons = _row(choices)
        _button(action_buttons, "← Назад", func():
            onboarding_draft["activity"] = activity.selected
            onboarding_draft["goal"] = goal.selected
            onboarding_draft["goal_weight"] = goal_weight.value
            onboarding_step = 0
            _render(true)
        , true)
        _button(action_buttons, "Сохранить и начать", func():
            var details = onboarding_draft.duplicate(true)
            details["activity"] = activity.selected
            details["goal"] = goal.selected
            details["goal_weight"] = goal_weight.value
            if not OnboardingMath.valid_details(details):
                _message("Проверь указанные параметры.")
                return
            var manual_kcal: int = StoreScript.parse_calorie_target(calories.text)
            if manual_kcal < 0:
                _message("Введи суточную норму от 1000 до 5000 ккал.")
                return
            if store.complete_onboarding(details, float(manual_kcal)):
                onboarding_draft.clear()
                onboarding_step = 0
                var return_tab = "settings" if onboarding_edit else "day"
                onboarding_edit = false
                tab = return_tab
                _hide_keyboard_and_focus()
                _render(true)
                _notify_saved("Твой ориентир по калориям сохранён")
            else:
                _message("Не удалось сохранить анкету. Проверь свободное место.")
        )
        _label(choices, "Это ориентировочная оценка для взрослых, не медицинское назначение. При беременности, грудном вскармливании или заболеваниях нужна индивидуальная консультация.", 12, MUTED)

func _show_calorie_goal_editor() -> void:
    var sheet = _mobile_sheet(
        "Изменить норму калорий",
        "Введи свой ориентир на день. Анкету повторять не нужно — записи питания и вес сохраняются.",
        "Сохранить", 330.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, "Калории в сутки", 14, INK)
    var current = int(store.data["settings"]["kcal"])
    var input = _text_input(fields, "Например, 1800", str(current))
    input.name = "CalorieGoalEditorInput"
    input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
    input.max_length = 4
    var hint = _label(fields, "Допустимый диапазон: 1000–5000 ккал. Это индивидуальный ориентир, который можно менять.", 12, MUTED)
    input.text_changed.connect(func(_value: String):
        var value = StoreScript.parse_calorie_target(input.text)
        hint.text = "Будет сохранено: " + str(value) + " ккал" if value > 0 else (
            "Введи целое число от 1000 до 5000 ккал."
        )
    )
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        var value = StoreScript.parse_calorie_target(input.text)
        if value < 0:
            _sheet_error(sheet, "Укажи число от 1000 до 5000 ккал, например 1800.")
            return
        if not store.set_daily_calorie_goal(value):
            _sheet_error(sheet, "Не удалось сохранить норму. Проверь свободное место.")
            return
        _hide_keyboard_and_focus()
        sheet["root"].queue_free()
        _render()
        _notify_saved("Норма изменена: " + str(value) + " ккал")
    )


func _show_profile() -> void:
    var profile: Dictionary = store.data.get("profile", {})
    var hero = _card("", "hero")
    hero.get_parent().name = "ProfileHero"
    _compact_card(hero, 14, 9)
    var intro = _row(hero)
    var badge = PanelContainer.new()
    badge.custom_minimum_size = Vector2(74, 74)
    var badge_style = StyleBoxFlat.new()
    badge_style.bg_color = CHIP_BG
    badge_style.set_corner_radius_all(37)
    var frame_data: Dictionary = RewardsScript.frame_by_id(str(profile.get("frame", "plain")))
    badge_style.border_color = Color(str(frame_data.get("color", "#9AAFA8")))
    badge_style.set_border_width_all(4 if str(profile.get("frame", "plain")) != "plain" else 1)
    var photo_texture = ProfilePhotoScript.decode_photo(str(profile.get("photo", "")))
    var inset = 1 if photo_texture != null else 14
    badge_style.content_margin_left = inset
    badge_style.content_margin_right = inset
    badge_style.content_margin_top = 1 if photo_texture != null else 10
    badge_style.content_margin_bottom = 1 if photo_texture != null else 10
    badge.add_theme_stylebox_override("panel", badge_style)
    intro.add_child(badge)
    if photo_texture != null:
        var avatar_picture = TextureRect.new()
        avatar_picture.name = "ProfileAvatarPhoto"
        avatar_picture.texture = photo_texture
        avatar_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        avatar_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        avatar_picture.custom_minimum_size = Vector2(66, 66)
        avatar_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var crop_shader = Shader.new()
        crop_shader.code = "shader_type canvas_item; void fragment() { vec4 pixel = texture(TEXTURE, UV); float mask = 1.0 - smoothstep(0.48, 0.5, distance(UV, vec2(0.5))); COLOR = vec4(pixel.rgb, pixel.a * mask); }"
        var crop_material = ShaderMaterial.new()
        crop_material.shader = crop_shader
        avatar_picture.material = crop_material
        badge.add_child(avatar_picture)
    else:
        var avatar = _label(badge, _avatar_character(str(profile.get("avatar", "leaf"))), 37, SOFT_GOLD)
        avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    var identity = VBoxContainer.new()
    identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    identity.add_theme_constant_override("separation", 4)
    intro.add_child(identity)
    _label(identity, str(profile.get("name", "Мой профиль")), 23, WHITE)
    _label(identity, str(profile.get("motto", "")), 13, HERO_MUTED)

    var settings: Dictionary = store.data["settings"]
    var progress: Dictionary = ProfileProgressScript.summarize(settings, store.data["weights"])
    var weight_metrics = _row(hero)
    weight_metrics.name = "ProfileWeightMetrics"
    weight_metrics.add_theme_constant_override("separation", 10)
    var current_col = VBoxContainer.new()
    current_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    current_col.add_theme_constant_override("separation", 2)
    weight_metrics.add_child(current_col)
    _label(current_col, "Сейчас", 12, HERO_MUTED)
    var current_value = _label(current_col, str(snappedf(float(progress["latest"]), 0.1)) + " кг", 20, WHITE)
    current_value.name = "ProfileCurrentWeight"
    var goal_col = VBoxContainer.new()
    goal_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    goal_col.add_theme_constant_override("separation", 2)
    weight_metrics.add_child(goal_col)
    _label(goal_col, "Цель", 12, HERO_MUTED)
    var goal_value = _label(goal_col, str(snappedf(float(progress["goal"]), 0.1)) + " кг", 20, WHITE)
    goal_value.name = "ProfileTargetWeight"
    var progress_caption = _row(hero)
    var caption_text = _label(progress_caption, "Прогресс к цели", 12, HERO_MUTED)
    caption_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var value_text = _label(progress_caption, str(roundi(float(progress["progress"]))) + "%", 14, WHITE)
    value_text.name = "ProfileGoalPercent"
    var bar = ProgressBar.new()
    bar.name = "ProfileGoalProgress"
    bar.min_value = 0.0
    bar.max_value = 100.0
    bar.value = float(progress["progress"])
    bar.show_percentage = false
    bar.custom_minimum_size.y = 12
    _style_progress(bar)
    hero.add_child(bar)
    var goal_status = "Цель достигнута" if bool(progress["reached"]) else (
        "До цели: " + str(snappedf(float(progress["remaining"]), 0.1)) + " кг"
    )
    var source = " · Последняя запись: " + str(progress["date"]) if bool(progress["has_records"]) else " · Пока используем стартовый вес"
    _label(hero, goal_status + " · Старт: " +
        str(snappedf(float(progress["start"]), 0.1)) + " кг" + source, 11, HERO_MUTED)
    var quick_weight = _button(hero, "＋ Записать вес", func(): _navigate_to_tab("weight"), true)
    quick_weight.name = "ProfileAddWeight"
    quick_weight.custom_minimum_size.y = 39
    quick_weight.add_theme_font_size_override("font_size", 13)
    var overview = _card("Мои ориентиры")
    _compact_card(overview, 12, 7)
    var change: float = float(progress["change"])
    _label(overview, str(roundi(float(settings["kcal"]))) +
        " ккал в сутки · Изменение с начала: " +
        ("+" if change > 0.0 else "") + str(snappedf(change, 0.1)) + " кг", 13, INK)
    var kcal_button = _button(overview, "✎ Изменить норму калорий",
        func(): _show_calorie_goal_editor(), true)
    kcal_button.custom_minimum_size.y = 39

    var summary: Dictionary = store.reward_summary()
    var awards = _card("Звёзды и награды", "tint")
    _compact_card(awards, 12, 7)
    _label(awards, "★ " + str(summary["points"]) + " звёзд  ·  Уровень " +
        str(summary["level"]) + "  ·  Серия " + str(summary["streak"]) + " дн.", 14, TEXT_ACCENT)
    var level_bar = ProgressBar.new()
    level_bar.name = "RewardLevelProgress"
    level_bar.min_value = 0.0
    level_bar.max_value = 100.0
    level_bar.value = float(summary["level_progress"])
    _style_progress(level_bar)
    awards.add_child(level_bar)
    _button(awards, "▴ Скрыть достижения" if rewards_expanded else "▾ Показать все достижения", func():
        rewards_expanded = not rewards_expanded
        _render()
    , true)
    if rewards_expanded:
        _label(awards, str(summary["earned"]) + " из " +
            str(RewardsScript.AWARDS.size()) + " достижений открыто", 12, MUTED)
        for achievement in RewardsScript.AWARDS:
            var achieved: bool = bool(summary["badges"].get(str(achievement["id"]), false))
            var award_row = _soft_list_row(awards)
            _label(award_row,
                ("✦ " if achieved else "◇ ") + str(achievement["title"]) +
                " · " + str(achievement["hint"]), 12,
                TEXT_ACCENT if achieved else MUTED)
        _label(awards, "За записи еды, движение и рецепты — без штрафов за превышение калорий.", 12, MUTED)
        _button(awards, "▴ Скрыть рамки" if frames_expanded else "▾ Выбрать рамку", func():
            frames_expanded = not frames_expanded
            _render()
        , true)
        if frames_expanded:
            for unlocked_frame in RewardsScript.FRAMES:
                var frame_id: String = str(unlocked_frame["id"])
                var limit: int = int(unlocked_frame["points"])
                var available: bool = int(summary["points"]) >= limit
                var frame_row = _soft_list_row(awards)
                var swatch = ColorRect.new()
                swatch.color = Color(str(unlocked_frame["color"]))
                swatch.custom_minimum_size = Vector2(24, 24)
                frame_row.add_child(swatch)
                var frame_label = _label(frame_row, str(unlocked_frame["name"]) +
                    (" · открыта" if available else " · от " + str(limit) + " ★"), 12, INK)
                frame_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                var select_button = _button(frame_row,
                    "✓" if str(profile.get("frame", "plain")) == frame_id else "Выбрать",
                    func():
                        if store.choose_avatar_frame(frame_id):
                            _render()
                            _notify_saved("Рамка изменена")
                        else:
                            _message("Для рамки пока не хватает звёзд.")
                , true)
                select_button.disabled = not available

    var edit = _card("Личная страница")
    _compact_card(edit, 12, 6)
    _button(edit, "📷 Выбрать фото для аватара", func(): _pick_avatar_photo(), true)
    if not str(profile.get("photo", "")).is_empty():
        _button(edit, "Удалить фото (вернуть значок)", func():
            _confirm_delete("Удалить фото профиля? Значок останется доступен.", func():
                if store.update_avatar_photo(""):
                    _render()
                    _notify_saved("Фото аватара удалено")
                else:
                    _message("Не удалось удалить фото.")
            )
        , true)
    if profile_edit_open:
        _label(edit, "Фото остаётся на устройстве и входит в резервную JSON-копию.", 12, MUTED)
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
    _button(edit, "⚙ Настройки и анкета", func():
        settings_page = "main"
        _navigate_to_tab("settings")
    , true)

func _pick_avatar_photo() -> void:
    var supported = PackedStringArray([
        "*.jpg,*.jpeg,*.png,*.webp;Фотографии;image/jpeg,image/png,image/webp"
    ])
    # Android 10+ uses SAF: FileAccess can read the selected content:// URI
    # without broad gallery/storage permissions.
    if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
        var result = DisplayServer.file_dialog_show(
            "Выбрать фото профиля", "", "", false,
            DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, supported,
            func(accepted: bool, paths: PackedStringArray, _filter_index: int):
                if accepted and not paths.is_empty():
                    _read_avatar_photo(paths[0])
        )
        if result == OK:
            return
    var picker = FileDialog.new()
    picker.use_native_dialog = true
    picker.access = FileDialog.ACCESS_FILESYSTEM
    picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    picker.filters = supported
    add_child(picker)
    picker.file_selected.connect(func(path: String):
        _read_avatar_photo(path)
        picker.queue_free()
    )
    picker.canceled.connect(func(): picker.queue_free())
    picker.popup_centered_ratio(0.85)


func _read_avatar_photo(path: String) -> void:
    var file = FileAccess.open(path, FileAccess.READ)
    if file == null:
        _message("Не получилось открыть фото. Выбери JPEG, PNG или WebP.")
        return
    if file.get_length() > ProfilePhotoScript.MAX_SOURCE_BYTES or file.get_length() <= 0:
        file.close()
        _message("Фото слишком большое. Выбери файл до 16 МБ.")
        return
    var bytes = file.get_buffer(file.get_length())
    file.close()
    _apply_avatar_photo_bytes(bytes)


func _apply_avatar_photo_bytes(bytes: PackedByteArray) -> bool:
    var encoded: String = ProfilePhotoScript.make_photo(bytes)
    if encoded.is_empty():
        _message("Не удалось обработать фото. Нужны JPEG, PNG или WebP до 16 МБ.")
        return false
    if not store.update_avatar_photo(encoded):
        _message("Не удалось сохранить фото. Проверь свободное место.")
        return false
    _render()
    _notify_saved("Фото профиля сохранено")
    return true


# Optional photographs use the same validated, locally stored JPEG data as
# avatar photos. Never load remote images or modify the recipe before Save.
func _recipe_photo_thumb(parent: Node, recipe: Dictionary, side: int = 74) -> void:
    var frame = PanelContainer.new()
    frame.name = "RecipePhotoThumb"
    frame.custom_minimum_size = Vector2(side, side)
    frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    var backing = StyleBoxFlat.new()
    backing.bg_color = TINT_BG if not DARK_MODE else CHIP_BG
    backing.border_color = BORDER
    backing.set_border_width_all(1)
    backing.set_corner_radius_all(14)
    backing.content_margin_left = 5
    backing.content_margin_right = 5
    backing.content_margin_top = 5
    backing.content_margin_bottom = 5
    frame.add_theme_stylebox_override("panel", backing)
    parent.add_child(frame)
    var art = TextureRect.new()
    art.name = "RecipePhotoImage"
    var saved_image: ImageTexture = ProfilePhotoScript.decode_photo(str(recipe.get("photo", "")))
    art.texture = saved_image if saved_image != null else NAV_TEXTURES["recipes"]
    art.modulate = Color.WHITE if saved_image != null else TEXT_ACCENT
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if saved_image != null else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    art.custom_minimum_size = Vector2(side - 10, side - 10)
    art.clip_contents = true
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    frame.add_child(art)


func _pick_recipe_photo() -> void:
    var filters = PackedStringArray([
        "*.jpg,*.jpeg,*.png,*.webp;Фото блюда;image/jpeg,image/png,image/webp"
    ])
    if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
        var status = DisplayServer.file_dialog_show(
            "Фото блюда", "", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
            filters,
            func(accepted: bool, paths: PackedStringArray, _filter_index: int):
                if accepted and not paths.is_empty():
                    _read_recipe_photo(paths[0])
        )
        if status == OK:
            return
    var picker = FileDialog.new()
    picker.use_native_dialog = true
    picker.access = FileDialog.ACCESS_FILESYSTEM
    picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    picker.filters = filters
    add_child(picker)
    picker.file_selected.connect(func(path: String):
        _read_recipe_photo(path)
        picker.queue_free()
    )
    picker.canceled.connect(func(): picker.queue_free())
    picker.popup_centered_ratio(0.85)


func _read_recipe_photo(path: String) -> void:
    var source = FileAccess.open(path, FileAccess.READ)
    if source == null:
        _message("Не удалось открыть фото блюда. Выбери JPEG, PNG или WebP.")
        return
    if source.get_length() <= 0 or source.get_length() > ProfilePhotoScript.MAX_SOURCE_BYTES:
        source.close()
        _message("Фото должно быть не больше 16 МБ.")
        return
    var raw = source.get_buffer(source.get_length())
    source.close()
    _apply_recipe_photo_bytes(raw)


func _apply_recipe_photo_bytes(raw: PackedByteArray) -> bool:
    var picture = ProfilePhotoScript.make_photo(raw)
    if picture.is_empty():
        _message("Фото не обработано. Поддерживаются JPEG, PNG и WebP до 16 МБ.")
        return false
    recipe_draft["photo"] = picture
    _render()
    _notify_saved("Фото добавлено к черновику. Сохрани рецепт.")
    return true


func _begin_recipe_editor(recipe: Dictionary = {}) -> void:
    recipe_editor_open = true
    recipe_search_text = ""
    recipe_manual_open = false
    if recipe.is_empty():
        recipe_draft = {
            "id": "", "name": "", "cooked_weight": 500.0,
            "servings": 4.0, "ingredients": [], "photo": ""
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
    var needle = search.text.strip_edges()
    filtered.clear()
    picker.clear()
    for food in store.all_foods():
        if FoodSearchScript.matches(food, needle):
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
    var picture_row = _row(toolbar)
    _recipe_photo_thumb(picture_row, recipe_draft, 70)
    var picture_actions = VBoxContainer.new()
    picture_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    picture_actions.add_theme_constant_override("separation", 4)
    picture_row.add_child(picture_actions)
    var photo_button = _button(picture_actions, "📷 Фото блюда", func():
        _recipe_sync_form(name, cooked, portions)
        _pick_recipe_photo()
    , true)
    photo_button.name = "RecipeChoosePhoto"
    photo_button.custom_minimum_size.y = 38
    if not str(recipe_draft.get("photo", "")).is_empty():
        var remove_photo = _button(picture_actions, "Удалить фото", func():
            _recipe_sync_form(name, cooked, portions)
            recipe_draft["photo"] = ""
            _render()
        , true)
        remove_photo.name = "RecipeRemovePhoto"
        remove_photo.custom_minimum_size.y = 34
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
        var recipe_id: String = str(recipe.get("id", ""))
        var card = _card("")
        card.get_parent().name = "RecipeCard_" + recipe_id
        _compact_card(card, 11, 7)
        var overview = _row(card)
        overview.add_theme_constant_override("separation", 10)
        _recipe_photo_thumb(overview, recipe, 76)
        var summary = VBoxContainer.new()
        summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        summary.add_theme_constant_override("separation", 3)
        overview.add_child(summary)
        var title = _label(summary, str(recipe.get("name", "Блюдо")), 16, INK)
        title.name = "RecipeCardTitle"
        title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        var serving_count: float = maxf(1.0, float(recipe.get("servings", 1.0)))
        var serving_grams: float = float(recipe["cooked_weight"]) / serving_count
        var portion_summary = _label(summary,
            str(roundi(float(details["total_kcal"]) / serving_count)) +
            " ккал / порция · " + str(roundi(serving_grams)) + " г", 13, TEXT_ACCENT)
        portion_summary.name = "RecipeCardKcal"
        var macros = _label(summary, "Б " +
            str(snappedf(float(details["total_p"]) / serving_count, 0.1)) +
            "  Ж " + str(snappedf(float(details["total_f"]) / serving_count, 0.1)) +
            "  У " + str(snappedf(float(details["total_c"]) / serving_count, 0.1)) +
            " г / порция", 11, MUTED)
        macros.name = "RecipeCardMacros"
        var actions = _row(card)
        actions.add_theme_constant_override("separation", 6)
        var add_portion = _button(actions, "+ Добавить порцию в дневник",
            func(): _recipe_portion_sheet(recipe))
        add_portion.custom_minimum_size.y = 42
        add_portion.add_theme_font_size_override("font_size", 12)
        var options = _button(actions, "⋯", func():
            recipe_actions_expanded[recipe_id] = not bool(recipe_actions_expanded.get(recipe_id, false))
            _render()
        , true)
        options.name = "RecipeCardMore"
        options.tooltip_text = "Действия с рецептом"
        options.custom_minimum_size = Vector2(44, 42)
        options.size_flags_horizontal = Control.SIZE_SHRINK_END
        options.add_theme_font_size_override("font_size", 22)
        if bool(recipe_actions_expanded.get(recipe_id, false)):
            var more = _row(card)
            more.name = "RecipeCardActions"
            _button(more, "✎ Изменить", func(): _begin_recipe_editor(recipe), true)
            _button(more, "Удалить", func():
                _confirm_delete("Удалить рецепт «" + str(recipe["name"]) + "»? Уже записанные порции останутся в дневнике.", func():
                    if store.delete_recipe(recipe_id):
                        recipe_actions_expanded.erase(recipe_id)
                        _render()
                        _notify_saved("Рецепт удалён")
                    else:
                        _message("Не удалось удалить рецепт.")
                )
            , true)
    if matched == 0 and not recipes.is_empty():
        var no_results = _card("Ничего не найдено")
        _label(no_results, "Попробуй другое название или очисти поиск.", 13, MUTED)

func _selected_food_date() -> String:
    return _meal_entry_date if _meal_entry_locked and not _meal_entry_date.is_empty() else date


func _open_meal_catalog(meal_name: String) -> void:
    # A selected diary section fixes both the destination meal and day.
    selected_meal = meal_name
    _meal_entry_locked = true
    _meal_entry_date = date
    _hide_keyboard_and_focus()
    tab = "search"
    _render(true)


func _reveal_barcode_section() -> void:
    var section = find_child("FoodBarcodePanel", true, false) as VBoxContainer
    var divider = find_child("FoodBarcodeDivider", true, false) as HSeparator
    if section != null:
        section.visible = true
    if divider != null:
        divider.visible = true
    if is_instance_valid(barcode_input):
        _ensure_field_visible(barcode_input)


func _meal_scan_or_manual(meal_name: String) -> void:
    selected_meal = meal_name
    _meal_entry_locked = true
    _meal_entry_date = date
    if barcode_scanner != null:
        barcode_scanner.scanBarcode()
    else:
        _open_meal_catalog(meal_name)
        _reveal_barcode_section()
        _barcode_message("На этом устройстве сканирование недоступно. Введи EAN/UPC с упаковки.")


func _repeat_recent_in_meal(food: Dictionary, recent: Dictionary, sheet: Dictionary) -> void:
    # Repeating is explicit. The destination is the meal/day selected before
    # opening the sheet, never the last meal stored in the old diary entry.
    var grams = float(recent.get("grams", 0))
    var portion_label = str(recent.get("portion_label", ""))
    if store.add_food_entry(food, grams, selected_meal, _selected_food_date(), portion_label):
        sheet["root"].queue_free()
        _barcode_add_success()
    else:
        _sheet_error(sheet, "Не удалось повторить порцию. Проверь память устройства.")


func _show_meal_add_actions(meal_name: String) -> void:
    if meal_name not in StoreScript.MEAL_NAMES:
        return
    selected_meal = meal_name
    _meal_entry_locked = true
    _meal_entry_date = date
    var recent: Array = store.recent_food_entries(3)
    var sheet = _mobile_sheet("Добавить в " + meal_name.to_lower(),
        "Дата: " + date.substr(8, 2) + "." + date.substr(5, 2) + "." + date.substr(0, 4) +
        ". Поиск, недавние продукты и штрихкод.", "⌕ Найти продукт",
        540.0 if not recent.is_empty() else 370.0)
    var fields: VBoxContainer = sheet["fields"]
    if not recent.is_empty():
        _label(fields, "Недавние продукты", 15, TEXT_ACCENT)
        for record in recent:
            var item: Dictionary = record["food"]
            var row = _soft_list_row(fields)
            var name = _button(row, str(item.get("name", "Продукт")), func():
                sheet["root"].queue_free()
                await get_tree().process_frame
                _quick_food_sheet(item)
            , true)
            name.clip_text = true
            name.custom_minimum_size = Vector2(75, 39)
            name.add_theme_font_size_override("font_size", 12)
            var grams = float(record["grams"])
            var unit = str(record["unit"])
            var repeat = _button(row, "↻ " + str(roundi(grams)) + " " + unit,
                func(): _repeat_recent_in_meal(item, record, sheet), true)
            repeat.name = "RepeatRecentMealPortion"
            repeat.custom_minimum_size = Vector2(90, 39)
            repeat.size_flags_horizontal = Control.SIZE_SHRINK_END
            repeat.add_theme_font_size_override("font_size", 12)
    else:
        _label(fields, "Недавние продукты появятся после первой записи питания.", 12, MUTED)
    var favorites_shown: int = 0
    for favorite_id in store.data.get("favorites", []):
        if favorites_shown >= 2:
            break
        var favorite: Dictionary = store.food_by_id(str(favorite_id))
        if favorite.is_empty():
            continue
        if favorites_shown == 0:
            _label(fields, "★ Избранное", 15, TEXT_ACCENT)
        var favorite_button = _button(fields, "★ " + str(favorite.get("name", "Продукт")), func():
            sheet["root"].queue_free()
            await get_tree().process_frame
            _quick_food_sheet(favorite)
        , true)
        favorite_button.clip_text = true
        favorite_button.custom_minimum_size.y = 39
        favorites_shown += 1
    var scan = _button(fields, "▣ Сканировать штрихкод", func():
        sheet["root"].queue_free()
        _meal_scan_or_manual(meal_name)
    )
    scan.name = "MealScanBarcode"
    var manual = _button(fields, "Ввести штрихкод вручную", func():
        sheet["root"].queue_free()
        _open_meal_catalog(meal_name)
        _reveal_barcode_section()
        _barcode_message("Введи номер с упаковки в поле EAN/UPC.")
    , true)
    manual.name = "MealEnterBarcode"
    sheet["confirm"].pressed.connect(func():
        sheet["root"].queue_free()
        _open_meal_catalog(meal_name)
    )


func _lookup_online_products(raw_terms: String) -> void:
    if not is_instance_valid(online_search_label) or not is_instance_valid(online_results_box):
        return
    var query = raw_terms.strip_edges()
    var url = BarcodeScript.search_url(query)
    if url.is_empty():
        online_search_label.text = "Введи минимум 2 символа названия или бренда."
        return
    if search_http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        online_search_label.text = "Поиск уже выполняется. Повтори после ответа."
        return
    online_request_query = query
    online_results_box.visible = false
    for child in online_results_box.get_children():
        child.queue_free()
    online_search_label.text = "Ищем «" + query + "» в Open Food Facts…"
    var headers = PackedStringArray([
        "User-Agent: MyBalance/0.7.23 (+https://github.com/Domenklay/My_balance)",
        "Accept: application/json"
    ])
    if search_http.request(url, headers, HTTPClient.METHOD_GET) != OK:
        online_request_query = ""
        online_search_label.text = "Не удалось начать поиск. Проверь интернет."


func _on_online_search_completed(result: int, status: int,
        _headers: PackedStringArray, body: PackedByteArray) -> void:
    var query = online_request_query
    online_request_query = ""
    if tab != "search" or not is_instance_valid(online_search_field) or \
            not is_instance_valid(online_results_box) or \
            not is_instance_valid(online_search_label):
        return
    if FoodSearchScript.normalize(query) != FoodSearchScript.normalize(online_search_field.text):
        return
    if result != HTTPRequest.RESULT_SUCCESS or status != 200:
        online_search_label.text = "Сервис недоступен. Локальный каталог работает без интернета."
        return
    if body.size() > 1500000:
        online_search_label.text = "Ответ слишком большой. Уточни название."
        return
    var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
    if not (parsed is Dictionary and parsed.get("products") is Array):
        online_search_label.text = "Сервис вернул некорректный список."
        return
    _show_online_search_results(BarcodeScript.parse_search_results(parsed, 12))


func _show_online_search_results(records: Array) -> void:
    if not is_instance_valid(online_results_box) or not is_instance_valid(online_search_label):
        return
    for old in online_results_box.get_children():
        old.queue_free()
    if records.is_empty():
        online_results_box.visible = false
        online_search_label.text = "Продукты с полными КБЖУ не найдены. Попробуй другое название."
        return
    online_results_box.visible = true
    online_search_label.text = "Найдено " + str(records.size()) + \
        " продуктов · проверь данные по упаковке перед сохранением."
    for record in records:
        var product: Dictionary = record
        var row = _soft_list_row(online_results_box)
        var info = VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        var name_label = _label(info, str(product.get("name", "Продукт")), 12, INK)
        name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _label(info, str(roundi(float(product.get("kcal", 0)))) +
            " ккал / 100 " + PortionMath.base_unit(product) + " · Б " +
            str(product.get("p", 0)) + " Ж " + str(product.get("f", 0)) +
            " У " + str(product.get("c", 0)), 11, MUTED)
        var choose = _button(row, "Выбрать", func():
            _confirm_barcode_product(product)
        , true)
        choose.custom_minimum_size.y = 40
        choose.size_flags_horizontal = Control.SIZE_SHRINK_END
        choose.add_theme_font_size_override("font_size", 12)


func _show_food_search() -> void:
    var intro = _card("Каталог продуктов", "hero")
    _label(intro, "Локальные продукты и онлайн-база Open Food Facts.", 14, HERO_MUTED)
    _label(intro, "Дата: " + _selected_food_date() + " · Приём пищи: " + selected_meal, 13, HERO_MUTED)
    _button(intro, "← Вернуться в дневник", func(): _navigate_to_tab("day"), true)
    var catalog = _card("Найти и добавить продукты")
    _food_form(catalog)


func _show_day() -> void:
    var overview = _card("", "overview")
    _compact_card(overview, 5, 2)
    _date_nav(overview)
    # Reduce decorative date padding without shrinking touch targets below 38.
    overview.get_parent().name = "DayDateNavigation"
    for control in overview.get_children():
        if control is HBoxContainer:
            control.add_theme_constant_override("separation", 5)
            for item in control.get_children():
                if item is Button:
                    item.custom_minimum_size = Vector2(42, 38)
                    item.add_theme_font_size_override("font_size", 13)
                elif item is Label:
                    item.custom_minimum_size.y = 38
    if calendar_expanded:
        _calendar(overview)

    var total: float = store.day_calories(date)
    var target: float = float(store.data["settings"]["kcal"])
    var hero = _card("", "hero")
    _compact_card(hero, 11, 6)
    var hero_content = _row(hero)
    var numbers = VBoxContainer.new()
    numbers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    numbers.add_theme_constant_override("separation", 2)
    hero_content.add_child(numbers)
    _label(numbers, "Энергия дня", 16, WHITE)
    _label(numbers, str(roundi(total)) + " из " + str(roundi(target)) + " ккал", 21, WHITE)
    var remaining: float = target - total
    _label(numbers,
        "Осталось " + str(roundi(remaining)) + " ккал" if remaining >= 0.0 else
        "Превышение +" + str(roundi(-remaining)) + " ккал",
        12, HERO_MUTED if remaining >= 0.0 else SOFT_GOLD)
    var ring = RingScript.new()
    ring.name = "DailyCalorieRing"
    ring.custom_minimum_size = Vector2(58, 58)
    ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    ring.size_flags_horizontal = Control.SIZE_SHRINK_END
    ring.set_palette(HERO_TRACK, HERO_FILL, WHITE)
    ring.set_value(total, target)
    var edit_goal = _button(hero_content, "Норма", func(): _show_calorie_goal_editor(), true)
    edit_goal.name = "EditDailyCalorieGoal"
    edit_goal.tooltip_text = "Изменить суточную норму калорий"
    edit_goal.custom_minimum_size = Vector2(68, 38)
    edit_goal.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    edit_goal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    edit_goal.add_theme_font_size_override("font_size", 12)
    hero_content.add_child(ring)
    var macros = _row(hero)
    macros.add_theme_constant_override("separation", 5)
    _compact_macro(macros, "Белки", store.day_macro(date, "p"), PROTEIN_BG, MACRO_PROTEIN)
    _compact_macro(macros, "Жиры", store.day_macro(date, "f"), FAT_BG, MACRO_FAT)
    _compact_macro(macros, "Углеводы", store.day_macro(date, "c"), CARBS_BG, MACRO_CARBS)

    # Compact sections are always present. Only the selected meal unfolds.
    # Expansion state is in-memory, keyed by date: diary records are untouched.
    # No extra standalone title card: every meal already has its own header.
    var existing = store.day_entries(date)
    var sections = [
        {"meal":"Завтрак", "variant":"overview", "accent":ACCENT},
        {"meal":"Обед", "variant":"tint", "accent":TEXT_ACCENT},
        {"meal":"Ужин", "variant":"activity", "accent":ACTIVITY_TEXT},
        {"meal":"Перекус", "variant":"plain", "accent":NAV_ACTIVE}
    ]
    var shares: Array = store.meal_shares()
    var yesterday: String = store.change_date(date, -1)
    var saved_templates: Array = store.data.get("meal_templates", [])
    for section_index in range(sections.size()):
        var section_info: Dictionary = sections[section_index]
        var meal_name: String = str(section_info["meal"])
        var meals_for_day: Array = existing.filter(func(e): return str(e.get("meal", "")) == meal_name)
        var meal_stats: Dictionary = store.meal_summary(date, meal_name)
        var meal_kcal: float = float(meal_stats["kcal"])
        var share: int = roundi(float(shares[section_index]))
        var meal_target: float = float(target) * float(share) / 100.0
        var section_key = date + "|" + meal_name
        var expanded: bool = bool(_expanded_meals.get(section_key, false))
        var meal_card = _card("", str(section_info["variant"]))
        _compact_card(meal_card, 10, 4)
        meal_card.get_parent().name = "DailyMeal_" + str(section_index)
        if current_theme == "botanical":
            var botanical_colors = [
                Color("#FFF2DE"), Color("#E9F5E9"),
                Color("#E9EEFC"), Color("#FFF0F2")
            ]
            var botanical_edges = [
                Color("#ECA14A"), Color("#51A46C"),
                Color("#6F89CF"), Color("#D77893")
            ]
            var meal_style = meal_card.get_parent().get_theme_stylebox("panel") as StyleBoxFlat
            meal_style.bg_color = botanical_colors[section_index]
            meal_style.border_color = botanical_edges[section_index].lightened(0.43)
            meal_style.set_border_width_all(2 if HIGH_CONTRAST else 1)
        if section_index == 0:
            diary_food_card = meal_card
        # One-row meal summary: tap its title or + to select a product,
        # tap chevron to open editing, nutrients and saved meal templates.
        var title_row = _row(meal_card)
        title_row.name = "MealCompactRow_" + str(section_index)
        title_row.add_theme_constant_override("separation", 4)
        var accent = ColorRect.new()
        accent.name = "MealAccent_" + str(section_index)
        accent.color = Color(str(["#ECA14A", "#51A46C", "#6F89CF", "#D77893"][section_index])) if current_theme == "botanical" else section_info["accent"]
        accent.custom_minimum_size = Vector2(4, 28)
        accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
        title_row.add_child(accent)
        # Four matching rounded line icons replace mixed-system emoji on
        # every theme. Keep each icon noninteractive so the meal's title and
        # action buttons retain their original hit targets.
        var food_art = TextureRect.new()
        food_art.name = "MealArt_" + str(section_index)
        food_art.texture = MEAL_TEXTURES[section_index]
        food_art.custom_minimum_size = Vector2(24, 24)
        food_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        food_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        food_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        food_art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        food_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
        if current_theme == "botanical":
            var icon_colors = [
                Color("#9F6424"), Color("#2D7650"),
                Color("#4C66AA"), Color("#AD4A6C")
            ]
            food_art.modulate = icon_colors[section_index]
        else:
            food_art.modulate = WHITE if DARK_MODE else INK
        title_row.add_child(food_art)
        var meal_title = Button.new()
        meal_title.name = "MealHeader_" + str(section_index)
        meal_title.text = meal_name
        meal_title.flat = true
        meal_title.alignment = HORIZONTAL_ALIGNMENT_LEFT
        meal_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        meal_title.size_flags_stretch_ratio = 1.2
        meal_title.custom_minimum_size.y = 38
        meal_title.clip_text = true
        meal_title.add_theme_font_size_override("font_size", 15)
        for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
            meal_title.add_theme_color_override(state, INK)
        meal_title.pressed.connect(func(): _show_meal_add_actions(meal_name))
        title_row.add_child(meal_title)
        var count_caption = (
            str(roundi(meal_kcal)) + " / " + str(roundi(meal_target)) + " ккал"
            if share > 0 else str(roundi(meal_kcal)) + " ккал"
        )
        var count_label = _label(title_row, count_caption, 12, TEXT_ACCENT)
        count_label.name = "MealCalorieSummary_" + str(section_index)
        count_label.custom_minimum_size.x = 100
        count_label.size_flags_horizontal = Control.SIZE_SHRINK_END
        count_label.autowrap_mode = TextServer.AUTOWRAP_OFF
        count_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        var add_button = _button(title_row, "+", func(): _show_meal_add_actions(meal_name), true)
        add_button.name = "MealQuickAdd_" + str(section_index)
        add_button.tooltip_text = "Добавить продукт в " + meal_name.to_lower()
        add_button.custom_minimum_size = Vector2(37, 38)
        add_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        add_button.add_theme_font_size_override("font_size", 21)
        var expand_button = _button(title_row, "⌃" if expanded else "⌄", func():
            _expanded_meals[section_key] = not expanded
            _render()
        , true)
        expand_button.name = "MealExpand_" + str(section_index)
        expand_button.tooltip_text = "Свернуть" if expanded else "Подробнее"
        expand_button.custom_minimum_size = Vector2(37, 38)
        expand_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        expand_button.add_theme_font_size_override("font_size", 19)
        if meal_kcal > 0 and share > 0:
            var meal_bar = ProgressBar.new()
            meal_bar.name = "MealProgress_" + str(section_index)
            meal_bar.min_value = 0.0
            meal_bar.max_value = maxf(1.0, meal_target)
            meal_bar.value = minf(meal_kcal, meal_bar.max_value)
            _style_progress(meal_bar)
            meal_bar.custom_minimum_size.y = 4
            var meal_fill = StyleBoxFlat.new()
            meal_fill.bg_color = Color("#E0705D") if meal_kcal > meal_target else section_info["accent"]
            meal_fill.set_corner_radius_all(8)
            meal_bar.add_theme_stylebox_override("fill", meal_fill)
            meal_card.add_child(meal_bar)
        if meal_kcal > meal_target and share > 0:
            _label(meal_card, "Превышение: +" +
                str(roundi(meal_kcal - meal_target)) + " ккал", 12, ACCENT)
        if not expanded:
            continue
        _label(meal_card, str(meals_for_day.size()) + " продуктов · " +
            str(share) + "% дневной цели", 12, MUTED)
        var macro_line = (
            "БЕЛКИ " + str(snappedf(float(meal_stats["p"]), 0.1)) + " г · " +
            "ЖИРЫ " + str(snappedf(float(meal_stats["f"]), 0.1)) + " г · " +
            "УГЛЕВОДЫ " + str(snappedf(float(meal_stats["c"]), 0.1)) + " г"
        )
        _label(meal_card, macro_line, 12, MUTED)
        var details = VBoxContainer.new()
        details.name = "MealDetails_" + str(section_index)
        details.add_theme_constant_override("separation", 8)
        meal_card.add_child(details)
        if meals_for_day.is_empty():
            _label(details, "Пока ничего не записано.", 13, MUTED)
        else:
            for entry in meals_for_day:
                var f: Dictionary = store.entry_food(entry)
                var meal_row = _soft_list_row(details)
                var caption = _label(meal_row, str(f.get("name", "Продукт")) + "\n" +
                    str(entry.get("grams", 0)) + " " + str(entry.get("unit", "г")) +
                    " · " + str(roundi(store.entry_kcal(entry))) + " ккал" +
                    (" · " + str(entry.get("portion_label", "")) if not str(entry.get("portion_label", "")).is_empty() else ""), 13)
                caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                _button(meal_row, "✎", func(): _edit_entry(entry), true)
                _button(meal_row, "×", func(): _confirm_delete("Удалить запись питания?", func():
                    if store.delete_saved_record("entries", entry):
                        _render()
                        _notify_saved("Запись питания удалена")
                    else:
                        _message("Не удалось удалить запись питания.")
                ), true)
            _button(details, "☆ Сохранить набор", func():
                _name_meal_template_sheet(meal_name)
            , true)
        var yesterday_count: int = store.day_entries(yesterday).filter(
            func(e): return str(e.get("meal", "")) == meal_name
        ).size()
        if yesterday_count > 0:
            _button(details, "↻ Повторить со вчера", func():
                _confirm_action("Повторить «" + meal_name.to_lower() + "» со вчера?",
                    "Добавить " + str(yesterday_count) + " записей в " + date +
                    "? Повторное добавление создаст дубликаты.", func():
                    var copied = store.repeat_meal(yesterday, meal_name, date)
                    if copied > 0:
                        _render()
                        _notify_saved("Добавлено записей: " + str(copied))
                    else:
                        _message("Не удалось повторить приём пищи.")
                )
            , true)
        for template in saved_templates:
            if not (template is Dictionary) or template["items"].is_empty():
                continue
            if str(template["items"][0].get("meal", "")) != meal_name:
                continue
            var template_row = _row(details)
            var template_name = _label(template_row, "★ " + str(template["name"]), 12, MUTED)
            template_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            _button(template_row, "+", func():
                var added = store.apply_meal_template(str(template["id"]), date)
                if added > 0:
                    _render()
                    _notify_saved("Добавлено продуктов: " + str(added))
                else:
                    _message("Не удалось добавить любимый набор.")
            )
            _button(template_row, "×", func():
                _confirm_delete("Удалить набор «" + str(template["name"]) + "»?", func():
                    if store.delete_meal_template(str(template["id"])):
                        _render()
                        _notify_saved("Набор удалён")
                    else:
                        _message("Не удалось удалить набор.")
                )
            , true)

    var activity = _card("Движение сегодня", "activity")
    activity.get_parent().name = "DailyActivity"
    _compact_card(activity, 11, 5)
    var walking = 0
    var exercise = 0
    for a in store.day_activities(date):
        if str(a.get("type", "")) == "walk":
            walking += int(a.get("minutes", 0))
        else:
            exercise += int(a.get("minutes", 0))
    var activity_caption = _label(activity, "Прогулки: " + str(walking) +
        " мин  ·  Тренировки: " + str(exercise) + " мин", 13, ACTIVITY_TEXT)
    activity_caption.name = "DailyActivitySummary"
    var shortcuts = _row(activity)
    shortcuts.add_theme_constant_override("separation", 6)
    for quick_link in [
        _button(shortcuts, "+ Спорт", func(): _navigate_to_tab("activity"), true),
        _button(shortcuts, "+ Вес", func(): _navigate_to_tab("weight"), true)
    ]:
        quick_link.custom_minimum_size.y = 39
        quick_link.add_theme_font_size_override("font_size", 13)

    # The collapsed note is a single compact row, not a tall empty card.
    var notes_card = _card("")
    notes_card.get_parent().name = "DailyNote"
    _compact_card(notes_card, 10, 4)
    var notes_header = _row(notes_card)
    notes_header.add_theme_constant_override("separation", 6)
    var note_heading = VBoxContainer.new()
    note_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    note_heading.add_theme_constant_override("separation", 1)
    notes_header.add_child(note_heading)
    _label(note_heading, "Заметка о дне", 18, INK)
    if not day_more_expanded and not str(store.data["notes"].get(date, "")).strip_edges().is_empty():
        _label(note_heading, "Заметка сохранена", 11, MUTED)
    var notes_toggle = _button(notes_header,
        "▴ Скрыть заметку" if day_more_expanded else "▾ Открыть заметку",
        func():
            if note_save_timer.time_left > 0.0:
                note_save_timer.stop()
                store.save()
            day_more_expanded = not day_more_expanded
            _render()
    , true)
    notes_toggle.name = "DailyNoteToggle"
    notes_toggle.custom_minimum_size = Vector2(145, 38)
    notes_toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
    notes_toggle.add_theme_font_size_override("font_size", 12)
    if day_more_expanded:
        var notes = TextEdit.new()
        notes.custom_minimum_size.y = 110
        _style_field(notes)
        notes.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
        notes.placeholder_text = "Как прошёл день? Настроение, самочувствие…"
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
    _meal_entry_locked = false
    _meal_entry_date = ""
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
    if _meal_entry_locked and not is_instance_valid(barcode_message):
        var chosen = selected_meal
        _open_meal_catalog(chosen)
    _reveal_barcode_section()
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
    _quick_food_sheet(food, true)

func _confirm_barcode_product(product: Dictionary, manual: bool = false) -> void:
    var description = "Внеси КБЖУ с этикетки на 100 г / мл." if manual else "Open Food Facts: сравни КБЖУ с этикеткой."
    var sheet = _mobile_sheet(
        "Новый товар" if manual else "Найденный товар",
        description, "Сохранить и добавить", 690.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, "Название", 13, MUTED)
    var name = _text_input(fields, "Название продукта", str(product.get("name", "")))
    _label(fields, "Основа КБЖУ с этикетки", 13, MUTED)
    var basis = _choice(fields, ["На 100 г", "На 100 мл"])
    basis.name = "BarcodeNutritionBasis"
    basis.select(1 if PortionMath.base_unit(product) == "мл" else 0)
    var detected_basis = str(product.get("unit_certainty", "unknown"))
    if str(product.get("source", "")) == "Open Food Facts":
        var basis_note = "Единица определена по упаковке. Сверь её и КБЖУ с этикеткой."
        if detected_basis in ["serving", "unknown"]:
            basis_note = "Основа КБЖУ не подтверждена. Выбери 100 г или 100 мл по этикетке."
        _label(fields, basis_note, 12, ACCENT)
    _label(fields, "Калории на 100 г или 100 мл (в зависимости от выбранной основы)", 13, MUTED)
    var kcal = _number(fields, float(product.get("kcal", 0)), 0, 1000, 0.1)
    _label(fields, "Белки • Жиры • Углеводы на 100 г", 13, MUTED)
    var nutrition_row = _row(fields)
    var protein = _number(nutrition_row, float(product.get("p", 0)), 0, 100, 0.1)
    var fat = _number(nutrition_row, float(product.get("f", 0)), 0, 100, 0.1)
    var carbs = _number(nutrition_row, float(product.get("c", 0)), 0, 100, 0.1)
    var serving_basis_label = _label(fields, "Количество порции, " +
        ("мл" if basis.selected == 1 else "г"), 13, MUTED)
    basis.item_selected.connect(func(index: int):
        serving_basis_label.text = "Количество порции, " + ("мл" if index == 1 else "г")
    )
    var grams = _number(fields, 100, 1, 5000, 1)
    _label(fields, "Приём пищи", 13, MUTED)
    var meal = _choice(fields, ["Завтрак", "Обед", "Перекус", "Ужин"])
    meal.disabled = _meal_entry_locked
    var meal_index = ["Завтрак", "Обед", "Перекус", "Ужин"].find(selected_meal)
    if meal_index >= 0:
        meal.select(meal_index)
    meal.item_selected.connect(func(index: int): selected_meal = meal.get_item_text(index))
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
        record["nutrition_unit"] = "мл" if basis.selected == 1 else "г"
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
            if not store.add_food_entry(saved_food, grams.value, meal.get_item_text(meal.selected), _selected_food_date()):
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


func _name_meal_template_sheet(meal_name: String) -> void:
    var sheet = _mobile_sheet("Сохранить приём пищи",
        "Шаблон можно использовать в любой день. КБЖУ сохраняются на момент создания.",
        "Сохранить", 400.0)
    var fields: VBoxContainer = sheet["fields"]
    var title_field = _text_input(fields, "Название шаблона", "Мой " + meal_name.to_lower())
    title_field.max_length = 70
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        if store.save_meal_template(date, meal_name, title_field.text):
            sheet["root"].queue_free()
            _hide_keyboard_and_focus()
            _render()
            _notify_saved("Приём пищи сохранён")
        else:
            _sheet_error(sheet, "Не удалось сохранить. Проверь название и состав.")
    )

func _quick_food_sheet(food: Dictionary, from_barcode: bool = false) -> void:
    var unit: String = PortionMath.base_unit(food)
    var description = "Проверь КБЖУ на упаковке (на 100 " + unit + ")." if from_barcode else "Выбери меру и количество. Свои размеры порций сохраняются."
    var sheet = _mobile_sheet("Продукт найден" if from_barcode else str(food.get("name", "Продукт")),
        description, "Добавить" if from_barcode else "Добавить в дневник", 680.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, str(food.get("name", "Продукт")), 17, INK)
    _label(fields, str(roundi(float(food.get("kcal", 0)))) + " ккал / 100 " + unit +
        " · Б " + str(food.get("p", 0)) + " Ж " + str(food.get("f", 0)) +
        " У " + str(food.get("c", 0)), 12, MUTED)
    _label(fields, "Единица измерения", 14, MUTED)
    var options: Array = store.portion_options(food)
    var labels: Array = []
    for option in options:
        var caption = str(option["label"])
        if not str(option["id"]).is_empty():
            caption += " · " + str(snappedf(float(option["amount"]), 0.1)) + " " + unit
        labels.append(caption)
    var measure = _choice(fields, labels)
    _label(fields, "Количество", 14, MUTED)
    var quantity = _number(fields, 100.0, 0.1, 5000.0, 0.1)
    var presets = _row(fields)
    for amount in [50, 100, 150, 200]:
        var value: int = amount
        _button(presets, str(value) + " " + unit, func(): quantity.value = value, true)
    var result_label = _label(fields, "", 14, TEXT_ACCENT)
    _label(fields, "Приём пищи", 14, MUTED)
    var meal = _choice(fields, ["Завтрак", "Обед", "Перекус", "Ужин"])
    meal.disabled = _meal_entry_locked
    var initial_meal = ["Завтрак", "Обед", "Перекус", "Ужин"].find(selected_meal)
    if initial_meal >= 0:
        meal.select(initial_meal)
    meal.item_selected.connect(func(index: int): selected_meal = meal.get_item_text(index))
    var amount_value = func() -> float:
        if measure.selected < 0 or measure.selected >= options.size():
            return 0.0
        return PortionMath.quantity_to_base(options[measure.selected], quantity.value)
    var refresh = func(_v: float):
        var total: float = float(amount_value.call())
        var calculated: Dictionary = PortionMath.nutrients(food, total)
        if calculated.is_empty():
            result_label.text = "Количество должно быть не более 5000 " + unit + "."
            return
        result_label.text = (
            str(snappedf(total, 0.1)) + " " + unit + " · " +
            str(roundi(float(calculated["kcal"]))) + " ккал" +
            "\nБ " + str(snappedf(float(calculated["p"]), 0.1)) +
            " · Ж " + str(snappedf(float(calculated["f"]), 0.1)) +
            " · У " + str(snappedf(float(calculated["c"]), 0.1))
        )
    measure.item_selected.connect(func(index: int):
        quantity.value = 100.0 if index == 0 else 1.0
        presets.visible = index == 0
        refresh.call(quantity.value)
    )
    quantity.value_changed.connect(refresh)
    refresh.call(quantity.value)
    _label(fields, "Своя мера для этого продукта", 14, TEXT_ACCENT)
    _label(fields, "Например: шт., ломтик, баночка, упаковка. Укажи вес или объём с этикетки.", 12, MUTED)
    var custom = _text_input(fields, "Название меры (например, 1 упаковка)")
    custom.max_length = 36
    _label(fields, "Количество " + unit + " в одной мере", 12, MUTED)
    var custom_amount = _number(fields, 100.0, 0.1, 5000.0, 0.1)
    _button(fields, "Сохранить свою меру", func():
        if store.save_food_portion(str(food.get("id", "")), custom.text, custom_amount.value):
            sheet["root"].queue_free()
            _quick_food_sheet(food, from_barcode)
            _notify_saved("Мера сохранена")
        else:
            _sheet_error(sheet, "Не удалось сохранить меру. Проверь название, количество и дубликаты.")
    , true)
    if options.size() > 1:
        _button(fields, "Удалить выбранную меру", func():
            if measure.selected <= 0:
                _sheet_error(sheet, "Сначала выбери сохранённую меру.")
                return
            var option: Dictionary = options[measure.selected]
            if store.delete_food_portion(str(option["id"])):
                sheet["root"].queue_free()
                _quick_food_sheet(food, from_barcode)
                _notify_saved("Мера удалена")
            else:
                _sheet_error(sheet, "Не удалось удалить меру.")
        , true)
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        var total: float = float(amount_value.call())
        if total <= 0.0:
            _sheet_error(sheet, "Допускается не более 5000 " + unit + " за запись.")
            return
        var portion_label = "" if measure.selected == 0 else str(options[measure.selected]["label"])
        if store.add_food_entry(food, total, meal.get_item_text(meal.selected), _selected_food_date(), portion_label):
            sheet["root"].queue_free()
            if from_barcode:
                _barcode_add_success()
            else:
                _render()
                _notify_saved("Продукт добавлен")
        else:
            _sheet_error(sheet, "Не удалось сохранить запись.")
    )

func _food_form(parent: VBoxContainer) -> void:
    var barcode_panel = VBoxContainer.new()
    barcode_panel.name = "FoodBarcodePanel"
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
    var barcode_divider = HSeparator.new()
    barcode_divider.name = "FoodBarcodeDivider"
    parent.add_child(barcode_divider)
    var search_heading = _label(parent, "Поиск продуктов по названию", 16, TEXT_ACCENT)
    var filtered: Array = []
    var search = _text_input(parent, "Поиск продукта по названию")
    search.name = "FoodNameSearch"
    online_search_field = search
    if not selected_barcode_food.is_empty():
        search.text = selected_barcode_food
        selected_barcode_food = ""
    search.clear_button_enabled = true
    var online_actions = _row(parent)
    online_actions.name = "OnlineFoodSearchActions"
    var online_button = _button(online_actions, "Найти в интернете", func():
        _lookup_online_products(search.text)
    , true)
    online_button.name = "OnlineFoodSearchButton"
    online_button.custom_minimum_size.y = 40
    online_button.add_theme_font_size_override("font_size", 13)
    var barcode_toggle = _button(online_actions, "▣ Штрихкод", func():
        barcode_panel.visible = not barcode_panel.visible
        barcode_divider.visible = barcode_panel.visible
        if barcode_panel.visible:
            _ensure_field_visible(barcode_input)
    , true)
    barcode_toggle.name = "FoodBarcodeToggle"
    barcode_toggle.custom_minimum_size.y = 40
    barcode_toggle.add_theme_font_size_override("font_size", 12)
    barcode_toggle.clip_text = true
    barcode_panel.visible = false
    barcode_divider.visible = false
    online_search_label = _label(parent,
        "Open Food Facts · поиск продуктов и брендов · нужен интернет.", 12, MUTED)
    online_search_label.name = "OnlineFoodSearchStatus"
    online_results_box = VBoxContainer.new()
    online_results_box.name = "OnlineFoodSearchResults"
    online_results_box.visible = false
    online_results_box.add_theme_constant_override("separation", 6)
    parent.add_child(online_results_box)
    var favorite_only = CheckButton.new()
    favorite_only.text = "Только избранные"
    favorite_only.add_theme_color_override("font_color", GREEN)
    favorite_only.add_theme_font_size_override("font_size", 13)
    parent.add_child(favorite_only)
    var picker = _choice(parent, [])
    var category_label = _label(parent, "Категория", 13, MUTED)
    var category = _choice(parent, ["Все", "Базовые", "Брендовые", "Мои продукты", "Избранное", "Недавние"])
    var units_hint = _label(parent, "Количество: выбери продукт (г или мл)", 14, MUTED)
    units_hint.name = "FoodQuantityUnitHint"
    var values = _row(parent)
    var grams = _number(values, 100, 1, 5000)
    grams.custom_minimum_size.x = 160
    var grams_presets = _row(parent)
    grams_presets.name = "FoodQuantityPresets"
    for option in [50, 100, 150, 200]:
        var value: int = option
        var preset_button = _button(grams_presets, str(value), func(): grams.value = value, true)
        preset_button.set_meta("quantity_amount", value)
    var meal = _choice(parent, ["Завтрак", "Обед", "Перекус", "Ужин"])
    meal.disabled = _meal_entry_locked
    var meal_index = ["Завтрак", "Обед", "Перекус", "Ужин"].find(selected_meal)
    if meal_index >= 0:
        meal.select(meal_index)
    meal.item_selected.connect(func(index: int): selected_meal = meal.get_item_text(index))
    var preview = _label(parent, "", 14, MUTED)
    var added_count = _label(parent, "Добавлено за сеанс: 0", 12, TEXT_ACCENT)
    var results_box = VBoxContainer.new()
    results_box.name = "FoodSearchResults"
    results_box.add_theme_constant_override("separation", 7)
    parent.add_child(results_box)
    var controls = _row(parent)
    var star = _button(controls, "☆ В избранное", Callable(), true)
    star.pressed.connect(func():
        if picker.selected < 0 or picker.selected >= filtered.size():
            return
        var food: Dictionary = filtered[picker.selected]
        if store.toggle_favorite(str(food.get("id", ""))):
            _refresh_food_picker(picker, search, favorite_only, filtered, grams, preview, star, category, results_box, meal, added_count)
        else:
            _message("Не удалось сохранить избранное.")
    )
    _button(controls, "Выбрать порцию", func():
        if picker.selected >= 0 and picker.selected < filtered.size():
            _quick_food_sheet(filtered[picker.selected])
    , true)
    _button(controls, "+ Добавить", func():
        if picker.selected < 0 or picker.selected >= filtered.size():
            _message("Выбери продукт. При необходимости отключи фильтр избранного.")
            return
        var f: Dictionary = filtered[picker.selected]
        if store.add_food_entry(f, grams.value, meal.get_item_text(meal.selected), _selected_food_date()):
            added_count.set_meta("count", int(added_count.get_meta("count", 0)) + 1)
            added_count.text = "Добавлено за сеанс: " + str(added_count.get_meta("count"))
            _notify_saved("Продукт добавлен в дневник")
        else:
            _message("Ошибка сохранения. Запись не добавлена; проверь свободное место.")
    )
    search.text_changed.connect(func(_value: String):
        if is_instance_valid(online_results_box):
            online_results_box.visible = false
            for old in online_results_box.get_children():
                old.queue_free()
        if is_instance_valid(online_search_label):
            online_search_label.text = "Поиск по всем брендам: нажми «Найти в интернете»."
        _refresh_food_picker(picker, search, favorite_only, filtered, grams, preview, star, category, results_box, meal, added_count)
    )
    favorite_only.toggled.connect(func(_value: bool):
        _refresh_food_picker(picker, search, favorite_only, filtered, grams, preview, star, category, results_box, meal, added_count)
    )
    category.item_selected.connect(func(_value: int):
        _refresh_food_picker(picker, search, favorite_only, filtered, grams, preview, star, category, results_box, meal, added_count)
    )
    picker.item_selected.connect(func(_value: int):
        _update_food_preview(picker, filtered, grams, preview, star)
    )
    grams.value_changed.connect(func(_value: float):
        _update_food_preview(picker, filtered, grams, preview, star)
    )
    # Make search immediately visible. The previous layout buried it under
    # barcode controls and a long catalog form.
    var quick_tabs = _row(parent)
    quick_tabs.name = "FoodQuickFilters"
    quick_tabs.add_theme_constant_override("separation", 4)
    for option in [
        ["Недавние", 5], ["★ Избранное", 4], ["Все", 0]
    ]:
        var target_index: int = int(option[1])
        var filter_button = _button(quick_tabs, str(option[0]), func():
            category.select(target_index)
            _refresh_food_picker(picker, search, favorite_only, filtered, grams, preview, star,
                category, results_box, meal, added_count)
        , true)
        filter_button.add_theme_font_size_override("font_size", 12)
        filter_button.custom_minimum_size.y = 38
        filter_button.clip_text = true

    var quick_lists = VBoxContainer.new()
    quick_lists.name = "FoodRecentFavorites"
    quick_lists.add_theme_constant_override("separation", 5)
    parent.add_child(quick_lists)
    var recents: Array = store.recent_food_entries(4)
    if not recents.is_empty():
        _label(quick_lists, "Недавние продукты", 15, TEXT_ACCENT)
        for record in recents:
            var food: Dictionary = record["food"]
            var last_amount = str(roundi(float(record["grams"]))) + " " + str(record["unit"])
            var shortcut = _soft_list_row(quick_lists)
            var caption = _label(shortcut, str(food.get("name", "Продукт")) + " · " + last_amount, 12, INK)
            caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            caption.autowrap_mode = TextServer.AUTOWRAP_OFF
            caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
            var edit = _button(shortcut, "Порция", func(): _quick_food_sheet(food), true)
            edit.custom_minimum_size.y = 37
            edit.add_theme_font_size_override("font_size", 12)
    else:
        _label(quick_lists, "Недавние продукты появятся после добавления еды.", 12, MUTED)
    var favorite_count = 0
    for favorite_id in store.data.get("favorites", []):
        if favorite_count >= 3:
            break
        var fav: Dictionary = store.food_by_id(str(favorite_id))
        if fav.is_empty():
            continue
        if favorite_count == 0:
            _label(quick_lists, "★ Избранные продукты", 15, TEXT_ACCENT)
        var fav_button = _button(quick_lists, "★ " + str(fav.get("name", "Продукт")), func():
            _quick_food_sheet(fav)
        , true)
        fav_button.clip_text = true
        fav_button.custom_minimum_size.y = 38
        favorite_count += 1
    search.text_changed.connect(func(_value: String):
        quick_lists.visible = search.text.strip_edges().is_empty()
    )
    # Results and portion selection are shown first. Legacy batch-add
    # controls remain accessible but are collapsed to avoid a long page.
    var advanced_controls: Array = [
        favorite_only, picker, category_label, category, units_hint, values,
        grams_presets, meal, preview, added_count, controls
    ]
    for control in advanced_controls:
        control.visible = false
    var advanced_button = _button(parent, "▾ Дополнительные настройки", func():
        var expanded = not picker.visible
        for control in advanced_controls:
            control.visible = expanded
    , true)
    advanced_button.name = "FoodAdvancedToggle"
    advanced_button.add_theme_font_size_override("font_size", 12)
    advanced_button.custom_minimum_size.y = 40
    # In the catalog itself, discoverability goes first.
    parent.move_child(search_heading, 1)
    parent.move_child(search, 2)
    parent.move_child(online_actions, 3)
    parent.move_child(online_search_label, 4)
    parent.move_child(online_results_box, 5)
    parent.move_child(quick_tabs, 6)
    parent.move_child(quick_lists, 7)
    parent.move_child(results_box, 8)
    parent.move_child(advanced_button, 9)
    parent.move_child(barcode_panel, parent.get_child_count() - 1)
    parent.move_child(barcode_divider, parent.get_child_count() - 2)
    _refresh_food_picker(picker, search, favorite_only, filtered, grams, preview, star, category, results_box, meal, added_count)

func _refresh_food_picker(picker: OptionButton, search: LineEdit, favorite_only: CheckButton,
        filtered: Array, grams: SpinBox, preview: Label, star: Button,
        category: OptionButton = null, results_box: VBoxContainer = null,
        meal: OptionButton = null, added_count: Label = null) -> void:
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
    if results_box != null:
        results_box.visible = not query.is_empty() or (category != null and category.selected != 0)
    var recent_ids: Dictionary = {}
    if category != null and category.selected == 5:
        for recent_food in store.recent_foods(20):
            recent_ids[str(recent_food.get("id", ""))] = true
    var owned_ids: Dictionary = {}
    if category != null and category.selected == 3:
        for own_food in store.data["foods"]:
            if own_food is Dictionary:
                owned_ids[str(own_food.get("id", ""))] = true
    for item in all:
        if not FoodSearchScript.matches(item, query):
            continue
        var item_id = str(item.get("id", ""))
        if favorite_only.button_pressed and not store.is_favorite(item_id):
            continue
        if category != null:
            match category.selected:
                1:
                    if not item_id.begins_with("d"):
                        continue
                2:
                    if str(item.get("brand", "")).is_empty() and str(item.get("barcode", "")).is_empty():
                        continue
                3:
                    if not owned_ids.has(item_id):
                        continue
                4:
                    if not store.is_favorite(item_id):
                        continue
                5:
                    if not recent_ids.has(item_id):
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
    if results_box != null and meal != null and added_count != null:
        _rebuild_food_results(results_box, filtered, grams, meal, added_count)

func _rebuild_food_results(results_box: VBoxContainer, filtered: Array,
        grams: SpinBox, meal: OptionButton, added_count: Label) -> void:
    for child in results_box.get_children():
        results_box.remove_child(child)
        child.queue_free()
    _label(results_box, "Найдено: " + str(filtered.size()) + " · первые 12 результатов", 12, MUTED)
    for index in range(mini(12, filtered.size())):
        var item: Dictionary = filtered[index]
        var row = _soft_list_row(results_box)
        var info = VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        var brand = str(item.get("brand", "")).strip_edges()
        _label(info, str(item.get("name", "Продукт")) + (" · " + brand if not brand.is_empty() else ""), 13, INK)
        _label(info, str(roundi(float(item.get("kcal", 0)))) +
            " ккал / 100 " + PortionMath.base_unit(item) +
            " · Б " + str(snappedf(float(item.get("p", 0)), 0.1)) +
            " Ж " + str(snappedf(float(item.get("f", 0)), 0.1)) +
            " У " + str(snappedf(float(item.get("c", 0)), 0.1)), 11, MUTED)
        _button(row, "Порция", func(): _quick_food_sheet(item), true)
        _button(row, "+", func():
            if store.add_food_entry(item, grams.value, meal.get_item_text(meal.selected), _selected_food_date()):
                added_count.set_meta("count", int(added_count.get_meta("count", 0)) + 1)
                added_count.text = "Добавлено за сеанс: " + str(added_count.get_meta("count"))
                _notify_saved("Продукт добавлен")
            else:
                _message("Не удалось сохранить продукт.")
        )

func _update_food_preview(picker: OptionButton, filtered: Array, grams: SpinBox,
        preview: Label, star: Button) -> void:
    if picker.selected < 0 or picker.selected >= filtered.size():
        preview.text = "Нет подходящих продуктов."
        var hint = picker.get_parent().get_node_or_null("FoodQuantityUnitHint") as Label
        if hint != null:
            hint.text = "Количество: выбери продукт (г или мл)"
        star.text = "☆ В избранное"
        star.disabled = true
        return
    var f: Dictionary = filtered[picker.selected]
    var measure_unit: String = PortionMath.base_unit(f)
    var outer: Node = picker.get_parent()
    var units_hint = outer.get_node_or_null("FoodQuantityUnitHint") as Label
    if units_hint != null:
        units_hint.text = "Количество, " + measure_unit
    var presets = outer.get_node_or_null("FoodQuantityPresets") as HBoxContainer
    if presets != null:
        for preset in presets.get_children():
            if preset is Button:
                preset.text = str(preset.get_meta("quantity_amount", 100)) + " " + measure_unit
    var amount = grams.value / 100.0
    preview.text = str(grams.value) + " " + PortionMath.base_unit(f) + " · " + str(roundi(float(f.get("kcal", 0)) * amount)) + " ккал  •  Б " + str(snappedf(float(f.get("p", 0)) * amount, 0.1)) + "  Ж " + str(snappedf(float(f.get("f", 0)) * amount, 0.1)) + "  У " + str(snappedf(float(f.get("c", 0)) * amount, 0.1))
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
    _label(fields, "Количество, г или мл (согласно выбранному продукту)", 13, MUTED)
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
        entry["unit"] = PortionMath.base_unit(product)
        entry["portion_label"] = ""
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

func _set_stats_period(mode: String) -> void:
    if mode not in ["week", "month"]:
        return
    if stats_anchor.is_empty():
        stats_anchor = date
    stats_period = mode
    _render(true)


func _shift_stats_period(amount: int) -> void:
    if stats_anchor.is_empty():
        stats_anchor = date
    if stats_period == "month":
        var month = _month_offset(stats_anchor.substr(0, 7), amount)
        var next_first = _month_offset(month, 1) + "-01"
        var last_day = store.change_date(next_first, -1)
        var preferred = mini(int(stats_anchor.substr(8, 2)), int(last_day.substr(8, 2)))
        stats_anchor = month + "-" + str(preferred).pad_zeros(2)
    else:
        stats_anchor = store.change_date(stats_anchor, amount * 7)
    _render(true)


func _show_stats() -> void:
    if stats_anchor.is_empty():
        stats_anchor = date
    var report: Dictionary = StatsMathScript.summarize(store, stats_anchor, stats_period)
    var card = _card("", "overview")
    card.get_parent().name = "StatsPeriodCard"
    _compact_card(card, 12, 8)
    _label(card, "Мои итоги", 19, INK)
    var period_buttons = _row(card)
    period_buttons.name = "StatsPeriodSelector"
    period_buttons.add_theme_constant_override("separation", 6)
    for option in [["Неделя", "week"], ["Месяц", "month"]]:
        var selected_mode: String = str(option[1])
        var button = _button(period_buttons, str(option[0]),
            func(): _set_stats_period(selected_mode), true)
        button.name = "StatsPeriod_" + selected_mode
        button.custom_minimum_size.y = 38
        button.add_theme_font_size_override("font_size", 13)
        if selected_mode == stats_period:
            var selected_style = StyleBoxFlat.new()
            selected_style.bg_color = NAV_ACTIVE
            selected_style.set_corner_radius_all(11)
            for style_name in ["normal", "hover", "pressed"]:
                button.add_theme_stylebox_override(style_name, selected_style)
            button.add_theme_color_override("font_color", WHITE)
    var navigator = _row(card)
    navigator.name = "StatsDateNavigation"
    navigator.add_theme_constant_override("separation", 6)
    var previous = _button(navigator, "◀", func(): _shift_stats_period(-1), true)
    previous.name = "StatsPreviousPeriod"
    previous.custom_minimum_size = Vector2(42, 38)
    var period_label = _label(navigator,
        StatsMathScript.label_for(report["dates"], stats_period), 14, TEXT_ACCENT)
    period_label.name = "StatsPeriodDates"
    period_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    period_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    period_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    var following = _button(navigator, "▶", func(): _shift_stats_period(1), true)
    following.name = "StatsNextPeriod"
    following.custom_minimum_size = Vector2(42, 38)
    var metrics = _row(card)
    metrics.add_theme_constant_override("separation", 5)
    var average = "—" if int(report["recorded"]) == 0 else (
        str(roundi(float(report["avg_kcal"]))) + " ккал"
    )
    _metric_tile(metrics, average, "Среднее по заполненным дням")
    _metric_tile(metrics, str(int(report["recorded"])) + " / " +
        str(int(report["total_days"])), "Дней с питанием")
    var activity_metrics = _row(card)
    activity_metrics.add_theme_constant_override("separation", 5)
    _metric_tile(activity_metrics, str(int(report["walking"])) + " мин", "Прогулки")
    _metric_tile(activity_metrics, str(int(report["exercise"])) + " мин", "Тренировки")
    _label(card, "Пустые дни не считаются нулём и не снижают среднее.", 12, MUTED)

    var calories = _card("Калории", "tint")
    calories.get_parent().name = "StatsCalorieCard"
    _compact_card(calories, 12, 8)
    _label(calories, "По дням" if stats_period == "week" else
        "Среднее за записанные дни каждой календарной недели", 12, MUTED)
    var kcal_chart = StatsChartScript.new()
    kcal_chart.name = "StatsCalorieChart"
    kcal_chart.custom_minimum_size.y = 160
    calories.add_child(kcal_chart)
    kcal_chart.setup(report["columns"], "calories",
        float(store.data["settings"]["kcal"]), TEXT_ACCENT, ACCENT, MUTED, CHART_GRID)
    _label(calories, "Пунктир — установленная норма калорий в сутки.", 11, MUTED)

    var macros = _card("Средние БЖУ")
    macros.get_parent().name = "StatsMacrosCard"
    _compact_card(macros, 12, 7)
    _label(macros, "На день с записями питания", 12, MUTED)
    if int(report["recorded"]) == 0:
        _label(macros, "Добавь продукты в дневник, чтобы увидеть средние БЖУ.", 13, MUTED)
    else:
        var macro_row = _row(macros)
        macro_row.add_theme_constant_override("separation", 5)
        _compact_macro(macro_row, "Белки", float(report["avg_p"]), PROTEIN_BG, INK)
        _compact_macro(macro_row, "Жиры", float(report["avg_f"]), FAT_BG, INK)
        _compact_macro(macro_row, "Углеводы", float(report["avg_c"]), CARBS_BG, INK)

    var movement = _card("Движение", "activity")
    movement.get_parent().name = "StatsActivityCard"
    _compact_card(movement, 12, 8)
    var contrast_text = WHITE if current_theme == "botanical" else INK
    _label(movement, "Прогулки: " + str(int(report["walking"])) +
        " мин · Тренировки: " + str(int(report["exercise"])) + " мин", 12, contrast_text)
    var activity_chart = StatsChartScript.new()
    activity_chart.name = "StatsActivityChart"
    activity_chart.custom_minimum_size.y = 140
    movement.add_child(activity_chart)
    activity_chart.setup(report["columns"], "activity", 0.0,
        GREEN, ACCENT, MUTED, CHART_GRID)
    _label(movement, "Зелёный — ходьба · Оранжевый — тренировки · Сеансов: " +
        str(int(report["workouts"])), 11, contrast_text)

    var weight = _card("Динамика веса")
    weight.get_parent().name = "StatsWeightCard"
    _compact_card(weight, 12, 8)
    _label(weight, "Взвешиваний за период: " +
        str(report["weights"].size()), 12, MUTED)
    var weight_graph = GraphScript.new()
    weight_graph.name = "StatsWeightGraph"
    weight_graph.custom_minimum_size.y = 185
    weight_graph.set_palette(TEXT_ACCENT, CHART_GRID, MUTED, ACCENT, CHART_AREA, SECONDARY)
    weight_graph.set_points(report["weights"], float(store.data["settings"]["goal"]))
    weight.add_child(weight_graph)


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
    _label(back_to_profile, "Версия 0.7.28 · Тема: " + AppearanceScript.name_for(current_theme), 12, MUTED)
    _button(back_to_profile, "← К личной странице", func(): _navigate_to_tab("profile"), true)
    var card = _card("Личные настройки")
    _button(card, "Моя анкета · пересчитать норму", func(): _begin_onboarding(true), true)
    _label(card, "Калории в сутки")
    var kcal = _text_input(card, "Например, 1800", str(roundi(float(store.data["settings"]["kcal"]))))
    kcal.name = "DailyCalorieTarget"
    kcal.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
    kcal.max_length = 4
    _label(card, "Вес на старте")
    var start = _number(card, float(store.data["settings"]["start"]), 20, 400, 0.1)
    _label(card, "Моя цель")
    var goal = _number(card, float(store.data["settings"]["goal"]), 20, 400, 0.1)
    _button(card, "Сохранить настройки", func():
        var new_kcal = StoreScript.parse_calorie_target(kcal.text)
        if new_kcal < 0:
            _message("Укажи норму от 1000 до 5000 ккал, например 1800.")
            return
        var previous_settings = store.data["settings"].duplicate(true)
        var next_settings = previous_settings.duplicate(true)
        next_settings["kcal"] = new_kcal
        next_settings["start"] = start.value
        next_settings["goal"] = goal.value
        store.data["settings"] = next_settings
        if store.save():
            _hide_keyboard_and_focus()
            _render()
            _notify_saved("Настройки сохранены · " + str(new_kcal) + " ккал")
        else:
            store.data["settings"] = previous_settings
            _message("Не удалось сохранить настройки. Прежние значения оставлены.")
    )
    var portions_card = _card("Распределение калорий по приёмам пищи")
    _label(portions_card, "Настрой свои ориентиры. Сумма четырёх процентов должна быть 100%.", 13, MUTED)
    var original_shares: Array = store.meal_shares()
    var portion_fields: Array = []
    for i in range(StoreScript.MEAL_NAMES.size()):
        var meal_row = _row(portions_card)
        var meal_caption = _label(meal_row, str(StoreScript.MEAL_NAMES[i]), 14, INK)
        meal_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var field = _number(meal_row, float(original_shares[i]), 0.0, 100.0, 1.0)
        field.name = "MealShareField_" + str(i)
        field.custom_minimum_size.x = 105
        portion_fields.append(field)
    var shares_preview = _label(portions_card, "", 13, TEXT_ACCENT)
    var calorie_preview = _label(portions_card, "", 12, MUTED)
    calorie_preview.name = "MealCaloriePreview"
    var refresh_shares = func(_new_value: float):
        var total_percent: int = 0
        var values: Array = []
        var parsed_kcal = StoreScript.parse_calorie_target(kcal.text)
        for field in portion_fields:
            var pct: int = roundi(field.value)
            total_percent += pct
            values.append(roundi(float(maxi(parsed_kcal, 0)) * float(pct) / 100.0))
        shares_preview.text = "Распределено: " + str(total_percent) + "% из 100%"
        if total_percent != 100:
            shares_preview.text += " · нужно ровно 100%"
        if parsed_kcal < 0:
            calorie_preview.text = "Для расчёта введи норму от 1000 до 5000 ккал."
        else:
            calorie_preview.text = "При " + str(parsed_kcal) + " ккал в день:\n" + (
                "Завтрак " + str(values[0]) + " · Обед " + str(values[1]) + " ккал\n" +
                "Ужин " + str(values[2]) + " · Перекус " + str(values[3]) + " ккал"
            )
    for field in portion_fields:
        field.value_changed.connect(refresh_shares)
    kcal.text_changed.connect(func(_value: String): refresh_shares.call(0.0))
    refresh_shares.call(0.0)
    _button(portions_card, "Сохранить распределение", func():
        var next: Array = []
        for field in portion_fields:
            next.append(roundi(field.value))
        if not StoreScript.valid_meal_shares(next):
            _message("Сумма долей должна быть 100%, каждое число от 0 до 100.")
            return
        if store.set_meal_shares(next):
            _render()
            _notify_saved("Ориентиры по приёмам пищи сохранены")
        else:
            _message("Не удалось сохранить распределение.")
    )
    _button(portions_card, "Вернуть 25 / 35 / 30 / 10", func():
        for i in range(portion_fields.size()):
            portion_fields[i].value = float(StoreScript.DEFAULT_MEAL_SHARES[i])
    , true)

    var appearance = _card("Оформление")
    _label(appearance, "Выбери тему — она сразу применится ко всем экранам.", 13, MUTED)
    _label(appearance, "Активная: " + AppearanceScript.name_for(current_theme), 14, TEXT_ACCENT)
    for id in AppearanceScript.ORDER:
        var theme_id: String = str(id)
        var sample: Dictionary = AppearanceScript.palette(theme_id, HIGH_CONTRAST)
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
    _button(appearance, "Контраст: повышенный" if HIGH_CONTRAST else "Контраст: обычный",
        func(): _toggle_high_contrast(), true)
    _label(appearance, "Повышенный контраст делает текст, карточки, кнопки и поля ввода заметнее во всех пяти темах.", 12, MUTED)

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
    _label(foods_card, "Основа КБЖУ с упаковки", 13, MUTED)
    var basis = _choice(foods_card, ["На 100 г", "На 100 мл"])
    _label(foods_card, "Калории на выбранные 100 единиц", 13, MUTED)
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
            "source": "Пользователь",
            "nutrition_unit": "мл" if basis.selected == 1 else "г"
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
    var sheet = _mobile_sheet("Редактировать продукт", "КБЖУ на 100 г или 100 мл. Исторические записи останутся прежними.", "Сохранить", 620.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, "Название", 13, MUTED)
    var name = _text_input(fields, "Название", str(food.get("name", "")))
    _label(fields, "Штрихкод (необязательно)", 13, MUTED)
    var code = _text_input(fields, "EAN / UPC", str(food.get("barcode", "")))
    code.max_length = 14
    code.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
    _label(fields, "Основа пищевой ценности", 13, MUTED)
    var basis = _choice(fields, ["На 100 г", "На 100 мл"])
    basis.select(1 if PortionMath.base_unit(food) == "мл" else 0)
    _label(fields, "Калории на 100 г / мл", 13, MUTED)
    var kcal = _number(fields, float(food.get("kcal", 0)), 0, 1000, 0.1)
    _label(fields, "Белки • Жиры • Углеводы на 100 г", 13, MUTED)
    var nutrition_row = _row(fields)
    var p = _number(nutrition_row, float(food.get("p", 0)), 0, 100, 0.1)
    var f = _number(nutrition_row, float(food.get("f", 0)), 0, 100, 0.1)
    var c = _number(nutrition_row, float(food.get("c", 0)), 0, 100, 0.1)
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        var changes = {"name": name.text.strip_edges(), "barcode": code.text.strip_edges(),
            "kcal": kcal.value, "p": p.value, "f": f.value, "c": c.value,
            "nutrition_unit": "мл" if basis.selected == 1 else "г"}
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

func _confirm_action(title: String, description: String, action: Callable) -> void:
    var dialog = ConfirmationDialog.new()
    dialog.title = title
    dialog.dialog_text = description
    dialog.ok_button_text = "Повторить"
    add_child(dialog)
    dialog.confirmed.connect(func(): action.call(); dialog.queue_free())
    dialog.canceled.connect(func(): dialog.queue_free())
    dialog.popup_centered(Vector2i(350, 190))

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
