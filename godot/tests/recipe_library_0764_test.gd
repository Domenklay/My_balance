extends SceneTree
const RecipeMath = preload("res://src/recipe_math.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("RECIPE LIBRARY 0.7.64: " + reason)
    quit(1)
func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    for sample in [["soup","soups",190],["cake","desserts",400],["main","mains",800]]:
        var record = {"id":sample[0],"name":sample[0],"category":sample[1],"instructions":"Mix and cook","cooked_weight":100.0,"servings":1.0,"ingredients":[{"name":"Test","grams":100.0,"kcal":sample[2],"p":1.0,"f":1.0,"c":1.0}]}
        if app.store.save_recipe(record) == "":
            _fail("recipe validation")
            return
    var before = app.store.data["recipes"].size()
    var share = app.store.export_shared_recipe("soup")
    var copy = app.store.import_shared_recipe(share)
    if copy.is_empty() or copy == "soup" or app.store.data["recipes"].size() != before + 1:
        _fail("share/import")
        return
    if not app.store.import_shared_recipe("{invalid").is_empty():
        _fail("invalid share accepted")
        return
    app.tab_buttons["search"].pressed.emit()
    await process_frame
    if app.tab != "recipes" or app.nav_labels["search"].text != "Рецепты":
        _fail("recipe tab navigation")
        return
    var category = app.find_child("RecipeCategoryFilter",true,false) as OptionButton
    var calories = app.find_child("RecipeCalorieFilter",true,false) as OptionButton
    if category == null or calories == null:
        _fail("filters missing")
        return
    category.select(RecipeMath.CATEGORY_IDS.find("soups")+1)
    category.item_selected.emit(category.selected)
    await process_frame
    if app.find_child("RecipeCard_soup",true,false) == null or app.find_child("RecipeCard_cake",true,false) != null:
        _fail("category filtering")
        return
    category = app.find_child("RecipeCategoryFilter",true,false)
    category.select(0)
    category.item_selected.emit(0)
    await process_frame
    calories = app.find_child("RecipeCalorieFilter",true,false)
    calories.select(3)
    calories.item_selected.emit(3)
    await process_frame
    if app.find_child("RecipeCard_cake",true,false) == null or app.find_child("RecipeCard_main",true,false) != null:
        _fail("calorie filtering")
        return
    app._begin_recipe_editor(app.store.recipe_by_id("soup"))
    await process_frame
    if app.find_child("RecipeEditCategory",true,false) == null or app.find_child("RecipeInstructions",true,false) == null:
        _fail("editor fields")
        return
    app.queue_free()
    print("PASS RECIPE LIBRARY 0.7.64: recipes tab, category, calories per serving, editor and portable recipe")
    quit(0)
