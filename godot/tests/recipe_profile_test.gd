extends SceneTree

const StoreScript = preload("res://src/store.gd")
const MathScript = preload("res://src/recipe_math.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("FAILED RECIPES/PROFILE: " + message)
    quit(1)

func _find_button(node: Node, text: String) -> Button:
    if node is Button and node.text == text:
        return node
    for child in node.get_children():
        var result = _find_button(child, text)
        if result != null:
            return result
    return null

func _find_input(node: Node, placeholder: String) -> LineEdit:
    if node is LineEdit and node.placeholder_text == placeholder:
        return node
    for child in node.get_children():
        var found = _find_input(child, placeholder)
        if found != null:
            return found
    return null

func _run() -> void:
    var store = StoreScript.new()
    store.data = store.default_data()
    var liver = {"id": "liver", "name": "Печень", "grams": 1000.0, "kcal": 130.0, "p": 20.0, "f": 5.0, "c": 0.0}
    var onion = {"id": "onion", "name": "Лук", "grams": 100.0, "kcal": 40.0, "p": 1.0, "f": 0.1, "c": 9.0}
    var cream = {"id": "cream", "name": "Сметана 15%", "grams": 50.0, "kcal": 160.0, "p": 2.5, "f": 15.0, "c": 3.0}
    var recipe = {"id": "", "name": "Печень со сметаной", "cooked_weight": 800.0, "servings": 4.0,
        "ingredients": [liver, onion, cream]}
    var totals = MathScript.calculate(recipe["ingredients"], float(recipe["cooked_weight"]))
    if totals.is_empty() or absf(float(totals["total_kcal"]) - 1420.0) > 0.01:
        _fail("ingredient totals wrong: " + str(totals))
        return
    if absf(float(totals["kcal"]) - 177.5) > 0.01:
        _fail("finished-weight calorie density wrong")
        return
    if absf(float(MathScript.portion("test", totals, 200.0)["kcal"]) - 355.0) > 0.01:
        _fail("portion calorie calculation wrong")
        return
    recipe["cooked_weight"] = 1150.0
    var diluted = MathScript.calculate(recipe["ingredients"], 1150.0)
    if absf(float(diluted["total_kcal"]) - 1420.0) > 0.01 or float(diluted["kcal"]) >= 177.5:
        _fail("water mass erroneously changed total calories")
        return
    recipe["cooked_weight"] = 800.0
    var recipe_id = store.save_recipe(recipe)
    if recipe_id.is_empty():
        _fail("could not save recipe")
        return
    if not store.add_recipe_portion(recipe_id, 200.0, "Обед", "2026-11-19"):
        _fail("could not add saved recipe portion")
        return
    if store.repeat_meal("2026-11-19", "Обед", "2026-11-20") != 1:
        _fail("could not repeat complete meal")
        return
    if store.day_entries("2026-11-20").size() != 1 or absf(store.day_calories("2026-11-20") - 355.0) > 0.01:
        _fail("repeated meal did not preserve nutrition snapshot")
        return
    if store.repeat_meal("2026-11-19", "Ужин", "2026-11-20") != 0:
        _fail("empty meal duplicated")
        return
    if not store.save_meal_template("2026-11-19", "Обед", "Любимый обед"):
        _fail("could not save meal template")
        return
    if store.data["meal_templates"].size() != 1:
        _fail("meal template not persisted in data")
        return
    var template_id = str(store.data["meal_templates"][0]["id"])
    if store.apply_meal_template(template_id, "2026-11-21") != 1:
        _fail("could not apply meal template")
        return
    if absf(store.day_calories("2026-11-21") - 355.0) > 0.01:
        _fail("meal template nutrition snapshot changed")
        return
    var after_template = StoreScript.new()
    if after_template.data["meal_templates"].size() != 1:
        _fail("meal template did not survive app restart")
        return
    if not store.delete_meal_template(template_id) or store.data["meal_templates"].size() != 0:
        _fail("cannot delete meal template")
        return
    if absf(store.day_calories("2026-11-21") - 355.0) > 0.01:
        _fail("deleting meal template changed diary history")
        return
    var recent = store.recent_foods(3)
    if recent.is_empty() or recent.size() > 3:
        _fail("recent foods not derived from diary")
        return
    var frequent = store.frequent_foods(3)
    if frequent.is_empty() or frequent.size() > 3:
        _fail("frequent foods not derived from diary")
        return
    var saved_kcal = store.day_calories("2026-11-19")
    if absf(saved_kcal - 355.0) > 0.01:
        _fail("recipe snapshot calorie calculation wrong")
        return
    var update = store.recipe_by_id(recipe_id).duplicate(true)
    update["ingredients"][0]["kcal"] = 200.0
    if store.save_recipe(update) != recipe_id or store.data["recipes"].size() != 1:
        _fail("editing recipe changed identity or created duplicate")
        return
    if absf(store.day_calories("2026-11-19") - saved_kcal) > 0.01:
        _fail("editing recipe changed historical diary entries")
        return
    var profile = {"name": "Света", "avatar": "moon", "motto": "Мой путь к цели"}
    if not store.update_profile(profile):
        _fail("could not save personal profile")
        return
    var reloaded = StoreScript.new()
    if str(reloaded.data["profile"]["name"]) != "Света" or reloaded.data["recipes"].size() != 1:
        _fail("profile or recipes not persisted after restart")
        return
    if reloaded.day_entries("2026-11-19").size() != 1:
        _fail("recipe portion disappeared from persisted diary")
        return
    if not store.delete_recipe(recipe_id) or store.data["recipes"].size() != 0:
        _fail("cannot delete recipe")
        return
    if absf(store.day_calories("2026-11-19") - 355.0) > 0.01:
        _fail("deleted recipe erased historical food diary value")
        return
    var invalid = {"id":"a", "name":"Bad", "cooked_weight":0, "servings":4, "ingredients":[liver]}
    if not store.save_recipe(invalid).is_empty():
        _fail("invalid finished weight accepted")
        return
    var legacy = store.default_data()
    legacy.erase("recipes")
    legacy.erase("profile")
    if not store.import_json(JSON.stringify(legacy)):
        _fail("previous versions' backup rejected")
        return
    if store.data["recipes"].size() != 0 or str(store.data["profile"]["avatar"]) != "leaf":
        _fail("legacy data migration did not create profile or recipes")
        return
    var fail = FailingStore.new()
    fail.data = fail.default_data()
    if fail.save_recipe(recipe) != "" or fail.data["recipes"].size() != 0:
        _fail("failed recipe save did not roll back")
        return
    if fail.update_profile(profile) or str(fail.data["profile"]["name"]) != "Мой профиль":
        _fail("failed profile save did not roll back")
        return

    var scene: PackedScene = load("res://main.tscn")
    var app = scene.instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.tab = "profile"
    app._render()
    await process_frame
    if app.tab_buttons.size() != 6 or _find_button(app, "✎ Изменить имя и значок") == null:
        _fail("personal page missing controls or sixth tab")
        return
    var edit_button = _find_button(app, "✎ Изменить имя и значок")
    edit_button.pressed.emit()
    await process_frame
    if not app.profile_edit_open or _find_button(app, "Сохранить профиль") == null:
        _fail("profile edit form not accessible")
        return
    app._navigate_to_tab("recipes")
    await process_frame
    if _find_button(app, "+ Создать рецепт") == null:
        _fail("recipes tab missing new recipe button")
        return
    _find_button(app, "+ Создать рецепт").pressed.emit()
    await process_frame
    if not app.recipe_editor_open or _find_button(app, "+ Добавить ингредиент") == null:
        _fail("recipe editor not accessible")
        return
    _find_button(app, "+ Ввести ингредиент вручную").pressed.emit()
    await process_frame
    var ingredient_name = _find_input(app, "Название ингредиента")
    if ingredient_name == null:
        _fail("manual ingredient form is missing")
        return
    ingredient_name.text = "Тестовые овощи"
    _find_button(app, "Добавить в состав").pressed.emit()
    await process_frame
    if app.recipe_draft["ingredients"].size() != 1:
        _fail("ingredient not attached to draft")
        return
    var dish_name = _find_input(app, "Название блюда")
    if dish_name == null:
        _fail("recipe name input missing")
        return
    dish_name.text = "Овощное блюдо"
    _find_button(app, "Сохранить рецепт").pressed.emit()
    await process_frame
    if app.store.data["recipes"].size() != 1 or app.recipe_editor_open:
        _fail("recipe editor did not save and close")
        return
    var log_button = _find_button(app, "+ Добавить порцию в дневник")
    if log_button == null:
        _fail("saved recipe has no diary action")
        return
    log_button.pressed.emit()
    await process_frame
    var modal = app.get_node_or_null("ProductSheet")
    if modal == null:
        _fail("recipe portion sheet not displayed")
        return
    var commit: Button = modal.find_child("ProductSheetConfirm", true, false)
    if commit == null:
        _fail("portion sheet missing confirm button")
        return
    commit.pressed.emit()
    await process_frame
    if app.tab != "day" or app.store.day_entries(app.date).size() != 1:
        _fail("recipe portion was not added to diary via UI")
        return
    print("PASS: recipe UI manual ingredient, save, portion sheet and diary entry")
    print("PASS: recipe math with cooked weight, CRUD, historical snapshots, profile persistence and six-tab UI")
    app.queue_free()
    quit(0)
