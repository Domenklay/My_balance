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
    var app = scene.instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    var scrollable_pages = 0
    for page in ["day", "activity", "weight", "stats", "settings"]:
        app.tab = page
        app._render()
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
        if page in ["day", "settings"] and range_px < 150.0:
            _fail("long page unexpectedly has no vertical scroll range: " + page)
            return
        if range_px > 150.0:
            scrollable_pages += 1
            scrolling.scroll_vertical = mini(230, int(range_px))
            await process_frame
            if scrolling.scroll_vertical < 100:
                _fail("could not scroll " + page + " programmatically")
                return
    # Activity and weight can legitimately fit without scrolling;
    # require the two long pages to be scrollable.
    if scrollable_pages < 2:
        _fail("missing scroll range on day/settings: " + str(scrollable_pages))
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

    print("PASS: vertical scroll range on pages, cards do not swallow touch, swipe moves screen")
    app.queue_free()
    quit(0)
