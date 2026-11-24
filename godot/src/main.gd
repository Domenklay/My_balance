extends Control

const StoreScript = preload("res://src/store.gd")
const GraphScript = preload("res://src/weight_graph.gd")
const ProgressGraph = preload("res://src/progress_graph_math.gd")
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
const PRODUCT_PLACEHOLDER = preload("res://assets/products/package.svg")
const FoodSearchScript = preload("res://src/food_search.gd")
const AppearanceScript = preload("res://src/appearance.gd")
const PatternScript = preload("res://src/theme_pattern.gd")
const ActivityMath = preload("res://src/activity_math.gd")
const BodyMeasurements = preload("res://src/body_measurements.gd")
const BodyMapScript = preload("res://src/body_map.gd")
const MealPlannerScript = preload("res://src/meal_planner.gd")
const MEAL_TEXTURES = [
    preload("res://assets/meals/breakfast.svg"),
    preload("res://assets/meals/lunch.svg"),
    preload("res://assets/meals/dinner.svg"),
    preload("res://assets/meals/snack.svg")
]
const NAV_TEXTURES = {
    "day": preload("res://assets/nav/day.svg"),
    "recipes": preload("res://assets/nav/recipes.svg"),
    "search": preload("res://assets/nav/search.svg"),
    "progress": preload("res://assets/nav/stats.svg"),
    "activity": preload("res://assets/nav/activity.svg"),
    "weight": preload("res://assets/nav/weight.svg"),
    "stats": preload("res://assets/nav/stats.svg"),
    "profile": preload("res://assets/nav/profile.svg")
}
# Keep the UI version tied to the Android export by regression test.
const APP_VERSION = "0.7.54"

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
# The combined Progress page retains separate weight and report views.
var progress_section: String = "weight"
var selected_body_metric: String = "waist"
var body_chart_period: String = "quarter"
var weight_chart_period: String = "quarter"
var weight_history_expanded: bool = false
var body_history_expanded: bool = false
var water_details_expanded: bool = false
var water_history_expanded: bool = false
# Optional, user-initiated Google Drive appDataFolder backup session.
# Tokens stay inside the native plugin; only cloud metadata reaches GDScript.
var google_plugin = null
var google_connected: bool = false
var google_checked: bool = false
var google_exists: bool = false
var google_checksum: String = ""
var google_file_id: String = ""
var google_modified: String = ""
var google_busy: bool = false
var planner_day: String = ""
var shopping_expanded: bool = false
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
# Only one category is expanded at a time to keep the long settings screen
# usable on smaller phones; this is presentation state, not diary data.
var settings_section_open: String = ""
var recipe_editor_open: bool = false
var profile_edit_open: bool = false
var rewards_expanded: bool = false
var frames_expanded: bool = false
var profile_more_expanded: bool = false
var day_more_expanded: bool = false
var day_tools_expanded: bool = false
var home_widget_editor_open: bool = false
var home_progress_view: String = "week"
var stats_detail_tab: String = "nutrition"
var onboarding_step: int = 0
var onboarding_edit: bool = false
var onboarding_draft: Dictionary = {}
var recipe_draft: Dictionary = {}
var recipe_search_text: String = ""
var recipe_list_query: String = ""
var recipe_list_filter: String = "all"
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
    DARK_MODE = current_theme in ["dark", "botanical"]
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
    # Preserve the selected light forest theme. The historical automatic
    # switch to botanical is no longer appropriate now that it is dark plum.
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
    if OS.has_feature("android") and Engine.has_singleton("MyBalanceGoogleDrive"):
        google_plugin = Engine.get_singleton("MyBalanceGoogleDrive")
        google_plugin.connect("google_connected", Callable(self, "_on_google_connected"))
        google_plugin.connect("google_disconnected", Callable(self, "_on_google_disconnected"))
        google_plugin.connect("google_status", Callable(self, "_on_google_status"))
        google_plugin.connect("google_backup_loaded", Callable(self, "_on_google_backup_loaded"))
        google_plugin.connect("google_backup_saved", Callable(self, "_on_google_backup_saved"))
        google_plugin.connect("google_backup_deleted", Callable(self, "_on_google_backup_deleted"))
        google_plugin.connect("google_error", Callable(self, "_on_google_error"))
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
    head_style.content_margin_left = 17
    head_style.content_margin_right = 17
    head_style.content_margin_top = 8
    head_style.content_margin_bottom = 8
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
    header_title = _label(brand, "Мой баланс", 21, WHITE)
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

func _navigate_to_products() -> void:
    # The bottom Products button opens a general catalog, not the last
    # locked meal. Diary meal headings still lock meal/date explicitly.
    _meal_entry_locked = false
    _meal_entry_date = ""
    _navigate_to_tab("search")


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
    st.set_corner_radius_all(12)
    st.content_margin_left = 12
    st.content_margin_right = 12
    st.content_margin_top = 10
    st.content_margin_bottom = 10
    return st

func _input_focus_style() -> StyleBoxFlat:
    var st = StyleBoxFlat.new()
    st.bg_color = Color(0, 0, 0, 0)
    st.border_color = TEXT_ACCENT if DARK_MODE else GREEN
    st.set_border_width_all(3 if HIGH_CONTRAST else 2)
    st.set_corner_radius_all(12)
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
    # Primary and secondary actions are visually distinct in all themes.
    for mode in ["normal", "hover", "pressed"]:
        var st = StyleBoxFlat.new()
        st.bg_color = SECONDARY if secondary else GREEN
        if mode == "hover":
            st.bg_color = SECONDARY.lightened(0.045) if secondary else GREEN.lightened(0.07)
        elif mode == "pressed":
            st.bg_color = SECONDARY.darkened(0.045) if secondary else GREEN.darkened(0.07)
        if secondary:
            st.border_color = BORDER if HIGH_CONTRAST else BORDER.lightened(0.12)
            st.set_border_width_all(1)
        elif HIGH_CONTRAST:
            st.border_color = GREEN.darkened(0.18)
            st.set_border_width_all(1)
        st.set_corner_radius_all(12)
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
    style.set_corner_radius_all(18)
    style.border_color = BORDER if variant == "plain" or HIGH_CONTRAST else style.bg_color
    if current_theme == "botanical":
        style.border_color = BORDER
    style.set_border_width_all(2 if HIGH_CONTRAST else 1)
    # Quiet elevation: the calorie card has visual priority.
    style.shadow_color = Color(0.0, 0.0, 0.0, 0.12 if DARK_MODE else 0.048)
    style.shadow_size = 3 if variant == "hero" else 1
    style.shadow_offset = Vector2(0, 1)
    style.content_margin_left = 15
    style.content_margin_right = 15
    style.content_margin_top = 15
    style.content_margin_bottom = 15
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
        mountain_art.configure("hills", PATTERN_COLOR, true, 0.13)
        panel.add_child(mountain_art)
    var content = VBoxContainer.new()
    content.mouse_filter = Control.MOUSE_FILTER_PASS
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 11)
    panel.add_child(content)
    if not title.is_empty():
        _label(content, title, 18, WHITE if variant == "hero" else INK)
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
            style.shadow_size = 1
            style.shadow_offset = Vector2(0, 1)
    content.add_theme_constant_override("separation", spacing)


func _compact_macro(parent: Node, name: String, value: float,
        background: Color, foreground: Color) -> void:
    var panel = PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style = StyleBoxFlat.new()
    style.bg_color = background
    style.set_corner_radius_all(10)
    style.content_margin_left = 5
    style.content_margin_right = 5
    style.content_margin_top = 6
    style.content_margin_bottom = 6
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
    st.border_color = BORDER if HIGH_CONTRAST else BORDER.lightened(0.20)
    st.set_border_width_all(1)
    st.set_corner_radius_all(12)
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
    st.content_margin_top = 7
    st.content_margin_bottom = 7
    bar.add_theme_stylebox_override("panel", st)
    shell.add_child(bar)
    var row = HBoxContainer.new()
    row.add_theme_constant_override("separation", 2)
    bar.add_child(row)
    var tabs = [
        ["День", "day"], ["Продукты", "search"], ["Спорт", "activity"],
        ["Прогресс", "progress"], ["Профиль", "profile"]
    ]
    for item in tabs:
        var target: String = item[1]
        var title: String = item[0]
        var button = _button(row, "", func():
            if target == "search":
                _navigate_to_products()
            else:
                _navigate_to_tab(target)
        , true)
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
        var active = key == tab or (key == "profile" and tab == "settings") or \
            (key == "search" and tab == "recipes") or \
            (key == "day" and tab == "planner") or \
            (key == "progress" and tab in ["weight", "stats"])
        var style = StyleBoxFlat.new()
        style.bg_color = NAV_ACTIVE if active else CARD_BG
        if HIGH_CONTRAST and active:
            style.border_color = SOFT_GOLD
            style.set_border_width_all(2)
        style.set_corner_radius_all(12)
        if active:
            style.border_color = SOFT_GOLD if HIGH_CONTRAST else NAV_ACTIVE.lightened(0.14)
            style.set_border_width_all(1)
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
        "planner": _show_week_planner()
        "onboarding": _show_onboarding()
        "search": _show_food_search()
        "recipes": _show_recipes()
        "profile": _show_profile()
        "activity": _show_activity()
        "weight": _show_weight()
        "stats": _show_stats()
        "progress": _show_progress()
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
    if tab == "day":
        var customize_button = _button(r, "⚙", func():
            home_widget_editor_open = not home_widget_editor_open
            _render()
        , true)
        customize_button.name = "HomeWidgetSettingsToggle"
        customize_button.tooltip_text = "Настроить виджеты главной страницы"
        customize_button.add_theme_font_size_override("font_size", 19)

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
    # Keep the % attached to its number on small Android screens.
    value_text.autowrap_mode = TextServer.AUTOWRAP_OFF
    value_text.custom_minimum_size.x = 54
    value_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value_text.size_flags_horizontal = Control.SIZE_SHRINK_END
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
    var measure_link = _button(hero, "📏 Замеры тела", func(): _set_progress_section("body"), true)
    measure_link.name = "ProfileBodyMeasurements"
    measure_link.custom_minimum_size.y = 39
    measure_link.add_theme_font_size_override("font_size", 13)
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
    var portion_weight: float = cooked.value / maxf(1.0, portions.value)
    var source_text: String = ("Исходные продукты: " +
        str(snappedf(float(result["raw_weight"]), 0.1)) + " г")
    if float(result.get("raw_volume", 0.0)) > 0.0:
        source_text += (" + " + str(snappedf(float(result["raw_volume"]), 0.1)) + " мл")
    label.text = (source_text +
        "\nПосле готовки: " + str(snappedf(cooked.value, 0.1)) + " г" +
        "\nВсё блюдо: " + str(roundi(result["total_kcal"])) + " ккал" +
        " · Б " + str(snappedf(float(result["total_p"]), 0.1)) +
        " Ж " + str(snappedf(float(result["total_f"]), 0.1)) +
        " У " + str(snappedf(float(result["total_c"]), 0.1)) +
        "\nНа 100 г готового: " + str(roundi(result["kcal"])) + " ккал" +
        " · Б " + str(snappedf(result["p"], 0.1)) +
        " Ж " + str(snappedf(result["f"], 0.1)) +
        " У " + str(snappedf(result["c"], 0.1)) +
        "\n1 порция ~" + str(roundi(portion_weight)) + " г: " +
        str(roundi(result["total_kcal"] / maxf(1.0, portions.value))) + " ккал")

func _recipe_append_ingredient(food: Dictionary, amount: float,
        name: LineEdit, cooked: SpinBox, portions: SpinBox) -> void:
    if recipe_draft.get("ingredients", []).size() >= 40:
        _message("В одном рецепте допускается до 40 ингредиентов.")
        return
    if not is_finite(amount) or amount <= 0.0 or amount > 10000.0:
        _message("Укажи допустимое количество ингредиента.")
        return
    _recipe_sync_form(name, cooked, portions)
    recipe_draft["ingredients"].append({
        "id": str(food.get("id", "")), "name": str(food.get("name", "")),
        "grams": amount, "unit": PortionMath.base_unit(food),
        "kcal": float(food.get("kcal", 0)),
        "p": float(food.get("p", 0)), "f": float(food.get("f", 0)),
        "c": float(food.get("c", 0))
    })
    _render()


func _show_recipe_editor() -> void:
    var toolbar = _card("Редактор домашнего блюда")
    _label(toolbar, "Для каждого ингредиента КБЖУ берётся на 100 г или 100 мл. Укажи съедобный вес готового блюда: выпаривание воды меняет калорийность 100 г, но не общие КБЖУ.", 13, MUTED)
    var name = _text_input(toolbar, "Название блюда", str(recipe_draft.get("name", "")))
    name.max_length = 160
    _label(toolbar, "Вес после приготовления, г (съедобная часть, без посуды)", 13, MUTED)
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
        var label = _label(line, str(ingredient.get("name", "Ингредиент")) +
            " (" + str(ingredient.get("unit", "г")) + ")", 13, INK)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var grams = _number(line, float(ingredient.get("grams", 100)), 1, 10000, 1)
        grams.tooltip_text = "Количество ингредиента, " + str(ingredient.get("unit", "г"))
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
    var ingredient_unit_hint = _label(add, "Количество ингредиента, г", 13, MUTED)
    var weight = _number(add, 100, 1, 10000, 1)
    picker.item_selected.connect(func(index: int):
        if index >= 0 and index < filtered.size():
            ingredient_unit_hint.text = ("Количество ингредиента, " +
                PortionMath.base_unit(filtered[index]))
    )
    search.text_changed.connect(func(_text: String):
        if not filtered.is_empty():
            ingredient_unit_hint.text = ("Количество ингредиента, " +
                PortionMath.base_unit(filtered[0]))
    )
    if not filtered.is_empty():
        ingredient_unit_hint.text = "Количество ингредиента, " + PortionMath.base_unit(filtered[0])
    _button(add, "+ Добавить ингредиент", func():
        if picker.selected < 0 or picker.selected >= filtered.size():
            _message("Сначала выбери ингредиент.")
            return
        _recipe_append_ingredient(filtered[picker.selected], weight.value, name, cooked, portions)
    )
    var shortcuts: Array = []
    var used_ids: Dictionary = {}
    for fav_id in store.data.get("favorites", []):
        var fav_food: Dictionary = store.food_by_id(str(fav_id))
        if not fav_food.is_empty() and not used_ids.has(str(fav_id)):
            shortcuts.append(fav_food)
            used_ids[str(fav_id)] = true
        if shortcuts.size() >= 3:
            break
    for recent_food in store.recent_foods(6):
        var recent_id: String = str(recent_food.get("id", ""))
        if not used_ids.has(recent_id) and not recent_id.begins_with("recipe:"):
            shortcuts.append(recent_food)
            used_ids[recent_id] = true
        if shortcuts.size() >= 5:
            break
    if not shortcuts.is_empty():
        _label(add, "Недавние и избранные ингредиенты", 12, TEXT_ACCENT)
        var chips = VBoxContainer.new()
        chips.name = "RecipeIngredientShortcuts"
        chips.add_theme_constant_override("separation", 3)
        add.add_child(chips)
        for food_record in shortcuts:
            var shortcut_food: Dictionary = food_record
            var shortcut_name: String = str(shortcut_food.get("name", "Продукт"))
            var chip = _button(chips, "+ " + shortcut_name + " · " +
                PortionMath.base_unit(shortcut_food), func():
                    _recipe_append_ingredient(shortcut_food, weight.value, name, cooked, portions)
            , true)
            chip.clip_text = true
            chip.custom_minimum_size.y = 35
            chip.add_theme_font_size_override("font_size", 12)
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
                "grams": manual_grams.value, "unit": "г", "kcal": manual_kcal.value,
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
    _label(preview_card, "Для КБЖУ используй съедобные ингредиенты, включая использованное масло и съеденный соус. Неучтённые потери питательных веществ при готовке автоматически не вычитаются.", 12, MUTED)
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
    var last: Dictionary = store.last_recipe_portion(str(recipe.get("id", "")))
    var normal_weight: float = float(recipe["cooked_weight"]) / maxf(1.0, float(recipe["servings"]))
    var initial_weight: float = float(last.get("grams", normal_weight))
    var sheet = _mobile_sheet(str(recipe.get("name", "Рецепт")),
        "Выбери съеденный вес готового блюда. Расчёт КБЖУ ведётся по фактическому весу после готовки.",
        "Добавить порцию", 425.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, "Порция готового блюда, г", 13, MUTED)
    var weight = _number(fields, minf(5000.0, initial_weight), 1, 5000, 1)
    weight.name = "RecipeServingWeight"
    var preset_row = _row(fields)
    preset_row.name = "RecipeServingPresets"
    for choice in [["½ порции", 0.5], ["1 порция", 1.0], ["2 порции", 2.0]]:
        var factor: float = float(choice[1])
        var preset = _button(preset_row, str(choice[0]), func():
            weight.value = minf(5000.0, normal_weight * factor)
        , true)
        preset.add_theme_font_size_override("font_size", 12)
    if not last.is_empty():
        var repeat_button = _button(fields, "↻ Последняя: " +
            str(snappedf(float(last["grams"]), 0.1)) + " г", func():
                weight.value = float(last["grams"])
        , true)
        repeat_button.name = "RecipeLastPortion"
    _label(fields, "Приём пищи", 13, MUTED)
    var meal = _choice(fields, ["Завтрак", "Обед", "Перекус", "Ужин"])
    meal.name = "RecipeServingMeal"
    var target_meal: String = selected_meal
    if not _meal_entry_locked and not last.is_empty():
        target_meal = str(last.get("meal", selected_meal))
    var chosen_index: int = ["Завтрак", "Обед", "Перекус", "Ужин"].find(target_meal)
    if chosen_index >= 0:
        meal.select(chosen_index)
    meal.disabled = _meal_entry_locked
    var portion_text = _label(fields, "", 14, TEXT_ACCENT)
    portion_text.name = "RecipeServingPreview"
    var refresh = func(v: float):
        var actual = RecipeMath.portion(str(recipe["name"]), values, v)
        portion_text.text = (str(snappedf(v, 0.1)) + " г · " +
            str(roundi(float(actual.get("kcal", 0)))) + " ккал" +
            "\nБ " + str(snappedf(float(actual.get("p", 0)), 0.1)) +
            " · Ж " + str(snappedf(float(actual.get("f", 0)), 0.1)) +
            " · У " + str(snappedf(float(actual.get("c", 0)), 0.1)))
    weight.value_changed.connect(refresh)
    refresh.call(weight.value)
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        if store.add_recipe_portion(str(recipe["id"]), weight.value,
                meal.get_item_text(meal.selected), _selected_food_date()):
            sheet["root"].queue_free()
            _meal_entry_locked = false
            _meal_entry_date = ""
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
    if _meal_entry_locked:
        var destination: String = selected_meal
        _button(intro, "← Назад к " + destination.to_lower(), func():
            _navigate_to_tab("day")
        , true)
    _button(intro, "+ Создать рецепт", func(): _begin_recipe_editor(), true)
    if not _meal_entry_locked:
        _button(intro, "⌕ Поиск продуктов", func(): _navigate_to_tab("search"), true)
    var recipes: Array = store.data.get("recipes", []).duplicate()
    recipes.sort_custom(func(a, b):
        var a_favorite: bool = bool(a.get("favorite", false))
        var b_favorite: bool = bool(b.get("favorite", false))
        if a_favorite != b_favorite:
            return a_favorite
        return str(a.get("name", "")).nocasecmp_to(str(b.get("name", ""))) < 0
    )
    var recently_logged: Dictionary = {}
    var recipe_search_field: LineEdit = null
    var recipe_search_count: Label = null
    var recipe_search_cards: Array = []
    for logged_recipe in store.recent_recipe_portions(100):
        recently_logged[str(logged_recipe["recipe_id"])] = true
    if not recipes.is_empty():
        var filter_card = _card("Поиск по рецептам")
        var filter_row = _row(filter_card)
        filter_row.name = "RecipeQuickFilters"
        for entry in [["Все", "all"], ["★ Избранные", "favorite"], ["Недавние", "recent"]]:
            var filter_key: String = str(entry[1])
            var tab_button = _button(filter_row, str(entry[0]), func():
                recipe_list_filter = filter_key
                _render()
            , recipe_list_filter != filter_key)
            tab_button.custom_minimum_size.y = 38
            tab_button.add_theme_font_size_override("font_size", 12)
            tab_button.clip_text = true
        recipe_search_field = _text_input(filter_card,
            "Поиск блюда или ингредиента", recipe_list_query)
        recipe_search_field.name = "RecipeLiveSearch"
        recipe_search_field.clear_button_enabled = true
        recipe_search_count = _label(filter_card, "", 12, MUTED)
        recipe_search_count.name = "RecipeSearchCount"
    if recipes.is_empty():
        var empty = _card("Пока нет рецептов")
        _label(empty, "Добавь ингредиенты с их сырым весом, взвесь готовое блюдо — и приложение рассчитает КБЖУ на 100 г.", 14, MUTED)
    var matched = 0
    for saved in recipes:
        var recipe: Dictionary = saved
        if recipe_list_filter == "favorite" and not bool(recipe.get("favorite", false)):
            continue
        if recipe_list_filter == "recent" and not recently_logged.has(str(recipe.get("id", ""))):
            continue
        matched += 1
        var details = RecipeMath.calculate(recipe["ingredients"], float(recipe["cooked_weight"]))
        if details.is_empty():
            continue
        var recipe_id: String = str(recipe.get("id", ""))
        var card = _card("")
        card.get_parent().name = "RecipeCard_" + recipe_id
        var search_terms: String = str(recipe.get("name", "")).to_lower()
        for ingredient in recipe.get("ingredients", []):
            search_terms += " " + str(ingredient.get("name", "")).to_lower()
        recipe_search_cards.append({"panel": card.get_parent(), "terms": search_terms})
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
        var star_button = _button(overview,
            "★" if bool(recipe.get("favorite", false)) else "☆", func():
                if store.toggle_recipe_favorite(recipe_id):
                    _render()
                else:
                    _message("Не удалось сохранить избранное.")
        , true)
        star_button.name = "RecipeFavorite_" + recipe_id
        star_button.tooltip_text = ("Удалить из избранного" if bool(recipe.get("favorite", false))
            else "Добавить в избранное")
        star_button.custom_minimum_size = Vector2(41, 42)
        star_button.size_flags_horizontal = Control.SIZE_SHRINK_END
        star_button.add_theme_font_size_override("font_size", 22)
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
        var previous_portion: Dictionary = store.last_recipe_portion(recipe_id)
        if not previous_portion.is_empty():
            var last_weight: float = float(previous_portion["grams"])
            var last_meal: String = str(previous_portion["meal"])
            var quick_repeat = _button(card,
                "↻ Повторить " + str(snappedf(last_weight, 0.1)) +
                " г · " + last_meal, func():
                    if store.repeat_recipe_portion(recipe_id, _selected_food_date()):
                        tab = "day"
                        _render()
                        _notify_saved("Порция рецепта повторена")
                    else:
                        _message("Не удалось повторить порцию.")
            , true)
            quick_repeat.name = "RecipeRepeat_" + recipe_id
            quick_repeat.custom_minimum_size.y = 37
            quick_repeat.add_theme_font_size_override("font_size", 12)
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
    if not recipes.is_empty():
        var no_results = _card("Ничего не найдено")
        no_results.get_parent().name = "RecipeNoMatches"
        var no_results_text = _label(no_results, "", 13, MUTED)
        var refresh_recipes = func(text_value: String):
            # Do not rebuild the entire screen as the user types. That would
            # drop keyboard focus and reset the Android cursor position.
            recipe_list_query = text_value
            var needle: String = text_value.strip_edges().to_lower()
            var visible_count: int = 0
            for result in recipe_search_cards:
                var found: bool = needle.is_empty() or str(result["terms"]).contains(needle)
                var panel: Control = result["panel"]
                panel.visible = found
                if found:
                    visible_count += 1
            no_results.get_parent().visible = visible_count == 0
            no_results_text.text = (
                "В этом разделе пока нет блюд. Выбери «Все»." if matched == 0
                else "Попробуй другое блюдо или ингредиент либо очисти поиск."
            )
            if recipe_search_count != null:
                recipe_search_count.text = ("Показано: " + str(visible_count) +
                    " из " + str(matched) + " · поиск без кнопки")
        if recipe_search_field != null:
            recipe_search_field.text_changed.connect(refresh_recipes)
            refresh_recipes.call(recipe_search_field.text)

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
    var last_count: float = float(recent.get("portion_count", 0.0))
    var last_measure_id: String = str(recent.get("portion_id", ""))
    if store.add_food_entry(food, grams, selected_meal, _selected_food_date(),
            portion_label, last_count, last_measure_id):
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
    if not store.data.get("recipes", []).is_empty():
        var to_recipes = _button(fields, "▤ Мои блюда и рецепты", func():
            sheet["root"].queue_free()
            tab = "recipes"
            recipe_list_filter = "all"
            _render(true)
        , true)
        to_recipes.name = "MealChooseRecipe"
        to_recipes.custom_minimum_size.y = 39
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


