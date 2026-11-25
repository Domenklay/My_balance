extends SceneTree
const Store = preload("res://src/store.gd")
const Snapshot = preload("res://src/widget_snapshot.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("ANDROID WIDGETS: " + reason)
    quit(1)
func _run() -> void:
    var s = Store.new()
    s.data = s.default_data()
    s.data["settings"]["onboarding_complete"] = true
    s.data["settings"]["kcal"] = 1800
    s.data["settings"]["theme"] = "sand"
    var day = "2026-11-25"
    var before = JSON.stringify(s.data)
    var snapshot = Snapshot.make(s,day)
    if snapshot["remaining"]!=1800 or not snapshot["macros"].is_empty() or snapshot["theme"]!="sand" or not snapshot["ready"] or JSON.stringify(s.data)!=before:
        _fail("empty day or optional goals")
        return
    s.data["settings"]["macro_goals"]["mode"]="manual"
    if not s.add_water(day,250) or not s.set_day_steps(day,1500):
        _fail("fixtures")
        return
    var food = {"id":"widget_test","name":"Private food","kcal":200,"p":10,"f":8,"c":22}
    if not s.add_food_entry(food,100,"Обед",day):
        _fail("food fixture")
        return
    snapshot=Snapshot.make(s,day)
    if snapshot["remaining"]!=1600 or snapshot["water"]!=250 or snapshot["steps"]!=1500 or snapshot["step_source"]!="manual" or snapshot["macros"]["p"]["used"]!=10 or JSON.stringify(snapshot).contains("Private food"):
        _fail("aggregate only, updated amounts")
        return
    var next = Snapshot.make(s,"2026-11-26")
    if next["eaten"]!=0 or next["water"]!=0 or next["steps"]!=0:
        _fail("date isolation")
        return
    var window = Snapshot.window(s,day)
    if window["days"].size()!=3 or window["days"][day]["eaten"]!=200 or window["days"]["2026-11-26"]["eaten"]!=0 or not Snapshot.window(s,"2026-12-31")["days"].has("2027-01-01"):
        _fail("rolling snapshot and year boundary")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data=s.data.duplicate(true)
    app._handle_widget_action("food")
    await process_frame
    if app.tab!="search" or app._meal_entry_locked or app.date!=Time.get_date_string_from_system():
        _fail("food route")
        return
    app._handle_widget_action("sport")
    await process_frame
    if app.tab!="activity":
        _fail("sport route")
        return
    app._handle_widget_action("settings")
    await process_frame
    var toggle=app.find_child("AndroidWidgetPrivacy",true,false) as CheckButton
    if toggle==null or not toggle.disabled or toggle.button_pressed:
        _fail("privacy default and desktop fallback")
        return
    print("PASS ANDROID WIDGETS: aggregate data, current date, optional macros, privacy and routes")
    app.queue_free()
    quit(0)
