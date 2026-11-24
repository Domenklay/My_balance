extends SceneTree
const Rewards = preload("res://src/rewards.gd")
const Appearance = preload("res://src/appearance.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("PROFILE DESIGN 0.7.57: " + reason)
    quit(1)
func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.tab = "profile"
    app.rewards_expanded = true
    for id in Appearance.ORDER:
        app.store.data["settings"]["theme"] = id
        app._refresh_appearance()
        var before = JSON.stringify(app.store.data)
        app._render()
        await process_frame
        await process_frame
        var avatar = app.find_child("ProfileAvatarFrame", true, false) as PanelContainer
        var settings = app.find_child("ProfileSettingsShortcut", true, false) as Button
        var grid = app.find_child("ProfileAchievementGrid", true, false) as GridContainer
        if avatar == null or avatar.size.x < 88 or settings == null or grid == null or grid.get_child_count() != Rewards.AWARDS.size():
            _fail("profile visual controls missing " + id)
            return
        if grid.columns != 2 or app.body.get_child_count() > 4:
            _fail("profile layout is not compact")
            return
        var first = app.find_child("Achievement_first", true, false)
        var progress = first.find_child("AchievementProgress", true, false) as ProgressBar
        if progress == null or progress.value != 0:
            _fail("invented award progress")
            return
        if JSON.stringify(app.store.data) != before:
            _fail("viewing profile changed saved data")
            return
    var today = Time.get_date_string_from_system()
    var food = app.store.food_by_id("d16")
    if not app.store.add_food_entry(food, 100.0, "Завтрак", today):
        _fail("fixture save failed")
        return
    app._render()
    await process_frame
    var first = app.find_child("Achievement_first", true, false)
    var progress = first.find_child("AchievementProgress", true, false) as ProgressBar
    if progress.value != 1.0:
        _fail("milestone did not reflect existing journal")
        return
    var summary = app.store.reward_summary()
    if Rewards.achievement_progress("week", summary)["value"] != 1:
        _fail("cumulative milestone value incorrect")
        return
    app.queue_free()
    print("PASS PROFILE DESIGN 0.7.57: larger avatar, top settings, achievement tiles, five themes, read-only records")
    quit(0)
