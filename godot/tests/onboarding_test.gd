extends SceneTree

const StoreScript = preload("res://src/store.gd")
const Onboard = preload("res://src/onboarding_math.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED ONBOARDING: " + message)
    quit(1)

func _button(root_node: Node, title: String) -> Button:
    if root_node is Button and root_node.text == title:
        return root_node
    for node in root_node.get_children():
        var match_button = _button(node, title)
        if match_button != null:
            return match_button
    return null

func _find_summary(node: Node, needle: String) -> bool:
    if node is Label and node.text.contains(needle):
        return true
    for c in node.get_children():
        if _find_summary(c, needle):
            return true
    return false

func _run() -> void:
    var store = StoreScript.new()
    store.data = store.default_data()
    if not store.needs_onboarding():
        _fail("fresh installation does not require initial setup")
        return
    var details: Dictionary = {
        "name":"Ирина", "age":30, "height":165.0, "weight":70.0,
        "goal_weight":64.0, "formula":"female", "activity":0, "goal":1
    }
    var estimate = Onboard.estimate(details)
    if estimate.is_empty() or absf(float(estimate["bmr"]) - 1420.0) > 1 or \
            absf(float(estimate["maintenance"]) - 1704.0) > 2 or \
            absf(float(estimate["kcal"]) - 1530.0) > 1:
        _fail("Mifflin adult estimate does not match expected result: " + str(estimate))
        return
    var personal_real = details.duplicate(true)
    personal_real["age"] = 28
    personal_real["height"] = 170.0
    personal_real["weight"] = 88.0
    personal_real["goal_weight"] = 65.0
    var real_estimate: Dictionary = Onboard.estimate(personal_real)
    if absf(float(real_estimate.get("bmr", 0)) - 1642) > 1 or \
            absf(float(real_estimate.get("maintenance", 0)) - 1970) > 1 or \
            absf(float(real_estimate.get("kcal", 0)) - 1970) > 1:
        _fail("88kg, 170cm, 28y adult estimate unexpectedly low: " + str(real_estimate))
        return
    personal_real["goal"] = 1
    var weight_loss_estimate: Dictionary = Onboard.estimate(personal_real)
    if absf(float(weight_loss_estimate.get("kcal", 0)) - 1770) > 1:
        _fail("88kg/170cm/28y low activity goal should be near 1770 kcal, not 1380")
        return
    for invalid_age in [17, 0, 120]:
        var bad = details.duplicate()
        bad["age"] = invalid_age
        if Onboard.valid_details(bad):
            _fail("invalid adult age accepted")
            return
    var unknown = details.duplicate()
    unknown["formula"] = "manual"
    if bool(Onboard.estimate(unknown).get("automatic", true)):
        _fail("manual-only formula should not present automatic calorie estimate")
        return
    if not store.complete_onboarding(details, 1530.0) or store.needs_onboarding():
        _fail("completed questionnaire not saved")
        return
    if str(store.data["profile"]["name"]) != "Ирина" or \
            int(store.data["settings"]["kcal"]) != 1530 or \
            float(store.data["settings"]["start"]) != 70.0:
        _fail("questionnaire did not populate profile and goal values")
        return
    var reload = StoreScript.new()
    if reload.needs_onboarding() or int(reload.data["settings"]["kcal"]) != 1530:
        _fail("onboarding flag lost after restart")
        return
    var user_food = reload.food_by_id("d16")
    if not reload.add_food_entry(user_food, 100.0, "Обед", Time.get_date_string_from_system()):
        _fail("cannot preserve existing diary record in test")
        return
    var old = reload.data.duplicate(true)
    old["settings"].erase("onboarding_complete")
    old["settings"].erase("personal")
    if not reload.import_json(JSON.stringify(old)) or reload.needs_onboarding():
        _fail("legacy backup wrongly forced onboarding")
        return
    if reload.day_entries(Time.get_date_string_from_system()).size() != 1:
        _fail("onboarding migration deleted an existing day")
        return
    var bad_save = FailingStore.new()
    bad_save.data = bad_save.default_data()
    if bad_save.complete_onboarding(details, 1530.0) or not bad_save.needs_onboarding():
        _fail("failed write did not roll back first-run setup")
        return
    if bad_save.complete_onboarding(details, 600.0):
        _fail("invalid calorie target was accepted")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app._begin_onboarding()
    await process_frame
    if app.tab != "onboarding" or app.onboarding_step != 0:
        _fail("two-step setup did not open on first step")
        return
    var nav = app.shell.get_node_or_null("BottomNavigation")
    if nav == null or nav.visible:
        _fail("main navigation is visible before questionnaire is completed")
        return
    var name = app.find_child("OnboardingName", true, false) as LineEdit
    var height = app.find_child("OnboardingHeight", true, false) as LineEdit
    var weight = app.find_child("OnboardingWeight", true, false) as LineEdit
    var age = app.find_child("OnboardingAge", true, false) as LineEdit
    if name == null or height == null or weight == null or age == null:
        _fail("first-run fields missing")
        return
    if not age.text.is_empty() or not height.text.is_empty() or not weight.text.is_empty():
        _fail("fresh questionnaire silently pre-filled age/height/current weight")
        return
    var next = _button(app, "Дальше →")
    if next == null:
        _fail("first step has no Continue button")
        return
    name.text = "Новая пользовательница"
    next.pressed.emit()
    await process_frame
    if app.onboarding_step != 0:
        _fail("blank personal measurements were accepted")
        return
    age.text = "28"
    height.text = "170"
    weight.text = "88"
    next.pressed.emit()
    await process_frame
    if app.onboarding_step != 1:
        _fail("first step did not advance after valid inputs")
        return
    var preview = app.find_child("OnboardingEstimate", true, false) as Label
    var calories = app.find_child("OnboardingCalories", true, false) as SpinBox
    var activity = app.find_child("OnboardingActivity", true, false) as OptionButton
    var target = app.find_child("OnboardingGoal", true, false) as OptionButton
    if preview == null or calories == null or activity == null or target == null:
        _fail("activity/goal/calorie result controls missing")
        return
    activity.select(1)
    activity.item_selected.emit(1)
    target.select(1)
    target.item_selected.emit(1)
    if not preview.text.contains("Оценка поддержания") or not preview.text.contains("1970") or \
            calories.value < 1000 or calories.value > 5000:
        _fail("88kg user's maintenance estimate was not calculated from entered data")
        return
    if not _find_summary(app, "28 лет") or not _find_summary(app, "170 см") or \
            not _find_summary(app, "88"):
        _fail("second step hides the age/height/weight used in calculation")
        return
    if not preview.text.contains("Оценка поддержания") or calories.value < 1000 or calories.value > 5000:
        _fail("activity and goal did not produce live estimate")
        return
    calories.value = 1790
    var finish = _button(app, "Сохранить и начать")
    if finish == null:
        _fail("second step has no Save button")
        return
    finish.pressed.emit()
    await process_frame
    if app.tab != "day" or app.store.needs_onboarding() or \
            str(app.store.data["profile"]["name"]) != "Новая пользовательница" or \
            int(app.store.data["settings"]["kcal"]) != 1790:
        _fail("first-run wizard did not save customized calorie target")
        return
    app._begin_onboarding(true)
    await process_frame
    if app.tab != "onboarding" or app.onboarding_step != 0 or \
            str(app.onboarding_draft.get("name", "")) != "Новая пользовательница":
        _fail("existing profile cannot reopen its questionnaire")
        return
    print("PASS ONBOARDING: math, adult limits, manual override, fresh setup, old data migration, rollback and two-step UI")
    app.queue_free()
    quit(0)