# Use the very same search field for names, brands or a complete EAN/UPC.
# Known barcodes always open the local saved portion; no network round-trip.
func _lookup_barcode_from_search(search: LineEdit) -> void:
    var code: String = BarcodeScript.normalize_code(search.text.strip_edges())
    if code.is_empty():
        if is_instance_valid(online_search_label):
            online_search_label.text = "Для поиска штрихкода введи полный EAN/UPC с контрольной цифрой."
        return
    var saved: Dictionary = store.food_by_barcode(code)
    if not saved.is_empty():
        _show_barcode_portion(saved)
        return
    _lookup_barcode(code)
    if is_instance_valid(online_search_label):
        online_search_label.text = "Проверяем штрихкод " + code + " в Open Food Facts…"


func _open_online_product(record: Dictionary) -> void:
    var code: String = str(record.get("barcode", ""))
    var saved: Dictionary = store.food_by_barcode(code)
    if not saved.is_empty():
        _show_barcode_portion(saved)
    else:
        _confirm_barcode_product(record)


# One explicit tap repeats the last actual amount and measure of a product,
# not an assumed 100 g. The meal/date remains the one selected in the diary.
func _repeat_search_food(food: Dictionary, last: Dictionary,
        added_label: Label) -> void:
    var grams: float = float(last.get("grams", 0))
    if grams <= 0.0 or grams > 5000.0 or \
            str(last.get("unit", "г")) != PortionMath.base_unit(food):
        _message("Сохранённая порция недоступна. Выбери вес вручную.")
        return
    if store.add_food_entry(food, grams, selected_meal, _selected_food_date(),
            str(last.get("portion_label", "")),
            float(last.get("portion_count", 0)), str(last.get("portion_id", ""))):
        if is_instance_valid(added_label):
            added_label.set_meta("count", int(added_label.get_meta("count", 0)) + 1)
            added_label.text = "Добавлено за сеанс: " + str(added_label.get_meta("count"))
        _notify_saved("Повторена порция: " + str(snappedf(grams, 0.1)) +
            " " + str(last.get("unit", "г")))
    else:
        _message("Не удалось добавить порцию. Проверь свободное место.")


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
        "User-Agent: MyBalance/0.7.31 (+https://github.com/Domenklay/My_balance)",
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
        online_search_label.text = "Товары не найдены. Попробуй название или бренд."
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
        var details: String = str(product.get("brand", ""))
        var package_text: String = str(product.get("quantity", "")).strip_edges()
        if not package_text.is_empty():
            details += (" · " if not details.is_empty() else "") + package_text
        if not details.is_empty():
            _label(info, details, 11, MUTED)
        var saved: Dictionary = store.food_by_barcode(str(product.get("barcode", "")))
        if not saved.is_empty():
            _label(info, "✓ Уже в каталоге · доступен офлайн", 11, TEXT_ACCENT)
        if not product.get("missing_fields", []).is_empty():
            _label(info, BarcodeScript.nutrition_review_label(product), 11, ACCENT)
        else:
            _label(info, str(roundi(float(product.get("kcal", 0)))) +
                " ккал / 100 " + PortionMath.base_unit(product) + " · Б " +
                str(product.get("p", 0)) + " Ж " + str(product.get("f", 0)) +
                " У " + str(product.get("c", 0)), 11, MUTED)
        var quality_issues: Array = BarcodeScript.quality_flags(product)
        if not quality_issues.is_empty() and product.get("missing_fields", []).is_empty():
            _label(info, "⚠ " + str(quality_issues[0]), 11, ACCENT)
        var choose = _button(row, "Выбрать", func():
            _open_online_product(product)
        , true)
        choose.name = "OnlineFoodChoose_" + str(product.get("barcode", ""))
        choose.custom_minimum_size.y = 40
        choose.size_flags_horizontal = Control.SIZE_SHRINK_END
        choose.add_theme_font_size_override("font_size", 12)
        if not saved.is_empty():
            var update = _button(info, "Сверить с этикеткой и обновить", func():
                _confirm_barcode_product(product)
            , true)
            update.custom_minimum_size.y = 34
            update.add_theme_font_size_override("font_size", 11)


func _open_recipes_from_products() -> void:
    # Keep the selected meal and date when opening saved dishes from catalog.
    recipe_list_filter = "all"
    tab = "recipes"
    _render(true)


func _show_food_search() -> void:
    var intro = _card("Продукты", "hero")
    _compact_card(intro, 10, 6)
    if _meal_entry_locked:
        _label(intro, "Добавление в «" + selected_meal + "» · " +
            _selected_food_date(), 13, HERO_MUTED)
        _button(intro, "← Назад к дневнику", func(): _navigate_to_tab("day"), true)
    else:
        _label(intro, "Поиск продуктов и быстрый доступ к домашним блюдам.", 13, HERO_MUTED)
    var shortcuts = _row(intro)
    shortcuts.name = "ProductShortcuts"
    var recipes_link = _button(shortcuts, "▤ Мои рецепты",
        func(): _open_recipes_from_products(), true)
    recipes_link.name = "ProductsOpenRecipes"
    recipes_link.custom_minimum_size.y = 40
    var my_foods_link = _button(shortcuts, "Мои продукты", func():
        settings_page = "foods"
        _navigate_to_tab("settings")
    , true)
    my_foods_link.name = "ProductsOpenMyFoods"
    my_foods_link.custom_minimum_size.y = 40
    if not _meal_entry_locked:
        var planner_link = _button(intro, "▦ План питания и покупки",
            func(): _open_week_planner(), true)
        planner_link.name = "ProductsOpenPlanner"
        planner_link.custom_minimum_size.y = 42
    var catalog = _card("Найти и добавить продукт")
    _compact_card(catalog, 10, 7)
    _food_form(catalog)


func _show_home_widget_editor(parent: Node) -> void:
    var area = VBoxContainer.new()
    area.name = "HomeWidgetSettings"
    area.add_theme_constant_override("separation", 5)
    parent.add_child(area)
    _label(area, "Показывать в блоке «Мой прогресс»:", 12, MUTED)
    var enabled_widgets: Dictionary = store.home_widgets()
    for option in [["week", "График калорий за неделю"],
            ["weight", "Вес и достижение цели"]]:
        var key: String = str(option[0])
        var is_enabled: bool = bool(enabled_widgets.get(key, false))
        var item = _button(area, ("✓  " if is_enabled else "○  ") + str(option[1]),
            func():
                if store.set_home_widget(key, not is_enabled):
                    # An enabled view is never allowed to remain selected
                    # after the user turns that specific view off.
                    if not is_enabled:
                        home_progress_view = key
                    _render()
                    _notify_saved("Виджеты главной обновлены")
                else:
                    _message("Не удалось сохранить настройки виджетов.")
        , true)
        item.name = "HomeWidgetChoice_" + key
        item.custom_minimum_size.y = 38
        item.alignment = HORIZONTAL_ALIGNMENT_LEFT
        item.add_theme_font_size_override("font_size", 13)


func _set_home_progress_view(view: String) -> void:
    if view not in ["week", "weight"] or not bool(store.home_widgets().get(view, false)):
        return
    home_progress_view = view
    _render()


# Semantic accents communicate purpose independently of the selected theme.
func _semantic_button(button: Button, background: Color, foreground: Color) -> void:
    for state in ["normal", "hover", "pressed"]:
        var style = button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
        if style == null:
            continue
        style.bg_color = background
        if state == "hover":
            style.bg_color = background.lightened(0.045)
        elif state == "pressed":
            style.bg_color = background.darkened(0.07)
        style.border_color = foreground if HIGH_CONTRAST else background
        style.set_border_width_all(2 if HIGH_CONTRAST else 1)
        button.add_theme_stylebox_override(state, style)
    for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
        button.add_theme_color_override(state, foreground)


func _daily_macro_tile(parent: Node, caption: String, grams: float, share: float,
        background: Color, foreground: Color, key: String) -> void:
    var panel = PanelContainer.new()
    panel.name = "DayMacro_" + key
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style = StyleBoxFlat.new()
    style.bg_color = background
    style.set_corner_radius_all(10)
    style.content_margin_left = 7
    style.content_margin_right = 7
    style.content_margin_top = 5
    style.content_margin_bottom = 5
    panel.add_theme_stylebox_override("panel", style)
    parent.add_child(panel)
    var stack = VBoxContainer.new()
    stack.add_theme_constant_override("separation", 2)
    panel.add_child(stack)
    var name_label = _nowrap(stack, caption, 11, foreground)
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var amount = _nowrap(stack, str(roundi(grams)) + " г", 17, foreground)
    amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var bar = ProgressBar.new()
    bar.name = "DayMacroShare_" + key
    bar.max_value = 100.0
    bar.value = clampf(share, 0.0, 100.0)
    bar.show_percentage = false
    bar.custom_minimum_size.y = 4
    bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var track = StyleBoxFlat.new()
    track.bg_color = foreground.lerp(background, 0.78)
    track.set_corner_radius_all(4)
    var fill = StyleBoxFlat.new()
    fill.bg_color = foreground
    fill.set_corner_radius_all(4)
    bar.add_theme_stylebox_override("background", track)
    bar.add_theme_stylebox_override("fill", fill)
    bar.tooltip_text = "Доля энергии БЖУ, не персональная норма"
    stack.add_child(bar)


func _show_water_card() -> void:
    # A single compact block in the existing Day tab; nothing changes in
    # food calories, activity targets or the five-tab navigation.
    var info: Dictionary = store.day_water_summary(date)
    var water_card = _card("", "plain")
    water_card.get_parent().name = "DayWaterCard"
    _compact_card(water_card, 10, 6)
    var water_bg = Color("#203E50") if DARK_MODE else Color("#E6F4F8")
    var water_ink = Color("#BDEDF5") if DARK_MODE else Color("#245D71")
    var water_button_bg = Color("#31596E") if DARK_MODE else Color("#D2EAF2")
    var water_style = water_card.get_parent().get_theme_stylebox("panel") as StyleBoxFlat
    water_style.bg_color = water_bg
    water_style.border_color = water_ink if HIGH_CONTRAST else water_bg.darkened(0.08)
    var heading = _row(water_card)
    var water_title = _label(heading, "💧 Вода", 16, water_ink)
    water_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var amount_label = _nowrap(heading, str(info["ml"]) + " / " +
        str(info["goal"]) + " мл", 15, water_ink)
    amount_label.name = "WaterDailyAmount"
    # _nowrap uses ellipsis and has no intrinsic minimum; reserve width so
    # the current ml / goal never disappears on a narrow phone screen.
    amount_label.custom_minimum_size.x = 145
    amount_label.size_flags_horizontal = Control.SIZE_SHRINK_END
    amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    var water_progress = ProgressBar.new()
    water_progress.name = "WaterDailyProgress"
    water_progress.min_value = 0
    water_progress.max_value = maxi(1, int(info["goal"]))
    water_progress.value = mini(int(info["ml"]), int(info["goal"]))
    water_progress.show_percentage = false
    water_progress.custom_minimum_size.y = 8
    _style_progress(water_progress)
    var fill = StyleBoxFlat.new()
    fill.bg_color = Color("#8BD8ED") if DARK_MODE else Color("#297B9B")
    fill.set_corner_radius_all(9)
    water_progress.add_theme_stylebox_override("fill", fill)
    var water_track = StyleBoxFlat.new()
    water_track.bg_color = water_button_bg
    water_track.set_corner_radius_all(9)
    water_progress.add_theme_stylebox_override("background", water_track)
    water_card.add_child(water_progress)
    var buttons = _row(water_card)
    buttons.name = "WaterQuickAmounts"
    buttons.add_theme_constant_override("separation", 5)
    for ml in [150, 250, 500]:
        var serving: int = ml
        var button = _button(buttons, "+" + str(serving) + " мл", func():
            if store.add_water(date, serving):
                _render()
                _notify_saved("Добавлено " + str(serving) + " мл воды")
            else:
                _message("Не удалось сохранить воду. Проверь объём или память устройства.")
        , true)
        button.name = "WaterQuickAdd_" + str(serving)
        _semantic_button(button, water_button_bg, water_ink)
        button.custom_minimum_size.y = 41
        button.add_theme_font_size_override("font_size", 12)
    var expanded = _button(water_card,
        "▴ Скрыть воду" if water_details_expanded else
        "▾ Своя порция, цель и история", func():
            water_details_expanded = not water_details_expanded
            _render()
    , true)
    expanded.name = "WaterDetailsToggle"
    _semantic_button(expanded, water_button_bg, water_ink)
    expanded.custom_minimum_size.y = 37
    expanded.add_theme_font_size_override("font_size", 12)
    if not water_details_expanded:
        return
    _label(water_card, "Добавить свою порцию", 13, INK)
    var custom_row = _row(water_card)
    var custom_amount = _number(custom_row, 300, 25, 2000, 25)
    custom_amount.name = "WaterCustomAmount"
    custom_amount.custom_minimum_size.x = 100
    var custom_save = _button(custom_row, "Добавить, мл", func():
        if store.add_water(date, roundi(custom_amount.value)):
            _render()
            _notify_saved("Вода записана")
        else:
            _message("Не удалось сохранить порцию воды.")
    )
    custom_save.name = "WaterCustomSave"
    custom_save.custom_minimum_size.y = 42
    _label(water_card, "Дневная цель, мл", 13, INK)
    var goal_row = _row(water_card)
    var goal_field = _number(goal_row, store.water_goal_ml(), 250, 6000, 50)
    goal_field.name = "WaterDailyGoal"
    goal_field.custom_minimum_size.x = 100
    var goal_save = _button(goal_row, "Сохранить цель", func():
        if store.set_water_goal_ml(roundi(goal_field.value)):
            _render()
            _notify_saved("Цель воды сохранена")
        else:
            _message("Не удалось сохранить цель воды.")
    , true)
    goal_save.name = "WaterSaveGoal"
    goal_save.custom_minimum_size.y = 42
    _label(water_card, "Цель настраивается вручную и не зависит от калорий. " +
        "Это личный ориентир, не медицинская рекомендация.", 11, MUTED)
    var week: Dictionary = store.week_water_summary(date)
    _label(water_card, "За неделю: " + str(week["ml"]) + " мл · " +
        str(week["days_logged"]) + " дней с записями", 12, MUTED)

    var history: Array = store.day_water_entries(date)
    history.reverse()
    _label(water_card, "Записи за выбранный день: " + str(history.size()), 13, INK)
    if history.is_empty():
        _label(water_card, "В этот день вода ещё не записана.", 12, MUTED)
    var limit: int = history.size() if water_history_expanded else mini(history.size(), 6)
    for i in range(limit):
        var item: Dictionary = history[i]
        var water_line = _soft_list_row(water_card)
        var label = _label(water_line, "Вода · " + str(item["ml"]) + " мл", 13, INK)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        var id: String = str(item["id"])
        var remove = _button(water_line, "×", func():
            if store.delete_water(id):
                _render()
                _notify_saved("Запись воды удалена")
            else:
                _message("Не удалось удалить запись воды.")
        , true)
        remove.name = "WaterDelete_" + id
        remove.tooltip_text = "Удалить эту порцию воды"
    if history.size() > 6:
        var toggle = _button(water_card,
            "Скрыть старые порции" if water_history_expanded else
            "Показать все порции (" + str(history.size()) + ")", func():
                water_history_expanded = not water_history_expanded
                _render()
        , true)
        toggle.name = "WaterHistoryToggle"


