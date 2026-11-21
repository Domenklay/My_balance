extends SceneTree

const StoreScript = preload("res://src/store.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED UI FIXES 0.7.37: " + message)
    quit(1)

func _button(node: Node, title: String) -> Button:
    if node is Button and node.text == title:
        return node
    for child in node.get_children():
        var found: Button = _button(child, title)
        if found != null:
            return found
    return null

func _run() -> void:
    var store = StoreScript.new()
    store.data = store.default_data()
    store.data["weights"] = [
        {"id":"a","date":"2026-11-02","value":87.2},
        {"id":"c","date":"2026-12-01","value":80.0},
        {"id":"b","date":"2026-11-15","value":85.6}
    ]
    if absf(store.weight_prefill("2026-11-21") - 85.6) > 0.001 or \
            absf(store.weight_prefill("2026-11-09") - 87.2) > 0.001 or \
            absf(store.weight_prefill("2026-11-01") - 88.0) > 0.001:
        _fail("weight prefill should use most recent nonfuture measurement")
        return
    if not store.save_weight_entry("2026-11-15", 85.1):
        _fail("could not update existing weight entry")
        return
    if store.data["weights"].filter(func(x):
            return x.get("date","") == "2026-11-15").size() != 1 or \
            absf(store.weight_prefill("2026-11-21") - 85.1) > 0.001:
        _fail("weight save created duplicates or did not update latest value")
        return
    var restored = StoreScript.new()
    if absf(restored.weight_prefill("2026-11-21") - 85.1) > 0.001:
        _fail("weight edit was not saved to disk")
        return
    var failing = FailingStore.new()
    failing.data = failing.default_data()
    failing.data["weights"].append({"date":"2026-11-15","value":86.0})
    if failing.save_weight_entry("2026-11-15", 84.0) or \
            absf(failing.weight_prefill("2026-11-21") - 86.0) > 0.001:
        _fail("failed weight save did not roll back")
        return
    if store.save_weight_entry("bad-date", 55.0) or store.save_weight_entry("2026-11-15", 501.0):
        _fail("invalid weight/date was accepted")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.store.data["weights"] = store.data["weights"].duplicate(true)
    app.date = "2026-11-21"
    app.tab = "weight"
    app._render()
    await process_frame
    var current = app.find_child("WeightEntryValue", true, false) as SpinBox
    if current == null or absf(current.value - 85.1) > 0.001:
        _fail("weight screen did not prefill latest measurement")
        return
    var chart = app.find_child("WeightEntryValue", true, false)
    var edit: Button = _button(app, "✎")
    if chart == null or edit == null:
        _fail("weight row edit button missing")
        return
    edit.pressed.emit()
    await process_frame
    var sheet = app.get_node_or_null("ProductSheet")
    var edit_value = sheet.find_child("WeightEditValue", true, false) as SpinBox if sheet != null else null
    if edit_value == null:
        _fail("edit-weight sheet missing")
        return
    edit_value.value = 84.9
    var save = sheet.find_child("ProductSheetConfirm", true, false) as Button
    save.pressed.emit()
    await process_frame
    # The history sorts by date descending; its first edit button targets
    # the December entry, not the current-day input for November.
    if absf(app.store.weight_prefill("2026-12-15") - 84.9) > 0.001 or \
            absf(app.store.weight_prefill("2026-11-21") - 85.1) > 0.001:
        _fail("weight edit must update only the selected historical date")
        return

    app.tab = "profile"
    app._render()
    await process_frame
    var progress = app.find_child("ProfileGoalPercent", true, false) as Label
    if progress == null or progress.autowrap_mode != TextServer.AUTOWRAP_OFF or \
            progress.custom_minimum_size.x < 50:
        _fail("profile percent can still wrap on mobile")
        return

    app.tab = "settings"
    app.settings_page = "main"
    app._render()
    await process_frame
    var version = app.find_child("AppVersionLabel", true, false) as Label
    var cfg = ConfigFile.new()
    if version == null or not version.text.contains("0.7.37") or \
            cfg.load("res://export_presets.cfg") != OK or \
            str(cfg.get_value("preset.0.options", "version/name", "")) != app.APP_VERSION:
        _fail("UI version diverged from Android package version")
        return
    var original = app.store.export_json()
    var newer = app.store.data.duplicate(true)
    newer["settings"]["goal"] = 63.0
    app._confirm_restore_json(JSON.stringify(newer), "буфера обмена")
    await process_frame
    var confirmation = app.get_node_or_null("BackupRestoreConfirm") as ConfirmationDialog
    if confirmation == null or str(confirmation.dialog_text).is_empty() or \
            not is_equal_approx(float(app.store.data["settings"]["goal"]), 65.0):
        _fail("clipboard import bypassed confirmation")
        return
    confirmation.canceled.emit()
    await process_frame
    if not is_equal_approx(float(app.store.data["settings"]["goal"]), 65.0):
        _fail("cancelled backup import changed data")
        return
    app._confirm_restore_json(JSON.stringify(newer), "буфера обмена")
    await process_frame
    confirmation = app.get_node_or_null("BackupRestoreConfirm") as ConfirmationDialog
    confirmation.confirmed.emit()
    await process_frame
    if not is_equal_approx(float(app.store.data["settings"]["goal"]), 63.0):
        _fail("confirmed import did not restore backup")
        return

    var fake = {"name":"Пробное молоко", "barcode":"3017624010701",
        "nutrition_unit":"мл","kcal":55.0,"p":3.0,"f":2.5,"c":5.0}
    app._confirm_barcode_product(fake, true)
    await process_frame
    sheet = app.get_node_or_null("ProductSheet")
    var calories = sheet.find_child("BarcodeCaloriesColumn", true, false) if sheet != null else null
    var kcal = sheet.find_child("BarcodeNutrition_kcal", true, false) as LineEdit if sheet != null else null
    if calories == null or not (calories is VBoxContainer) or kcal == null or \
            kcal.get_parent() != calories or kcal.custom_minimum_size.y > 60:
        _fail("barcode calories layout should be vertical, not squeezed")
        return
    sheet.queue_free()
    await process_frame

    app.tab = "search"
    app._render()
    await process_frame
    var results = app.find_child("FoodSearchResults", true, false)
    var row = results.find_child("FoodSearchRow_0", true, false) if results != null else null
    var quick = _button(row, "＋ Порция") if row != null else null
    if quick == null:
        _fail("search result quick portion button missing")
        return
    var before_count: int = app.store.data["entries"].size()
    quick.pressed.emit()
    await process_frame
    sheet = app.get_node_or_null("ProductSheet")
    if sheet == null or sheet.find_child("QuickPortionQuantity", true, false) == null or \
            app.store.data["entries"].size() != before_count:
        _fail("catalog quick button silently entered unconfirmed food")
        return
    sheet.queue_free()
    await process_frame

    var dish = {"id":"r_new", "name":"Тестовый суп", "cooked_weight":300.0,
        "servings":2.0,"ingredients":[{"name":"Овощи","grams":100.0,
        "kcal":30.0,"p":1.0,"f":0.0,"c":7.0}]}
    app.store.data["recipes"].append(dish)
    app.tab = "day"
    app.date = "2026-11-21"
    app._render()
    app._show_meal_add_actions("Обед")
    await process_frame
    sheet = app.get_node_or_null("ProductSheet")
    var recipe_link = sheet.find_child("MealChooseRecipe", true, false) as Button if sheet != null else null
    if recipe_link == null:
        _fail("direct recipe choice missing from meal sheet")
        return
    recipe_link.pressed.emit()
    await process_frame
    if app.tab != "recipes" or not app._meal_entry_locked or app.selected_meal != "Обед":
        _fail("meal-to-recipe navigation lost destination meal")
        return
    app._recipe_portion_sheet(dish)
    await process_frame
    sheet = app.get_node_or_null("ProductSheet")
    var recipe_meal = sheet.find_child("RecipeServingMeal", true, false) as OptionButton if sheet != null else null
    if recipe_meal == null or not recipe_meal.disabled or \
            recipe_meal.get_item_text(recipe_meal.selected) != "Обед":
        _fail("recipe portion changed chosen meal")
        return
    sheet.queue_free()
    app.queue_free()
    print("PASS UI 0.7.37: safe import, weight edit/prefill, profile, barcode layout, recipe navigation, no hidden food add")
    quit(0)
