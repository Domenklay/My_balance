extends SceneTree

const Appearance = preload("res://src/appearance.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED FIVE THEMES 0.7.50.1: " + reason)
    quit(1)

func _run() -> void:
    var expected = {
        "forest": ["Лесная светлая", "#F3F7F1", "#194B38"],
        "mint": ["Мятная нежность", "#EDF9FB", "#126882"],
        "sand": ["Тёплый беж", "#FCF7EF", "#8C5C3B"],
        "dark": ["Ночной синий", "#101B2B", "#223D5D"],
        "botanical": ["Сливовый уют", "#241C2A", "#543456"]
    }
    var known: Dictionary = {}
    for key in Appearance.ORDER:
        var id: String = str(key)
        var palette: Dictionary = Appearance.palette(id)
        var high: Dictionary = Appearance.palette(id, true)
        if not expected.has(id) or Appearance.name_for(id) != expected[id][0]:
            _fail("theme id/name mismatch: " + id)
            return
        if str(palette["background"]) != expected[id][1] or \
                str(palette["hero"]) != expected[id][2]:
            _fail("unexpected theme signature color: " + id)
            return
        var signature: String = str(palette["header"]) + "|" + str(palette["green"])
        if known.has(signature):
            _fail("different themes share the same dominant identity")
            return
        known[signature] = true
        for token in ["green","deep","ink","muted","input","border",
                "secondary","background","surface","hero","nav_active",
                "text_accent","track","fill","grid","area","pattern_color"]:
            if not palette.has(token) or not high.has(token):
                _fail("missing complete theme token " + token + " for " + id)
                return
        if high["background"] == palette["background"] or \
                high["border"] == palette["border"]:
            _fail("high contrast has no visible effect for " + id)
            return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    var preserved: String = JSON.stringify(app.store.data)
    for id in Appearance.ORDER:
        app.store.data["settings"]["theme"] = id
        app._refresh_appearance()
        app.tab = "day"
        app._render()
        await process_frame
        var style: Dictionary = Appearance.palette(id)
        if app.DARK_MODE != (id in ["dark","botanical"]) or \
                app.HERO_BG != Color(str(style["hero"])) or \
                app.BACKGROUND != Color(str(style["background"])) or \
                app.NAV_ACTIVE != Color(str(style["nav_active"])):
            _fail("theme not propagated to whole interface: " + id)
            return
        if app.tab_buttons.size() != 5 or \
                app.find_child("MealQuickAdd_0", true, false) == null:
            _fail("visual update removed controls: " + id)
            return
        app.tab = "settings"
        app.settings_page = "main"
        app._render()
        await process_frame
        var swatch = app.find_child("ThemeSwatch_" + id, true, false) as HBoxContainer
        if swatch == null or swatch.get_child_count() != 3:
            _fail("3-color theme preview missing for " + id)
            return
        var first = swatch.get_child(0) as ColorRect
        var second = swatch.get_child(1) as ColorRect
        if first.color != Color(str(style["background"])) or \
                second.color != Color(str(style["hero"])):
            _fail("theme preview does not match real colors " + id)
            return
    app.store.data["settings"]["theme"] = "forest"
    app._refresh_appearance()
    if str(app.store.data["settings"]["theme"]) != "forest":
        _fail("theme choice was silently overridden")
        return
    app.queue_free()
    print("PASS FIVE THEMES: five distinctive palettes, mobile UI, high contrast, tri-color previews and stable IDs")
    quit(0)