func _open_week_planner() -> void:
    planner_day = date
    shopping_expanded = false
    _meal_entry_locked = false
    _meal_entry_date = ""
    tab = "planner"
    _render(true)


func _planner_choose_day(chosen: String) -> void:
    if not StoreScript.valid_diary_date(chosen):
        return
    planner_day = chosen
    _render(true)


func _planner_shift_week(weeks: int) -> void:
    planner_day = store.change_date(planner_day, weeks * 7)
    _render(true)


func _planner_add_sheet(kind: String) -> void:
    var sources: Array = []
    if kind == "recipe":
        sources = store.data.get("recipes", []).duplicate()
        sources.sort_custom(func(a, b):
            if bool(a.get("favorite", false)) != bool(b.get("favorite", false)):
                return bool(a.get("favorite", false))
            return str(a.get("name", "")).nocasecmp_to(str(b.get("name", ""))) < 0)
    elif kind == "food":
        sources = store.all_foods()
    if sources.is_empty():
        _message("Сначала создай рецепт или добавь продукт в каталог.")
        return
    var title: String = "Запланировать рецепт" if kind == "recipe" else "Запланировать продукт"
    var detail: String = ("Вес готового блюда в граммах. Список покупок учитывает сырые ингредиенты."
        if kind == "recipe" else "Порция продукта. Вес и объём считаются в своих единицах.")
    var sheet = _mobile_sheet(title, detail, "Добавить в план", 555.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, "Дата: " + planner_day.substr(8, 2) + "." + \
        planner_day.substr(5, 2) + "." + planner_day.substr(0, 4), 13, TEXT_ACCENT)
    _label(fields, "Приём пищи", 13, MUTED)
    var meal_picker = _choice(fields, MealPlannerScript.MEALS)
    meal_picker.name = "PlannerMeal"
    _label(fields, "Найти название", 13, MUTED)
    var search = _text_input(fields, "Поиск рецепта или продукта")
    search.name = "PlannerSourceSearch"
    var picker = _choice(fields, [])
    picker.name = "PlannerSourcePicker"
    _label(fields, "Количество, г или мл", 13, MUTED)
    var amount = _number(fields, 200 if kind == "recipe" else 100, 1, 5000, 1)
    amount.name = "PlannerPortion"
    var preview = _label(fields, "Выбери продукт или рецепт.", 13, TEXT_ACCENT)
    preview.name = "PlannerNutritionPreview"
    var visible_ids: Array = []
    var refresh_options = func(query: String):
        visible_ids.clear()
        picker.clear()
        var normalized: String = query.strip_edges().to_lower()
        for item in sources:
            if not (item is Dictionary):
                continue
            var name: String = str(item.get("name", ""))
            if not normalized.is_empty() and not name.to_lower().contains(normalized):
                continue
            var id: String = str(item.get("id", ""))
            if id.is_empty():
                continue
            picker.add_item(name)
            visible_ids.append(id)
            if visible_ids.size() >= 30:
                break
        if not visible_ids.is_empty():
            picker.select(0)
    var update_preview = func():
        if picker.selected < 0 or picker.selected >= visible_ids.size():
            preview.text = "Ничего не найдено. Уточни поиск."
            return
        var id: String = str(visible_ids[picker.selected])
        var meal: String = str(MealPlannerScript.MEALS[meal_picker.selected])
        var planned: Dictionary = store.planned_preview(kind, id,
            planner_day, meal, amount.value)
        if planned.is_empty():
            preview.text = "Не удалось рассчитать блюдо. Проверь сохранённый рецепт."
            return
        var nutrition: Dictionary = planned["nutrition"]
        var factor: float = float(planned["grams"]) / 100.0
        preview.text = (str(roundi(float(nutrition["kcal"]) * factor)) + \
            " ккал · Б " + str(snappedf(float(nutrition["p"]) * factor, 0.1)) + \
            " · Ж " + str(snappedf(float(nutrition["f"]) * factor, 0.1)) + \
            " · У " + str(snappedf(float(nutrition["c"]) * factor, 0.1)) + \
            " · " + str(planned["grams"]) + " " + str(planned["unit"]))
    refresh_options.call("")
    update_preview.call()
    search.text_changed.connect(func(query: String):
        refresh_options.call(query)
        update_preview.call())
    picker.item_selected.connect(func(_index: int): update_preview.call())
    meal_picker.item_selected.connect(func(_index: int): update_preview.call())
    amount.value_changed.connect(func(_amount: float): update_preview.call())
    var confirm: Button = sheet["confirm"]
    confirm.name = "PlannerConfirmAdd"
    confirm.pressed.connect(func():
        if picker.selected < 0 or picker.selected >= visible_ids.size():
            _sheet_error(sheet, "Выбери продукт или рецепт из поиска.")
            return
        var id: String = str(visible_ids[picker.selected])
        var meal: String = str(MealPlannerScript.MEALS[meal_picker.selected])
        if store.add_planned_meal(kind, id, planner_day, meal, amount.value):
            sheet["root"].queue_free()
            _hide_keyboard_and_focus()
            _render()
            _notify_saved("Блюдо добавлено в план")
        else:
            _sheet_error(sheet, "Не удалось сохранить блюдо. Проверь порцию.")
    )


func _planner_commit_day() -> void:
    var pending: int = store.planned_day_pending(planner_day)
    if pending <= 0:
        _message("Всё запланированное уже перенесено в дневник.")
        return
    _confirm_action("Перенести план в дневник",
        "Добавить " + str(pending) + " блюд за " + planner_day + \
        "? Ранее перенесённые блюда не будут добавлены повторно.",
        func():
            var count: int = store.apply_planned_day(planner_day)
            if count <= 0:
                _message("Не удалось перенести план в дневник.")
                return
            _render()
            _notify_saved("В дневник добавлено " + str(count) + " блюд")
    , "Добавить " + str(pending))


func _show_week_planner() -> void:
    if not StoreScript.valid_diary_date(planner_day):
        planner_day = date
    var week: Array = store.week_dates(planner_day)
    var first: String = str(week[0])
    var last: String = str(week[6])
    var header = _card("План питания на неделю", "hero")
    _compact_card(header, 12, 8)
    _label(header, "Сначала запланируй блюда, затем перенеси выбранный день в дневник.", 12, HERO_MUTED)
    var navigation = _row(header)
    var previous = _button(navigation, "‹", func(): _planner_shift_week(-1), true)
    previous.name = "PlannerPreviousWeek"
    var week_label = _nowrap(navigation,
        first.substr(8, 2) + "." + first.substr(5, 2) + " — " + \
        last.substr(8, 2) + "." + last.substr(5, 2), 14, WHITE)
    week_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    week_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var following = _button(navigation, "›", func(): _planner_shift_week(1), true)
    following.name = "PlannerNextWeek"
    var shortcuts = _row(header)
    var today = _button(shortcuts, "Текущая неделя", func():
        planner_day = Time.get_date_string_from_system()
        _render(true)
    , true)
    today.name = "PlannerCurrentWeek"
    var back = _button(shortcuts, "← Дневник", func(): _navigate_to_tab("day"), true)
    back.name = "PlannerBackToDay"

    var grid_card = _card("Выбери день")
    _compact_card(grid_card, 9, 7)
    var dates = _row(grid_card)
    dates.name = "PlannerWeekDates"
    dates.add_theme_constant_override("separation", 2)
    var weekdays = ["Пн","Вт","Ср","Чт","Пт","Сб","Вс"]
    for i in range(7):
        var day: String = str(week[i])
        var count: int = store.planned_meals_on(day).size()
        var label: String = str(weekdays[i]) + "\n" + day.substr(8, 2) + (
            " •" if count > 0 else "")
        var selected: bool = day == planner_day
        var choose = _button(dates, label, func(): _planner_choose_day(day), not selected)
        choose.name = "PlannerDay_" + str(i)
        choose.custom_minimum_size = Vector2(0, 52)
        choose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        choose.add_theme_font_size_override("font_size", 11)
        choose.clip_text = true
    var total: float = store.planned_day_kcal(planner_day)
    var day_card = _card("Блюда на " + planner_day.substr(8, 2) + "." + \
        planner_day.substr(5, 2))
    _compact_card(day_card, 11, 8)
    var daily_total = _label(day_card, str(roundi(total)) + " ккал в плане · " + \
        str(roundi(float(store.data["settings"]["kcal"]))) + \
        " ккал дневной ориентир", 14, TEXT_ACCENT)
    daily_total.name = "PlannerDayCalories"
    _label(day_card, "Калории плана не учитываются в дневнике до переноса.", 11, MUTED)
    var add_row = _row(day_card)
    var recipe_button = _button(add_row, "+ Рецепт", func(): _planner_add_sheet("recipe"), true)
    recipe_button.name = "PlannerAddRecipe"
    recipe_button.custom_minimum_size.y = 41
    var food_button = _button(add_row, "+ Продукт", func(): _planner_add_sheet("food"), true)
    food_button.name = "PlannerAddFood"
    food_button.custom_minimum_size.y = 41
    var records: Array = store.planned_meals_on(planner_day)
    for meal in MealPlannerScript.MEALS:
        var meal_items: Array = records.filter(func(item):
            return str(item["meal"]) == str(meal))
        var meal_box = _soft_list_row(day_card)
        var meal_col = VBoxContainer.new()
        meal_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        meal_col.add_theme_constant_override("separation", 5)
        meal_box.add_child(meal_col)
        _label(meal_col, str(meal) + " · " + str(meal_items.size()) + " блюд", 13, INK)
        for item in meal_items:
            var row = _row(meal_col)
            var amount: String = str(snappedf(float(item["grams"]), 0.1)) + " " + \
                str(item["unit"])
            var meal_label = _label(row, str(item["name"]) + " · " + amount + \
                " · " + str(roundi(MealPlannerScript.item_kcal(item))) + " ккал", 12, MUTED)
            meal_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            var pid: String = str(item["id"])
            var remove = _button(row, "×", func():
                _confirm_delete("Убрать блюдо из плана?", func():
                    if store.delete_planned_meal(pid):
                        _render()
                        _notify_saved("Блюдо убрано из плана")
                    else:
                        _message("Не удалось изменить план.")
                )
            , true)
            remove.name = "PlannerRemove_" + pid
    if not records.is_empty():
        var pending: int = store.planned_day_pending(planner_day)
        if pending > 0:
            var transfer = _button(day_card,
                "Перенести в дневник (" + str(pending) + ")", func():
                    _planner_commit_day())
            transfer.name = "PlannerApplyDay"
            transfer.custom_minimum_size.y = 43
        else:
            _label(day_card, "Все эти блюда уже записаны в дневник.", 12, TEXT_ACCENT)
        var open_diary = _button(day_card, "Открыть этот день", func():
            date = planner_day
            _navigate_to_tab("day")
        , true)
        open_diary.name = "PlannerOpenDiary"

    var shopping = _card("Покупки на всю неделю")
    _compact_card(shopping, 11, 7)
    var shopping_items: Array = store.week_planned_shopping(planner_day)
    var purchased: int = 0
    for item in shopping_items:
        if bool(item["bought"]):
            purchased += 1
    var count = _label(shopping, "Отмечено " + str(purchased) + " из " + \
        str(shopping_items.size()) + " продуктов", 13, TEXT_ACCENT)
    count.name = "PlannerShoppingCount"
    _label(shopping, "Одинаковые ингредиенты объединены. Граммы и миллилитры считаются отдельно.", 11, MUTED)
    if shopping_items.is_empty():
        _label(shopping, "Добавь блюда — ингредиенты появятся здесь.", 12, MUTED)
    var max_visible: int = shopping_items.size() if shopping_expanded else mini(shopping_items.size(), 14)
    for index in range(max_visible):
        var item: Dictionary = shopping_items[index]
        var shopping_row = _soft_list_row(shopping)
        var item_key: String = str(item["key"])
        var bought: bool = bool(item["bought"])
        var check = _button(shopping_row, "☑" if bought else "☐", func():
            if store.toggle_shopping_item(planner_day, item_key):
                _render()
            else:
                _message("Не удалось сохранить список покупок.")
        , true)
        check.name = "PlannerBuy_" + str(index)
        check.tooltip_text = "Отметить купленным" if not bought else "Вернуть в список"
        check.custom_minimum_size = Vector2(40, 40)
        check.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        var caption = _label(shopping_row, str(item["name"]) + " · " + \
            str(snappedf(float(item["grams"]), 0.1)) + " " + str(item["unit"]), 13,
            MUTED if bought else INK)
        caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    if shopping_items.size() > 14:
        var expand = _button(shopping,
            "Свернуть список" if shopping_expanded else
            "Показать все (" + str(shopping_items.size()) + ")", func():
                shopping_expanded = not shopping_expanded
                _render()
        , true)
        expand.name = "PlannerShoppingMore"


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
    if home_widget_editor_open:
        _show_home_widget_editor(overview)

    var total: float = store.day_calories(date)
    var target: float = float(store.data["settings"]["kcal"])
    var hero = _card("", "hero")
    _compact_card(hero, 11, 6)
    hero.name = "DailyEnergyCard"
    var hero_content = _row(hero)
    var numbers = VBoxContainer.new()
    numbers.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    numbers.add_theme_constant_override("separation", 2)
    hero_content.add_child(numbers)
    var remaining: float = target - total
    _label(numbers, "Осталось на сегодня" if remaining >= 0.0 else "Превышение нормы",
        12, HERO_MUTED if remaining >= 0.0 else SOFT_GOLD)
    var calorie_value = _nowrap(numbers,
        str(roundi(remaining)) + " ккал" if remaining >= 0.0 else
        "+" + str(roundi(-remaining)) + " ккал", 27, WHITE)
    calorie_value.name = "DailyEnergyValue"
    var consumed_label = _nowrap(numbers, "Съедено " + str(roundi(total)) + " из " +
        str(roundi(target)) + " ккал", 12, HERO_MUTED)
    consumed_label.name = "DailyConsumedValue"
    var ring = RingScript.new()
    ring.name = "DailyCalorieRing"
    ring.custom_minimum_size = Vector2(65, 65)
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
    var p: float = store.day_macro(date, "p")
    var f: float = store.day_macro(date, "f")
    var c: float = store.day_macro(date, "c")
    var macro_energy: float = maxf(1.0, p * 4.0 + f * 9.0 + c * 4.0)
    _daily_macro_tile(macros, "Белки", p, 400.0 * p / macro_energy, PROTEIN_BG, MACRO_PROTEIN, "p")
    _daily_macro_tile(macros, "Жиры", f, 900.0 * f / macro_energy, FAT_BG, MACRO_FAT, "f")
    _daily_macro_tile(macros, "Углеводы", c, 400.0 * c / macro_energy, CARBS_BG, MACRO_CARBS, "c")
    var macro_caption = _nowrap(hero, "Полоски — доля энергии БЖУ", 10, HERO_MUTED)
    macro_caption.name = "DayMacroShareCaption"
    # Show movement beside the journal without altering its calorie target.
    var movement: Dictionary = store.day_activity_summary(date)
    if int(movement["steps"]) > 0 or int(movement["count"]) > 0:
        var hint = _label(hero, "Движение: " + str(movement["steps"]) +
            " шагов · " + str(movement["minutes"]) + " мин · ≈" +
            str(movement["estimated_kcal"]) + " ккал (не вычитаются)", 11, HERO_MUTED)
        hint.name = "DayActivitySummary"
        hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    var day_tools_toggle = _button(hero, "⋯ Действия с днём" +
        (" ▴" if day_tools_expanded else " ▾"), func():
            day_tools_expanded = not day_tools_expanded
            _render()
    , true)
    day_tools_toggle.name = "DayToolsToggle"
    day_tools_toggle.custom_minimum_size.y = 36
    day_tools_toggle.add_theme_font_size_override("font_size", 12)
    if day_tools_expanded:
        var small_screen: bool = get_viewport_rect().size.x < 390.0
        var day_tool_buttons: BoxContainer = (
            VBoxContainer.new() if small_screen else HBoxContainer.new())
        hero.add_child(day_tool_buttons)
        day_tool_buttons.name = "DayToolsActions"
        day_tool_buttons.add_theme_constant_override("separation", 5)
        var copy_button = _button(day_tool_buttons, "↻ Копировать день",
            func(): _copy_day_sheet(), true)
        copy_button.name = "DayCopyOpen"
        copy_button.custom_minimum_size.y = 39
        copy_button.add_theme_font_size_override("font_size", 12)
        var templates_button = _button(day_tool_buttons, "☆ Мои наборы",
            func(): _meal_templates_sheet(), true)
        templates_button.name = "DayTemplatesOpen"
        templates_button.custom_minimum_size.y = 39
        templates_button.add_theme_font_size_override("font_size", 12)
        if store.can_undo_day_copy(date):
            var undo = _button(hero, "↶ Отменить копирование",
                func(): _request_undo_day_copy(), true)
            undo.name = "DayCopyUndo"
            undo.custom_minimum_size.y = 39
            undo.add_theme_font_size_override("font_size", 12)

    _show_water_card()

    var planner_shortcut = _card("", "tint")
    _compact_card(planner_shortcut, 8, 4)
    planner_shortcut.get_parent().name = "DayPlannerShortcut"
    var plan_shortcut = _button(planner_shortcut, "▦ План недели и покупки",
        func(): _open_week_planner(), true)
    plan_shortcut.name = "DayOpenPlanner"
    plan_shortcut.custom_minimum_size.y = 40

    # Compact sections are always present. Only the selected meal unfolds.
    # Expansion state is in-memory, keyed by date: diary records are untouched.
    # No extra standalone title card: every meal already has its own header.
    var existing = store.day_entries(date)
    var meal_colors = [
        Color("#E7B36B"), Color("#8BD4BB"), Color("#B9B0EC"), Color("#EBA7A1")
    ] if DARK_MODE else [
        Color("#946226"), Color("#287553"), Color("#69589E"), Color("#A44D45")
    ]
    var sections = [
        {"meal":"Завтрак", "variant":"overview", "accent":meal_colors[0]},
        {"meal":"Обед", "variant":"tint", "accent":meal_colors[1]},
        {"meal":"Ужин", "variant":"activity", "accent":meal_colors[2]},
        {"meal":"Перекус", "variant":"plain", "accent":meal_colors[3]}
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
                Color("#423046"), Color("#3B354F"),
                Color("#40334F"), Color("#503348")
            ]
            var botanical_edges = [
                Color("#B87B9E"), Color("#8D88B4"),
                Color("#9B82C0"), Color("#D08DA8")
            ]
            var meal_style = meal_card.get_parent().get_theme_stylebox("panel") as StyleBoxFlat
            meal_style.bg_color = botanical_colors[section_index]
            meal_style.border_color = botanical_edges[section_index].lightened(0.43)
            meal_style.set_border_width_all(2 if HIGH_CONTRAST else 1)
        else:
            var meal_style = meal_card.get_parent().get_theme_stylebox("panel") as StyleBoxFlat
            var meal_backgrounds = [
                Color("#45372F"), Color("#233F40"), Color("#32354F"), Color("#463440")
            ] if DARK_MODE else [
                Color("#F8EDD9"), Color("#E1F1E7"), Color("#ECE8F7"), Color("#F8E8E5")
            ]
            meal_style.bg_color = meal_backgrounds[section_index]
            meal_style.border_color = meal_colors[section_index] if HIGH_CONTRAST else meal_style.bg_color.darkened(0.09)
        if section_index == 0:
            diary_food_card = meal_card
        # One-row meal summary: tap its title or + to select a product,
        # tap chevron to open editing, nutrients and saved meal templates.
        var title_row = _row(meal_card)
        title_row.name = "MealCompactRow_" + str(section_index)
        title_row.add_theme_constant_override("separation", 4)
        var accent = ColorRect.new()
        accent.name = "MealAccent_" + str(section_index)
        accent.color = Color(str(["#D59BB9", "#9FA3D3", "#A98BD3", "#E4A2B9"][section_index])) if current_theme == "botanical" else section_info["accent"]
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
                Color("#F2C6DF"), Color("#CED0FF"),
                Color("#DCC9FF"), Color("#F8C9DB")
            ]
            food_art.modulate = icon_colors[section_index]
        else:
            food_art.modulate = meal_colors[section_index]
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
        meal_title.pressed.connect(func(): _open_meal_catalog(meal_name))
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
        _semantic_button(add_button, meal_colors[section_index], Color("#15202C") if DARK_MODE else Color.WHITE)
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
                    (" · " +
                        (str(snappedf(float(entry.get("portion_count", 0.0)), 0.1)) + " × "
                        if float(entry.get("portion_count", 0.0)) > 0.0 else "") +
                        str(entry.get("portion_label", ""))
                        if not str(entry.get("portion_label", "")).is_empty() else ""), 13)
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

    # Both 0.7.29 preferences stay independently saved, but the diary only
    # renders one compact graph at a time to avoid another long scroll.
    var enabled_widgets: Dictionary = store.home_widgets()
    if bool(enabled_widgets.get("week", false)) or bool(enabled_widgets.get("weight", false)):
        var visible_view: String = home_progress_view
        if not bool(enabled_widgets.get(visible_view, false)):
            visible_view = "week" if bool(enabled_widgets.get("week", false)) else "weight"
        var progress_card = _card("", "tint")
        progress_card.get_parent().name = "HomeProgressWidget"
        _compact_card(progress_card, 11, 6)
        var progress_head = _row(progress_card)
        progress_head.add_theme_constant_override("separation", 7)
        var progress_title = _label(progress_head, "Мой прогресс", 16, INK)
        progress_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        if bool(enabled_widgets.get("week", false)) and bool(enabled_widgets.get("weight", false)):
            var chooser = _row(progress_card)
            chooser.name = "HomeProgressViewSelector"
            chooser.add_theme_constant_override("separation", 6)
            for pair in [["Калории", "week"], ["Вес", "weight"]]:
                var view: String = str(pair[1])
                var choice = _button(chooser, str(pair[0]), func():
                    _set_home_progress_view(view)
                , true)
                choice.name = "HomeProgressView_" + view
                choice.custom_minimum_size.y = 38
                choice.add_theme_font_size_override("font_size", 13)
                if view == visible_view:
                    var selected = StyleBoxFlat.new()
                    selected.bg_color = NAV_ACTIVE
                    selected.set_corner_radius_all(11)
                    for mode in ["normal", "hover", "pressed"]:
                        choice.add_theme_stylebox_override(mode, selected)
                    choice.add_theme_color_override("font_color", WHITE)
        var inner = VBoxContainer.new()
        inner.add_theme_constant_override("separation", 6)
        progress_card.add_child(inner)
        if visible_view == "week":
            inner.name = "HomeWeekWidget"
            var week_data: Dictionary = StatsMathScript.summarize(store, date, "week")
            var week_header = _row(inner)
            var week_title = _label(week_header, "Калории за неделю", 13, INK)
            week_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            var stats_link = _button(week_header, "Итоги", func():
                stats_anchor = date
                stats_period = "week"
                stats_detail_tab = "nutrition"
                _navigate_to_tab("stats")
            , true)
            stats_link.name = "HomeWeekOpenStats"
            stats_link.custom_minimum_size.y = 37
            stats_link.size_flags_horizontal = Control.SIZE_SHRINK_END
            var week_average = "Нет записей" if int(week_data["recorded"]) == 0 else (
                str(roundi(float(week_data["avg_kcal"]))) + " ккал / день с питанием"
            )
            var week_summary = _label(inner,
                week_average + " · " + str(week_data["recorded"]) + " из 7 дней", 12, MUTED)
            week_summary.name = "HomeWeekSummary"
            var small_chart = StatsChartScript.new()
            small_chart.name = "HomeWeekChart"
            small_chart.custom_minimum_size.y = 100
            inner.add_child(small_chart)
            small_chart.setup(week_data["columns"], "calories",
                float(store.data["settings"]["kcal"]), TEXT_ACCENT, ACCENT, MUTED, CHART_GRID)
        else:
            inner.name = "HomeWeightWidget"
            var current: Dictionary = ProfileProgressScript.summarize(
                store.data["settings"], store.data["weights"])
            var weight_head = _row(inner)
            var current_label = _label(weight_head, "Вес и цель", 13, INK)
            current_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            var weight_link = _button(weight_head, "История веса",
                func(): _navigate_to_tab("weight"), true)
            weight_link.name = "HomeWeightOpenHistory"
            weight_link.custom_minimum_size.y = 37
            weight_link.size_flags_horizontal = Control.SIZE_SHRINK_END
            weight_link.add_theme_font_size_override("font_size", 12)
            var weight_numbers = _label(inner,
                str(snappedf(float(current["latest"]), 0.1)) + " кг сейчас · " +
                str(snappedf(float(current["goal"]), 0.1)) + " кг цель", 14, TEXT_ACCENT)
            weight_numbers.name = "HomeWeightSummary"
            var weight_bar = ProgressBar.new()
            weight_bar.name = "HomeWeightGoalProgress"
            weight_bar.min_value = 0.0
            weight_bar.max_value = 100.0
            weight_bar.value = float(current["progress"])
            _style_progress(weight_bar)
            weight_bar.custom_minimum_size.y = 8
            inner.add_child(weight_bar)
            _label(inner, "Прогресс: " +
                str(roundi(float(current["progress"]))) + "%" +
                (" · От стартового веса" if not bool(current["has_records"]) else ""), 12, MUTED)

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
        "User-Agent: MyBalance/0.7.31 (+https://github.com/Domenklay/My_balance)",
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
    return {"barcode": code, "name": "", "kcal": -1.0,
        "p": -1.0, "f": -1.0, "c": -1.0,
        "missing_fields": ["kcal", "p", "f", "c"],
        "source": "Пользователь", "nutrition_unit": "г"}

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

