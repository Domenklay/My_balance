extends SceneTree
const Store = preload("res://src/store.gd")
const Math = preload("res://src/recipe_math.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("FOOD HISTORY AND DISH: " + reason)
    quit(1)
func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-24"
    app.tab = "day"
    app._render()
    await process_frame
    (app.find_child("MealQuickAdd_0",true,false) as Button).pressed.emit()
    await process_frame
    if app.tab != "search" or app.selected_meal != "Завтрак" or not app._meal_entry_locked or app.get_node_or_null("ProductSheet") != null:
        _fail("plus must open direct breakfast search")
        return
    if not app.store.remember_food_search("яблоко") or not app.store.remember_food_search("молоко") or not app.store.remember_food_search("Яблоко"):
        _fail("history save")
        return
    var restored = Store.new()
    if restored.food_search_history() != ["Яблоко","молоко"]:
        _fail("history ordering, uniqueness or persistence")
        return
    app._render()
    await process_frame
    if app.find_child("FoodSearchHistory",true,false) == null:
        _fail("history not visible")
        return
    for i in range(8):
        app.store.remember_food_search("запрос " + str(i))
    app._render()
    await process_frame
    var history = app.find_child("FoodSearchHistory",true,false)
    var more = app.find_child("FoodSearchHistoryMore",true,false) as Button
    if history == null or history.get_child_count() != 6 or more == null:
        _fail("compact history")
        return
    more.pressed.emit()
    await process_frame
    history = app.find_child("FoodSearchHistory",true,false)
    if history.get_child_count() != 10:
        _fail("full history inaccessible")
        return
    (app.find_child("FoodCreateDish",true,false) as Button).pressed.emit()
    await process_frame
    if app.tab != "recipes" or not app.recipe_from_search or not app._meal_entry_locked:
        _fail("dish editor lost meal context")
        return
    app.recipe_draft["name"] = "Тестовое блюдо"
    app.recipe_draft["ingredients"] = [{"name":"Ингредиент","grams":200,"kcal":100,"p":10,"f":4,"c":8}]
    app.recipe_draft["cooked_weight"] = 400
    app._render()
    await process_frame
    var preview = app.find_child("RecipeDishNutrition",true,false) as Label
    if preview == null or not preview.text.contains("На 100 г готового: 50 ккал") or not preview.text.contains("Б 5"):
        _fail("whole dish nutrition calculation")
        return
    var details = app.find_child("RecipeOptionalDetails",true,false)
    var toggle = app.find_child("RecipeOptionalToggle",true,false) as Button
    if details == null or details.visible or toggle == null:
        _fail("quick calculator must hide optional recipe details")
        return
    toggle.pressed.emit()
    if not details.visible:
        _fail("optional details cannot be opened")
        return
    toggle.pressed.emit()
    var grams = app.find_child("RecipeIngredientWeight_0",true,false) as SpinBox
    var cooked = app.find_child("RecipeCookedWeight",true,false) as SpinBox
    grams.value = 300
    if not preview.text.contains("На 100 г готового: 75 ккал"):
        _fail("ingredient edit did not refresh nutrition immediately")
        return
    cooked.value = 600
    if not preview.text.contains("На 100 г готового: 50 ккал"):
        _fail("cooked weight edit did not refresh nutrition")
        return
    grams.value = 200
    cooked.value = 400
    (app.find_child("RecipeDishAdd",true,false) as Button).pressed.emit()
    await process_frame
    var full = app.find_child("RecipeWholeDish",true,false) as Button
    if full == null or not app.store.data["entries"].is_empty():
        _fail("whole dish choice or premature persistence")
        return
    full.pressed.emit()
    (app.find_child("ProductSheetConfirm",true,false) as Button).pressed.emit()
    await process_frame
    if app.store.data["entries"].size() != 1 or app.store.data["recipes"].size() != 1 or app.store.data["entries"][0]["meal"] != "Завтрак" or absf(app.store.day_calories("2026-11-24") - 200) > 0.01:
        _fail("whole dish confirmation")
        return
    if not app.store.clear_food_search_history() or not app.store.food_search_history().is_empty():
        _fail("history clear")
        return
    print("PASS FOOD HISTORY AND DISH: direct plus, search persistence, whole dish per 100g and exact meal")
    app.queue_free()
    quit(0)
