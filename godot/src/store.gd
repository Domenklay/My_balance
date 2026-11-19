extends RefCounted

const DATA_PATH = "user://my_balance.json"
const BACKUP_PATH = "user://my_balance.previous.json"
const TEMP_PATH = "user://my_balance.pending.json"
const OFFLINE_CATALOG_PATH = "res://data/barcode_catalog.json"
const UPDATE_CATALOG_PATH = "user://barcode_catalog_verified.json"
const BarcodeScript = preload("res://src/barcode_lookup.gd")
const RecipeMath = preload("res://src/recipe_math.gd")

const DEFAULT_PRODUCTS = [
    ["Овсяные хлопья (сухие)",370,13,7,62],
    ["Молоко 2%",50,3.2,2,4.8],
    ["Банан",89,1.1,0.3,23],
    ["Яблоко",52,0.3,0.2,14],
    ["Ягоды",45,0.8,0.3,10],
    ["Огурцы",15,0.7,0.1,3.6],
    ["Помидоры",18,0.9,0.2,3.9],
    ["Овощи",35,2,0.5,6],
    ["Картофель варёный",82,2,0.1,19],
    ["Гречка варёная",110,4,1,21],
    ["Рис варёный",130,2.7,0.3,28],
    ["Макароны варёные",155,5.8,0.9,31],
    ["Куриная грудка готовая",165,31,3.6,0],
    ["Индейка готовая",150,29,3.5,0],
    ["Треска готовая",105,23,0.9,0],
    ["Лосось готовый",206,22,12,0],
    ["Яйцо",143,13,10,1],
    ["Творог 5%",121,17,5,2],
    ["Скир натуральный",62,11,0.2,4],
    ["Йогурт 2%",65,5,2,6],
    ["Цельнозерновой хлеб",235,9,3.5,43],
    ["Оливковое масло",884,0,100,0],
    ["Молочный шоколад",535,7,30,59],
    ["Печенье",460,6,18,68],
    ["Сладкая булочка",340,7,11,54],
    ["Шоколадные конфеты",500,6,28,59]
]

var data: Dictionary = {}
var bundled_foods: Array = []

func _init() -> void:
    _load_bundled_foods()
    data = default_data()
    if FileAccess.file_exists(DATA_PATH):
        var content = FileAccess.get_file_as_string(DATA_PATH)
        if not import_json(content, false) and FileAccess.file_exists(BACKUP_PATH):
            import_json(FileAccess.get_file_as_string(BACKUP_PATH), false)

func _load_bundled_foods() -> void:
    bundled_foods.clear()
    if FileAccess.file_exists(UPDATE_CATALOG_PATH):
        var update = FileAccess.get_file_as_string(UPDATE_CATALOG_PATH)
        if _set_bundled_catalog(update):
            return
        push_warning("Обновление каталога повреждено, используется встроенная база.")
    if FileAccess.file_exists(OFFLINE_CATALOG_PATH):
        if not _set_bundled_catalog(FileAccess.get_file_as_string(OFFLINE_CATALOG_PATH)):
            push_warning("Встроенный офлайн-каталог штрихкодов повреждён")

func _set_bundled_catalog(raw: String) -> bool:
    var parsed = JSON.parse_string(raw)
    if not (parsed is Dictionary and parsed.get("products") is Array):
        return false
    if str(parsed.get("source", "")) != "Open Food Facts":
        return false
    var entries: Array = parsed["products"]
    if entries.size() < 30 or entries.size() > 15000:
        return false
    var candidate: Array = []
    var existing = {}
    for item in entries:
        if not (item is Dictionary):
            return false
        var code = str(item.get("barcode", ""))
        if not _is_barcode(code) or existing.has(code):
            return false
        if str(item.get("name", "")).strip_edges().is_empty():
            return false
        var valid = true
        for nutrient in ["kcal", "p", "f", "c"]:
            var amount = item.get(nutrient)
            if not (amount is int or amount is float):
                valid = false
                break
            if not is_finite(float(amount)) or float(amount) < 0.0 or float(amount) > (1000.0 if nutrient == "kcal" else 100.0):
                valid = false
                break
        if not valid:
            return false
        if not BarcodeScript.nutrition_warning(item).is_empty():
            return false
        existing[code] = true
        candidate.append(item)
    bundled_foods = candidate
    return true