# Display a small product photo when OFF supplied a safe CDN URL. No
# image fetch is made for bundled/offline products without an image.
func _barcode_product_overview(parent: Node, product: Dictionary, sheet_root: Node) -> void:
    var row = _row(parent)
    row.name = "BarcodeProductOverview"
    row.add_theme_constant_override("separation", 10)
    var photo = TextureRect.new()
    photo.name = "BarcodeProductImage"
    photo.texture = PRODUCT_PLACEHOLDER
    photo.modulate = TEXT_ACCENT
    photo.custom_minimum_size = Vector2(72, 72)
    photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    photo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(photo)
    var texts = VBoxContainer.new()
    texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    texts.add_theme_constant_override("separation", 3)
    row.add_child(texts)
    var brand = str(product.get("brand", "")).strip_edges()
    if not brand.is_empty():
        var b = _label(texts, brand, 13, INK)
        b.name = "BarcodeProductBrand"
        b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var quantity = str(product.get("quantity", "")).strip_edges()
    if not quantity.is_empty():
        var q = _label(texts, "Упаковка: " + quantity, 12, MUTED)
        q.name = "BarcodeProductPackage"
        q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var source = str(product.get("source", ""))
    _label(texts, "Источник: Open Food Facts" if source == "Open Food Facts"
        else "Сохранённый продукт", 11, MUTED)
    var image_url: String = BarcodeScript.safe_image_url(
        str(product.get("image_url", "")))
    if image_url.is_empty():
        return
    var http = HTTPRequest.new()
    http.name = "BarcodeImageRequest"
    http.body_size_limit = 800000
    http.max_redirects = 0
    http.timeout = 8.0
    sheet_root.add_child(http)
    http.request_completed.connect(func(result: int, status: int,
            _headers: PackedStringArray, bytes: PackedByteArray):
        if not is_instance_valid(photo) or result != HTTPRequest.RESULT_SUCCESS or \
                status != 200 or bytes.is_empty() or bytes.size() > 800000:
            return
        var picture = Image.new()
        var path: String = image_url.to_lower()
        var error: int = picture.load_png_from_buffer(bytes) if path.ends_with(".png") else \
            picture.load_jpg_from_buffer(bytes)
        if error != OK or picture.get_width() < 1 or picture.get_height() < 1 or \
                picture.get_width() > 2048 or picture.get_height() > 2048:
            return
        photo.texture = ImageTexture.create_from_image(picture)
        photo.modulate = WHITE
    )
    http.request(image_url, PackedStringArray(["User-Agent: MyBalance/0.7.31"]))


# Blank or malformed nutritional fields must never silently become zero.
func _barcode_nutrition_value(raw: String, maximum: float) -> float:
    var formatted = raw.strip_edges().replace(",", ".")
    if formatted.is_empty() or not formatted.is_valid_float():
        return -1.0
    var value: float = formatted.to_float()
    if not is_finite(value) or value < 0.0 or value > maximum:
        return -1.0
    return value


func _barcode_prefill(product: Dictionary, key: String) -> String:
    var value = float(product.get(key, -1.0))
    if value < 0.0:
        return ""
    return str(snappedf(value, 0.1))


func _show_barcode_portion(food: Dictionary) -> void:
    _quick_food_sheet(food, true)

func _confirm_barcode_product(product: Dictionary, manual: bool = false) -> void:
    var description = "Внеси значения с этикетки. Неизвестные поля оставлены пустыми." if manual else \
        "Проверь карточку Open Food Facts по упаковке перед добавлением."
    var sheet = _mobile_sheet(
        "Добавить свой товар" if manual else "Найден товар по штрихкоду",
        description, "Сохранить и добавить", 730.0)
    var fields: VBoxContainer = sheet["fields"]
    _barcode_product_overview(fields, product, sheet["root"])
    _label(fields, "Название товара", 13, MUTED)
    var name = _text_input(fields, "Название продукта", str(product.get("name", "")))
    name.name = "BarcodeProductName"
    name.max_length = 160
    var review_text = BarcodeScript.nutrition_review_label(product)
    if manual:
        review_text = "Внеси калории, белки, жиры и углеводы с упаковки."
    var review_label = _label(fields, review_text, 12,
        ACCENT if manual or BarcodeScript.needs_nutrition_review(product) else MUTED)
    review_label.name = "BarcodeNutritionReviewStatus"
    review_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _label(fields, "Основа значений с этикетки", 13, MUTED)
    var basis = _choice(fields, ["На 100 г", "На 100 мл"])
    basis.name = "BarcodeNutritionBasis"
    basis.select(1 if PortionMath.base_unit(product) == "мл" else 0)
    if str(product.get("unit_certainty", "unknown")) in ["serving", "unknown"] and not manual:
        _label(fields, "Единица определена неуверенно: выбери г или мл по этикетке.", 12, ACCENT)
    # Label goes ABOVE the input. The old horizontal row squeezed its
    # caption into a vertical word and inflated the field on a 420px screen.
    var kcal_box = VBoxContainer.new()
    kcal_box.name = "BarcodeCaloriesColumn"
    kcal_box.mouse_filter = Control.MOUSE_FILTER_PASS
    kcal_box.add_theme_constant_override("separation", 4)
    fields.add_child(kcal_box)
    _label(kcal_box, "Калории на 100 г / мл", 13, MUTED)
    var kcal = _text_input(kcal_box, "ккал на 100", _barcode_prefill(product, "kcal"))
    kcal.name = "BarcodeNutrition_kcal"
    kcal.custom_minimum_size.y = 48
    kcal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    kcal.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
    kcal.max_length = 7
    var nutrient_row = _row(fields)
    nutrient_row.add_theme_constant_override("separation", 7)
    var nutrient_inputs: Dictionary = {"kcal": kcal}
    for entry in [["p", "Белки"], ["f", "Жиры"], ["c", "Углеводы"]]:
        var item = VBoxContainer.new()
        item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        item.add_theme_constant_override("separation", 3)
        nutrient_row.add_child(item)
        _label(item, str(entry[1]) + " /100", 12, MUTED)
        var input = _text_input(item, "0,0", _barcode_prefill(product, str(entry[0])))
        input.name = "BarcodeNutrition_" + str(entry[0])
        input.custom_minimum_size.y = 48
        input.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
        input.max_length = 6
        nutrient_inputs[str(entry[0])] = input
    var serving_title = _label(fields,
        "Количество порции, " + ("мл" if basis.selected == 1 else "г"), 13, MUTED)
    basis.item_selected.connect(func(index: int):
        serving_title.text = "Количество порции, " + ("мл" if index == 1 else "г")
    )
    var grams = _number(fields, 100, 1, 5000, 1)
    grams.name = "BarcodePortionAmount"
    var package_size: float = BarcodeScript.package_amount(product)
    if package_size > 0.0:
        var package_button = _button(fields, "Вся упаковка · " +
            str(snappedf(package_size, 0.1)) + " " +
            str(product.get("nutrition_unit", "г")), func():
                if ("мл" if basis.selected == 1 else "г") != str(product.get("nutrition_unit", "г")):
                    _sheet_error(sheet, "Основа этикетки не совпадает с единицей упаковки.")
                    return
                grams.value = package_size
        , true)
        package_button.name = "BarcodePackagePortion"
        package_button.custom_minimum_size.y = 38
    var calculated = _label(fields, "", 13, TEXT_ACCENT)
    calculated.name = "BarcodePortionPreview"
    var refresh_preview = func():
        var value: float = _barcode_nutrition_value(kcal.text, 1000.0)
        if value < 0.0:
            calculated.text = "Заполни КБЖУ, чтобы рассчитать порцию."
            return
        calculated.text = str(roundi(value * grams.value / 100.0)) + \
            " ккал за выбранное количество"
    for key in ["kcal", "p", "f", "c"]:
        var target: LineEdit = nutrient_inputs[key]
        target.text_changed.connect(func(_v: String): refresh_preview.call())
    grams.value_changed.connect(func(_v: float): refresh_preview.call())
    refresh_preview.call()
    _label(fields, "Приём пищи", 13, MUTED)
    var meal = _choice(fields, ["Завтрак", "Обед", "Перекус", "Ужин"])
    meal.disabled = _meal_entry_locked
    var meal_index = ["Завтрак", "Обед", "Перекус", "Ужин"].find(selected_meal)
    if meal_index >= 0:
        meal.select(meal_index)
    meal.item_selected.connect(func(index: int): selected_meal = meal.get_item_text(index))
    var needs_confirmation: bool = not manual and \
        BarcodeScript.needs_nutrition_review(product)
    var confirmed = CheckBox.new()
    confirmed.name = "BarcodeLabelConfirmed"
    confirmed.text = "КБЖУ и единицы проверены по этикетке"
    confirmed.add_theme_font_size_override("font_size", 13)
    confirmed.add_theme_color_override("font_color", INK)
    confirmed.visible = needs_confirmation
    fields.add_child(confirmed)
    var quality_notice = _label(fields, "", 12, ACCENT)
    quality_notice.name = "BarcodeLiveQuality"
    quality_notice.visible = false
    # Validate the current edited values, not just the original OFF response.
    # The checkbox becomes visible when editing introduces a new warning.
    var refresh_quality = func():
        var probe: Dictionary = {
            "nutrition_unit": "мл" if basis.selected == 1 else "г"
        }
        for field in ["kcal", "p", "f", "c"]:
            var editable: LineEdit = nutrient_inputs[field]
            probe[field] = _barcode_nutrition_value(
                editable.text, 1000.0 if field == "kcal" else 100.0)
        var complete: bool = true
        for field in ["kcal", "p", "f", "c"]:
            if float(probe[field]) < 0.0:
                complete = false
        var advisory: String = BarcodeScript.quality_message(probe) if complete else ""
        quality_notice.text = "⚠ " + advisory
        quality_notice.visible = not advisory.is_empty()
        confirmed.visible = needs_confirmation or not advisory.is_empty()
    for key in ["kcal", "p", "f", "c"]:
        var field_input: LineEdit = nutrient_inputs[key]
        field_input.text_changed.connect(func(_v: String):
            refresh_quality.call()
        )
    basis.item_selected.connect(func(_index: int):
        refresh_quality.call()
    )
    refresh_quality.call()
    _label(fields, "Данные открытой базы справочные. Сохранённый товар доступен офлайн.", 12, MUTED)
    var commit_record = func(add_to_diary: bool):
        var record: Dictionary = product.duplicate(true)
        record["name"] = name.text.strip_edges()
        record["nutrition_unit"] = "мл" if basis.selected == 1 else "г"
        if record["name"].is_empty():
            _sheet_error(sheet, "Введи название товара.")
            return
        for key in ["kcal", "p", "f", "c"]:
            var input: LineEdit = nutrient_inputs[key]
            var maximum: float = 1000.0 if key == "kcal" else 100.0
            var number: float = _barcode_nutrition_value(input.text, maximum)
            if number < 0.0:
                _sheet_error(sheet, "Заполни «" + {
                    "kcal":"Калории", "p":"Белки", "f":"Жиры", "c":"Углеводы"
                }[key] + "» по этикетке, допустимый диапазон 0–" +
                    str(roundi(maximum)) + ".")
                return
            record[key] = number
        if float(record["kcal"]) == 0.0 and \
                (float(record["p"]) > 1.0 or float(record["f"]) > 1.0 or float(record["c"]) > 1.0):
            _sheet_error(sheet, "Нулевые калории противоречат БЖУ. Проверь этикетку.")
            return
        # A corrected product can still have suspicious energy-to-macro
        # ratios. A warning requires an explicit acknowledgement, never a
        # silent correction or a fabricated zero for missing nutrients.
        if (needs_confirmation or not BarcodeScript.quality_flags(record).is_empty()) and \
                not confirmed.button_pressed:
            _sheet_error(sheet, "Проверь предупреждения и подтверди КБЖУ по этикетке.")
            return
        # Missing remote fields were explicitly filled and reviewed locally.
        record.erase("missing_fields")
        record["nutrition_complete"] = true
        record["image_url"] = BarcodeScript.safe_image_url(
            str(record.get("image_url", "")))
        var saved_id = store.save_barcode_food(record)
        if saved_id.is_empty():
            _sheet_error(sheet, "Не удалось сохранить товар. Проверь штрихкод или память.")
            return
        if add_to_diary:
            var saved_food = store.food_by_id(saved_id)
            if not store.add_food_entry(saved_food, grams.value,
                    meal.get_item_text(meal.selected), _selected_food_date()):
                _sheet_error(sheet, "Товар сохранён, но порция не записана. Повтори добавление.")
                return
            sheet["root"].queue_free()
            _barcode_add_success()
        else:
            sheet["root"].queue_free()
            _render()
            _notify_saved("Продукт сохранён в каталоге")
    var save_only = _button(fields, "Сохранить без записи в дневник",
        func(): commit_record.call(false), true)
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


# Summary uses the historical nutrient snapshot; editing a catalog food or
# deleting an original recipe must never affect copied or saved diary entries.
func _request_undo_day_copy() -> void:
    if not store.can_undo_day_copy(date):
        _message("Этот день уже изменён или копирования для отмены нет.")
        return
    _confirm_action("Отменить последнее копирование?",
        "Вернуть питание до копирования? Спорт, заметки и вес сохранятся.",
        func(): _perform_undo_day_copy(), "Отменить копирование")


func _perform_undo_day_copy() -> void:
    if store.undo_day_copy():
        _render()
        _notify_saved("Питание восстановлено")
    else:
        _message("Не удалось отменить: записи изменились.")


