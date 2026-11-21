extends SceneTree

const Barcode = preload("res://src/barcode_lookup.gd")
const Store = preload("res://src/store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED BARCODE REVIEW 0.7.31: " + reason)
    quit(1)

func _find_button(node: Node, caption: String) -> Button:
    if node is Button and node.text == caption:
        return node
    for child in node.get_children():
        var result: Button = _find_button(child, caption)
        if result != null:
            return result
    return null

func _run() -> void:
    var safe = "https://images.openfoodfacts.org/images/products/301/762/401/0701/front_fr.200.jpg"
    if Barcode.safe_image_url(safe) != safe or \
            Barcode.safe_image_url("http://images.openfoodfacts.org/images/products/a.jpg") != "" or \
            Barcode.safe_image_url("https://evil.test/a.jpg") != "" or \
            Barcode.safe_image_url("https://images.openfoodfacts.org/redirect?target=https://evil.test") != "":
        _fail("untrusted URL passed the image CDN filter")
        return
    var payload = {"status":1, "product":{
        "product_name_ru":"Йогурт питьевой", "brands":"Тестовая марка",
        "quantity":"330 мл", "product_quantity_unit":"ml",
        "image_front_small_url":safe,
        "nutriments":{"energy-kcal_100g":93.0, "fat_100g":2.5,
            "carbohydrates_100g":11.0}
    }}
    var partial: Dictionary = Barcode.parse_product(payload, "3017624010701")
    if partial.has("error") or partial.get("missing_fields", []) != ["p"] or \
            float(partial.get("p", 0)) != -1.0 or \
            Barcode.package_amount(partial) != 330.0 or \
            str(partial.get("brand", "")) != "Тестовая марка" or \
            str(partial.get("image_url", "")) != safe or \
            not Barcode.needs_nutrition_review(partial):
        _fail("incomplete remote product lost its package, brand, image or missing nutrient")
        return
    if Barcode.package_amount({"quantity":"6 x 100 g","nutrition_unit":"г"}) != 0.0 or \
            Barcode.package_amount({"quantity":"1.5 kg","nutrition_unit":"г"}) != 1500.0 or \
            Barcode.package_amount({"quantity":"0,5 l","nutrition_unit":"мл"}) != 500.0 or \
            Barcode.package_amount({"quantity":"300 ml","nutrition_unit":"г"}) != 0.0:
        _fail("whole package calculation is ambiguous or uses the wrong unit")
        return
    var complete = payload.duplicate(true)
    complete["product"]["nutriments"]["proteins_100g"] = 4.2
    var complete_record = Barcode.parse_product(complete, "3017624010701")
    if not complete_record.get("missing_fields", []).is_empty() or \
            str(complete_record.get("quantity", "")) != "330 мл":
        _fail("complete product should not invent missing nutrients")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.date = "2026-11-21"
    app.tab = "day"
    var ui_product = partial.duplicate(true)
    ui_product["image_url"] = ""
    app._confirm_barcode_product(ui_product)
    await process_frame
    var sheet = app.get_node_or_null("ProductSheet")
    var brand = app.find_child("BarcodeProductBrand", true, false) as Label
    var package_label = app.find_child("BarcodeProductPackage", true, false) as Label
    var protein = app.find_child("BarcodeNutrition_p", true, false) as LineEdit
    var kcal = app.find_child("BarcodeNutrition_kcal", true, false) as LineEdit
    var confirmed = app.find_child("BarcodeLabelConfirmed", true, false) as CheckBox
    var amount = app.find_child("BarcodePortionAmount", true, false) as SpinBox
    var pack_button = app.find_child("BarcodePackagePortion", true, false) as Button
    var photo = app.find_child("BarcodeProductImage", true, false) as TextureRect
    var basis = app.find_child("BarcodeNutritionBasis", true, false) as OptionButton
    var status = app.find_child("BarcodeNutritionReviewStatus", true, false) as Label
    if sheet == null or brand == null or package_label == null or protein == null or \
            kcal == null or confirmed == null or amount == null or \
            pack_button == null or photo == null or basis == null or status == null:
        _fail("brand, package, image or nutrition editing controls missing")
        return
    if not protein.text.is_empty() or kcal.text.is_empty() or basis.selected != 1 or \
            not status.text.contains("КБЖУ неполные") or \
            not package_label.text.contains("330") or photo.texture == null:
        _fail("unknown nutrition was displayed as zero or package data missing")
        return
    pack_button.pressed.emit()
    await process_frame
    if absf(amount.value - 330.0) > 0.1:
        _fail("whole-package quantity shortcut did not work")
        return
    var confirm_button = app.find_child("ProductSheetConfirm", true, false) as Button
    confirm_button.pressed.emit()
    await process_frame
    if not app.store.data["foods"].is_empty() or not app.store.data["entries"].is_empty():
        _fail("unknown protein was saved as zero without input")
        return
    protein.text = "4,2"
    confirm_button.pressed.emit()
    await process_frame
    if not app.store.data["foods"].is_empty():
        _fail("source label confirmation was bypassed")
        return
    confirmed.button_pressed = true
    confirm_button.pressed.emit()
    await process_frame
    var saved = app.store.food_by_barcode("3017624010701")
    if saved.is_empty() or absf(float(saved.get("p", 0)) - 4.2) > 0.01 or \
            str(saved.get("nutrition_unit", "")) != "мл" or \
            str(saved.get("brand", "")) != "Тестовая марка" or \
            str(saved.get("quantity", "")) != "330 мл":
        _fail("manually completed OFF product was not saved correctly")
        return
    var entries = app.store.day_entries("2026-11-21")
    if entries.size() != 1 or absf(float(entries[0].get("grams", 0)) - 330.0) > 0.1:
        _fail("whole package was not recorded in the selected meal")
        return
    var store = Store.new()
    if store.food_by_barcode("3017624010701").is_empty():
        _fail("barcode metadata missing after data reload")
        return
    var malicious = partial.duplicate(true)
    malicious["image_url"] = "https://malicious.example/track.jpg"
    malicious["p"] = 4.2
    if store.save_barcode_food(malicious).is_empty() or \
            str(store.food_by_barcode("3017624010701").get("image_url", "")) != "":
        _fail("unsafe image address was persisted")
        return
    var manual = app._manual_barcode_product("3017624010701")
    if float(manual["kcal"]) != -1.0 or manual.get("missing_fields", []).size() != 4:
        _fail("manual fallback silently pre-fills missing data as zero")
        return
    print("PASS BARCODE 0.7.31: partial nutrients, label review, brand/package/photo, safe CDN, whole-pack portions, persistence")
    app.queue_free()
    quit(0)
