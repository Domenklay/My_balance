extends SceneTree
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("CATALOG DESIGN 0.7.55: " + reason)
    quit(1)
func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-24"
    app.tab = "search"
    app._render()
    await process_frame
    var search = app.find_child("FoodNameSearch", true, false) as LineEdit
    if search == null or app.find_child("FoodCameraQuick", true, false) == null:
        _fail("search or camera missing")
        return
    search.text = "банан"
    search.text_changed.emit(search.text)
    await process_frame
    var row = app.find_child("FoodSearchRow_0", true, false)
    if row == null or row.find_child("FoodMacroTiles", true, false) == null or row.find_child("CatalogProductIcon", true, false) == null:
        _fail("nutrition cards missing")
        return
    var fav = row.find_child("FoodCardFavorite_0", true, false) as Button
    if fav == null:
        _fail("direct favorite missing")
        return
    var before = app.store.data["favorites"].size()
    fav.pressed.emit()
    await process_frame
    if app.store.data["favorites"].size() != before + 1:
        _fail("direct favorite failed")
        return
    for i in range(2):
        app.store.data["recipes"].append({"id":"design_recipe_" + str(i),
            "name":"Блюдо " + str(i), "cooked_weight":500.0,"servings":2.0,
            "ingredients":[{"name":"Яблоко","id":"d3","grams":500.0,"kcal":52.0,
                "p":0.3,"f":0.2,"c":14.0}]})
    app.tab = "recipes"
    app._render()
    await process_frame
    var toggle = app.find_child("RecipeLayoutToggle", true, false) as Button
    if toggle == null or app.find_child("RecipeMacroTiles", true, false) == null:
        _fail("recipe presentation missing")
        return
    toggle.pressed.emit()
    await process_frame
    var grid = app.find_child("RecipeGrid", true, false) as GridContainer
    if grid == null or grid.columns != 2 or grid.get_child_count() != 2:
        _fail("grid failed")
        return
    (app.find_child("RecipeLayoutToggle", true, false) as Button).pressed.emit()
    await process_frame
    if app.find_child("RecipeGrid", true, false) != null or app.find_child("RecipeCard_design_recipe_0", true, false) == null:
        _fail("list return failed")
        return
    app.queue_free()
    print("PASS CATALOG DESIGN 0.7.55: camera, nutrient tiles, favorites, recipe grid and list")
    quit(0)