func _render_copy_calendar(holder: VBoxContainer, state: Dictionary,
        field: LineEdit, destination: String) -> void:
    for child in holder.get_children():
        holder.remove_child(child)
        child.queue_free()
    var month: String = str(state["month"])
    var navigation = _row(holder)
    var prev = _button(navigation, "‹", func():
        state["month"] = _month_offset(str(state["month"]), -1)
        _render_copy_calendar(holder, state, field, destination)
    , true)
    prev.custom_minimum_size = Vector2(38, 38)
    var caption = _label(navigation, month, 15, TEXT_ACCENT)
    caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var next = _button(navigation, "›", func():
        state["month"] = _month_offset(str(state["month"]), 1)
        _render_copy_calendar(holder, state, field, destination)
    , true)
    next.custom_minimum_size = Vector2(38, 38)
    var grid = GridContainer.new()
    grid.name = "DayCopyCalendarGrid"
    grid.columns = 7
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 2)
    grid.add_theme_constant_override("v_separation", 2)
    holder.add_child(grid)
    for weekday in ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]:
        var heading = _label(grid, weekday, 11, MUTED)
        heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var first_info = Time.get_datetime_dict_from_datetime_string(month + "-01T12:00:00", true)
    var padding: int = (int(first_info.get("weekday", 1)) + 6) % 7
    for _i in range(padding):
        _label(grid, "")
    var end_stamp: int = int(Time.get_unix_time_from_datetime_string(
        _month_offset(month, 1) + "-01T12:00:00")) - 86400
    var last_day: int = int(Time.get_datetime_dict_from_unix_time(end_stamp).get("day", 28))
    for d in range(1, last_day + 1):
        var candidate: String = month + "-" + str(d).pad_zeros(2)
        var logged: bool = not store.day_entries(candidate).is_empty()
        var pick = _button(grid, str(d) + ("•" if logged else ""), func():
            field.text = candidate
            field.text_changed.emit(candidate)
        , true)
        pick.name = "DayCopyCalendar_" + candidate
        pick.custom_minimum_size = Vector2(33, 37)
        pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        pick.add_theme_font_size_override("font_size", 11)
        pick.disabled = not logged or candidate == destination
    _label(holder, "• — день с питанием; пустые даты недоступны.", 11, MUTED)


func _day_food_summary(chosen_date: String) -> Dictionary:
    var result: Dictionary = {"count": 0, "kcal": 0.0, "p": 0.0, "f": 0.0, "c": 0.0}
    for entry in store.day_entries(chosen_date):
        result["count"] += 1
        var snapshot: Dictionary = store.entry_food(entry)
        var ratio: float = float(entry.get("grams", 0.0)) / 100.0
        for nutrient in ["kcal", "p", "f", "c"]:
            result[nutrient] = float(result[nutrient]) + float(snapshot.get(nutrient, 0.0)) * ratio
    return result


func _copy_day_sheet() -> void:
    var destination: String = date
    var source_default: String = store.change_date(destination, -1)
    var sheet = _mobile_sheet("Скопировать день",
        "Переносится только питание с сохранёнными порциями и КБЖУ. Спорт, вес и заметки не изменятся.",
        "Продолжить", 490.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, "Откуда скопировать (ГГГГ-ММ-ДД)", 13, MUTED)
    var source = _text_input(fields, "Например, 2026-11-20", source_default)
    source.name = "DayCopySource"
    source.max_length = 10
    var dates = _row(fields)
    for preset in [["Вчера", -1], ["Позавчера", -2]]:
        var offset: int = int(preset[1])
        _button(dates, str(preset[0]), func():
            source.text = store.change_date(destination, offset)
            source.text_changed.emit(source.text)
        , true)
    var calendar = VBoxContainer.new()
    calendar.name = "DayCopyCalendar"
    calendar.visible = false
    calendar.add_theme_constant_override("separation", 4)
    var cursor: Dictionary = {"month": source_default.substr(0, 7)}
    var calendar_toggle = _button(fields, "▦ Выбрать дату в календаре", func():
        calendar.visible = not calendar.visible
        if calendar.visible:
            _render_copy_calendar(calendar, cursor, source, destination)
    , true)
    calendar_toggle.name = "DayCopyCalendarToggle"
    calendar_toggle.custom_minimum_size.y = 38
    fields.add_child(calendar)
    _label(fields, "Что делать с питанием выбранного дня", 13, MUTED)
    var mode = _choice(fields, [
        "Добавить без совпадений", "Заменить питание", "Добавить всё, включая повторы"])
    mode.name = "DayCopyMode"
    var preview = _label(fields, "", 13, TEXT_ACCENT)
    preview.name = "DayCopyPreview"
    var refresh = func():
        var from_date: String = source.text.strip_edges()
        if not StoreScript.valid_diary_date(from_date) or from_date == destination:
            preview.text = "Укажи другую существующую календарную дату."
            return
        var plan: Dictionary = store.day_copy_plan(
            from_date, destination, mode.selected == 1, mode.selected == 0)
        var candidates: Array = plan["entries"]
        if int(plan["source_count"]) == 0:
            preview.text = "На выбранную дату нет записей питания."
            return
        var amounts: Dictionary = {"kcal": 0.0, "p": 0.0, "f": 0.0, "c": 0.0}
        for record in candidates:
            var original_food: Dictionary = store.entry_food(record)
            var ratio: float = float(record.get("grams", 0)) / 100.0
            for key in ["kcal", "p", "f", "c"]:
                amounts[key] = float(amounts[key]) + float(original_food.get(key, 0)) * ratio
        var final_kcal: float = float(amounts["kcal"]) + \
            (0.0 if mode.selected == 1 else store.day_calories(destination))
        preview.text = (str(candidates.size()) + " из " + str(plan["source_count"]) +
            " записей · " + str(roundi(float(amounts["kcal"]))) + " ккал" +
            "\nБ " + str(snappedf(float(amounts["p"]), 0.1)) +
            " · Ж " + str(snappedf(float(amounts["f"]), 0.1)) +
            " · У " + str(snappedf(float(amounts["c"]), 0.1)) +
            "\nВсего после копирования: " + str(roundi(final_kcal)) + " ккал." +
            (" Совпадений: " + str(plan["duplicates"]) + "."
                if int(plan["duplicates"]) > 0 else "") +
            (" Всё уже добавлено." if candidates.is_empty() else ""))
    source.text_changed.connect(func(_txt: String): refresh.call())
    mode.item_selected.connect(func(_index: int): refresh.call())
    refresh.call()
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        var from_date: String = source.text.strip_edges()
        if not StoreScript.valid_diary_date(from_date) or from_date == destination:
            _sheet_error(sheet, "Выбери корректную дату, отличную от текущей.")
            return
        var replace_existing: bool = mode.selected == 1
        var skip_matches: bool = mode.selected == 0
        var plan: Dictionary = store.day_copy_plan(
            from_date, destination, replace_existing, skip_matches)
        var count_to_copy: int = plan["entries"].size()
        if count_to_copy == 0:
            _sheet_error(sheet, "Нет новых записей для копирования.")
            return
        var old_count: int = store.day_entries(destination).size()
        var explanation: String = ("Добавить " + str(count_to_copy) +
            " записей из " + from_date + " в " + destination + "?"
            if not replace_existing else
            "Заменить " + str(old_count) + " записей питания " +
            "на " + str(count_to_copy) + " из " + from_date + "?")
        _confirm_day_copy(explanation, replace_existing, func():
            var copied: int = store.copy_day(
                from_date, destination, replace_existing, skip_matches)
            if copied > 0:
                sheet["root"].queue_free()
                _render()
                _notify_saved("Скопировано продуктов: " + str(copied))
            else:
                _sheet_error(sheet, "Не удалось скопировать день. Старые данные сохранены.")
        )
    )


func _confirm_day_copy(explanation: String, replacing: bool, action: Callable) -> void:
    var dialog = ConfirmationDialog.new()
    dialog.name = "DayCopyConfirmation"
    dialog.title = "Заменить питание?" if replacing else "Добавить питание?"
    dialog.dialog_text = explanation
    dialog.ok_button_text = "Заменить" if replacing else "Добавить"
    add_child(dialog)
    dialog.confirmed.connect(func():
        action.call()
        dialog.queue_free()
    )
    dialog.canceled.connect(func(): dialog.queue_free())
    dialog.popup_centered(Vector2i(360, 220))


func _meal_templates_sheet() -> void:
    var templates: Array = store.data.get("meal_templates", [])
    var template_sheet_height: float = minf(650.0,
        240.0 + float(mini(templates.size(), 5)) * 87.0)
    var sheet = _mobile_sheet("Мои наборы питания",
        "Повторяй сохранённые завтраки, обеды и ужины целиком. Изменения рецептов не затрагивают шаблоны.",
        "Закрыть", template_sheet_height)
    var fields: VBoxContainer = sheet["fields"]
    sheet["cancel"].visible = false
    if templates.is_empty():
        _label(fields, "Наборов пока нет. Открой приём пищи, добавь продукты и нажми «☆ Сохранить набор».",
            13, MUTED)
    else:
        for template in templates:
            if not (template is Dictionary) or template.get("items", []).is_empty():
                continue
            var items: Array = template["items"]
            var template_id: String = str(template.get("id", ""))
            var meal_name: String = str(items[0].get("meal", ""))
            var kcal_total: float = 0.0
            for item in items:
                kcal_total += float(item.get("grams", 0.0)) / 100.0 * \
                    float(item.get("nutrition", {}).get("kcal", 0.0))
            var panel = _soft_list_row(fields)
            var info = VBoxContainer.new()
            info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            panel.add_child(info)
            var title = _label(info, str(template["name"]), 13, INK)
            title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            _label(info, meal_name + " · " + str(items.size()) + " продуктов · " +
                str(roundi(kcal_total)) + " ккал", 11, MUTED)
            var add_button = _button(panel, "+", func():
                _prompt_apply_template(template_id, str(template["name"]),
                    items.size(), date, sheet)
            )
            add_button.name = "TemplateQuickAdd_" + template_id
            add_button.custom_minimum_size = Vector2(37, 39)
            var edit = _button(panel, "✎", func():
                _open_template_editor_from_list(template_id, sheet)
            , true)
            edit.name = "TemplateEdit_" + template_id
            edit.custom_minimum_size = Vector2(37, 39)
            var remove = _button(panel, "×", func():
                _confirm_delete("Удалить набор «" + str(template["name"]) + "»?",
                    func(): _delete_selected_template(template_id, sheet))
            , true)
            remove.custom_minimum_size = Vector2(37, 39)
    var close: Button = sheet["confirm"]
    close.pressed.connect(func(): sheet["root"].queue_free())


func _open_template_editor_from_list(template_id: String, sheet: Dictionary) -> void:
    # Free the old sheet's node name before opening a second one.
    # queue_free alone keeps the old ProductSheet registered this frame, so
    # Godot auto-renames the new sheet and downstream navigation cannot find it.
    var old_root: Control = sheet["root"]
    old_root.get_parent().remove_child(old_root)
    old_root.queue_free()
    _edit_meal_template_sheet(template_id)


func _prompt_apply_template(template_id: String, title: String, count: int,
        target_date: String, sheet: Dictionary) -> void:
    _confirm_action("Добавить набор «" + title + "»?",
        "Добавить " + str(count) + " продуктов в " + target_date +
        "? При повторном добавлении могут возникнуть дубликаты.",
        func(): _apply_selected_template(template_id, target_date, sheet),
        "Добавить набор")


func _render_template_editor_items(holder: VBoxContainer, draft: Dictionary) -> void:
    for node in holder.get_children():
        holder.remove_child(node)
        node.queue_free()
    var items: Array = draft["items"]
    for i in range(items.size()):
        var index: int = i
        var item: Dictionary = items[i]
        var panel = _soft_list_row(holder)
        var content = VBoxContainer.new()
        content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        content.add_theme_constant_override("separation", 4)
        panel.add_child(content)
        var head = _row(content)
        var title = _label(head, str(item.get("nutrition", {}).get("name", "Продукт")),
            13, INK)
        title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        var remove = _button(head, "×", func():
            items.remove_at(index)
            _render_template_editor_items(holder, draft)
        , true)
        remove.name = "TemplateEditRemove_" + str(index)
        remove.custom_minimum_size = Vector2(34, 36)
        # A horizontal label + expanding SpinBox wrapped text vertically on
        # narrow screens and made this row several hundred pixels tall.
        var amount_column = VBoxContainer.new()
        amount_column.add_theme_constant_override("separation", 3)
        content.add_child(amount_column)
        _label(amount_column, "Количество, " + str(item.get("unit", "г")), 12, MUTED)
        var amount = _number(amount_column, float(item.get("grams", 100.0)),
            1.0, 5000.0, 0.1)
        amount.name = "TemplateEditAmount_" + str(index)
        amount.custom_minimum_size = Vector2(120, 42)
        amount.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        amount.value_changed.connect(func(value: float):
            if not is_equal_approx(float(item.get("grams", 0.0)), value):
                item["grams"] = value
                item.erase("portion_count")
                item.erase("portion_id")
                item.erase("portion_label")
        )


func _template_add_recent_food(holder: VBoxContainer, draft: Dictionary,
        food: Dictionary, amount: float) -> void:
    var items: Array = draft["items"]
    if items.size() >= 30:
        _message("В одном наборе не более 30 продуктов.")
        return
    var unit: String = PortionMath.base_unit(food)
    items.append({
        "food": str(food.get("id", "")),
        "meal": "Завтрак", "grams": amount, "unit": unit,
        "nutrition": {
            "name": str(food.get("name", "Продукт")), "nutrition_unit": unit,
            "kcal": float(food.get("kcal", 0)),
            "p": float(food.get("p", 0)), "f": float(food.get("f", 0)),
            "c": float(food.get("c", 0))
        }
    })
    _render_template_editor_items(holder, draft)


func _edit_meal_template_sheet(template_id: String) -> void:
    var original: Dictionary = {}
    for template in store.data.get("meal_templates", []):
        if str(template.get("id", "")) == template_id:
            original = template
            break
    if original.is_empty():
        _message("Сохранённый набор не найден.")
        return
    var draft: Dictionary = {"items": original["items"].duplicate(true)}
    var sheet = _mobile_sheet("Изменить набор питания",
        "Меняй название, порции и состав. Исторические КБЖУ останутся прежними.",
        "Сохранить", 720.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, "Название набора", 13, MUTED)
    var title = _text_input(fields, "Название", str(original["name"]))
    title.name = "TemplateEditName"
    title.max_length = 70
    _label(fields, "Приём пищи", 13, MUTED)
    var meal = _choice(fields, StoreScript.MEAL_NAMES)
    meal.name = "TemplateEditMeal"
    var existing_meal: String = str(original["items"][0].get("meal", "Завтрак"))
    meal.select(maxi(0, StoreScript.MEAL_NAMES.find(existing_meal)))
    _label(fields, "Состав", 13, MUTED)
    var item_list = VBoxContainer.new()
    item_list.name = "TemplateEditItems"
    item_list.add_theme_constant_override("separation", 6)
    fields.add_child(item_list)
    _render_template_editor_items(item_list, draft)
    var foods: Array = store.recent_foods(12)
    if foods.is_empty():
        foods = store.all_foods().slice(0, 16)
    if not foods.is_empty():
        _label(fields, "Добавить продукт в набор", 13, MUTED)
        var picker = _choice(fields, foods.map(func(food):
            return str(food.get("name", "Продукт"))))
        picker.name = "TemplateAddProduct"
        var add_row = _row(fields)
        var grams = _number(add_row, 100.0, 1.0, 5000.0, 0.1)
        grams.name = "TemplateNewAmount"
        var add = _button(add_row, "+ В набор", func():
            if picker.selected >= 0 and picker.selected < foods.size():
                _template_add_recent_food(item_list, draft,
                    foods[picker.selected], grams.value)
        , true)
        add.name = "TemplateAddItem"
        add.custom_minimum_size.y = 40
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        var final_items: Array = draft["items"].duplicate(true)
        for item in final_items:
            item["meal"] = str(meal.get_item_text(meal.selected))
        if store.update_meal_template(template_id, title.text, final_items):
            sheet["root"].queue_free()
            _hide_keyboard_and_focus()
            _render()
            _notify_saved("Набор изменён")
        else:
            _sheet_error(sheet, "Проверь название и оставь хотя бы один продукт.")
    )


func _apply_selected_template(template_id: String, target_date: String,
        sheet: Dictionary) -> void:
    var number: int = store.apply_meal_template(template_id, target_date)
    if number > 0:
        sheet["root"].queue_free()
        _render()
        _notify_saved("Набор добавлен: " + str(number) + " продуктов")
    else:
        _sheet_error(sheet, "Набор не добавлен. Проверь память.")


func _delete_selected_template(template_id: String, sheet: Dictionary) -> void:
    if store.delete_meal_template(template_id):
        sheet["root"].queue_free()
        _render()
        _notify_saved("Набор удалён")
    else:
        _sheet_error(sheet, "Не удалось удалить набор.")


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

