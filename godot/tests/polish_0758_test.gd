extends SceneTree
const Ring = preload("res://src/calorie_ring.gd")
const Store = preload("res://src/store.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("POLISH 0.7.58: " + reason)
    quit(1)
func _run() -> void:
    var graph = Ring.new()
    root.add_child(graph)
    graph.set_value(900, 1800)
    graph.animate_from(0.2)
    if absf(graph.progress - 0.5) > 0.001 or graph.goal_text != "50%":
        _fail("animation changed actual calorie data")
        return
    graph.queue_free()
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.tab = "recipes"
    app._render()
    await process_frame
    var empty = app.find_child("EmptyState_recipes", true, false)
    if empty == null or empty.find_child("EmptyStateArt", true, false) == null:
        _fail("recipe illustration missing")
        return
    app.tab = "activity"
    app._render()
    await process_frame
    if app.find_child("EmptyState_activity", true, false) == null:
        _fail("activity illustration missing")
        return
    app.tab = "settings"
    app.settings_page = "main"
    app.settings_section_open = "appearance"
    app._render()
    await process_frame
    var toggle = app.find_child("AppearanceAnimationsToggle", true, false) as Button
    if toggle == null:
        _fail("motion setting missing")
        return
    toggle.pressed.emit()
    await process_frame
    if app._motion_enabled():
        _fail("motion toggle failed")
        return
    app.tab = "day"
    app._render()
    if app.body.modulate.a != 1.0:
        _fail("disabled animations still fade")
        return
    var legacy = app.store.data.duplicate(true)
    legacy["settings"].erase("animations")
    var restored = Store.new()
    if not restored.import_json(JSON.stringify(legacy), false) or not bool(restored.data["settings"]["animations"]):
        _fail("legacy data lost motion default")
        return
    app.queue_free()
    print("PASS POLISH 0.7.58: actual calorie values, illustrations, reduced motion, migration")
    quit(0)
