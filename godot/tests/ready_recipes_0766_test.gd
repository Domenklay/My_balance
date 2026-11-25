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
    if ids.size() != 112:
        _fail("expected 112 unique offline recipes")
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
    if grid == null or grid.get_child_count() != 20:
        _fail("initial page must contain 20 entries")
        return
    var more = app.find_child("ReadyRecipeMore", true, false) as Button
    if more == null or not more.visible:
        _fail("missing pagination button")
        return
    more.pressed.emit()
    await process_frame
    if grid.get_child_count() != 40:
        _fail("next page did not append 20 entries")
        return
    var search = app.find_child("ReadyRecipeSearch", true, false) as LineEdit
    search.text = str(Catalog.all().back()["name"])
    search.text_changed.emit(search.text)
    await process_frame
    if grid.get_child_count() != 1 or app.find_child("ReadyRecipe_" + str(Catalog.all().back()["id"]), true, false) == null or more.visible:
        _fail("search must include recipes outside initial pages")
        return
    search.text = ""
    search.text_changed.emit("")
    await process_frame
    if grid.get_child_count() != 20:
        _fail("clearing search must reset pagination")
        return
    search.text = "шпинат курица"
    search.text_changed.emit(search.text)
    await process_frame
    if app.find_child("ReadyRecipe_catalog_chicken_spin_pasta",true,false) == null or app.find_child("ReadyRecipe_catalog_oats",true,false) != null:
        _fail("unordered multiword ingredient search")
        return
    search.text = ""
    search.text_changed.emit("")
    var sort = app.find_child("ReadyRecipeSort",true,false) as OptionButton
    if sort == null:
        _fail("sort menu missing")
        return
    sort.select(1)
    sort.item_selected.emit(1)
    await process_frame
    grid = app.find_child("ReadyRecipeGrid",true,false) as GridContainer
    var previous_kcal = -1.0
    for card in grid.get_children():
        var recipe_id = str(card.name).trim_prefix("ReadyRecipe_")
        for record in Catalog.all():
            if record["id"] == recipe_id:
                var metrics = Math.calculate(record["ingredients"],float(record["cooked_weight"]))
                var current = float(metrics["total_kcal"])/float(record["servings"])
                if current < previous_kcal:
                    _fail("calorie ordering incorrect")
                    return
                previous_kcal = current
                break
    sort = app.find_child("ReadyRecipeSort",true,false) as OptionButton
    sort.select(0)
    sort.item_selected.emit(0)
    await process_frame
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