func update_catalog_json(raw: String) -> bool:
    if raw.length() > 4000000 or raw.length() < 100:
        return false
    var previous: Array = bundled_foods.duplicate(true)
    if not _set_bundled_catalog(raw):
        bundled_foods = previous
        return false
    var file = FileAccess.open(UPDATE_CATALOG_PATH, FileAccess.WRITE)
    if file == null:
        bundled_foods = previous
        return false
    file.store_string(raw)
    file.flush()
    var result = file.get_error()
    file.close()
    if result != OK:
        bundled_foods = previous
        return false
    return true

func _is_barcode(code: String) -> bool:
    return not BarcodeScript.normalize_code(code).is_empty()

func default_data() -> Dictionary:
    return {
        "settings": {"kcal": 1800, "start": 88.0, "goal": 65.0, "theme": "forest", "patterns": true},
        "foods": [], "entries": [], "activities": [], "weights": [], "notes": {}, "favorites": [],
        "recipes": [], "profile": {"name": "Мой профиль", "avatar": "leaf", "motto": "Маленькие шаги — большой результат"}
    }

func save() -> bool:
    var serialized = JSON.stringify(data)
    var tmp = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
    if tmp == null:
        push_error("Не удалось создать временную копию дневника")
        return false
    tmp.store_string(serialized)
    tmp.flush()
    var write_error = tmp.get_error()
    tmp.close()
    if write_error != OK:
        push_error("Ошибка записи временной копии дневника")
        return false
    # Copy the last complete file first; keep it if replacing the active file fails.
    if FileAccess.file_exists(DATA_PATH):
        var previous_text = FileAccess.get_file_as_string(DATA_PATH)
        var previous = JSON.parse_string(previous_text)
        if previous is Dictionary:
            var backup_status = DirAccess.copy_absolute(DATA_PATH, BACKUP_PATH)
            if backup_status != OK:
                push_warning("Не удалось обновить аварийную копию дневника")
    var status = DirAccess.rename_absolute(TEMP_PATH, DATA_PATH)
    if status != OK:
        push_error("Не удалось заменить файл дневника: " + str(status))
        return false
    return true

func _valid_profile(profile: Dictionary) -> bool:
    var name = profile.get("name")
    var motto = profile.get("motto")
    var avatar = profile.get("avatar")
    if not (name is String and motto is String and avatar is String):
        return false
    if name.strip_edges().is_empty() or name.length() > 45 or motto.length() > 140:
        return false
    return avatar in ["leaf", "star", "moon", "sun", "flower", "heart"]

func update_profile(changes: Dictionary) -> bool:
    if not _valid_profile(changes):
        return false
    var previous = data["profile"].duplicate(true)
    data["profile"] = changes.duplicate(true)
    if save():
        return true
    data["profile"] = previous
    return false

func recipe_by_id(recipe_id: String) -> Dictionary:
    for recipe in data.get("recipes", []):
        if recipe is Dictionary and str(recipe.get("id", "")) == recipe_id:
            return recipe
    return {}

func save_recipe(recipe_data: Dictionary) -> String:
    var recipe = recipe_data.duplicate(true)
    var recipe_id = str(recipe.get("id", "")).strip_edges()
    if recipe_id.is_empty():
        recipe_id = "r" + str(Time.get_ticks_usec()) + "_" + str(data["recipes"].size())
    recipe["id"] = recipe_id
    if not RecipeMath.validate_recipe(recipe):
        return ""
    var recipes: Array = data["recipes"]
    var index = -1
    for i in range(recipes.size()):
        if str(recipes[i].get("id", "")) == recipe_id:
            index = i
            break
    if index < 0 and recipes.size() >= 300:
        return ""
    if index >= 0:
        var previous = recipes[index].duplicate(true)
        recipes[index] = recipe
        if save():
            return recipe_id
        recipes[index] = previous
        return ""
    recipes.append(recipe)
    if save():
        return recipe_id
    recipes.erase(recipe)
    return ""

func delete_recipe(recipe_id: String) -> bool:
    var recipes: Array = data["recipes"]
    for i in range(recipes.size()):
        if str(recipes[i].get("id", "")) == recipe_id:
            var removed = recipes[i]
            recipes.remove_at(i)
            if save():
                return true
            recipes.insert(i, removed)
            return false
    return false

