extends SceneTree
const Store = preload("res://src/store.gd")
const FailStore = preload("res://tests/failing_store.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("AUTO STEPS: " + reason)
    quit(1)
func _run() -> void:
    var s = Store.new()
    s.data = s.default_data()
    var d = "2026-11-25"
    var old = "2026-11-24"
    s.data["steps"][old] = 6000
    var goal = s.data["settings"]["kcal"]
    if not s.sync_automatic_steps({d:1200,old:3000}) or s.day_steps(d)!=1200 or s.day_steps(old)!=6000:
        _fail("legacy steps and automatic source")
        return
    if not s.sync_automatic_steps({d:1500}) or not s.sync_automatic_steps({d:1000}) or s.day_steps(d)!=1500:
        _fail("duplicate or stale snapshot")
        return
    if not s.set_day_steps(d,2300) or not s.sync_automatic_steps({d:2000}) or s.day_steps(d)!=2300:
        _fail("manual override must not add automatic steps")
        return
    if not s.set_day_steps(d,0) or s.day_steps(d)!=0 or not s.use_automatic_steps(d) or s.day_steps(d)!=2000:
        _fail("zero override or explicit automatic source")
        return
    var restored = Store.new()
    if restored.day_steps(d)!=2000 or restored.day_steps(old)!=6000 or restored.data["settings"]["kcal"]!=goal:
        _fail("persistence or calories changed")
        return
    var bad = FailStore.new()
    bad.data = bad.default_data()
    if bad.sync_automatic_steps({d:500}) or bad.day_steps(d)!=0 or bad.set_day_steps(d,200) or bad.step_source(d)!="auto":
        _fail("save rollback")
        return
    if s.sync_automatic_steps({d:-1}) or s.sync_automatic_steps({"bad":10}):
        _fail("invalid sensor data")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = s.data.duplicate(true)
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = d
    app.tab = "activity"
    app._render()
    await process_frame
    var toggle = app.find_child("AutoStepToggle",true,false) as Button
    var manual = app.find_child("ActivitySteps",true,false) as SpinBox
    if toggle == null or not toggle.disabled or manual == null or manual.value!=2000:
        _fail("desktop/manual fallback")
        return
    print("PASS AUTO STEPS: separate sources, manual zero override, persistence, stale snapshots and fallback")
    app.queue_free()
    quit(0)
