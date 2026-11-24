extends SceneTree
const Macro = preload("res://src/macro_goals.gd")
const Store = preload("res://src/store.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("MACRO GOALS 0.7.60: " + reason)
    quit(1)

func _run() -> void:
    var s = Store.new()
    s.data = s.default_data()
    if not s.macro_targets().is_empty() or Macro.automatic(1800) != {"p":90,"f":60,"c":225}:
        _fail("default off or auto calculation")
        return
    var choice = {"mode":"auto","manual":{"p":110,"f":60,"c":205}}
    if not s.set_macro_goals(choice) or s.macro_targets()["p"] != 90 or not s.set_daily_calorie_goal(2000) or s.macro_targets()["p"] != 100:
        _fail("auto recalculation")
        return
    choice["mode"] = "manual"
    if not s.set_macro_goals(choice) or s.macro_targets()["p"] != 110 or not s.set_daily_calorie_goal(1800) or s.macro_targets()["c"] != 205:
        _fail("manual goals changed")
        return
    var saved = JSON.stringify(s.data)
    if s.set_macro_goals({"mode":"manual","manual":{"p":0,"f":60,"c":205}}) or JSON.stringify(s.data) != saved:
        _fail("invalid goals accepted")
        return
    var broken = FailingStore.new()
    broken.data = broken.default_data()
    if broken.set_macro_goals(choice) or not broken.macro_targets().is_empty():
        _fail("failed save not rolled back")
        return
    var legacy = s.data.duplicate(true)
    legacy["settings"].erase("macro_goals")
    if not s.import_json(JSON.stringify(legacy), false) or not s.macro_targets().is_empty():
        _fail("legacy migration")
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
    var open = app.find_child("EditDailyMacroGoals", true, false) as Button
    if open == null:
        _fail("editor missing")
        return
    open.pressed.emit()
    await process_frame
    var mode = app.find_child("MacroGoalMode", true, false) as OptionButton
    if mode == null:
        _fail("mode missing")
        return
    mode.select(1)
    mode.item_selected.emit(1)
    (app.find_child("MacroGoalSave", true, false) as Button).pressed.emit()
    await process_frame
    var bar = app.find_child("DayMacroTarget_p", true, false) as ProgressBar
    var amount = app.find_child("DayMacroAmount_p", true, false) as Label
    var remainder = app.find_child("DayMacroRemaining_p", true, false) as Label
    if bar == null or amount == null or remainder == null or not amount.text.contains("90") or not remainder.text.contains("90"):
        _fail("target display")
        return
    var water = app.find_child("DayWaterCard", true, false)
    var snack = app.find_child("DailyMeal_3", true, false)
    if water.get_index() != snack.get_index()+1:
        _fail("water location changed")
        return
    app.queue_free()
    print("PASS MACRO GOALS 0.7.60: opt-in, automatic and manual goals, rollback, migration, editor and remaining grams")
    quit(0)