func add_recipe_portion(recipe_id: String, grams: float, meal: String, day: String) -> bool:
    if not is_finite(grams) or grams <= 0.0 or grams > 5000.0:
        return false
    if meal not in ["Завтрак", "Обед", "Перекус", "Ужин"]:
        return false
    var recipe = recipe_by_id(recipe_id)
    if recipe.is_empty():
        return false
    var metrics = RecipeMath.calculate(recipe["ingredients"], float(recipe["cooked_weight"]))
    if metrics.is_empty():
        return false
    var nutrition = {"name": str(recipe["name"])}
    for field in RecipeMath.NUTRIENTS:
        nutrition[field] = float(metrics[field])
    var entry = {
        "id": "recipe_" + str(Time.get_ticks_usec()) + "_" + str(data["entries"].size()),
        "date": day, "food": "recipe:" + recipe_id, "recipe_id": recipe_id,
        "nutrition": nutrition,
        "grams": grams, "meal": meal
    }
    data["entries"].append(entry)
    if save():
        return true
    data["entries"].erase(entry)
    return false

func import_json(raw: String, persist: bool = true) -> bool:
    var obj = JSON.parse_string(raw)
    if not (obj is Dictionary):
        return false
    for key in ["settings", "foods", "entries", "activities", "weights", "notes"]:
        if not obj.has(key):
            if key == "activities":
                obj[key] = []
            elif key == "notes":
                obj[key] = {}
            else:
                return false
    # Favorites were introduced in 0.5.3; older exports have no such field.
    if not obj.has("recipes"):
        obj["recipes"] = []
    if not obj.has("profile"):
        obj["profile"] = {"name": "Мой профиль", "avatar": "leaf", "motto": "Маленькие шаги — большой результат"}
    if not obj.has("favorites"):
        obj["favorites"] = []
    if not (obj["favorites"] is Array) or obj["favorites"].size() > 500:
        return false
    for id in obj["favorites"]:
        if not (id is String) or id.length() > 100:
            return false
    if not (obj["settings"] is Dictionary and obj["foods"] is Array and obj["entries"] is Array and obj["activities"] is Array and obj["weights"] is Array and obj["notes"] is Dictionary):
        return false
    if not (obj["recipes"] is Array and obj["profile"] is Dictionary) or obj["recipes"].size() > 300:
        return false
    var profile: Dictionary = obj["profile"]
    if not _valid_profile(profile):
        return false
    var ids = {}
    for saved_recipe in obj["recipes"]:
        if not RecipeMath.validate_recipe(saved_recipe):
            return false
        var recipe_id = str(saved_recipe["id"])
        if ids.has(recipe_id):
            return false
        ids[recipe_id] = true
    var settings: Dictionary = obj["settings"]
    if not (settings.has("kcal") and settings.has("start") and settings.has("goal")):
        return false
    for name in ["kcal", "start", "goal"]:
        if not (settings[name] is float or settings[name] is int):
            return false
    if float(settings["kcal"]) < 1000.0 or float(settings["kcal"]) > 5000.0:
        return false
    if float(settings["start"]) < 20.0 or float(settings["start"]) > 400.0:
        return false
    if float(settings["goal"]) < 20.0 or float(settings["goal"]) > 400.0:
        return false
    # Older diary backups predate appearance controls; import them unchanged
    # and fill in safe defaults. Unknown themes are never applied.
    if not settings.has("theme"):
        settings["theme"] = "forest"
    if not (settings["theme"] is String) or str(settings["theme"]) not in ["forest", "mint", "sand", "dark"]:
        return false
    if not settings.has("patterns"):
        settings["patterns"] = true
    if not (settings["patterns"] is bool):
        return false
    if obj["foods"].size() > 10000 or obj["entries"].size() > 50000 or obj["weights"].size() > 5000 or obj["activities"].size() > 50000:
        return false
    for entry in obj["entries"]:
        if not (entry is Dictionary):
            return false
        var grams = entry.get("grams", 0)
        if not (grams is float or grams is int):
            return false
        if float(grams) <= 0.0 or float(grams) > 5000.0:
            return false
    var original_data = data
    data = obj
    if persist and not save():
        data = original_data
        return false
    return true

func export_json() -> String:
    return JSON.stringify(data, "\t")

func all_foods() -> Array:
    var result = []
    for i in range(DEFAULT_PRODUCTS.size()):
        var f: Array = DEFAULT_PRODUCTS[i]
        result.append({"id": "d" + str(i), "name": f[0], "kcal": f[1], "p": f[2], "f": f[3], "c": f[4]})
    var replaced_barcodes = {}
    for f in data["foods"]:
        if f is Dictionary and not str(f.get("barcode", "")).is_empty():
            replaced_barcodes[str(f["barcode"])] = true
    for item in bundled_foods:
        if not replaced_barcodes.has(str(item.get("barcode", ""))):
            result.append(item)
    for f in data["foods"]:
        if f is Dictionary:
            result.append(f)
    return result

