extends SceneTree
const Suggest = preload("res://src/recipe_suggest.gd")
const Catalog = preload("res://src/ready_recipes.gd")
const FailingStore = preload("res://tests/failing_store.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(message: String) -> void:
    push_error("RECIPE SUGGEST: " + message)
    quit(1)
func _run() -> void:
    var budget = Suggest.remaining(1800, 1350, {"p":100,"f":60}, {"p":70,"f":50})
    if budget != {"kcal":450.0,"p":30.0,"f":10.0}:
        _fail("explicit remaining goals")
        return
    var all = Catalog.all()
    var matches = Suggest.recommend(all, budget, 1.0)
    if matches.is_empty():
        _fail("no candidates for ordinary budget")
        return
    for item in matches:
        for key in budget:
            if float(item["portion"][key]) > float(budget[key]) + 0.00001:
                _fail("recommendation exceeds a configured goal")
                return
    if not Suggest.recommend(all, {"kcal":0}, 0.5).is_empty():
        _fail("zero budget must not invent a target")
        return
    var sample = {"id":"auto_test","name":"Тест","category":"mains","servings":2,"cooked_weight":400,
        "ingredients":[{"name":"Тест","grams":400,"kcal":200,"p":10,"f":5,"c":20}]}
    var auto = Suggest.recommend([sample], {"kcal":180,"p":8}, 0.0)
    if auto.size() != 1 or float(auto[0]["grams"]) != 80.0 or float(auto[0]["portion"]["kcal"]) != 160.0:
        _fail("auto portion must fit the strictest explicit target")
        return
    if not Suggest.recommend([sample], {"kcal":40}, 0.0).is_empty():
        _fail("auto mode must not suggest portions under 25 g")
        return
    var full = Suggest.recommend([sample], {"kcal":2000}, 0.0)
    if full.size() != 1 or float(full[0]["grams"]) != 200.0:
        _fail("auto portion must not exceed one normal serving")
        return
    if not Suggest.recommend([sample], {"kcal":500,"f":0}, 0.0).is_empty():
        _fail("auto mode must respect an exhausted configured macro")
        return
    var without_macros = Suggest.recommend(all, {"kcal":500}, 1.0, "soups")
    if without_macros.is_empty():
        _fail("optional macro goals or category")
        return
    for item in without_macros:
        if item["recipe"]["category"] != "soups":
            _fail("category not respected")
            return
    var failed = FailingStore.new()
    failed.data = failed.default_data()
    if failed.add_suggested_recipe_portion(Catalog.personal_copy(all[0]), 100, "Обед", "2026-11-24") or not failed.data["recipes"].is_empty() or not failed.data["entries"].is_empty():
        _fail("failed persistence left a recipe or entry")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-24"
    app.tab = "day"
    app._render()
    await process_frame
    var before = JSON.stringify(app.store.data)
    var button = app.find_child("DayRecipeSuggest", true, false) as Button
    if button == null:
        _fail("day entry point")
        return
    button.pressed.emit()
    await process_frame
    if app.find_child("SuggestResults", true, false) == null or JSON.stringify(app.store.data) != before:
        _fail("suggestions missing or mutated diary")
        return
    var portion_mode = app.find_child("SuggestPortion",true,false) as OptionButton
    if portion_mode == null or portion_mode.item_count != 5:
        _fail("auto portion mode missing")
        return
    portion_mode.select(4)
    portion_mode.item_selected.emit(4)
    await process_frame
    if JSON.stringify(app.store.data) != before:
        _fail("auto portion selection mutated diary")
        return
    var results = app.find_child("SuggestResults",true,false)
    var choice: Button = null
    for child in results.get_children():
        if child is PanelContainer:
            for node in child.find_children("SuggestChoose_*", "Button", true, false):
                choice = node
                break
        if choice != null:
            break
    if choice == null:
        _fail("no portion selection")
        return
    choice.pressed.emit()
    await process_frame
    await process_frame
    if app.find_child("RecipeServingWeight",true,false) == null or JSON.stringify(app.store.data) != before:
        _fail("selection should not persist before confirmation")
        return
    var confirm = app.find_child("ProductSheetConfirm",true,false) as Button
    confirm.pressed.emit()
    await process_frame
    if app.store.data["entries"].size() != 1 or app.store.data["recipes"].size() != 1 or app.store.data["entries"][0]["date"] != "2026-11-24":
        _fail("confirmed diary portion or date")
        return
    print("PASS RECIPE SUGGEST: explicit goals, optional macros, category, no mutation before confirm, atomic rollback and dated portion")
    app.queue_free()
    quit(0)
