extends SceneTree
const Ocr = preload("res://src/label_ocr.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("LABEL OCR: " + reason)
    quit(1)
func _run() -> void:
    var parsed = Ocr.parse("На 100 г\nЭнергетическая ценность 837 кДж / 200 ккал\nБелки 10,5 г\nЖиры 8 г\nУглеводы 20 г\nиз них сахара 5 г")
    if parsed.get("kcal") != 200.0 or parsed.get("p") != 10.5 or parsed.get("f") != 8.0 or parsed.get("c") != 20.0:
        _fail("Russian decimal and energy parsing " + str(parsed))
        return
    var polish = Ocr.parse("w 100 ml\nWartość energetyczna 418 kJ\nTłuszcz 2,5 g\nBiałko 4 g\nWęglowodany 10 g")
    if polish.get("nutrition_unit") != "мл" or absf(float(polish.get("kcal",0))-99.9)>0.2 or polish.get("f") != 2.5:
        _fail("Polish and kJ parsing")
        return
    if Ocr.parse("per serving 50 g\nProtein 10 g").has("p") or Ocr.parse("100 g per serving\nFat 2 g 1 g").has("f") or Ocr.parse("100 g\nFat <0.5 g").has("f") or Ocr.parse("100 g\nFat 1 g\nFat 2 g").has("f"):
        _fail("ambiguous data must stay blank")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-24"
    app._open_meal_catalog("Обед")
    await process_frame
    if app.find_child("FoodOcrLabel",true,false) == null:
        _fail("OCR entry point")
        return
    app._review_ocr_text("100 g\nEnergy 200 kcal\nProtein 10 g\nFat 8 g\nCarbohydrate 22 g")
    await process_frame
    var name = app.find_child("BarcodeProductName",true,false) as LineEdit
    var check = app.find_child("BarcodeLabelConfirmed",true,false) as CheckBox
    var confirm = app.find_child("ProductSheetConfirm",true,false) as Button
    name.text = "OCR test"
    if not check.visible or check.button_pressed:
        _fail("review must be explicit")
        return
    confirm.pressed.emit()
    await process_frame
    if not app.store.data["foods"].is_empty():
        _fail("unconfirmed OCR persisted")
        return
    check.button_pressed = true
    confirm.pressed.emit()
    await process_frame
    if app.store.data["foods"].size()!=1 or app.store.day_entries("2026-11-24").size()!=1 or app.store.data["entries"][0]["meal"]!="Обед" or absf(app.store.day_calories("2026-11-24")-200)>0.01:
        _fail("reviewed product without barcode not saved correctly")
        return
    print("PASS LABEL OCR: Russian Polish English parsing, ambiguity, mandatory review, unbarcoded product and meal")
    app.queue_free()
    quit(0)
