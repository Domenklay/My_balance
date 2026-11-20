extends SceneTree

const AppearanceScript = preload("res://src/appearance.gd")
const StoreScript = preload("res://src/store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED THEME: " + message)
    quit(1)

func _find_button(node: Node, label: String) -> Button:
    if node is Button and node.text == label:
        return node
    for child in node.get_children():
        var found = _find_button(child, label)
        if found != null:
            return found
    return null

func _run() -> void:
    var packed: PackedScene = load("res://main.tscn")
    if packed == null:
        _fail("missing app scene")
        return
    var app: Variant = packed.instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    if not app.store.save():
        _fail("could not establish test store")
        return
    app._refresh_appearance()
    app._render()
    for selected_theme in AppearanceScript.ORDER:
        var id: String = str(selected_theme)
        if not AppearanceScript.is_valid_theme(id):
            _fail("theme id not registered: " + id)
            return
        app._choose_theme(id)
        await process_frame
        await process_frame
        var palette: Dictionary = AppearanceScript.palette(id)
        if app.current_theme != id or str(app.store.data["settings"]["theme"]) != id:
            _fail("theme selection not applied: " + id)
            return
        if app.BACKGROUND != Color(str(palette["background"])):
            _fail("theme palette background not applied: " + id)
            return
        if app.background_rect.color != app.BACKGROUND:
            _fail("viewport background stale after theme switch: " + id)
            return
        if app.header_panel.get_theme_stylebox("panel").bg_color != Color(str(palette["header"])):
            _fail("app header has previous theme: " + id)
            return
        var hero: PanelContainer = app.body.get_child(1) as PanelContainer
        if hero == null or hero.get_theme_stylebox("panel").bg_color != app.HERO_BG:
            _fail("daily hero missing themed card: " + id)
            return
        var overview: PanelContainer = app.body.get_child(0) as PanelContainer
        var activity: PanelContainer = app.body.get_child(2) as PanelContainer
        if overview == null or overview.get_theme_stylebox("panel").bg_color != Color(str(palette["overview"])):
            _fail("day overview section color not applied: " + id)
            return
        if activity == null or activity.get_theme_stylebox("panel").bg_color != Color(str(palette["activity"])):
            _fail("activity section color not applied: " + id)
            return
        if str(palette["hero"]) == str(palette["activity"]) or str(palette["hero"]) == str(palette["overview"]):
            _fail("multi-colored cards do not have distinct backgrounds: " + id)
            return
        if str(palette["protein_bg"]) == str(palette["fat_bg"]) or str(palette["fat_bg"]) == str(palette["carbs_bg"]):
            _fail("protein, fat and carb tiles are not individually colored: " + id)
            return
        if app.NAV_ACTIVE != Color(str(palette["nav_active"])):
            _fail("bottom navigation accent was not updated: " + id)
            return
        if app.tab_buttons.size() != 6:
            _fail("theme broke bottom navigation: " + id)
            return
        var navigation = app.shell.get_node("BottomNavigation") as PanelContainer
        if navigation.get_theme_stylebox("panel").bg_color != app.CARD_BG:
            _fail("bottom navigation not themed: " + id)
            return
        if not app.wallpaper_pattern.enabled:
            _fail("selected theme lost enabled ornament: " + id)
            return
        print("PASS THEME: " + id + " background/card/nav/ornament")

    # Check both contrast modes for each existing theme. Keep the chosen
    # theme and contrast setting independent from one another.
    app._toggle_high_contrast()
    await process_frame
    if not app.HIGH_CONTRAST or not bool(app.store.data["settings"]["high_contrast"]):
        _fail("high contrast toggle was not persisted")
        return
    for selected_theme in AppearanceScript.ORDER:
        var id: String = str(selected_theme)
        app._choose_theme(id)
        await process_frame
        var high: Dictionary = AppearanceScript.palette(id, true)
        if app.BACKGROUND != Color(str(high["background"])) or app.INK != Color(str(high["ink"])):
            _fail("high contrast palette was not applied to " + id)
            return
        if not app.HIGH_CONTRAST or not bool(app.store.data["settings"]["high_contrast"]):
            _fail("switching theme reset high contrast")
            return
        if app.NAV_ACTIVE != Color(str(high["nav_active"])) or app.ACTIVITY_BG != Color(str(high["activity"])):
            _fail("colorful high-contrast sections not applied to " + id)
            return
        var normal: Dictionary = AppearanceScript.palette(id)
        if str(high["background"]) == str(normal["background"]) or str(high["border"]) == str(normal["border"]):
            _fail("high contrast must visibly separate cards/inputs for " + id)
            return
    app.tab = "settings"
    app.settings_page = "main"
    app._render()
    await process_frame
    if _find_button(app, "Контраст: повышенный") == null:
        _fail("contrast control missing from settings")
        return
    app._choose_theme("dark")
    app._toggle_patterns()
    await process_frame
    if app.PATTERNS or app.wallpaper_pattern.enabled or bool(app.store.data["settings"].get("patterns", true)):
        _fail("turning off patterns did not update UI/persistence")
        return
    app.tab = "settings"
    app.settings_page = "main"
    app._render()
    await process_frame
    var save_settings = _find_button(app, "Сохранить настройки")
    if save_settings == null:
        _fail("settings save button not found")
        return
    save_settings.pressed.emit()
    await process_frame
    if str(app.store.data["settings"]["theme"]) != "dark" or bool(app.store.data["settings"]["patterns"]) or not bool(app.store.data["settings"]["high_contrast"]):
        _fail("updating personal goals erased appearance settings")
        return
    var persistent = StoreScript.new()
    if str(persistent.data["settings"]["theme"]) != "dark" or bool(persistent.data["settings"]["patterns"]) or not bool(persistent.data["settings"]["high_contrast"]):
        _fail("dark theme or pattern toggle did not survive relaunch")
        return

    var old_backup = persistent.data.duplicate(true)
    old_backup["settings"].erase("theme")
    old_backup["settings"].erase("patterns")
    old_backup["settings"].erase("high_contrast")
    if not persistent.import_json(JSON.stringify(old_backup)):
        _fail("legacy JSON backup cannot be imported")
        return
    if str(persistent.data["settings"]["theme"]) != "forest" or not bool(persistent.data["settings"]["patterns"]) or bool(persistent.data["settings"]["high_contrast"]):
        _fail("legacy JSON lacked safe default visual settings")
        return
    var invalid = persistent.data.duplicate(true)
    invalid["settings"]["theme"] = "broken-theme"
    if persistent.import_json(JSON.stringify(invalid)):
        _fail("unsupported theme name was accepted from backup")
        return
    var bad_contrast = persistent.data.duplicate(true)
    bad_contrast["settings"]["high_contrast"] = "true"
    if persistent.import_json(JSON.stringify(bad_contrast)):
        _fail("nonboolean contrast setting accepted")
        return
    print("PASS THEME: four palettes, both contrast modes, persistence, migration and settings safety")
    app.queue_free()
    quit(0)