func _quick_food_sheet(food: Dictionary, from_barcode: bool = false,
        preferred_measure: String = "") -> void:
    var unit: String = PortionMath.base_unit(food)
    var description: String = (
        "Проверь КБЖУ на этикетке (на 100 " + unit + ")."
        if from_barcode else "Быстрые порции · свои меры · сохранение последнего выбора."
    )
    var sheet = _mobile_sheet("Продукт найден" if from_barcode else str(food.get("name", "Продукт")),
        description, "Добавить" if from_barcode else "Добавить в дневник", 675.0)
    var fields: VBoxContainer = sheet["fields"]
    fields.add_theme_constant_override("separation", 7)
    if from_barcode or not str(food.get("image_url", "")).is_empty():
        _barcode_product_overview(fields, food, sheet["root"])
    _label(fields, str(food.get("name", "Продукт")), 16, INK)
    _label(fields, str(roundi(float(food.get("kcal", 0)))) + " ккал / 100 " + unit +
        " · Б " + str(food.get("p", 0)) + " Ж " + str(food.get("f", 0)) +
        " У " + str(food.get("c", 0)), 12, MUTED)
    var quality: Array = BarcodeScript.quality_flags(food)
    if not quality.is_empty():
        var note = _label(fields, "⚠ " + str(quality[0]) +
            " Сверь с упаковкой перед добавлением.", 12, ACCENT)
        note.name = "QuickFoodQualityWarning"
    var food_id: String = str(food.get("id", ""))
    if not food_id.is_empty() and not store.food_by_id(food_id).is_empty():
        var favorite = _button(fields,
            "★ В избранном" if store.is_favorite(food_id) else
            "☆ Добавить в избранное", Callable(), true)
        favorite.name = "QuickFavoriteToggle"
        favorite.custom_minimum_size.y = 35
        favorite.add_theme_font_size_override("font_size", 12)
        favorite.pressed.connect(func():
            if store.toggle_favorite(food_id):
                favorite.text = ("★ В избранном" if store.is_favorite(food_id) else
                    "☆ Добавить в избранное")
            else:
                _sheet_error(sheet, "Не удалось изменить избранное.")
        )

    var options: Array = store.portion_options(food)
    var last: Dictionary = store.last_food_portion(food)
    var recalled: Dictionary = PortionMath.recalled_choice(options, last)
    var selected_index: int = int(recalled["index"])
    var initial_quantity: float = float(recalled["quantity"])
    if not preferred_measure.is_empty():
        for i in range(1, options.size()):
            if str(options[i].get("label", "")) == preferred_measure:
                selected_index = i
                initial_quantity = 1.0
                break
    if not last.is_empty() and preferred_measure.is_empty():
        var last_amount: String = str(snappedf(float(last["grams"]), 0.1)) + " " + unit
        var previous_text: String = "В прошлый раз: " + last_amount
        if selected_index > 0:
            previous_text = ("В прошлый раз: " + str(snappedf(initial_quantity, 0.1)) +
                " × " + str(options[selected_index]["label"]) + " · " + last_amount)
        var last_label = _label(fields, previous_text, 12, TEXT_ACCENT)
        last_label.name = "QuickLastPortion"

    _label(fields, "Мера", 13, MUTED)
    var labels: Array = []
    for option in options:
        var caption: String = str(option["label"])
        if not str(option["id"]).is_empty():
            caption += " · " + str(snappedf(float(option["amount"]), 0.1)) + " " + unit
        labels.append(caption)
    var measure: OptionButton = _choice(fields, labels)
    measure.name = "QuickPortionMeasure"
    measure.select(selected_index)

    _label(fields, "Количество", 13, MUTED)
    var quantity: SpinBox = _number(fields, initial_quantity, 0.1, 5000.0, 0.1)
    quantity.name = "QuickPortionQuantity"
    var presets = _row(fields)
    presets.name = "QuickPortionPresets"
    presets.add_theme_constant_override("separation", 4)
    var preset_values: Array = [50.0, 100.0, 150.0, 200.0]
    var preset_buttons: Array = []
    for i in range(4):
        var slot: int = i
        var preset: Button = _button(presets, "", func():
            quantity.value = float(preset_values[slot])
        , true)
        preset.name = "QuickPortionPreset_" + str(i)
        preset.custom_minimum_size = Vector2(0, 40)
        preset.add_theme_font_size_override("font_size", 12)
        preset_buttons.append(preset)
    var show_presets = func():
        var is_weight: bool = measure.selected == 0
        var values: Array = [50.0, 100.0, 150.0, 200.0] if is_weight else [0.5, 1.0, 2.0, 3.0]
        var captions: Array = [] if is_weight else ["½", "1", "2", "3"]
        for i in range(4):
            preset_values[i] = values[i]
            preset_buttons[i].text = (
                str(roundi(float(values[i]))) + " " + unit if is_weight else str(captions[i])
            )
    show_presets.call()
    var package_size: float = BarcodeScript.package_amount(food)
    if package_size > 0.0:
        var package_button = _button(fields,
            "Вся упаковка · " + str(snappedf(package_size, 0.1)) + " " + unit,
            func():
                measure.select(0)
                quantity.value = package_size
                show_presets.call()
        , true)
        package_button.name = "QuickPackagePortion"

    var result_label = _label(fields, "", 15, TEXT_ACCENT)
    result_label.name = "QuickPortionPreview"
    var amount_value = func() -> float:
        if measure.selected < 0 or measure.selected >= options.size():
            return 0.0
        return PortionMath.quantity_to_base(options[measure.selected], quantity.value)
    var refresh = func(_v: float):
        var total: float = float(amount_value.call())
        var calculated: Dictionary = PortionMath.nutrients(food, total)
        if calculated.is_empty():
            result_label.text = "Слишком большая порция. Максимум — 5000 " + unit + "."
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
        show_presets.call()
        refresh.call(quantity.value)
    )
    quantity.value_changed.connect(refresh)
    refresh.call(quantity.value)

    _label(fields, "Приём пищи", 13, MUTED)
    var meal = _choice(fields, ["Завтрак", "Обед", "Перекус", "Ужин"])
    meal.name = "QuickPortionMeal"
    meal.disabled = _meal_entry_locked
    var initial_meal = ["Завтрак", "Обед", "Перекус", "Ужин"].find(selected_meal)
    if initial_meal >= 0:
        meal.select(initial_meal)
    meal.item_selected.connect(func(index: int): selected_meal = meal.get_item_text(index))

    # The custom measure editor is collapsed; saving a measure opens the
    # selected new measure directly with count 1 instead of resetting to 100 g.
    var custom_toggle: Button = _button(fields, "▾ Своя мера: шт., ложка, стакан", Callable(), true)
    custom_toggle.name = "QuickCustomPortionToggle"
    custom_toggle.custom_minimum_size.y = 40
    var custom_fields = VBoxContainer.new()
    custom_fields.name = "QuickCustomPortionFields"
    custom_fields.add_theme_constant_override("separation", 6)
    custom_fields.visible = false
    fields.add_child(custom_fields)
    custom_toggle.pressed.connect(func():
        custom_fields.visible = not custom_fields.visible
        custom_toggle.text = ("▴ Свернуть свои меры" if custom_fields.visible else
            "▾ Своя мера: шт., ложка, стакан")
    )
    _label(custom_fields, "Выбери название или напиши своё", 12, MUTED)
    var templates = _choice(custom_fields, [
        "Своя мера", "1 шт.", "1 ч. л.", "1 ст. л.",
        "1 стакан", "1 чашка", "1 ломтик", "1 упаковка"
    ])
    templates.name = "QuickCustomMeasureTemplates"
    var custom: LineEdit = _text_input(custom_fields, "Название меры (например, 1 упаковка)")
    custom.name = "QuickCustomMeasureLabel"
    custom.max_length = 36
    templates.item_selected.connect(func(index: int):
        if index > 0:
            custom.text = templates.get_item_text(index)
    )
    _label(custom_fields, "Сколько " + unit + " в одной мере?", 12, MUTED)
    var custom_amount: SpinBox = _number(custom_fields, 100.0, 0.1, 5000.0, 0.1)
    custom_amount.name = "QuickCustomMeasureAmount"
    _label(custom_fields, "Укажи вес или объём с упаковки либо по измерению. " +
        "Массу ложки, штуки и стакана приложение не угадывает.", 11, MUTED)
    var save_measure = _button(custom_fields, "Сохранить меру", func():
        var title: String = custom.text.strip_edges()
        if store.save_food_portion(str(food.get("id", "")), title, custom_amount.value):
            # Detach immediately so the replacement keeps the stable
            # ProductSheet node name (queued_free alone retains it one frame).
            var previous_sheet: Control = sheet["root"]
            remove_child(previous_sheet)
            previous_sheet.queue_free()
            _quick_food_sheet(food, from_barcode, title)
            _notify_saved("Мера сохранена")
        else:
            _sheet_error(sheet, "Не удалось сохранить меру. Проверь название, вес и дубликаты.")
    , true)
    save_measure.name = "QuickCustomMeasureSave"
    if options.size() > 1:
        _button(custom_fields, "Удалить выбранную меру", func():
            if measure.selected <= 0:
                _sheet_error(sheet, "Сначала выбери сохранённую меру.")
                return
            var option: Dictionary = options[measure.selected]
            if store.delete_food_portion(str(option["id"])):
                var previous_sheet: Control = sheet["root"]
                remove_child(previous_sheet)
                previous_sheet.queue_free()
                _quick_food_sheet(food, from_barcode)
                _notify_saved("Мера удалена, старые записи сохранены")
            else:
                _sheet_error(sheet, "Не удалось удалить меру.")
        , true)

    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        var total: float = float(amount_value.call())
        if total <= 0.0 or measure.selected < 0 or measure.selected >= options.size():
            _sheet_error(sheet, "Допускается не более 5000 " + unit + " за запись.")
            return
        var portion_label: String = "" if measure.selected == 0 else str(options[measure.selected]["label"])
        var measure_id: String = "" if measure.selected == 0 else str(options[measure.selected]["id"])
        var count: float = quantity.value if measure.selected > 0 else 0.0
        if store.add_food_entry(food, total, meal.get_item_text(meal.selected),
                _selected_food_date(), portion_label, count, measure_id):
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
    var search_heading = _label(parent, "Поиск: название, бренд или штрихкод", 16, TEXT_ACCENT)
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
        if not BarcodeScript.normalize_code(search.text).is_empty():
            _lookup_barcode_from_search(search)
        else:
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
    var category = _choice(parent, ["Все", "Базовые", "Брендовые", "Мои продукты", "Избранное", "Недавние", "Частые"])
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
    _button(controls, "+ Добавить выбранный вес", func():
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
        var code: String = BarcodeScript.normalize_code(search.text)
        online_button.text = "Найти штрихкод" if not code.is_empty() else "Найти в интернете"
        if is_instance_valid(online_search_label):
            if not code.is_empty():
                var local: Dictionary = store.food_by_barcode(code)
                online_search_label.text = ("✓ Сохранён офлайн: " +
                    str(local.get("name", "Продукт")) + ". Нажми «Найти штрихкод»."
                    if not local.is_empty() else
                    "Код проверен. Нажми «Найти штрихкод» для поиска онлайн.")
            else:
                online_search_label.text = "Поиск по названию и бренду; для EAN/UPC введи полный код."
        _refresh_food_picker(picker, search, favorite_only, filtered, grams, preview, star, category, results_box, meal, added_count)
    )
    search.text_submitted.connect(func(_value: String):
        if not BarcodeScript.normalize_code(search.text).is_empty():
            _lookup_barcode_from_search(search)
        else:
            _lookup_online_products(search.text)
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
    # Six concise chips in two rows: show own saved products without
    # burying them inside the legacy advanced filter.
    var quick_tabs = GridContainer.new()
    quick_tabs.name = "FoodQuickFilters"
    quick_tabs.columns = 3
    quick_tabs.add_theme_constant_override("h_separation", 4)
    quick_tabs.add_theme_constant_override("v_separation", 4)
    parent.add_child(quick_tabs)
    for option in [
        ["Недавние", 5], ["Мои", 3], ["★ Избранное", 4],
        ["Частые", 6], ["Брендовые", 2], ["Все", 0]
    ]:
        var target_index: int = int(option[1])
        var filter_button = _button(quick_tabs, str(option[0]), func():
            category.select(target_index)
            _refresh_food_picker(picker, search, favorite_only, filtered, grams, preview, star,
                category, results_box, meal, added_count)
        , true)
        filter_button.name = "FoodFilter_" + str(target_index)
        filter_button.add_theme_font_size_override("font_size", 11)
        filter_button.custom_minimum_size.y = 36
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
    var common: Array = store.frequent_foods(3, 2)
    if not common.is_empty():
        _label(quick_lists, "Часто добавляю", 14, TEXT_ACCENT)
        var common_buttons = _row(quick_lists)
        common_buttons.name = "FrequentFoodShortcuts"
        common_buttons.add_theme_constant_override("separation", 4)
        for food_record in common:
            var common_food: Dictionary = food_record
            var common_name: String = str(common_food.get("name", "Продукт"))
            var common_button = _button(common_buttons, common_name, func():
                _quick_food_sheet(common_food)
            , true)
            common_button.name = "FrequentFood_" + str(common_food.get("id", ""))
            common_button.tooltip_text = common_name
            common_button.clip_text = true
            common_button.custom_minimum_size.y = 38
            common_button.add_theme_font_size_override("font_size", 11)
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
        quick_lists.visible = search.text.strip_edges().is_empty() and category.selected == 0
    )
    # One compact sorter for local results; online Open Food Facts search keeps
    # its own result ordering and label-review workflow.
    var sort_row = _row(parent)
    sort_row.name = "FoodSorting"
    sort_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    sort_row.custom_minimum_size.y = 42
    sort_row.add_theme_constant_override("separation", 6)
    var sort_caption = _label(sort_row, "Сортировка", 12, MUTED)
    sort_caption.custom_minimum_size.x = 88
    sort_caption.autowrap_mode = TextServer.AUTOWRAP_OFF
    sort_caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    var sort_order = _choice(sort_row, ["Подходящие", "Частые", "Название А–Я", "Ккал ↑", "Ккал ↓"])
    sort_order.name = "FoodSortOrder"
    sort_order.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    sort_order.custom_minimum_size = Vector2(150, 42)
    sort_row.visible = false
    sort_order.item_selected.connect(func(index: int):
        results_box.set_meta("sort_mode", index)
        _refresh_food_picker(picker, search, favorite_only, filtered, grams, preview, star,
            category, results_box, meal, added_count)
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
    parent.move_child(sort_row, 8)
    parent.move_child(results_box, 9)
    parent.move_child(advanced_button, 10)
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
    var query = search.text.strip_edges().to_lower()
    if results_box != null:
        var quick_area = results_box.get_parent().get_node_or_null("FoodRecentFavorites") as VBoxContainer
        if quick_area != null:
            quick_area.visible = query.is_empty() and (category == null or category.selected == 0)
        results_box.visible = not query.is_empty() or (category != null and category.selected != 0)
        var sorting = results_box.get_parent().get_node_or_null("FoodSorting") as HBoxContainer
        if sorting != null:
            sorting.visible = results_box.visible
    var recent_ids: Dictionary = {}
    if category != null and category.selected == 5:
        for recent_food in store.recent_foods(20):
            recent_ids[str(recent_food.get("id", ""))] = true
    var frequent_ids: Dictionary = {}
    if category != null and category.selected == 6:
        for frequent_food in store.frequent_foods(100, 2):
            frequent_ids[str(frequent_food.get("id", ""))] = true
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
                6:
                    if not frequent_ids.has(item_id):
                        continue
        filtered.append(item)
    # Sorting is applied to the entire filtered set, before pagination.
    # The selected product is restored by id, never by its old index.
    var usage_counts: Dictionary = store.food_usage_counts()
    var favorites_index: Dictionary = {}
    for favorite_id in store.data.get("favorites", []):
        favorites_index[str(favorite_id)] = true
    var sort_mode: int = int(results_box.get_meta("sort_mode", 0)) if results_box != null else 0
    filtered.sort_custom(func(a, b):
        return FoodSearchScript.sort_before(a, b, query, sort_mode, usage_counts, favorites_index)
    )
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
        # Reset pagination only when the search/filter changes, not when
        # a product is selected or saved to the diary.
        var search_key: String = query + "|" + str(category.selected if category != null else -1) + "|" + str(favorite_only.button_pressed) + "|" + str(sort_mode)
        if str(results_box.get_meta("food_search_key", "")) != search_key:
            results_box.set_meta("food_search_key", search_key)
            results_box.set_meta("visible_count", 12)
        _rebuild_food_results(results_box, filtered, grams, meal, added_count)

func _rebuild_food_results(results_box: VBoxContainer, filtered: Array,
        grams: SpinBox, meal: OptionButton, added_count: Label) -> void:
    for child in results_box.get_children():
        results_box.remove_child(child)
        child.queue_free()
    var shown: int = mini(maxi(12, int(results_box.get_meta("visible_count", 12))), filtered.size())
    _label(results_box, "Найдено: " + str(filtered.size()) + " · показано: " + str(shown), 12, MUTED)
    if filtered.is_empty():
        _label(results_box, "Ничего не найдено. Попробуй другое название или бренд.", 12, MUTED)
    for index in range(shown):
        var item: Dictionary = filtered[index]
        var row = _soft_list_row(results_box)
        row.name = "FoodSearchRow_" + str(index)
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
        var warnings: Array = BarcodeScript.quality_flags(item)
        if not warnings.is_empty():
            var alert = _label(info, "⚠ " + str(warnings[0]), 11, ACCENT)
            alert.name = "FoodQualityWarning_" + str(index)
        var last: Dictionary = store.last_food_portion(item)
        if not last.is_empty() and \
                str(last.get("unit", "г")) == PortionMath.base_unit(item):
            var repeat = _button(info,
                "↻ Последняя порция · " +
                str(snappedf(float(last.get("grams", 0)), 0.1)) +
                " " + str(last.get("unit", "г")), func():
                    _repeat_search_food(item, last, added_count)
            , true)
            repeat.name = "FoodRepeatLast_" + str(index)
            repeat.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
            repeat.custom_minimum_size.y = 34
            repeat.add_theme_font_size_override("font_size", 11)
        _button(row, "＋ Порция", func(): _quick_food_sheet(item))
    if shown < filtered.size():
        var next_count: int = mini(12, filtered.size() - shown)
        var more = _button(results_box, "Показать ещё " + str(next_count), func():
            results_box.set_meta("visible_count", shown + 12)
            _rebuild_food_results(results_box, filtered, grams, meal, added_count)
        , true)
        more.name = "FoodLoadMore"
        more.custom_minimum_size.y = 42

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
        entry.erase("portion_count")
        entry.erase("portion_id")
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

# Sport metric cards use the existing semantic nutrition palettes, with
# independent captions and values so no narrow label can stretch a row.
func _sport_metric(parent: Node, caption: String, value: String, unit: String,
        background: Color, foreground: Color, metric_id: String) -> void:
    var panel = PanelContainer.new()
    panel.name = "SportMetric_" + metric_id
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style = StyleBoxFlat.new()
    style.bg_color = background
    style.set_corner_radius_all(12)
    style.content_margin_left = 5
    style.content_margin_right = 5
    style.content_margin_top = 9
    style.content_margin_bottom = 9
    panel.add_theme_stylebox_override("panel", style)
    parent.add_child(panel)
    var stack = VBoxContainer.new()
    stack.add_theme_constant_override("separation", 2)
    panel.add_child(stack)
    for item in [[caption, 12], [value, 18], [unit, 11]]:
        var label = _nowrap(stack, str(item[0]), int(item[1]), foreground)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _show_activity() -> void:
    var overview = _card("Движение за день")
    overview.name = "SportOverviewCard"
    _compact_card(overview, 12, 8)
    _date_nav(overview)
    if calendar_expanded:
        _calendar(overview)
    var summary: Dictionary = store.day_activity_summary(date)
    var metrics = _row(overview)
    metrics.name = "ActivityOverview"
    metrics.add_theme_constant_override("separation", 6)
    _sport_metric(metrics, "Шаги", str(summary["steps"]), "за день", PROTEIN_BG, MACRO_PROTEIN, "steps")
    _sport_metric(metrics, "Занятия", str(summary["minutes"]), "мин", CARBS_BG, MACRO_CARBS, "minutes")
    _sport_metric(metrics, "Энергия", "≈" + str(summary["estimated_kcal"]), "ккал", FAT_BG, MACRO_FAT, "energy")
    var step_title = _nowrap(overview, "Шаги за день", 13, INK)
    step_title.name = "SportStepsCaption"
    var step_row = _row(overview)
    step_row.name = "SportStepsRow"
    var steps_input = _number(step_row, float(store.day_steps(date)), 0, 100000, 1)
    steps_input.name = "ActivitySteps"
    steps_input.custom_minimum_size = Vector2(90, 44)
    steps_input.get_line_edit().virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
    for delta in [-500, 500]:
        var amount: int = delta
        var adjust = _button(step_row, "−500" if amount < 0 else "+500", func():
            steps_input.value = clampf(steps_input.value + amount, 0, 100000)
        , true)
        adjust.name = "SportStepsMinus" if amount < 0 else "SportStepsPlus"
        adjust.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
        adjust.custom_minimum_size = Vector2(62, 44)
    var save_steps = _button(overview, "Сохранить шаги", func():
        if store.set_day_steps(date, roundi(steps_input.value)):
            _render()
            _notify_saved("Шаги сохранены")
        else:
            _message("Не удалось сохранить шаги.")
    )
    save_steps.name = "ActivitySaveSteps"
    save_steps.custom_minimum_size.y = 44
    _label(overview, "Шаги вводятся вручную. Ккал — только по тренировкам; норма питания не меняется.", 11, MUTED)

    var card = _card("Добавить тренировку")
    _compact_card(card, 10, 7)
    _label(card, "Вид активности", 13, MUTED)
    var kinds = ["Ходьба", "Бег", "Велосипед", "Силовая", "Йога", "Плавание", "Другое"]
    var types = ["walk", "run", "cycling", "strength", "yoga", "swim", "other"]
    var kind = _choice(card, kinds)
    kind.name = "ActivityKind"
    var duration_row = _row(card)
    var minutes_box = VBoxContainer.new()
    minutes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    duration_row.add_child(minutes_box)
    _label(minutes_box, "Минуты", 12, MUTED)
    var minutes = _number(minutes_box, 30, 1, 1440)
    minutes.name = "ActivityMinutes"
    var distance_box = VBoxContainer.new()
    distance_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    duration_row.add_child(distance_box)
    _nowrap(distance_box, "Км (необязательно)", 12, MUTED)
    var distance = _number(distance_box, 0, 0, 100, 0.1)
    distance.name = "ActivityDistance"
    var detail = _text_input(card, "Комментарий (необязательно)")
    detail.name = "ActivityDetail"
    var save_activity = _button(card, "Сохранить активность", func():
        if store.add_activity(date, types[kind.selected], minutes.value, distance.value, detail.text):
            _render()
            _notify_saved("Тренировка сохранена")
        else:
            _message("Не удалось сохранить тренировку. Проверь данные и память устройства.")
    )
    save_activity.name = "ActivitySaveWorkout"
    save_activity.custom_minimum_size.y = 44

    var saved = _card("Тренировки за день")
    _compact_card(saved, 10, 6)
    var items: Array = store.day_activities(date)
    if items.is_empty():
        _label(saved, "Записей пока нет.", 13, MUTED)
    for a in items:
        var r = _soft_list_row(saved)
        var kind_title = ActivityMath.type_name(str(a.get("type", "other")))
        var record_text = kind_title + " · " + str(roundi(float(a.get("minutes", 0)))) + " мин"
        var estimate = ActivityMath.estimate_kcal(a, store.weight_prefill(date))
        record_text += " · ≈" + str(estimate) + " ккал"
        if float(a.get("distance", 0.0)) > 0.0:
            record_text += "\n" + str(a["distance"]) + " км"
        if str(a.get("detail", "")) != "":
            record_text += "\n" + str(a["detail"])
        var l = _label(r, record_text, 13)
        l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _button(r, "✎", func(): _edit_activity(a), true)
        _button(r, "×", func(): _confirm_delete("Удалить активность?", func():
            if store.delete_saved_record("activities", a):
                _render()
                _notify_saved("Активность удалена")
            else:
                _message("Не удалось удалить активность.")
        ), true)

    var weekly: Dictionary = store.week_activity_summary(date)
    var week_card = _card("Итоги недели")
    _compact_card(week_card, 10, 6)
    _label(week_card, str(weekly["count"]) + " тренировок · " +
        str(weekly["minutes"]) + " мин · " + str(weekly["steps"]) + " шагов", 14, INK)
    _label(week_card, "Оценочный расход на тренировках: ≈" +
        str(weekly["estimated_kcal"]) + " ккал", 12, MUTED)
    _label(week_card, "Расход рассчитан по интенсивности (MET) и последнему весу на дату тренировки. Возможна значительная погрешность.", 12, MUTED)


func _edit_activity(activity: Dictionary) -> void:
    var dialog = ConfirmationDialog.new()
    dialog.title = "Изменить тренировку"
    add_child(dialog)
    var fields = VBoxContainer.new()
    dialog.add_child(fields)
    var kinds = ["Ходьба", "Бег", "Велосипед", "Силовая", "Йога", "Плавание", "Другое"]
    var types = ["walk", "run", "cycling", "strength", "yoga", "swim", "other"]
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
        if store.update_activity(activity, {
            "type": types[kind.selected],
            "minutes": minutes.value, "distance": distance.value, "detail": detail.text
        }):
            dialog.queue_free()
            _render()
            _notify_saved("Тренировка изменена")
        else:
            dialog.queue_free()
            _message("Не удалось сохранить изменения тренировки.")
    )
    dialog.canceled.connect(func(): dialog.queue_free())
    dialog.popup_centered(Vector2i(390, 440))


