extends SceneTree

const Barcode = preload("res://src/barcode_lookup.gd")
const Store = preload("res://src/store.gd")

func _initialize() -> void:
    call_deferred("_test")

func _fail(message: String) -> void:
    push_error("FAILED PRODUCT SEARCH 0.7.42: " + message)
    quit(1)

func _find_button(node: Node, label_text: String) -> Button:
    if node == null:
        return null
    if node is Button and node.text == label_text:
        return node
    for child in node.get_children():
        var result: Button = _find_button(child, label_text)
        if result != null:
            return result
    return null

func _test() -> void:
    var healthy: Dictionary = {
        "name":"Злаковый батончик", "nutrition_unit":"г",
        "kcal":240.0, "p":10.0, "f":10.0, "c":27.0
    }
    if not Barcode.quality_flags(healthy).is_empty():
        _fail("good balanced 4/9/4 label wrongly warned")
        return
    var implausible: Dictionary = healthy.duplicate(true)
    implausible["p"] = 86.0
    if Barcode.quality_flags(implausible).is_empty() or \
            not Barcode.quality_message(implausible).contains("больше 100"):
        _fail("implausible macro sum not flagged")
        return
    var missing: Dictionary = healthy.duplicate(true)
    missing["f"] = -1.0
    if Barcode.quality_flags(missing).is_empty():
        _fail("missing fats not flagged")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    var offline: Dictionary = healthy.duplicate(true)
    offline.merge({
        "id":"barcode_3017624010701", "barcode":"3017624010701",
        "brand":"Пекарня тест", "quantity":"160 г", "source":"Пользователь"
    }, true)
    app.store.data["foods"].append(offline)
    app.store.data["entries"].append({
        "id":"last_serving","date":"2026-11-22", "food":offline["id"],
        "nutrition":offline.duplicate(true),"grams":160.0,"unit":"г",
        "meal":"Завтрак"
    })
    app.date = "2026-11-23"
    app.selected_meal = "Обед"
    app._meal_entry_locked = true
    app._meal_entry_date = "2026-11-23"
    app.tab = "search"
    app._render()
    await process_frame
    var search = app.find_child("FoodNameSearch", true, false) as LineEdit
    var mine = app.find_child("FoodFilter_3", true, false) as Button
    var results = app.find_child("FoodSearchResults", true, false) as VBoxContainer
    if search == null or mine == null or results == null:
        _fail("product search or my-products filter missing")
        return
    mine.pressed.emit()
    await process_frame
    search.text = "злаковый батончик"
    search.text_changed.emit(search.text)
    await process_frame
    var repeat = app.find_child("FoodRepeatLast_0", true, false) as Button
    if repeat == null or not repeat.text.contains("160"):
        _fail("search result lacks exact previous portion")
        return
    repeat.pressed.emit()
    await process_frame
    var added: Array = app.store.day_entries("2026-11-23")
    if added.size() != 1 or float(added[0]["grams"]) != 160.0 or \
            str(added[0]["meal"]) != "Обед":
        _fail("last portion shortcut lost selected day, meal or grams")
        return
    search.text = "3017624010701"
    search.text_changed.emit(search.text)
    await process_frame
    var online = app.find_child("OnlineFoodSearchButton", true, false) as Button
    var online_status = app.find_child("OnlineFoodSearchStatus", true, false) as Label
    if online == null or online.text != "Найти штрихкод" or online_status == null or \
            not online_status.text.contains("офлайн"):
        _fail("exact EAN/UPC was not detected in unified search field")
        return
    online.pressed.emit()
    await process_frame
    var sheet = app.get_node_or_null("ProductSheet")
    var favorite = sheet.find_child("QuickFavoriteToggle", true, false) as Button if sheet != null else null
    var measure = sheet.find_child("QuickPortionMeasure", true, false) as OptionButton if sheet != null else null
    if favorite == null or measure == null:
        _fail("known barcode did not open cached offline portion chooser")
        return
    favorite.pressed.emit()
    if not app.store.is_favorite(str(offline["id"])):
        _fail("portion favorite shortcut did not persist")
        return
    sheet.queue_free()
    await process_frame
    var remote: Dictionary = {
        "barcode":"4006381333931", "name":"Новый товар с базы", "brand":"Тест",
        "quantity":"250 г", "source":"Open Food Facts",
        "nutrition_unit":"г", "unit_certainty":"quantity",
        "kcal":240.0, "p":10.0, "f":10.0, "c":27.0,
        "missing_fields":[]
    }
    app._show_online_search_results([offline, remote])
    var saved_label: Button = app.find_child("OnlineFoodChoose_3017624010701", true, false) as Button
    var choose = app.find_child("OnlineFoodChoose_4006381333931", true, false) as Button
    if saved_label == null or saved_label.text != "Порция" or \
            choose == null or choose.text != "Проверить":
        _fail("online results failed to distinguish offline and new products")
        return
    choose.pressed.emit()
    await process_frame
    sheet = app.get_node_or_null("ProductSheet")
    var protein = sheet.find_child("BarcodeNutrition_p", true, false) as LineEdit if sheet != null else null
    var quality = sheet.find_child("BarcodeLiveQuality", true, false) as Label if sheet != null else null
    var verified = sheet.find_child("BarcodeLabelConfirmed", true, false) as CheckBox if sheet != null else null
    var save_only = _find_button(sheet, "Сохранить без записи в дневник")
    if protein == null or quality == null or verified == null or save_only == null:
        _fail("barcode review lacks live quality indicators or offline-save action")
        return
    protein.text = "86"
    protein.text_changed.emit(protein.text)
    if not quality.visible or not verified.visible or \
            not quality.text.contains("100 г"):
        _fail("suspicious edited label did not show a warning")
        return
    save_only.pressed.emit()
    if not app.store.food_by_barcode("4006381333931").is_empty():
        _fail("unverified suspicious nutrients were saved automatically")
        return
    protein.text = "10"
    protein.text_changed.emit(protein.text)
    if quality.visible or verified.visible:
        _fail("valid corrected label still has mandatory warning")
        return
    save_only.pressed.emit()
    await process_frame
    var cached: Dictionary = app.store.food_by_barcode("4006381333931")
    if cached.is_empty() or str(cached.get("name", "")) != "Новый товар с базы":
        _fail("reviewed OFF product did not save for offline reuse")
        return
    if app.store.day_entries("2026-11-23").size() != 1:
        _fail("save-only inserted an unwanted diary portion")
        return
    var restored = Store.new()
    if restored.food_by_barcode("4006381333931").is_empty():
        _fail("saved offline barcode product did not survive restart")
        return
    app.queue_free()
    print("PASS PRODUCT SEARCH 0.7.42: united EAN, offline cache, my products, exact quick-repeat, favorite, live quality and safe save-only")
    quit(0)
