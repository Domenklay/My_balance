extends SceneTree

const Search = preload("res://src/food_search.gd")
const Barcode = preload("res://src/barcode_lookup.gd")
const Store = preload("res://src/store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED RUSSIAN SEARCH: " + reason)
    quit(1)

func _find_button(node: Node, label: String) -> Button:
    if node is Button and node.text == label:
        return node
    for child in node.get_children():
        var found: Button = _find_button(child, label)
        if found != null:
            return found
    return null

func _run() -> void:
    var sample = {
        "name": "Молоко Простоквашино 2,5%",
        "brand": "Простоквашино",
        "barcode": "4607053473544"
    }
    for query in ["молоко", "ПРОСТОКВАШИНО", "простоквашино молоко",
            "Prostokvashino", "ghjcnjrdfibyj", "4607053473544"]:
        if not Search.matches(sample, query):
            _fail("local lookup should accept: " + query)
            return
    if Search.matches(sample, "йогурт") or Search.matches(sample, "карамель"):
        _fail("local matcher returns unrelated products")
        return
    var url = Barcode.search_url("простоквашино")
    if not url.contains("search_terms=") or not url.contains("%D0%BF") or \
            not Barcode.search_url("a").is_empty():
        _fail("online query URL is malformed")
        return
    var response = {"products": [
        {
            "code": "4607053473544", "product_name_ru": "Молоко Простоквашино",
            "brands": "Простоквашино",
            "nutriments": {
                "energy-kcal_100g": 53.8,
                "proteins_100g": 2.9, "fat_100g": 2.5, "carbohydrates_100g": 4.7
            }
        },
        {
            "code": "4607053473544", "product_name": "Дублирующая запись",
            "nutriments": {"energy-kcal_100g": 50.0,
                "proteins_100g": 2, "fat_100g": 3, "carbohydrates_100g": 5}
        },
        {"code":"bad", "product_name":"Неверный код"},
        {"code":"4601674084714", "product_name":"Без БЖУ",
            "nutriments":{"energy-kcal_100g":110}}
    ]}
    var remote: Array = Barcode.parse_search_results(response)
    if remote.size() != 1 or str(remote[0]["barcode"]) != "4607053473544" or \
            absf(float(remote[0]["kcal"]) - 53.8) > 0.1 or \
            str(remote[0]["brand"]) != "Простоквашино":
        _fail("online results were not checked/deduplicated")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.tab = "search"
    app._render()
    await process_frame
    var field = app.find_child("FoodNameSearch", true, false) as LineEdit
    var online_status = app.find_child("OnlineFoodSearchStatus", true, false) as Label
    var results = app.find_child("OnlineFoodSearchResults", true, false) as VBoxContainer
    if field == null or online_status == null or results == null or \
            _find_button(app, "Найти в интернете") == null:
        _fail("online search fields are missing from catalog")
        return
    if field.get_parent().get_child(2) != field:
        _fail("name search must remain near top of catalog")
        return
    app._show_online_search_results(remote)
    await process_frame
    if not results.visible or _find_button(results, "Выбрать") == null:
        _fail("validated products not shown with choose button")
        return
    field.text = "йогурт"
    field.text_changed.emit(field.text)
    await process_frame
    if results.visible:
        _fail("stale online search results were not hidden")
        return
    var offline = Store.new()
    if offline.bundled_foods.size() < 150:
        _fail("original verified offline catalog has been lost")
        return
    print("PASS RUSSIAN SEARCH: Russian, transliteration, keyboard layout, remote parse, UI and offline safety")
    app.queue_free()
    quit(0)
