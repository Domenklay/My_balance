extends SceneTree
const Store = preload("res://src/store.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("PROFILE SYSTEM 0.7.62: " + reason)
    quit(1)
func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.store.data["settings"]["start"] = 88.0
    app.tab = "profile"
    app._render()
    await process_frame
    var settings = app.find_child("ProfileSettingsShortcut", true, false) as Button
    var questionnaire = app.find_child("ProfileQuestionnaire", true, false) as Button
    var system_card = app.find_child("ProfileSystemSettings", true, false)
    var rewards = app.find_child("ProfileRewardsCard", true, false)
    if settings == null or questionnaire == null or system_card == null or rewards == null or system_card.get_parent() != app.body or system_card.get_index() >= rewards.get_index():
        _fail("questionnaire or accessible settings above rewards missing")
        return
    questionnaire.pressed.emit()
    await process_frame
    if app.tab != "onboarding" or app.onboarding_return_tab != "profile":
        _fail("questionnaire navigation")
        return
    app.tab = "profile"
    app._render()
    await process_frame
    (app.find_child("ProfileSettingsShortcut",true,false) as Button).pressed.emit()
    await process_frame
    if app.tab != "settings" or app.body.get_child(1).name != "SettingsSection_language" or app.body.get_child(2).name != "SettingsSection_appearance":
        _fail("system settings order")
        return
    app.settings_section_open = "language"
    app._render()
    await process_frame
    var picker = app.find_child("InterfaceLanguagePicker",true,false) as OptionButton
    picker.select(1)
    (app.find_child("InterfaceLanguageApply",true,false) as Button).pressed.emit()
    await process_frame
    if app.store.data["settings"]["language"] != "en" or str(TranslationServer.translate("День")) != "Day":
        _fail("English translation not active")
        return
    if not app.store.set_interface_language("ru"):
        _fail("return to Russian")
        return
    app._apply_interface_language()
    if str(TranslationServer.translate("День")) != "День":
        _fail("Russian translation not restored")
        return
    var details = {"name":"Test","age":30,"height":170.0,"weight":80.0,"goal_weight":75.0,"formula":"manual","activity":0,"goal":1}
    if not app.store.complete_onboarding(details,1800,true) or app.store.data["settings"]["start"] != 88.0:
        _fail("editing questionnaire reset starting weight")
        return
    var legacy = app.store.data.duplicate(true)
    legacy["settings"].erase("language")
    if not app.store.import_json(JSON.stringify(legacy),false) or app.store.data["settings"]["language"] != "ru":
        _fail("legacy language migration")
        return
    app.queue_free()
    print("PASS PROFILE SYSTEM: questionnaire, accessible settings, language, legacy and starting weight")
    quit(0)
