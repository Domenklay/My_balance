extends SceneTree

const StoreScript = preload("res://src/store.gd")
const RecipeMath = preload("res://src/recipe_math.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED RECIPES 0.7.36: " + reason)
    quit(1)

func _find_button(node: Node, label: String) -> Button:
    if node is Button and node.text == label:
        return node
    for child in node.get_children():
        var found: Button = _find_button(child, label)
        if found != null:
            return found
    return null

func _run() -> void:
    var store = StoreScript.new()
    store.data = store.default_data()
    var dish = {"id":"recipe_test_0736", "name":"Тестовая каша",
        "cooked_weight":500.0, "servings":2.0,
        "ingredients":[
            {"id":"oats", "name":"Крупа", "grams":100.0,
             "kcal":370.0,"p":13.0,"f":7.0,"c":62.0},
            {"id":"milk", "name":"Молоко", "grams":200.0,"unit":"мл",
             "kcal":50.0,"p":3.0,"f":2.0,"c":5.0}
        ]}
    var metrics: Dictionary = RecipeMath.calculate(dish["ingredients"], float(dish["cooked_weight"]))
    if absf(float(metrics["total_kcal"]) - 470.0) > 0.001 or \
            absf(float(metrics["kcal"]) - 94.0) > 0.001 or \
            absf(float(metrics["raw_weight"]) - 100.0) > 0.001 or \
            absf(float(metrics["raw_volume"]) - 200.0) > 0.001 or \
            absf(float(metrics["total_p"]) - 19.0) > 0.001:
        _fail("mixed g/ml recipe calculation is incorrect: " + str(metrics))
        return
    var cooked = RecipeMath.calculate(dish["ingredients"], 250.0)
    if absf(float(cooked["total_kcal"]) - 470.0) > 0.001 or \
            absf(float(cooked["kcal"]) - 188.0) > 0.001:
        _fail("cooking mass loss must affect density but not total nutrients")
        return
    var bad = dish.duplicate(true)
    bad["ingredients"][1]["unit"] = "cups"
    bad["id"] = "bad"
    if RecipeMath.validate_recipe(bad):
        _fail("invalid ingredient unit accepted")
        return
    bad = dish.duplicate(true)
    bad["favorite"] = "yes"
    if RecipeMath.validate_recipe(bad):
        _fail("invalid favorite flag accepted")
        return
    if store.save_recipe(dish) != "recipe_test_0736":
        _fail("valid legacy recipe not saved")
        return
    if not store.toggle_recipe_favorite("recipe_test_0736") or \
            not bool(store.recipe_by_id("recipe_test_0736").get("favorite", false)):
        _fail("could not favorite recipe")
        return
    var restarted = StoreScript.new()
    if not bool(restarted.recipe_by_id("recipe_test_0736").get("favorite", false)):
        _fail("recipe favorite not persisted on restart")
        return
    if not store.toggle_recipe_favorite("recipe_test_0736") or \
            bool(store.recipe_by_id("recipe_test_0736").get("favorite", false)):
        _fail("could not unfavorite recipe")
        return
    if not store.toggle_recipe_favorite("recipe_test_0736"):
        _fail("could not restore favorite")
        return
    if not store.add_recipe_portion("recipe_test_0736", 120.0, "Обед", "2026-11-20"):
        _fail("could not add first cooked portion")
        return
    if not store.add_recipe_portion("recipe_test_0736", 150.0, "Ужин", "2026-11-20"):
        _fail("could not add second cooked portion")
        return
    var last: Dictionary = store.last_recipe_portion("recipe_test_0736")
    if float(last.get("grams", 0)) != 150.0 or str(last.get("meal", "")) != "Ужин":
        _fail("most recent recipe serving not resolved")
        return
    if not store.repeat_recipe_portion("recipe_test_0736", "2026-11-21"):
        _fail("could not repeat recipe with last portion")
        return
    var todays: Array = store.day_entries("2026-11-21")
    if todays.size() != 1 or float(todays[0].get("grams", 0)) != 150.0 or \
            todays[0].get("meal", "") != "Ужин" or \
            absf(store.day_calories("2026-11-21") - 141.0) > 0.001:
        _fail("repeat changed grams, meal, or calories")
        return
    var saved_calories: float = store.day_calories("2026-11-21")
    var edited = store.recipe_by_id("recipe_test_0736").duplicate(true)
    edited["cooked_weight"] = 250.0
    if store.save_recipe(edited) != "recipe_test_0736" or \
            absf(store.day_calories("2026-11-21") - saved_calories) > 0.001:
        _fail("editing cooked mass changed historical diary")
        return
    var exported = JSON.parse_string(store.export_json())
    for entry in exported["recipes"]:
        entry.erase("favorite")
    if not store.import_json(JSON.stringify(exported)):
        _fail("old JSON recipes without favorite rejected")
        return
    if bool(store.recipe_by_id("recipe_test_0736").get("favorite", false)):
        _fail("legacy favorite incorrectly defaulted true")
        return
    var failing = FailingStore.new()
    failing.data = failing.default_data()
    failing.data["recipes"].append(dish.duplicate(true))
    if failing.toggle_recipe_favorite("recipe_test_0736") or \
            failing.recipe_by_id("recipe_test_0736").has("favorite"):
        _fail("favorite toggle failed to roll back storage failure")
        return
    if failing.repeat_recipe_portion("recipe_test_0736", "2026-11-21"):
        _fail("empty history repeated a nonexistent portion")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.store.data["recipes"].append(dish.duplicate(true))
    app.date = "2026-11-21"
    app.tab = "recipes"
    app._render()
    await process_frame
    var card = app.find_child("RecipeCard_recipe_test_0736", true, false)
    var star = app.find_child("RecipeFavorite_recipe_test_0736", true, false) as Button
    var filters = app.find_child("RecipeQuickFilters", true, false)
    if card == null or star == null or filters == null or \
            _find_button(filters, "★ Избранные") == null or \
            _find_button(filters, "Недавние") == null:
        _fail("recipe card favorite or tabs missing")
        return
    star.pressed.emit()
    await process_frame
    if not bool(app.store.recipe_by_id("recipe_test_0736").get("favorite", false)):
        _fail("favorite star did not persist click")
        return
    _find_button(app.find_child("RecipeQuickFilters", true, false), "★ Избранные").pressed.emit()
    await process_frame
    if app.find_child("RecipeCard_recipe_test_0736", true, false) == null:
        _fail("favorite filter hid starred recipe")
        return
    _find_button(app.find_child("RecipeQuickFilters", true, false), "Недавние").pressed.emit()
    await process_frame
    if app.find_child("RecipeCard_recipe_test_0736", true, false) != null:
        _fail("unlogged recipe should not appear in recent filter")
        return
    _find_button(app.find_child("RecipeQuickFilters", true, false), "Все").pressed.emit()
    await process_frame
    var existing = app.store.recipe_by_id("recipe_test_0736")
    app._recipe_portion_sheet(existing)
    await process_frame
    var sheet = app.get_node_or_null("ProductSheet")
    var spin = sheet.find_child("RecipeServingWeight", true, false) as SpinBox if sheet != null else null
    var buttons = sheet.find_child("RecipeServingPresets", true, false) if sheet != null else null
    var preview = sheet.find_child("RecipeServingPreview", true, false) as Label if sheet != null else null
    if spin == null or buttons == null or preview == null or \
            _find_button(buttons, "½ порции") == null:
        _fail("portion size presets / preview missing")
        return
    _find_button(buttons, "½ порции").pressed.emit()
    await process_frame
    if absf(spin.value - 125.0) > 0.001 or not preview.text.contains("118"):
        _fail("half of cooked portion wrong")
        return
    var confirm = sheet.find_child("ProductSheetConfirm", true, false) as Button
    confirm.pressed.emit()
    await process_frame
    if app.store.day_entries("2026-11-21").size() != 1 or \
            absf(app.store.day_calories("2026-11-21") - 117.5) > 0.001:
        _fail("recipe sheet failed to save calculated half portion")
        return
    app.tab = "recipes"
    app._render()
    await process_frame
    var quick = app.find_child("RecipeRepeat_recipe_test_0736", true, false) as Button
    if quick == null or not quick.text.contains("125"):
        _fail("last logged recipe serving shortcut missing")
        return
    quick.pressed.emit()
    await process_frame
    if app.store.day_entries("2026-11-21").size() != 2 or \
            absf(app.store.day_calories("2026-11-21") - 235.0) > 0.001:
        _fail("one-tap repeated recipe portion incorrectly")
        return
    print("PASS RECIPE 0.7.36: mixed mass/volume, cooked totals, favorites, quick repeat, save, legacy JSON and UI")
    app.queue_free()
    quit(0)
