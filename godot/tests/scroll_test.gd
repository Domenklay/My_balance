extends SceneTree

# Tests real viewport dimensions, scroll range and touch event routing.
func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED SCROLL: " + reason)
    quit(1)

func _run() -> void:
    var scene: PackedScene = load("res://main.tscn")
    if scene == null:
        _fail("main scene missing")
        return
    print("SCROLL DEBUG: scene instantiated")
    var app = scene.instantiate()
    root.add_child(app)
    print("SCROLL DEBUG: app mounted; waiting one frame")
    await process_frame
    print("SCROLL DEBUG: frame received")
    app.store.data = app.store.default_data()
    # Populate a realistic long diary; compact empty pages can legitimately fit.
    var sample_food = app.store.all_foods()[0]
    for i in range(10):
        app.store.data["entries"].append({
            "id": "scroll_sample_" + str(i), "date": app.date,
            "food": sample_food["id"],
            "nutrition": sample_food.duplicate(true),
            "grams": 100.0,
            "meal": ["Завтрак", "Обед", "Перекус", "Ужин"][i % 4]
        })
    var scrollable_pages = 0
    for page in ["day", "recipes", "activity", "weight", "stats", "profile", "settings"]:
        print("SCROLL DEBUG: before page render: ", page)
        app.tab = page
        app._render()
        print("SCROLL DEBUG: after page render: ", page)
        await process_frame
        await process_frame
        var scrolling: ScrollContainer = app.scroll
        if scrolling.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
            _fail("vertical scrolling disabled on " + page)
            return
        var bar: VScrollBar = scrolling.get_v_scroll_bar()
        var range_px = maxf(0.0, bar.max_value - bar.page)
        print("SCROLL PAGE: ", page, " range=", range_px,
            " viewport=", scrolling.size.y, " body=", app.body.size.y)
        if page == "day" and range_px < 150.0:
            _fail("filled diary unexpectedly has no scroll range")
            return
        if range_px > 150.0:
            scrollable_pages += 1
            scrolling.scroll_vertical = mini(230, int(range_px))
            await process_frame
            if scrolling.scroll_vertical < 100:
                _fail("could not scroll " + page + " programmatically")
                return
    # The compact settings page may fit, but the food management page must scroll.
    print("SCROLL DEBUG: before own-foods settings")
    app.tab = "settings"
    app.settings_page = "foods"
    app._render()
    await process_frame
    await process_frame
    var catalog_range = app.scroll.get_v_scroll_bar().max_value - app.scroll.get_v_scroll_bar().page
    print("SCROLL PAGE: settings:foods range=", catalog_range)
    if catalog_range < 150.0:
        _fail("own-product management page has no scroll range")
        return
    if scrollable_pages < 1:
        _fail("filled day does not scroll")
        return

    app.tab = "day"
    app._render()
    await process_frame
    await process_frame
    if app.scroll.scroll_vertical != 0:
        app.scroll.scroll_vertical = 0
        await process_frame

    var margins = app.scroll.get_child(0)
    if margins.mouse_filter == Control.MOUSE_FILTER_STOP:
        _fail("inner margins intercept swipes")
        return
    for panel in app.body.get_children():
        if panel is Control and panel.mouse_filter == Control.MOUSE_FILTER_STOP:
            _fail("day card intercepts swipes: " + panel.name)
            return

    # Inject touch in the middle of a content card (not in the scrollbar).
    # Desktop CI does not replace physical-device QA but verifies drag routing.
    var finger = Vector2(190, 590)
    var touch = InputEventScreenTouch.new()
    touch.index = 0
    touch.pressed = true
    touch.position = finger
    Input.parse_input_event(touch)
    await process_frame
    # Some headless render drivers do not dispatch synthetic touch through
    # Viewport. Call the same production handler explicitly as fallback.
    var direct_fallback = app._swipe_index < 0
    if direct_fallback:
        # Headless backend skips Node._input dispatch for injected touch.
        app._input(touch)
    for i in range(12):
        var drag = InputEventScreenDrag.new()
        drag.index = 0
        drag.position = finger + Vector2(0, -20.0 * float(i + 1))
        drag.relative = Vector2(0, -20)
        drag.velocity = Vector2(0, -400)
        if direct_fallback:
            app._input(drag)
        else:
            Input.parse_input_event(drag)
        await process_frame
    var release = InputEventScreenTouch.new()
    release.index = 0
    release.pressed = false
    release.position = finger + Vector2(0, -240)
    if direct_fallback:
        app._input(release)
    else:
        Input.parse_input_event(release)
    await process_frame
    print("SCROLL TOUCH: scroll_vertical=", app.scroll.scroll_vertical)
    if app.scroll.scroll_vertical < 15:
        _fail("swipe over day card did not move ScrollContainer")
        return

    var after_touch = app.scroll.scroll_vertical
    app._render()
    await process_frame
    await process_frame
    if abs(app.scroll.scroll_vertical - after_touch) > 20:
        _fail("rebuilding the day reset scroll from " + str(after_touch) + " to " + str(app.scroll.scroll_vertical))
        return
    app.tab = "settings"
    app.settings_page = "foods"
    app._render()
    await process_frame
    await process_frame
    var food_scroll_position = mini(110, maxi(0, roundi(catalog_range) - 10))
    app.scroll.scroll_vertical = food_scroll_position
    await process_frame
    app.tab = "day"
    app._render()
    await process_frame
    await process_frame
    if abs(app.scroll.scroll_vertical - after_touch) > 20:
        _fail("switching away and back lost saved day position")
        return
    app.tab = "settings"
    app._render()
    await process_frame
    await process_frame
    if abs(app.scroll.scroll_vertical - food_scroll_position) > 20:
        _fail("switching back to own products lost scroll: expected " +
            str(food_scroll_position) + ", actual " + str(app.scroll.scroll_vertical))
        return

    print("PASS: swipe, independent page positions, no reset after diary rerender")
    app.queue_free()
    quit(0)