func _set_progress_section(section: String) -> void:
    if section not in ["weight", "stats", "body"]:
        return
    progress_section = section
    tab = "progress"
    _render(true)


func _show_progress() -> void:
    var card = _card("Мой прогресс")
    _compact_card(card, 10, 7)
    _label(card, "Вес, замеры тела, питание и активность в одном разделе.", 12, MUTED)
    var choices = _row(card)
    choices.name = "ProgressSectionChoices"
    for item in [["weight", "Вес"], ["body", "Замеры"], ["stats", "Итоги"]]:
        var section: String = str(item[0])
        var action = _button(choices, str(item[1]),
            func(): _set_progress_section(section), true)
        action.name = "ProgressSection_" + section
        action.custom_minimum_size.y = 41
        action.add_theme_font_size_override("font_size", 13)
        if section == progress_section:
            var selected = StyleBoxFlat.new()
            selected.bg_color = NAV_ACTIVE
            selected.set_corner_radius_all(12)
            for state in ["normal", "hover", "pressed"]:
                action.add_theme_stylebox_override(state, selected)
            action.add_theme_color_override("font_color", WHITE)
    if progress_section == "stats":
        _show_stats()
    elif progress_section == "body":
        _show_body_measurements()
    else:
        _show_weight()


func _set_graph_period(kind: String, period: String) -> void:
    if not ProgressGraph.valid_period(period):
        return
    if kind == "weight":
        weight_chart_period = period
    elif kind == "body":
        body_chart_period = period
        _refresh_body_diagram_preserving_draft()
        return
    else:
        return
    _render()


func _graph_period_buttons(parent: Node, kind: String) -> void:
    var controls = _row(parent)
    controls.name = "GraphPeriodButtons_" + kind
    controls.add_theme_constant_override("separation", 5)
    var selected: String = weight_chart_period if kind == "weight" else body_chart_period
    for period in ["month", "quarter", "all"]:
        var captured: String = period
        var btn = _button(controls, ProgressGraph.period_label(period),
            func(): _set_graph_period(kind, captured), true)
        btn.name = ("WeightPeriod_" if kind == "weight" else "BodyPeriod_") + period
        btn.custom_minimum_size.y = 39
        btn.add_theme_font_size_override("font_size", 12)
        if captured == selected:
            var selected_style = StyleBoxFlat.new()
            selected_style.bg_color = NAV_ACTIVE
            selected_style.set_corner_radius_all(12)
            for state in ["normal", "hover", "pressed"]:
                btn.add_theme_stylebox_override(state, selected_style)
            btn.add_theme_color_override("font_color", WHITE)
            btn.add_theme_color_override("font_hover_color", WHITE)
            btn.add_theme_color_override("font_pressed_color", WHITE)


func _graph_period_info(parent: Node, points: Array, unit: String) -> void:
    var stats: Dictionary = ProgressGraph.summarize(points)
    if stats.is_empty():
        _label(parent, "За выбранный период измерений пока нет.", 13, MUTED)
        return
    var line = _row(parent)
    line.name = "GraphMetricOverview"
    var recent = _nowrap(line, str(snappedf(float(stats["latest"]), 0.1)) +
        " " + unit, 21, TEXT_ACCENT)
    recent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var change: float = float(stats["change"])
    var change_text = _nowrap(line,
        ProgressGraph.format_delta(change, unit), 17,
        TEXT_ACCENT if change <= 0.0 else ACCENT)
    change_text.name = "GraphPeriodDelta"
    # Fix narrow-screen flex layout: never render "-6.0 см" vertically.
    change_text.custom_minimum_size.x = 96
    change_text.size_flags_horizontal = Control.SIZE_SHRINK_END
    change_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _label(parent, str(stats["first_date"]) + " — " +
        str(stats["latest_date"]) + " · " +
        str(stats["count"]) + " измерений", 12, MUTED)
    _label(parent, "Разница между первым и последним замером выбранного периода.", 11, MUTED)


func _refresh_body_diagram_preserving_draft() -> void:
    # Changing a graph metric or time range must never discard unsubmitted
    # measurements in the editing form.
    var draft: Dictionary = {}
    for definition in BodyMeasurements.FIELDS:
        var field = find_child("BodyField_" + str(definition[0]), true, false) as LineEdit
        if field != null:
            draft[str(definition[0])] = field.text
    _render()
    for key in draft:
        var field = find_child("BodyField_" + str(key), true, false) as LineEdit
        if field != null:
            field.text = str(draft[key])


func _body_map_select(metric: String) -> void:
    if not BodyMeasurements.is_metric(metric) or metric == selected_body_metric:
        return
    selected_body_metric = metric
    _refresh_body_diagram_preserving_draft()


func _body_metric_picker_changed(index: int) -> void:
    if index < 0 or index >= BodyMeasurements.FIELDS.size():
        return
    _body_map_select(str(BodyMeasurements.FIELDS[index][0]))


func _show_body_measurements() -> void:
    var edit_card = _card("Замеры тела")
    _compact_card(edit_card, 10, 7)
    _date_nav(edit_card)
    _label(edit_card, "Указывай только то, что измерила. Пустые поля не заполняются автоматически.", 12, MUTED)
    var current: Dictionary = store.body_measurements_on(date)
    var fields: Dictionary = {}
    var grid = GridContainer.new()
    grid.name = "BodyMeasurementsGrid"
    grid.columns = 2
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 7)
    edit_card.add_child(grid)
    for definition in BodyMeasurements.FIELDS:
        var key: String = str(definition[0])
        var caption: String = str(definition[1])
        var holder = VBoxContainer.new()
        holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        holder.add_theme_constant_override("separation", 3)
        grid.add_child(holder)
        _label(holder, caption + ", см", 12, INK)
        var entry = _text_input(holder, "Не указано")
        entry.name = "BodyField_" + key
        entry.max_length = 8
        entry.custom_minimum_size = Vector2(85, 44)
        if current.has(key):
            entry.text = str(snappedf(float(current[key]), 0.1))
        else:
            var earlier: Dictionary = store.body_metric_summary(key, date)
            if not earlier.is_empty():
                entry.placeholder_text = "Было " + str(snappedf(float(earlier["latest"]), 0.1))
        fields[key] = entry
    var save_button = _button(edit_card, "Сохранить замеры", func():
        var values: Dictionary = {}
        for definition in BodyMeasurements.FIELDS:
            var key: String = str(definition[0])
            var raw: String = str(fields[key].text).strip_edges().replace(",", ".")
            if raw.is_empty():
                continue
            if not raw.is_valid_float() or not BodyMeasurements.valid_value(float(raw)):
                _message("Проверь «" + str(definition[1]) + "». Введи число от 10 до 300 см.")
                return
            values[key] = snappedf(float(raw), 0.1)
        if values.is_empty():
            _message("Укажи хотя бы один параметр тела.")
            return
        if store.save_body_measurements(date, values):
            _render()
            _notify_saved("Замеры сохранены")
        else:
            _message("Не удалось сохранить замеры.")
    )
    save_button.name = "BodyMeasurementsSave"

    var graph_card = _card("Карта тела и график")
    _compact_card(graph_card, 10, 7)
    _label(graph_card,
        "Нажми на область тела, чтобы выбрать параметр и посмотреть его изменения.",
        12, MUTED)
    var silhouette = BodyMapScript.new()
    silhouette.name = "BodyMeasurementMap"
    silhouette.custom_minimum_size = Vector2(0, 338)
    graph_card.add_child(silhouette)
    var latest: Dictionary = {}
    for definition in BodyMeasurements.FIELDS:
        var key: String = str(definition[0])
        var result: Dictionary = store.body_metric_summary(key, date)
        if not result.is_empty():
            latest[key] = float(result["latest"])
    silhouette.configure(selected_body_metric, latest, INK,
        SECONDARY, BORDER, NAV_ACTIVE, DARK_MODE, HIGH_CONTRAST)
    silhouette.metric_selected.connect(_body_map_select)
    var picker = _choice(graph_card, [])
    picker.name = "BodyMeasurementMetricPicker"
    var selected_index = 0
    for i in range(BodyMeasurements.FIELDS.size()):
        var definition: Array = BodyMeasurements.FIELDS[i]
        picker.add_item(str(definition[1]))
        if str(definition[0]) == selected_body_metric:
            selected_index = i
    picker.select(selected_index)
    picker.item_selected.connect(_body_metric_picker_changed)
    _graph_period_buttons(graph_card, "body")
    var points: Array = ProgressGraph.filter_records(
        store.body_metric_history(selected_body_metric, date), date, body_chart_period)
    _graph_period_info(graph_card, points, "см")
    var plot = GraphScript.new()
    plot.name = "BodyMeasurementsGraph"
    plot.custom_minimum_size = Vector2(0, 205)
    plot.set_palette(TEXT_ACCENT, CHART_GRID, MUTED, ACCENT, CHART_AREA, SECONDARY)
    plot.set_unit("см")
    plot.set_overview_points(points, -1.0)
    graph_card.add_child(plot)
    # Show the recent dates for the *selected* body parameter, while the
    # complete mixed-parameter journal remains intact below the chart.
    var selected_history = VBoxContainer.new()
    selected_history.name = "BodySelectedMetricHistory"
    selected_history.add_theme_constant_override("separation", 5)
    graph_card.add_child(selected_history)
    var recorded: Array = store.body_metric_history(selected_body_metric, date)
    _label(selected_history, "История: " +
        BodyMeasurements.display_name(selected_body_metric) +
        " (" + str(recorded.size()) + ")", 14, INK)
    if recorded.is_empty():
        _label(selected_history, "Пока нет записей для этого параметра.", 12, MUTED)
    else:
        for offset in range(mini(4, recorded.size())):
            var item: Dictionary = recorded[recorded.size() - 1 - offset]
            var row = _soft_list_row(selected_history)
            _label(row, str(item["date"]) + "  ·  " +
                str(snappedf(float(item["value"]), 0.1)) + " см", 12, MUTED)
        if recorded.size() > 4:
            _label(selected_history, "Остальные записи доступны в общей истории ниже.",
                11, MUTED)

    var summary_card = _card("Изменения по параметрам")
    _compact_card(summary_card, 10, 6)
    var any_data = false
    for definition in BodyMeasurements.FIELDS:
        var key: String = str(definition[0])
        var details: Dictionary = store.body_metric_summary(key, date)
        if details.is_empty():
            continue
        any_data = true
        var line = _soft_list_row(summary_card)
        var delta: float = float(details["change"])
        var delta_text = ("+" if delta > 0.0 else "") + str(snappedf(delta, 0.1)) + " см"
        var caption = _label(line, str(definition[1]) + "  " +
            str(snappedf(float(details["latest"]), 0.1)) +
            " см  ·  " + delta_text, 13, INK)
        caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    if not any_data:
        _label(summary_card, "Запиши первый замер, чтобы увидеть изменения.", 13, MUTED)
    else:
        _label(summary_card, "Изменение указано относительно первого замера каждого параметра.", 11, MUTED)

    var history_card = _card("История замеров")
    _compact_card(history_card, 10, 6)
    var history: Array = store.data.get("body_measurements", []).filter(
        func(item): return str(item.get("date", "")) <= date)
    history.sort_custom(func(a, b): return str(a.get("date", "")) > str(b.get("date", "")))
    var max_visible = history.size() if body_history_expanded else mini(history.size(), 8)
    for i in range(max_visible):
        var item: Dictionary = history[i]
        var day: String = str(item["date"])
        var vals: Dictionary = item["values"]
        var summary = []
        for def in BodyMeasurements.FIELDS:
            if vals.has(def[0]):
                summary.append(str(def[1]) + " " + str(snappedf(float(vals[def[0]]), 0.1)))
        var line = _soft_list_row(history_card)
        var label = _label(line, day + "\n" + " · ".join(summary) + " см", 12)
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        var edit = _button(line, "✎", func():
            date = day
            month_shown = date.substr(0, 7)
            _render(true)
        , true)
        edit.tooltip_text = "Изменить замеры за " + day
        _button(line, "×", func(): _confirm_delete("Удалить замеры за " + day + "?", func():
            if store.delete_body_measurements(day):
                _render()
                _notify_saved("Замеры удалены")
            else:
                _message("Не удалось удалить замеры.")
        ), true)
    if history.size() > 8:
        _button(history_card, "Скрыть старые записи" if body_history_expanded else
            "Показать всю историю (" + str(history.size()) + ")",
            func():
                body_history_expanded = not body_history_expanded
                _render()
        , true)


func _show_weight() -> void:
    var card = _card("История веса")
    _date_nav(card)
    var settings: Dictionary = store.data["settings"]
    _label(card, "Старт: " + str(settings["start"]) + " кг     Цель: " + str(settings["goal"]) + " кг", 15, MUTED)
    var value = _number(card, store.weight_prefill(date), 20, 400, 0.1)
    value.name = "WeightEntryValue"
    _label(card, "Предложен последний измеренный вес на выбранную дату. Измени его перед сохранением.", 12, MUTED)
    _button(card, "Записать вес", func():
        if store.save_weight_entry(date, value.value):
            _render()
            _notify_saved("Вес записан")
        else:
            _message("Не удалось сохранить вес. Предыдущие данные сохранены.")
    )
    var chart = _card("Как меняется вес")
    _compact_card(chart, 11, 7)
    _graph_period_buttons(chart, "weight")
    var window: Array = ProgressGraph.filter_records(
        store.data["weights"], date, weight_chart_period)
    _graph_period_info(chart, window, "кг")
    var g = GraphScript.new()
    g.name = "WeightProgressGraph"
    g.custom_minimum_size = Vector2(0, 210)
    g.set_palette(TEXT_ACCENT, CHART_GRID, MUTED, ACCENT, CHART_AREA, SECONDARY)
    g.set_unit("кг")
    g.set_overview_points(window, float(settings["goal"]))
    chart.add_child(g)
    var history = store.data["weights"].duplicate()
    history.sort_custom(func(a,b): return str(a.get("date", "")) > str(b.get("date", "")))
    var total_history: int = history.size()
    var visible_count: int = total_history if weight_history_expanded else mini(total_history, 8)
    var history_label = _label(chart, "История записей (" + str(total_history) + ")", 15, INK)
    history_label.name = "WeightHistoryTitle"
    for index in range(visible_count):
        var w: Dictionary = history[index]
        var r = _soft_list_row(chart)
        var l = _label(r, str(w.get("date", "")) + " · " + str(w.get("value", 0)) + " кг", 14)
        l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        _button(r, "✎", func(): _edit_weight_entry(w), true)
        _button(r, "×", func(): _confirm_delete("Удалить запись веса?", func():
            if store.delete_saved_record("weights", w):
                _render()
                _notify_saved("Запись веса удалена")
            else:
                _message("Не удалось удалить запись веса.")
        ), true)
    if total_history > 8:
        var more = _button(chart, "Скрыть историю" if weight_history_expanded
            else "Показать все записи (" + str(total_history) + ")", func():
                weight_history_expanded = not weight_history_expanded
                _render()
        , true)
        more.name = "WeightHistoryToggle"


func _edit_weight_entry(weight_record: Dictionary) -> void:
    var day: String = str(weight_record.get("date", ""))
    var sheet = _mobile_sheet("Изменить вес", "Изменяется только запись за " + day + ".", "Сохранить", 330.0)
    var fields: VBoxContainer = sheet["fields"]
    _label(fields, "Вес, кг", 14, MUTED)
    var value = _number(fields, float(weight_record.get("value", 0.0)), 20, 400, 0.1)
    value.name = "WeightEditValue"
    var confirm: Button = sheet["confirm"]
    confirm.pressed.connect(func():
        if store.save_weight_entry(day, value.value):
            sheet["root"].queue_free()
            _render()
            _notify_saved("Вес изменён")
        else:
            _sheet_error(sheet, "Не удалось изменить вес, старое значение сохранено.")
    )


func _set_stats_period(mode: String) -> void:
    if mode not in ["week", "month", "quarter"]:
        return
    if stats_anchor.is_empty():
        stats_anchor = date
    stats_period = mode
    _render(true)


func _shift_stats_period(amount: int) -> void:
    if stats_anchor.is_empty():
        stats_anchor = date
    if stats_period in ["month", "quarter"]:
        var delta_months: int = amount * (3 if stats_period == "quarter" else 1)
        var month = StatsMathScript.shifted_month(stats_anchor.substr(0, 7), delta_months)
        var next_first = _month_offset(month, 1) + "-01"
        var last_day = store.change_date(next_first, -1)
        var preferred = mini(int(stats_anchor.substr(8, 2)), int(last_day.substr(8, 2)))
        stats_anchor = month + "-" + str(preferred).pad_zeros(2)
    else:
        stats_anchor = store.change_date(stats_anchor, amount * 7)
    _render(true)


func _set_stats_detail(section: String) -> void:
    if section not in ["nutrition", "activity", "weight"]:
        return
    stats_detail_tab = section
    _render(true)