func food_by_barcode(code: String) -> Dictionary:
    if not _is_barcode(code):
        return {}
    for item in data["foods"]:
        if item is Dictionary and str(item.get("barcode", "")) == code:
            return item
    for item in bundled_foods:
        if str(item.get("barcode", "")) == code:
            return item
    return {}

func link_barcode_to_food(food_id: String, code: String) -> bool:
    if not _is_barcode(code):
        return false
    for item in data["foods"]:
        if not (item is Dictionary) or str(item.get("id", "")) != food_id:
            continue
        var existing = food_by_barcode(code)
        if not existing.is_empty() and str(existing.get("id", "")) != food_id:
            # A local copy of an offline item can override it; do not silently
            # attach another barcode to an unrelated saved product.
            if str(existing.get("id", "")).begins_with("offline_"):
                pass
            else:
                return false
        var previous = str(item.get("barcode", ""))
        item["barcode"] = code
        if save():
            return true
        if previous.is_empty():
            item.erase("barcode")
        else:
            item["barcode"] = previous
        return false
    return false

func save_barcode_food(details: Dictionary) -> String:
    # Called after the user has reviewed the label and confirmed the product.
    # If its barcode exists locally, update that card rather than returning
    # stale nutrition silently. Preserve the ID used by favorites and diary.
    var barcode = str(details.get("barcode", ""))
    if not _is_barcode(barcode):
        return ""
    for field in ["name", "kcal", "p", "f", "c"]:
        if not details.has(field):
            return ""
    var name = str(details["name"]).strip_edges().substr(0, 160)
    if name.is_empty():
        return ""
    var nutrients = {}
    for field in ["kcal", "p", "f", "c"]:
        var value = details[field]
        if not (value is int or value is float) or not is_finite(float(value)):
            return ""
        var limit = 1000.0 if field == "kcal" else 100.0
        if float(value) < 0.0 or float(value) > limit:
            return ""
        nutrients[field] = float(value)
    for saved in data["foods"]:
        if not (saved is Dictionary) or str(saved.get("barcode", "")) != barcode:
            continue
        var previous: Dictionary = saved.duplicate(true)
        saved["name"] = name
        for field in ["kcal", "p", "f", "c"]:
            saved[field] = nutrients[field]
        saved["source"] = str(details.get("source", "Пользователь"))
        if save():
            return str(saved.get("id", ""))
        saved.clear()
        saved.merge(previous, true)
        return ""
    var item = {
        "id": "barcode_" + barcode,
        "barcode": barcode,
        "name": name,
        "kcal": nutrients["kcal"],
        "p": nutrients["p"],
        "f": nutrients["f"],
        "c": nutrients["c"],
        "source": str(details.get("source", "Пользователь"))
    }
    data["foods"].append(item)
    if not save():
        data["foods"].erase(item)
        return ""
    return str(item["id"])


func add_custom_food_without_barcode(food: Dictionary) -> bool:
    var name = str(food.get("name", "")).strip_edges()
    if name.is_empty() or name.length() > 160:
        return false
    var item = food.duplicate(true)
    item.erase("barcode")
    for field in ["kcal", "p", "f", "c"]:
        var value = item.get(field)
        if not (value is int or value is float) or not is_finite(float(value)):
            return false
        if float(value) < 0.0 or float(value) > (1000.0 if field == "kcal" else 100.0):
            return false
    item["name"] = name
    item["id"] = "u" + str(Time.get_ticks_usec()) + "_" + str(data["foods"].size())
    item["source"] = "Пользователь"
    data["foods"].append(item)
    if save():
        return true
    data["foods"].erase(item)
    return false

func delete_saved_record(collection: String, record: Dictionary) -> bool:
    if collection not in ["entries", "activities", "weights"] or not data.has(collection):
        return false
    var records: Array = data[collection]
    var index = records.find(record)
    if index < 0:
        return false
    records.remove_at(index)
    if save():
        return true
    records.insert(index, record)
    return false

func add_food_entry(food: Dictionary, grams: float, meal: String, day: String) -> bool:
    if food.is_empty() or grams <= 0.0 or grams > 5000.0:
        return false
    var entry = {
        "id": str(Time.get_ticks_usec()) + "_" + str(data["entries"].size()),
        "date": day,
        "food": str(food.get("id", "")),
        "nutrition": {
            "name": str(food.get("name", "")),
            "kcal": float(food.get("kcal", 0)),
            "p": float(food.get("p", 0)),
            "f": float(food.get("f", 0)),
            "c": float(food.get("c", 0))
        },
        "grams": grams,
        "meal": meal
    }
    data["entries"].append(entry)
    if not save():
        data["entries"].erase(entry)
        return false
    return true

