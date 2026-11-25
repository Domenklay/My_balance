extends SceneTree

const Store = preload("res://src/store.gd")
const PlanMath = preload("res://src/meal_planner.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED WEEK PLANNER 0.7.50: " + reason)
    quit(1)

func _run() -> void:
    var monday: String = "2026-11-23"
    var tuesday: String = "2026-11-24"
    var store = Store.new()
    store.data = store.default_data()
    store.data["notes"][monday] = "Существующая заметка"
    var recipe: Dictionary = {
        "id":"r_planner", "name":"Овсяная каша",
        "cooked_weight":500.0, "servings":2,
        "ingredients":[
            {"name":"Овсяные хлопья (сухие)", "grams":200.0, "unit":"г",
                "kcal":370.0, "p":13.0, "f":7.0, "c":62.0},
            {"name":"Молоко", "grams":300.0, "unit":"мл",
                "kcal":50.0, "p":3.2, "f":2.0, "c":4.8}
        ]
    }
    if store.save_recipe(recipe).is_empty():
        _fail("cannot create original recipe")
        return
    var food: Dictionary = store.all_foods()[0]
    var food_id: String = str(food["id"])
    if not store.add_planned_meal("recipe", "r_planner", monday, "Завтрак", 250.0) or \
            not store.add_planned_meal("food", food_id, monday, "Перекус", 100.0) or \
            not store.add_planned_meal("recipe", "r_planner", tuesday, "Завтрак", 500.0):
        _fail("recipe and product portions did not save for the correct dates")
        return
    var monday_items: Array = store.planned_meals_on(monday)
    var tuesday_items: Array = store.planned_meals_on(tuesday)
    if monday_items.size() != 2 or tuesday_items.size() != 1 or \
            monday_items[0]["source"] != "recipe":
        _fail("weekly meal and date isolation broken")
        return
    var calories: float = store.planned_day_kcal(monday)
    if absf(calories - (445.0 + float(food["kcal"]))) > 0.01 or \
            store.day_entries(monday).size() != 0:
        _fail("planned Kcal wrong or plan improperly logged into actual diary")
        return
    var totals: Dictionary = PlanMath.nutrition_totals(monday_items)
    if not is_equal_approx(float(totals["kcal"]), calories) or absf(float(totals["p"]) - (17.8 + float(food["p"]))) > 0.01:
        _fail("planned nutrition summary does not reflect serving sizes")
        return
    var shopping: Array = store.week_planned_shopping(monday)
    if shopping.size() < 2:
        _fail("ingredient shopping list did not merge same ingredient")
        return
    var oats: Dictionary = {}
    var milk: Dictionary = {}
    for element in shopping:
        if str(element["name"]) == "Овсяные хлопья (сухие)":
            oats = element
        elif str(element["name"]) == "Молоко":
            milk = element
    var expected_oats: float = 300.0
    var expected_milk: float = 450.0
    # The additional standalone food can share a name with one of the
    # recipe ingredients, and must then contribute to grocery totals too.
    if str(food["name"]).strip_edges().to_lower() == "овсяные хлопья (сухие)" and \
            str(food.get("unit", "г")) == "г":
        expected_oats += 100.0
    if str(food["name"]).strip_edges().to_lower() == "молоко" and \
            str(food.get("unit", "г")) == "мл":
        expected_milk += 100.0
    if oats.is_empty() or milk.is_empty() or \
            absf(float(oats["grams"]) - expected_oats) > 0.01 or \
            absf(float(milk["grams"]) - expected_milk) > 0.01 or \
            oats["unit"] != "г" or milk["unit"] != "мл":
        _fail("raw ingredients did not aggregate by name/unit: " + JSON.stringify(shopping))
        return
    var key: String = str(milk["key"])
    if not store.toggle_shopping_item(monday, key) or \
            store.week_planned_shopping(monday).filter(
                func(item): return item["key"] == key and item["bought"]).size() != 1:
        _fail("shopping checklist not saved")
        return
    var checked_list: Array = store.week_planned_shopping(monday)
    if PlanMath.filter_shopping(checked_list, 2).size() != 1 or PlanMath.filter_shopping(checked_list, 1).size() != checked_list.size() - 1:
        _fail("shopping filter does not respect checked status")
        return
    var copied: String = PlanMath.shopping_text(checked_list, ["Чай"])
    if copied.contains("Молоко —") or not copied.contains("Чай") or not copied.contains("Овсяные хлопья"):
        _fail("copied shopping list includes purchased items or omits remaining items")
        return
    if store.toggle_shopping_item(monday, "unknown|г"):
        _fail("shopping toggled an ingredient absent from the week")
        return
    var saved_recipe_snapshot: Dictionary = monday_items[0].duplicate(true)
    if not store.delete_recipe("r_planner") or \
            store.planned_meals_on(monday)[0] != saved_recipe_snapshot:
        _fail("editing/deleting recipe changed immutable planned nutrition snapshot")
        return
    if store.apply_planned_day(monday) != 2 or \
            store.apply_planned_day(monday) != 0 or \
            store.day_entries(monday).size() != 2 or \
            not is_equal_approx(store.day_calories(monday), calories):
        _fail("moving day to actual diary duplicated items or broke kcal")
        return
    if store.data["notes"][monday] != "Существующая заметка" or \
            store.day_entries(tuesday).size() != 0:
        _fail("moving planned day changed unrelated diary data")
        return
    if not store.delete_planned_meal(str(monday_items[1]["id"])) or \
            store.planned_meals_on(monday).size() != 1 or \
            store.day_entries(monday).size() != 2:
        _fail("removing planned product affected diary or wrong item")
        return
    var restarted = Store.new()
    if restarted.planned_meals_on(monday).size() != 1 or \
            restarted.data["shopping_checked"].is_empty():
        _fail("plan or checked groceries not persisted across app restart")
        return
    var backup = restarted.export_json()
    var imported = Store.new()
    imported.data = imported.default_data()
    if not imported.import_json(backup, false) or \
            imported.planned_meals_on(tuesday).size() != 1:
        _fail("full JSON backup import lost meal plans")
        return
    var old = imported.data.duplicate(true)
    old.erase("planned_meals")
    old.erase("shopping_checked")
    if not imported.import_json(JSON.stringify(old), false) or \
            not imported.data["planned_meals"].is_empty() or \
            imported.data["notes"][monday] != "Существующая заметка":
        _fail("legacy backup did not receive empty planner without losing diary")
        return
    var invalid = old.duplicate(true)
    invalid["planned_meals"] = [saved_recipe_snapshot.duplicate(true)]
    invalid["planned_meals"][0]["grams"] = -5.0
    if imported.import_json(JSON.stringify(invalid), false):
        _fail("invalid plan was accepted in backup")
        return
    invalid["planned_meals"] = [saved_recipe_snapshot, saved_recipe_snapshot]
    if imported.import_json(JSON.stringify(invalid), false):
        _fail("duplicate plan ids were accepted in backup")
        return
    invalid["planned_meals"] = []
    invalid["shopping_checked"] = {monday: ["duplicate", "duplicate"]}
    if imported.import_json(JSON.stringify(invalid), false):
        _fail("invalid shopping checklist was accepted in backup")
        return
    var broken = FailingStore.new()
    broken.data = store.data.duplicate(true)
    var previous = JSON.stringify(broken.data)
    if broken.add_planned_meal("food", food_id, monday, "Ужин", 100.0) or \
            broken.toggle_shopping_item(monday, key) or \
            broken.apply_planned_day(tuesday) != 0 or \
            JSON.stringify(broken.data) != previous:
        _fail("failed storage writes did not revert plan and shopping")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = monday
    app.store.data["recipes"].append(recipe.duplicate(true))
    app.tab = "day"
    app._render()
    await process_frame
    if app.tab_buttons.size() != 5 or app.find_child("DayOpenPlanner", true, false) == null:
        _fail("five-tab day navigation or planner entry missing")
        return
    (app.find_child("DayOpenPlanner", true, false) as Button).pressed.emit()
    await process_frame
    if app.tab != "planner" or app.find_child("PlannerWeekDates", true, false) == null or \
            app.find_child("PlannerAddRecipe", true, false) == null or \
            app.find_child("PlannerShoppingCount", true, false) == null:
        _fail("weekly planner screen missing buttons or shopping section")
        return
    (app.find_child("PlannerAddRecipe", true, false) as Button).pressed.emit()
    await process_frame
    var picker = app.find_child("PlannerSourcePicker", true, false) as OptionButton
    var portion = app.find_child("PlannerPortion", true, false) as SpinBox
    var meal = app.find_child("PlannerMeal", true, false) as OptionButton
    var confirm = app.find_child("PlannerConfirmAdd", true, false) as Button
    if picker == null or picker.item_count == 0 or \
            portion == null or meal == null or confirm == null:
        _fail("planner search/serving modal missing")
        return
    portion.value = 250.0
    meal.select(0)
    confirm.pressed.emit()
    await process_frame
    if app.store.planned_meals_on(monday).size() != 1 or \
            app.find_child("PlannerApplyDay", true, false) == null or \
            app.find_child("PlannerBuy_0", true, false) == null:
        _fail("planner form did not create day plan and shopping list")
        return
    var macro_label = app.find_child("PlannerDayMacros", true, false) as Label
    var remaining_label = app.find_child("PlannerRemainingCalories", true, false) as Label
    if macro_label == null or not macro_label.text.contains("17.8") or remaining_label == null or app.find_child("PlannerCopyShopping", true, false) == null:
        _fail("new nutrition summary or shopping copy missing")
        return
    (app.find_child("PlannerBuy_0", true, false) as Button).pressed.emit()
    await process_frame
    var filter = app.find_child("PlannerShoppingFilter", true, false) as OptionButton
    filter.select(2)
    filter.item_selected.emit(2)
    await process_frame
    if app.find_child("PlannerBuy_0", true, false) == null or app.find_child("PlannerBuy_1", true, false) != null:
        _fail("purchased-only UI filter failed")
        return
    if app.store.data["shopping_checked"].is_empty():
        _fail("shopping checklist tap does not persist")
        return
    (app.find_child("PlannerApplyDay", true, false) as Button).pressed.emit()
    await process_frame
    var confirm_dialog: ConfirmationDialog = null
    for node in app.get_children():
        if node is ConfirmationDialog:
            confirm_dialog = node
            break
    if confirm_dialog == null:
        _fail("day transfer is missing confirmation")
        return
    confirm_dialog.confirmed.emit()
    await process_frame
    if app.store.day_entries(monday).size() != 1 or \
            app.find_child("PlannerApplyDay", true, false) != null:
        _fail("confirmed day transfer not recorded or allows duplicates")
        return
    (app.find_child("PlannerNextWeek", true, false) as Button).pressed.emit()
    await process_frame
    if app.planner_day != "2026-11-30" or \
            app.store.planned_meals_on(monday).size() != 1:
        _fail("week navigation modified saved plan")
        return
    app.queue_free()
    print("PASS WEEK PLANNER 0.7.50: recipe/product portions, grocery sums, checks, one-time day transfer, legacy backup, rollback and UI")
    quit(0)