func _show_stats() -> void:
    if stats_anchor.is_empty():
        stats_anchor = date
    var report: Dictionary = StatsMathScript.summarize(store, stats_anchor, stats_period)
    var previous_anchor: String = StatsMathScript.previous_anchor(store, stats_anchor, stats_period)
    var previous_report: Dictionary = StatsMathScript.summarize(store, previous_anchor, stats_period)
    var card = _card("", "overview")
    card.get_parent().name = "StatsPeriodCard"
    _compact_card(card, 12, 8)
    _label(card, "Мои итоги", 19, INK)
    var period_buttons = _row(card)
    period_buttons.name = "StatsPeriodSelector"
    period_buttons.add_theme_constant_override("separation", 6)
    for option in [["Неделя", "week"], ["Месяц", "month"], ["3 месяца", "quarter"]]:
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
    period_label.autowrap_mode = TextServer.AUTOWRAP_OFF
    period_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    period_label.add_theme_font_size_override("font_size", 12 if stats_period == "quarter" else 13)
    period_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    period_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    period_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    var following = _button(navigator, "▶", func(): _shift_stats_period(1), true)
    following.name = "StatsNextPeriod"
    following.custom_minimum_size = Vector2(42, 38)
    var jump_current = _button(navigator, "Сейчас", func():
        stats_anchor = Time.get_date_string_from_system()
        _render(true)
    , true)
    jump_current.name = "StatsCurrentPeriod"
    jump_current.custom_minimum_size = Vector2(66, 38)
    jump_current.size_flags_horizontal = Control.SIZE_SHRINK_END
    jump_current.add_theme_font_size_override("font_size", 11)
    var metrics = _row(card)
    metrics.add_theme_constant_override("separation", 5)
    var average = "—" if int(report["recorded"]) == 0 else (
        str(roundi(float(report["avg_kcal"]))) + " ккал"
    )
    _metric_tile(metrics, average, "Среднее по заполненным дням")
    _metric_tile(metrics, str(int(report["recorded"])) + " / " +
        str(int(report["total_days"])), "Дней с питанием")
    var stats_explanation = _label(card,
        "Среднее по дням с питанием, пустые дни не считаются.", 12, MUTED)
    stats_explanation.name = "StatsMethodNote"
    var previous_days: int = int(previous_report["recorded"])
    var current_days: int = int(report["recorded"])
    var compare_text: String = ""
    if current_days > 0 and previous_days > 0:
        var delta_kcal: float = float(report["avg_kcal"]) - float(previous_report["avg_kcal"])
        compare_text = ("К прошлому периоду: " +
            ("+" if delta_kcal > 0 else "") + str(roundi(delta_kcal)) +
            " ккал/заполненный день. Дней с питанием: " +
            str(current_days) + " и " + str(previous_days) + ".")
    else:
        compare_text = ("Сравнение с прошлым периодом: нужны записи питания " +
            "в обоих периодах (" + str(current_days) + " и " + str(previous_days) + " дн.).")
    var compare_label = _label(card, compare_text, 12, TEXT_ACCENT)
    compare_label.name = "StatsPreviousComparison"
    # One visualization at a time: larger readable graphs, shorter page.
    var tabrow = _row(card)
    tabrow.name = "StatsSectionSelector"
    tabrow.add_theme_constant_override("separation", 5)
    for tab_option in [["Питание", "nutrition"], ["Активность", "activity"], ["Вес", "weight"]]:
        var section: String = str(tab_option[1])
        var select_button = _button(tabrow, str(tab_option[0]),
            func(): _set_stats_detail(section), true)
        select_button.name = "StatsSection_" + section
        select_button.custom_minimum_size.y = 42
        select_button.add_theme_font_size_override("font_size", 12)
        if section == stats_detail_tab:
            var active_section = StyleBoxFlat.new()
            active_section.bg_color = NAV_ACTIVE
            active_section.set_corner_radius_all(11)
            for state in ["normal", "hover", "pressed"]:
                select_button.add_theme_stylebox_override(state, active_section)
            select_button.add_theme_color_override("font_color", WHITE)

    match stats_detail_tab:
        "activity":
            var movement = _card("Движение", "activity")
            movement.get_parent().name = "StatsActivityCard"
            _compact_card(movement, 12, 8)
            var contrast_text = INK
            var activity_stats = _row(movement)
            _metric_tile(activity_stats, str(int(report["walking"])) + " мин", "Прогулки")
            _metric_tile(activity_stats, str(int(report["exercise"])) + " мин", "Тренировки")
            var activity_chart = StatsChartScript.new()
            activity_chart.name = "StatsActivityChart"
            activity_chart.custom_minimum_size.y = 185
            movement.add_child(activity_chart)
            activity_chart.setup(report["columns"], "activity", 0.0,
                TEXT_ACCENT, ACCENT, MUTED, CHART_GRID)
            _label(movement, "Линия 1 — ходьба · линия 2 — тренировки · Сеансов: " +
                str(int(report["workouts"])), 12, contrast_text)
            if (int(report["walking"]) + int(report["exercise"]) +
                    int(previous_report["walking"]) + int(previous_report["exercise"]) > 0):
                var walk_change: int = int(report["walking"]) - int(previous_report["walking"])
                var exercise_change: int = int(report["exercise"]) - int(previous_report["exercise"])
                var activity_compare = _label(movement,
                    "К прошлому периоду: ходьба " +
                    ("+" if walk_change > 0 else "") + str(walk_change) +
                    " мин · тренировки " +
                    ("+" if exercise_change > 0 else "") + str(exercise_change) + " мин",
                    12, contrast_text)
                activity_compare.name = "StatsActivityComparison"
        "weight":
            var weight = _card("Динамика веса")
            weight.get_parent().name = "StatsWeightCard"
            _compact_card(weight, 12, 8)
            _label(weight, "Измерений за выбранный период: " +
                str(report["weights"].size()), 12, MUTED)
            var samples: Array = report["weights"]
            if samples.size() >= 2:
                var change_value: float = float(samples[samples.size() - 1]["value"]) - float(samples[0]["value"])
                var change_line = _label(weight,
                    "Изменение между первым и последним измерением: " +
                    ("+" if change_value > 0 else "") +
                    str(snappedf(change_value, 0.1)) + " кг", 13, TEXT_ACCENT)
                change_line.name = "StatsWeightDelta"
            var weight_graph = GraphScript.new()
            weight_graph.name = "StatsWeightGraph"
            weight_graph.custom_minimum_size.y = 235
            weight_graph.set_palette(TEXT_ACCENT, CHART_GRID, MUTED, ACCENT, CHART_AREA, SECONDARY)
            weight_graph.set_points(report["weights"], float(store.data["settings"]["goal"]),
                120 if stats_period == "quarter" else 30)
            weight.add_child(weight_graph)
        _:
            var calories = _card("Калории и БЖУ", "tint")
            calories.get_parent().name = "StatsCalorieCard"
            _compact_card(calories, 12, 8)
            var calorie_group_hint: String = ("По дням" if stats_period == "week"
                else ("Средние калории по календарным неделям" if stats_period == "month"
                else "Средние калории по месяцам (только заполненные дни)"))
            _label(calories, calorie_group_hint, 12, MUTED)
            var kcal_chart = StatsChartScript.new()
            kcal_chart.name = "StatsCalorieChart"
            kcal_chart.custom_minimum_size.y = 190
            calories.add_child(kcal_chart)
            kcal_chart.setup(report["columns"], "calories",
                float(store.data["settings"]["kcal"]), TEXT_ACCENT, ACCENT, MUTED, CHART_GRID)
            _label(calories, "Пунктир — установленная суточная норма.", 12, MUTED)
            if int(report["recorded"]) > 0:
                var difference: float = float(report["avg_kcal"]) - float(store.data["settings"]["kcal"])
                var target_comparison = _label(calories,
                    "Среднее к установленной цели: " +
                    ("+" if difference > 0.0 else "") +
                    str(roundi(difference)) + " ккал/день", 13, TEXT_ACCENT)
                target_comparison.name = "StatsTargetDifference"
            if int(report["recorded"]) == 0:
                _label(calories, "Добавь продукты в дневник для расчёта БЖУ.", 13, MUTED)
            else:
                var macro_heading = _label(calories, "Средние БЖУ за заполненный день", 13, INK)
                macro_heading.name = "StatsMacrosHeading"
                var macro_row = _row(calories)
                macro_row.add_theme_constant_override("separation", 4)
                _compact_macro(macro_row, "Белки", float(report["avg_p"]), PROTEIN_BG, INK)
                _compact_macro(macro_row, "Жиры", float(report["avg_f"]), FAT_BG, INK)
                _compact_macro(macro_row, "Углеводы", float(report["avg_c"]), CARBS_BG, INK)


func _settings_section(title: String, section: String, summary: String) -> VBoxContainer:
    var card = _card("")
    card.get_parent().name = "SettingsSection_" + section
    _compact_card(card, 12, 6)
    var expanded: bool = settings_section_open == section
    var toggle = _button(card, ("▴ " if expanded else "▾ ") + title, func():
        settings_section_open = "" if settings_section_open == section else section
        _render()
    , true)
    toggle.name = "SettingsSectionToggle_" + section
    toggle.custom_minimum_size.y = 44
    toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
    if not expanded:
        var caption = _label(card, summary, 12, MUTED)
        caption.name = "SettingsSectionSummary_" + section
    var contents = VBoxContainer.new()
    contents.name = "SettingsSectionContent_" + section
    contents.mouse_filter = Control.MOUSE_FILTER_PASS
    contents.add_theme_constant_override("separation", 8)
    card.add_child(contents)
    contents.visible = expanded
    return contents


func _google_refresh_settings() -> void:
    if tab == "settings" and settings_page == "main":
        _render()


func _google_connect() -> void:
    if google_plugin == null:
        _message("Google Диск доступен в Android-приложении с Google Play Services.")
        return
    if google_busy:
        return
    google_busy = true
    google_plugin.authorize()
    _google_refresh_settings()


func _on_google_connected() -> void:
    google_connected = true
    google_checked = false
    google_busy = true
    google_plugin.checkBackup()
    _google_refresh_settings()


func _on_google_disconnected() -> void:
    google_connected = false
    google_checked = false
    google_exists = false
    google_checksum = ""
    google_file_id = ""
    google_modified = ""
    google_busy = false
    _google_refresh_settings()


func _on_google_status(has_backup: bool, updated: String, checksum: String, file_id: String) -> void:
    google_checked = true
    google_exists = has_backup
    google_checksum = checksum
    google_file_id = file_id
    google_modified = updated
    google_busy = false
    _google_refresh_settings()


func _on_google_backup_saved(updated: String) -> void:
    google_busy = false
    _notify_saved("Копия сохранена в Google Диске")
    _google_refresh_settings()


func _on_google_backup_deleted() -> void:
    google_busy = false
    google_checked = false
    google_exists = false
    google_checksum = ""
    google_file_id = ""
    google_modified = ""
    _notify_saved("Облачная копия удалена")
    _google_refresh_settings()


func _on_google_error(message: String) -> void:
    google_busy = false
    if message.contains("изменилась"):
        google_checked = false
    _google_refresh_settings()
    _message("Google Диск: " + message)


func _on_google_backup_loaded(raw: String) -> void:
    google_busy = false
    _google_refresh_settings()
    # Cloud data is never silently installed. The existing JSON validation and
    # restore confirmation protect diet, weights, photos and current settings.
    _confirm_restore_json(raw, "Google Диска")


func _google_check() -> void:
    if google_plugin == null or not google_connected or google_busy:
        return
    google_busy = true
    google_plugin.checkBackup()
    _google_refresh_settings()


func _google_upload() -> void:
    if google_plugin == null or not google_connected or google_busy:
        return
    if not google_checked:
        _message("Сначала проверь, есть ли резервная копия на Google Диске.")
        return
    var expected: String = google_checksum
    var expected_id: String = google_file_id
    var serialized: String = store.export_json()
    if serialized.to_utf8_buffer().size() > 5000000:
        _message("Резервная копия больше 5 МБ. Сделай локальный экспорт.")
        return
    _confirm_action("Сохранить на Google Диск?",
        "Это заменит предыдущую облачную копию, но не изменит дневник. " +
        "При изменении копии другим устройством загрузка будет остановлена.",
        func():
            google_busy = true
            google_plugin.uploadBackup(serialized, expected, expected_id)
            _google_refresh_settings()
    , "Сохранить")


func _google_download() -> void:
    if google_plugin == null or not google_connected or not google_checked or \
            not google_exists or google_busy:
        return
    google_busy = true
    google_plugin.downloadBackup(google_file_id, google_checksum)
    _google_refresh_settings()


func _google_delete() -> void:
    if google_plugin == null or not google_connected or not google_checked or \
            not google_exists or google_busy:
        return
    var expected_id: String = google_file_id
    var expected_md5: String = google_checksum
    _confirm_delete("Удалить облачную копию на Google Диске? " +
        "Данные на этом телефоне останутся без изменений.", func():
            google_busy = true
            google_plugin.deleteBackup(expected_id, expected_md5)
            _google_refresh_settings()
    )


func _google_revoke() -> void:
    if google_plugin == null or not google_connected or google_busy:
        return
    _confirm_action("Отключить Google Диск?",
        "Доступ приложения к Google Диску будет отозван. " +
        "Уже сохранённая копия останется в Google Диске; её можно удалить отдельно.",
        func():
            google_busy = true
            google_plugin.revoke()
            _google_refresh_settings()
    , "Отключить")


func _show_google_backup_settings() -> void:
    var state: String = ("Подключено" if google_connected else
        ("Доступно только на Android" if google_plugin == null else "Не подключено"))
    if google_busy:
        state = "Обращение к Google Диску…"
    var card = _settings_section("Google Диск · резервные копии", "google", state)
    if google_plugin == null:
        var notice = _label(card,
            "Подключение к Google доступно в Android-сборке с Google Play Services. " +
            "На компьютере остаются обычные JSON-копии.", 13, MUTED)
        notice.name = "GoogleCloudUnavailable"
        return
    _label(card,
        "Доступ только к скрытой папке данных «Мой баланс» на твоём Google Диске. " +
        "Без сервера разработчика. Синхронизация пока выполняется вручную.", 12, MUTED)
    if not google_connected:
        var sign_in = _button(card, "Подключить Google Диск", func(): _google_connect())
        sign_in.name = "GoogleCloudConnect"
        sign_in.disabled = google_busy
        return
    var status: String = "Копия ещё не проверена"
    if google_checked:
        status = ("Облачная копия: " + google_modified) if google_exists else \
            "На этом Google Диске пока нет резервной копии"
    var summary = _label(card, status, 13, TEXT_ACCENT)
    summary.name = "GoogleCloudStatus"
    var check = _button(card, "Проверить облачную копию", func(): _google_check(), true)
    check.name = "GoogleCloudCheck"
    check.disabled = google_busy
    var save = _button(card, "Сохранить данные в Google Диск", func(): _google_upload())
    save.name = "GoogleCloudUpload"
    save.disabled = not google_checked or google_busy
    var restore = _button(card, "Восстановить данные из Google Диска", func(): _google_download(), true)
    restore.name = "GoogleCloudRestore"
    restore.disabled = not google_checked or not google_exists or google_busy
    _label(card, "Восстановление запрашивает подтверждение и не объединяет записи автоматически. " +
        "При изменении копии другим устройством операция будет остановлена. " +
        "Перед заменой сохрани локальную JSON-копию.", 12, MUTED)
    if google_exists:
        var remove = _button(card, "Удалить облачную копию", func(): _google_delete(), true)
        remove.name = "GoogleCloudDelete"
        remove.disabled = google_busy or not google_checked
    var disconnect_button = _button(card, "Отключить Google Диск", func(): _google_revoke(), true)
    disconnect_button.name = "GoogleCloudDisconnect"
    disconnect_button.disabled = google_busy


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
    _compact_card(back_to_profile, 11, 6)
    var version_label = _label(back_to_profile,
        "Версия " + APP_VERSION + " · Тема: " + AppearanceScript.name_for(current_theme), 12, MUTED)
    version_label.name = "AppVersionLabel"
    _button(back_to_profile, "← К личной странице", func(): _navigate_to_tab("profile"), true)
    var card = _settings_section("Мои цели и параметры", "personal",
        str(roundi(float(store.data["settings"]["kcal"]))) + " ккал/день · Цель: " +
        str(snappedf(float(store.data["settings"]["goal"]), 0.1)) + " кг")
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
    var summary_shares: Array = store.meal_shares()
    var portions_card = _settings_section("Калории по приёмам пищи", "shares",
        "Завтрак / Обед / Ужин / Перекус · " +
        str(summary_shares[0]) + " / " + str(summary_shares[1]) + " / " +
        str(summary_shares[2]) + " / " + str(summary_shares[3]) + "%")
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

    var appearance = _settings_section("Темы и оформление", "appearance",
        AppearanceScript.name_for(current_theme) + " · " +
        ("узоры включены" if PATTERNS else "без узоров"))
    _label(appearance, "Выбери тему — она сразу применится ко всем экранам.", 13, MUTED)
    _label(appearance, "Активная: " + AppearanceScript.name_for(current_theme), 14, TEXT_ACCENT)
    for id in AppearanceScript.ORDER:
        var theme_id: String = str(id)
        var sample: Dictionary = AppearanceScript.palette(theme_id, HIGH_CONTRAST)
        var sample_row = _soft_list_row(appearance)
        var color_preview = HBoxContainer.new()
        color_preview.name = "ThemeSwatch_" + theme_id
        color_preview.add_theme_constant_override("separation", 0)
        color_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
        color_preview.custom_minimum_size = Vector2(54, 36)
        for token in ["background", "hero", "accent"]:
            var strip = ColorRect.new()
            strip.color = Color(str(sample[token]))
            strip.custom_minimum_size = Vector2(18, 36)
            strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
            color_preview.add_child(strip)
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
    _compact_card(my_foods_link, 11, 6)
    _label(my_foods_link, "Создание и редактирование продуктов, привязка штрихкодов, обновление каталога.", 13, MUTED)
    _button(my_foods_link, "Открыть мои продукты", func():
        settings_page = "foods"
        _render()
    , true)
    _show_google_backup_settings()
    var backup = _settings_section("Резервная копия и перенос", "backup",
        "Сохранить или восстановить JSON")
    _label(backup, "Сохрани файл JSON вне приложения, чтобы восстановить данные после удаления или переустановки.", 13, MUTED)
    _button(backup, "Сохранить JSON в файл", func(): _pick_backup_file(true))
    _button(backup, "Импортировать JSON из файла", func(): _pick_backup_file(false), true)
    _label(backup, "Можно скопировать JSON в буфер обмена и восстановить его позже. Буфер обмена может быть доступен другим приложениям: не оставляй в нём личные данные.", 13, MUTED)
    _button(backup, "Скопировать резервную копию", func():
        DisplayServer.clipboard_set(store.export_json())
        _message("JSON скопирован. Сохрани его в надёжном месте.")
    )
    _button(backup, "Восстановить JSON из буфера", func():
        _confirm_restore_json(DisplayServer.clipboard_get(), "буфера обмена")
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
    _confirm_restore_json(raw, "файла")


func _confirm_restore_json(raw: String, source: String) -> void:
    if raw.length() > 5000000 or not (JSON.parse_string(raw) is Dictionary):
        _message("Неверная резервная копия JSON.")
        return
    var confirmation = ConfirmationDialog.new()
    confirmation.name = "BackupRestoreConfirm"
    confirmation.title = "Заменить данные дневника?"
    confirmation.dialog_text = ("Восстановление из " + source +
        " заменит текущие записи питания, веса, рецепты и настройки. " +
        "Перед этим сохрани резервную копию.")
    confirmation.ok_button_text = "Восстановить"
    add_child(confirmation)
    confirmation.confirmed.connect(func():
        if store.import_json(raw):
            date = Time.get_date_string_from_system()
            month_shown = date.substr(0, 7)
            _render()
            _notify_saved("Дневник восстановлен")
        else:
            _message("Файл повреждён или несовместим. Старые данные сохранены.")
        confirmation.queue_free()
    )
    confirmation.canceled.connect(func(): confirmation.queue_free())
    confirmation.popup_centered(Vector2i(365, 210))

func _confirm_action(title: String, description: String, action: Callable,
        confirm_label: String = "Повторить") -> void:
    var dialog = ConfirmationDialog.new()
    dialog.title = title
    dialog.dialog_text = description
    dialog.ok_button_text = confirm_label
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