func update_custom_food(id: String, changes: Dictionary) -> bool:
    var name = str(changes.get("name", "")).strip_edges()
    if name.is_empty() or name.length() > 160:
        return false
    var code = str(changes.get("barcode", "")).strip_edges()
    if not code.is_empty() and not _is_barcode(code):
        return false
    for nutrient in ["kcal", "p", "f", "c"]:
        var amount = changes.get(nutrient)
        if not (amount is float or amount is int) or not is_finite(float(amount)):
            return false
        if float(amount) < 0.0 or float(amount) > (1000.0 if nutrient == "kcal" else 100.0):
            return false
    for food in data["foods"]:
        if not (food is Dictionary):
            continue
        if str(food.get("id", "")) == id:
            continue
        if not code.is_empty() and str(food.get("barcode", "")) == code:
            return false
    for food in data["foods"]:
        if not (food is Dictionary) or str(food.get("id", "")) != id:
            continue
        var old = food.duplicate(true)
        for key in ["name", "kcal", "p", "f", "c"]:
            food[key] = changes[key]
        if code.is_empty():
            food.erase("barcode")
        else:
            food["barcode"] = code
        if save():
            return true
        food.clear()
        food.merge(old, true)
        return false
    return false

func delete_custom_food(id: String) -> bool:
    var found: Dictionary = {}
    for item in data["foods"]:
        if item is Dictionary and str(item.get("id", "")) == id:
            found = item
            break
    if found.is_empty():
        return false
    var original = data["foods"].duplicate(true)
    var previous_favorites = data["favorites"].duplicate()
    data["foods"].erase(found)
    data["favorites"].erase(id)
    if save():
        return true
    data["foods"] = original
    data["favorites"] = previous_favorites
    return false

func is_favorite(food_id: String) -> bool:
    return data.get("favorites", []).has(food_id)

func toggle_favorite(food_id: String) -> bool:
    if food_by_id(food_id).is_empty():
        return false
    var before: Array = data.get("favorites", []).duplicate()
    var favorites: Array = before.duplicate()
    if favorites.has(food_id):
        favorites.erase(food_id)
    else:
        favorites.append(food_id)
    data["favorites"] = favorites
    if save():
        return true
    data["favorites"] = before
    return false

func repeat_entry(entry: Dictionary, destination_date: String) -> bool:
    if not data["entries"].has(entry):
        return false
    var new_entry: Dictionary = entry.duplicate(true)
    new_entry["id"] = "repeat_" + str(Time.get_ticks_usec()) + "_" + str(data["entries"].size())
    new_entry["date"] = destination_date
    data["entries"].append(new_entry)
    if save():
        return true
    data["entries"].erase(new_entry)
    return false

func food_by_id(id: String) -> Dictionary:
    for f in all_foods():
        if str(f.get("id", "")) == id:
            return f
    return {}

func entry_food(entry: Dictionary) -> Dictionary:
    if entry.get("nutrition", null) is Dictionary:
        return entry["nutrition"]
    return food_by_id(str(entry.get("food", "")))

func entry_kcal(entry: Dictionary) -> float:
    var f = entry_food(entry)
    return float(f.get("kcal", 0)) * float(entry.get("grams", 0)) / 100.0

func day_entries(date: String) -> Array:
    return data["entries"].filter(func(e): return e is Dictionary and str(e.get("date", "")) == date)

func day_activities(date: String) -> Array:
    return data["activities"].filter(func(e): return e is Dictionary and str(e.get("date", "")) == date)

func day_calories(date: String) -> float:
    var total = 0.0
    for e in day_entries(date):
        total += entry_kcal(e)
    return total

func day_macro(date: String, name: String) -> float:
    var total = 0.0
    for e in day_entries(date):
        var f = entry_food(e)
        total += float(f.get(name, 0)) * float(e.get("grams", 0)) / 100.0
    return total

func change_date(date: String, days: int) -> String:
    var unix = Time.get_unix_time_from_datetime_string(date + "T12:00:00")
    return Time.get_date_string_from_unix_time(int(unix) + days * 86400)

func week_dates(date: String) -> Array:
    var weekday = int(Time.get_datetime_dict_from_datetime_string(date + "T12:00:00", true).get("weekday", 1))
    var monday = change_date(date, -((weekday + 6) % 7))
    var result = []
    for i in range(7):
        result.append(change_date(monday, i))
    return result
