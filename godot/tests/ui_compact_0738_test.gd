extends SceneTree

const StoreScript = preload("res://src/store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED UI 0.7.38: " + message)
    quit(1)

func _button(node: Node, name: String) -> Button:
    if node is Button and node.text == name:
        return node
    for child in node.get_children():
        var found: Button = _button(child, name)
        if found != null:
            return found
    return null

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.tab = "settings"
    app.settings_page = "main"
    app.settings_section_open = ""
    app._render()
    await process_frame
    for section in ["personal", "shares", "appearance", "backup"]:
        var card = app.find_child("SettingsSection_" + section, true, false)
        var details = app.find_child("SettingsSectionContent_" + section, true, false)
        var toggle = app.find_child("SettingsSectionToggle_" + section, true, false) as Button
        if card == null or details == null or toggle == null or details.visible:
            _fail("settings should be collapsed by default: " + section)
            return
        if toggle.icon == null or toggle.custom_minimum_size.y < 40:
            _fail("undersized section toggle: " + section)
            return
    var settings_search = app.find_child("SettingsSearch", true, false) as LineEdit
    if settings_search == null:
        _fail("settings search is missing")
        return
    settings_search.text = "гуГл"
    settings_search.text_changed.emit(settings_search.text)
    if not app.find_child("SettingsSection_google", true, false).visible or app.find_child("SettingsSection_language", true, false).visible:
        _fail("settings search failed case-insensitive filtering")
        return
    settings_search.text = "нет_такой_настройки"
    settings_search.text_changed.emit(settings_search.text)
    if not app.find_child("SettingsNoMatches", true, false).visible:
        _fail("settings search missing empty state")
        return
    settings_search.text = ""
    settings_search.text_changed.emit(settings_search.text)
    if not app.find_child("SettingsSection_language", true, false).visible or app.find_child("SettingsNoMatches", true, false).visible:
        _fail("clearing settings search did not restore sections")
        return
    var food_settings = _button(app, "Открыть мои продукты")
    if food_settings == null:
        _fail("own food management disappeared from settings")
        return
    var personal = app.find_child("SettingsSectionToggle_personal", true, false) as Button
    personal.pressed.emit()
    await process_frame
    if not app.find_child("SettingsSectionContent_personal", true, false).visible or \
            app.find_child("SettingsSectionContent_shares", true, false).visible:
        _fail("personal settings failed to expand")
        return
    var kcal = app.find_child("DailyCalorieTarget", true, false) as LineEdit
    if kcal == null or kcal.text != str(roundi(float(app.store.data["settings"]["kcal"]))):
        _fail("personal settings lost existing calorie input")
        return
    (app.find_child("SettingsSectionToggle_shares", true, false) as Button).pressed.emit()
    await process_frame
    if app.find_child("SettingsSectionContent_personal", true, false).visible or \
            not app.find_child("SettingsSectionContent_shares", true, false).visible:
        _fail("expanding another section must close the previous one")
        return
    if app.find_child("MealCaloriePreview", true, false) == null:
        _fail("editable meal share preview missing")
        return
    (app.find_child("SettingsSectionToggle_backup", true, false) as Button).pressed.emit()
    await process_frame
    if not app.find_child("SettingsSectionContent_backup", true, false).visible or \
            _button(app, "Сохранить JSON в файл") == null:
        _fail("backup export hidden or missing")
        return

    var sample = [
        {"id":"search_one","name":"Суп с курицей","cooked_weight":400.0,
         "servings":2.0,"ingredients":[
            {"name":"Курица","grams":200.0,"kcal":160.0,"p":21.0,"f":7.0,"c":0.0}]},
        {"id":"search_two","name":"Каша","cooked_weight":300.0,
         "servings":2.0,"ingredients":[
            {"name":"Гречка","grams":100.0,"kcal":340.0,"p":12.0,"f":3.0,"c":67.0}]},
        {"id":"search_three","name":"Овощная смесь","cooked_weight":400.0,
         "servings":2.0,"ingredients":[
            {"name":"Томаты","grams":100.0,"kcal":20.0,"p":1.0,"f":0.1,"c":4.0}]}
    ]
    for recipe in sample:
        app.store.data["recipes"].append(recipe)
    app.tab = "recipes"
    app._render()
    await process_frame
    var field = app.find_child("RecipeLiveSearch", true, false) as LineEdit
    var count = app.find_child("RecipeSearchCount", true, false) as Label
    if field == null or count == null or not count.text.contains("3 из 3"):
        _fail("live recipe search / count missing")
        return
    var original_field_id: int = field.get_instance_id()
    field.text = "гречка"
    field.text_changed.emit(field.text)
    await process_frame
    if not field.is_inside_tree() or field.get_instance_id() != original_field_id or \
            app.find_child("RecipeCard_search_one", true, false).visible or \
            not app.find_child("RecipeCard_search_two", true, false).visible or \
            app.find_child("RecipeCard_search_three", true, false).visible or \
            not count.text.contains("1 из 3"):
        _fail("recipe ingredient search did not filter in place")
        return
    field.text = "сУП"
    field.text_changed.emit(field.text)
    await process_frame
    if not app.find_child("RecipeCard_search_one", true, false).visible or \
            app.find_child("RecipeCard_search_two", true, false).visible:
        _fail("recipe title search is not case insensitive")
        return
    field.text = "несуществующее"
    field.text_changed.emit(field.text)
    await process_frame
    var not_found = app.find_child("RecipeNoMatches", true, false)
    if not_found == null or not not_found.visible:
        _fail("search has no visible empty-state")
        return
    field.text = ""
    field.text_changed.emit(field.text)
    await process_frame
    if not_found.visible or not count.text.contains("3 из 3"):
        _fail("clearing recipe query did not restore results")
        return

    app.store.data["entries"].append({
        "id":"sample_kcal","date":"2026-11-20","food":"d2",
        "grams":100.0,"meal":"Завтрак",
        "nutrition":app.store.food_by_id("d2").duplicate(true)
    })
    app.store.data["weights"] = [
        {"date":"2026-11-18","value":88.0},
        {"date":"2026-11-21","value":86.8}
    ]
    app.tab = "stats"
    app.stats_period = "week"
    app.stats_anchor = "2026-11-21"
    app.stats_detail_tab = "nutrition"
    app._render()
    await process_frame
    var now = app.find_child("StatsCurrentPeriod", true, false) as Button
    var delta = app.find_child("StatsTargetDifference", true, false) as Label
    if now == null or delta == null or not delta.text.contains("ккал/день"):
        _fail("stats navigation or calorie target comparison missing")
        return
    (app.find_child("StatsSection_weight", true, false) as Button).pressed.emit()
    await process_frame
    var weight_delta = app.find_child("StatsWeightDelta", true, false) as Label
    if weight_delta == null or not weight_delta.text.contains("-1.2"):
        _fail("stats weight period change should be -1.2kg")
        return
    app.stats_anchor = "2026-10-21"
    app._render()
    await process_frame
    (app.find_child("StatsCurrentPeriod", true, false) as Button).pressed.emit()
    await process_frame
    if app.stats_anchor != Time.get_date_string_from_system():
        _fail("current period button did not return to today")
        return
    var cfg = ConfigFile.new()
    if cfg.load("res://export_presets.cfg") != OK or \
            str(cfg.get_value("preset.0.options", "version/name", "")) != app.APP_VERSION:
        _fail("UI version differs from APK version")
        return
    app.queue_free()
    print("PASS UI 0.7.38: compact accordion, instant ingredient search, stats labels and current period")
    quit(0)
