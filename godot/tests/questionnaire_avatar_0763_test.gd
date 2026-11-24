extends SceneTree
const Store = preload("res://src/store.gd")
const FailingStore = preload("res://tests/failing_store.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("QUESTIONNAIRE AVATAR 0.7.63: " + reason)
    quit(1)
func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    var details = {"name":"Test","age":30,"height":170.0,"weight":80.0,"goal_weight":75.0,"formula":"female","activity":0,"goal":1}
    if not app.store.complete_onboarding(details,1900):
        _fail("fixture")
        return
    app.tab = "profile"
    app._render()
    await process_frame
    if app.body.get_child_count() != 4 or app.find_child("QuestionnairePhotoPick",true,false) != null:
        _fail("profile not compact")
        return
    (app.find_child("ProfileQuestionnaire",true,false) as Button).pressed.emit()
    await process_frame
    var picker = app.find_child("QuestionnaireAvatarIcon",true,false) as OptionButton
    var name_field = app.find_child("OnboardingName",true,false) as LineEdit
    if picker == null or name_field == null or app.find_child("QuestionnairePhotoPick",true,false) == null:
        _fail("questionnaire appearance missing")
        return
    name_field.text = "Updated"
    picker.select(2)
    picker.item_selected.emit(2)
    var drawing = Image.create(100,100,false,Image.FORMAT_RGB8)
    drawing.fill(Color.BLUE)
    if not app._apply_avatar_photo_bytes(drawing.save_png_to_buffer()) or name_field.text != "Updated":
        _fail("photo selection lost draft fields")
        return
    if app.store.data["profile"]["photo"] != "" or app.store.data["profile"]["avatar"] != "leaf":
        _fail("draft appearance saved prematurely")
        return
    var draft = app.onboarding_profile.duplicate(true)
    var fail = FailingStore.new()
    fail.data = fail.default_data()
    var before = JSON.stringify(fail.data)
    if fail.complete_onboarding(details,1900,true,draft) or JSON.stringify(fail.data) != before:
        _fail("atomic failure rollback")
        return
    if not app.store.complete_onboarding(details,1900,true,draft) or app.store.data["profile"]["avatar"] != "moon" or app.store.data["profile"]["photo"] == "":
        _fail("combined appearance save")
        return
    app.queue_free()
    print("PASS QUESTIONNAIRE AVATAR: consolidated profile, draft photo and icon, atomic save")
    quit(0)
