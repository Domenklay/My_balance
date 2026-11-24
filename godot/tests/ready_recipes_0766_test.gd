extends SceneTree
const Catalog = preload("res://src/ready_recipes.gd")
const Math = preload("res://src/recipe_math.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("READY RECIPES: " + reason)
    quit(1)
func _run() -> void:
    var ids = {}
    for recipe in Catalog.all():
        if not Math.validate_recipe(recipe) or ids.has(recipe["id"]) or not str(recipe["source_url"]).begins_with("https://ru.wikibooks.org/wiki/"):
            _fail("invalid catalog entry")
            return
        ids[recipe["id"]] = true
    if ids.size() != 100:
        _fail("expected 100 unique offline recipes")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    var original = JSON.stringify(app.store.data)
    app.tab_buttons["search"].pressed.emit()
    await process_frame
    if app.find_child("ReadyRecipe_catalog_oats",true,false) == null or JSON.stringify(app.store.data) != original:
        _fail("empty diary does not show ready catalog or modified data")
        return
    var grid = app.find_child("ReadyRecipeGrid", true, false) as GridContainer
    if grid == null or grid.get_child_count() != 100:
        _fail("catalog grid does not contain all entries")
        return
    var cat = app.find_child("ReadyRecipeCategory",true,false) as OptionButton
    cat.select(Math.CATEGORY_IDS.find("soups")+1)
    cat.item_selected.emit(cat.selected)
    await process_frame
    if app.find_child("ReadyRecipe_catalog_onion_soup",true,false) == null or app.find_child("ReadyRecipe_catalog_oats",true,false) != null:
        _fail("category filter")
        return
    var id = app._save_ready_recipe(Catalog.all()[0])
    if id.is_empty() or app._save_ready_recipe(Catalog.all()[0]) != id or app.store.data["recipes"].size() != 1 or app.store.data["entries"].size() != 0:
        _fail("copy or duplicate prevention")
        return
    if not app.store.recipe_by_id(id)["instructions"].contains("Викиучебника"):
        _fail("source attribution lost")
        return
    app.queue_free()
    print("PASS READY RECIPES: offline catalog, filters, source, idempotent save and no diary mutation")
    quit(0)
