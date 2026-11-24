extends SceneTree

# Regression for compact five-tab mobile navigation in 0.7.44.
func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED NAVIGATION ICONS: " + reason)
    quit(1)

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.tab = "day"
    app._render()
    await process_frame
    var titles = {"day":"День", "search":"Рецепты", "activity":"Спорт",
        "progress":"Прогресс", "profile":"Профиль"}
    var navigation = app.shell.get_node_or_null("BottomNavigation")
    if navigation == null or app.nav_icons.size() != 5 or \
            app.nav_labels.size() != 5 or app.tab_buttons.size() != 5:
        _fail("missing any of the five complete tab buttons")
        return
    for key in titles:
        var icon: TextureRect = app.nav_icons[key]
        var label: Label = app.nav_labels[key]
        var button: Button = app.tab_buttons[key]
        if icon.texture == null or icon.texture.get_width() < 32:
            _fail("missing icon resource for " + key)
            return
        if label.text != titles[key] or \
                icon.mouse_filter != Control.MOUSE_FILTER_IGNORE or \
                label.mouse_filter != Control.MOUSE_FILTER_IGNORE:
            _fail("wrong caption or blocked tap target for " + key)
            return
        if button.custom_minimum_size.y < 59 or button.tooltip_text != titles[key]:
            _fail("undersized or unlabelled navigation button: " + key)
            return
        if button.get_parent().get_parent() != navigation:
            _fail("navigation item escaped bottom bar: " + key)
            return
    for mode in ["forest", "botanical", "dark"]:
        app.store.data["settings"]["theme"] = mode
        app._refresh_appearance()
        app.tab = "day"
        app._update_tabs()
        if app.nav_icons["day"].modulate != app.WHITE:
            _fail("active tab icon is not bright in " + mode)
            return
        if app.nav_icons["progress"].modulate == app.WHITE:
            _fail("inactive icon is not subdued in " + mode)
            return
    for target in ["search", "activity", "progress", "profile", "day"]:
        app.tab_buttons[target].pressed.emit()
        await process_frame
        if app.tab != ("recipes" if target == "search" else target) or app.nav_icons[target].modulate != app.WHITE:
            _fail("press or active icon broken: " + target)
            return
    # Legacy internal destinations remain reachable via old profile and day links.
    for target in ["weight", "stats"]:
        app.tab = target
        app._update_tabs()
        if app.nav_icons["progress"].modulate != app.WHITE:
            _fail("legacy progress view lost active navigation: " + target)
            return
    app.tab = "recipes"
    app._update_tabs()
    if app.nav_icons["search"].modulate != app.WHITE:
        _fail("recipe screen no longer marks Products active")
        return
    app.tab = "settings"
    app._update_tabs()
    if app.nav_icons["profile"].modulate != app.WHITE:
        _fail("profile icon should stay selected on the settings page")
        return
    print("PASS NAVIGATION ICONS 0.7.44: five tabs, vector assets, colors, taps and legacy routes")
    app.queue_free()
    quit(0)
