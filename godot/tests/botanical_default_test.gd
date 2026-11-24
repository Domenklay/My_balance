extends SceneTree

const StoreScript = preload("res://src/store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED BOTANICAL DEFAULT: " + reason)
    quit(1)

func _start_app() -> Control:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    return app

func _run() -> void:
    var old = StoreScript.new()
    old.data = old.default_data()
    old.data["settings"]["onboarding_complete"] = true
    old.data["settings"]["kcal"] = 1760
    old.data["notes"]["2026-11-21"] = "Записи должны сохраниться"
    if not old.save():
        _fail("cannot prepare existing journal")
        return

    var app = _start_app()
    await process_frame
    if app.current_theme != "forest" or app.PATTERN_STYLE == "botanical":
        _fail("update unexpectedly changed the user's forest theme")
        return
    var promoted = StoreScript.new()
    if str(promoted.data["settings"].get("theme", "")) != "forest" or \
            not bool(promoted.data["settings"].get("botanical_default_applied", false)):
        _fail("migration should mark the schema but preserve forest selection")
        return
    if int(promoted.data["settings"]["kcal"]) != 1760 or \
            str(promoted.data["notes"].get("2026-11-21", "")) != "Записи должны сохраниться":
        _fail("upgrade discarded personal goals or diary")
        return
    app._choose_theme("forest")
    await process_frame
    app.queue_free()
    await process_frame

    var again = _start_app()
    await process_frame
    if again.current_theme != "forest":
        _fail("app reverts manual choice to botanical on restart")
        return
    again.queue_free()
    await process_frame

    var other = StoreScript.new()
    other.data["settings"]["theme"] = "dark"
    other.data["settings"]["patterns"] = false
    other.data["settings"].erase("botanical_default_applied")
    if not other.save():
        _fail("cannot prepare existing dark-theme diary")
        return
    var preserved = _start_app()
    await process_frame
    if preserved.current_theme != "dark" or preserved.PATTERNS:
        _fail("upgrade overwrote explicitly selected theme or pattern setting")
        return
    if int(preserved.store.data["settings"]["kcal"]) != 1760:
        _fail("upgrade modified the user's calorie target")
        return
    preserved.queue_free()
    print("PASS BOTANICAL DEFAULT: one-time upgrade, manual theme persistence, preserved diary and contrast preferences")
    quit(0)
