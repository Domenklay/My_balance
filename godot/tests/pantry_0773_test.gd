extends SceneTree
const Pantry = preload("res://src/pantry_math.gd")
const Store = preload("res://src/store.gd")
const FailStore = preload("res://tests/failing_store.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("PANTRY: " + reason)
    quit(1)
func _run() -> void:
    var recipe = {"id":"fixture","name":"Омлет","category":"breakfast","cooked_weight":150,"servings":1,"ingredients":[{"name":"Яйцо без скорлупы","grams":100,"kcal":143,"p":12,"f":9,"c":1},{"name":"Молоко 2,5%","grams":50,"kcal":52,"p":3,"f":2.5,"c":4}]}
    if not Pantry.matches([recipe],["ЯЙЦА","молоко 2,5%"],0).size() == 1 or not Pantry.matches([recipe],["яйца"],0).is_empty():
        _fail("exact and alias matching")
        return
    var near = Pantry.matches([recipe],["яйца"],2)
    if near.size() != 1 or near[0]["missing"] != ["Молоко 2,5%"]:
        _fail("missing ingredients")
        return
    if not Pantry.matches([recipe],["яйца вареные"],2).is_empty() or not Pantry.matches([recipe],[],2).is_empty():
        _fail("false match or empty pantry")
        return
    var s = Store.new()
    s.data = s.default_data()
    if not s.add_pantry_names(["Яйца","яйцо","рис"]) or s.pantry_list().size() != 2 or not s.add_pantry_names(near[0]["missing"],"pantry_shopping"):
        _fail("persist lists")
        return
    var restored = Store.new()
    if restored.pantry_list().size() != 2 or restored.pantry_list("pantry_shopping") != ["Молоко 2,5%"]:
        _fail("restart")
        return
    var legacy = restored.data.duplicate(true)
    legacy.erase("pantry_items")
    legacy.erase("pantry_shopping")
    if not restored.import_json(JSON.stringify(legacy)) or not restored.pantry_list().is_empty():
        _fail("legacy migration")
        return
    var bad = FailStore.new()
    bad.data = bad.default_data()
    if bad.add_pantry_names(["яблоко"]) or not bad.pantry_list().is_empty():
        _fail("rollback")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.store.data["recipes"] = [recipe]
    app.tab = "recipes"
    app.ready_recipes_open = false
    app._render()
    await process_frame
    (app.find_child("PersonalRecipePantry",true,false) as Button).pressed.emit()
    await process_frame
    var input = app.find_child("PantryInput",true,false) as LineEdit
    input.text = "яйца"
    (app.find_child("PantryAdd",true,false) as Button).pressed.emit()
    await process_frame
    var buy = app.find_child("PantryBuy_fixture",true,false) as Button
    if buy == null:
        _fail("UI missing ingredients")
        return
    buy.pressed.emit()
    if app.store.pantry_list("pantry_shopping") != ["Молоко 2,5%"] or not app.store.data["entries"].is_empty():
        _fail("shopping action or premature diary entry")
        return
    print("PASS PANTRY: exact aliases, missing items, offline shopping, migration, rollback and UI")
    app.queue_free()
    quit(0)
