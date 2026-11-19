extends RefCounted

const DATA_PATH = "user://my_balance.json"
const BACKUP_PATH = "user://my_balance.previous.json"
const TEMP_PATH = "user://my_balance.pending.json"
const OFFLINE_CATALOG_PATH = "res://data/barcode_catalog.json"

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

func _load_bundled_foods() -> void:
    bundled_foods.clear()
    if not FileAccess.file_exists(OFFLINE_CATALOG_PATH):
        return
    var parsed = JSON.parse_string(FileAccess.get_file_as_string(OFFLINE_CATALOG_PATH))
    if not (parsed is Dictionary) or not (parsed.get("products") is Array):
        push_warning("Офлайн-каталог штрихкодов повреждён")
        return
    for item in parsed["products"]:
        if not (item is Dictionary):
            continue
        var code = str(item.get("barcode", ""))
        if not _is_barcode(code) or not item.has("name"):
            continue
        if str(item["name"]).strip_edges().is_empty():
            continue
        var valid = true
        for nutrient in ["kcal", "p", "f", "c"]:
            if not (item.get(nutrient) is int or item.get(nutrient) is float):
                valid = false
                break
        if valid:
            bundled_foods.append(item)

func _is_barcode(code: String) -> bool:
    if code.length() < 8 or code.length() > 14:
        return false
    for i in range(code.length()):
        var digit = code.unicode_at(i)
        if digit < 48 or digit > 57:
            return false
    return true
    if FileAccess.file_exists(DATA_PATH):
        var content = FileAccess.get_file_as_string(DATA_PATH)
        if not import_json(content, false) and FileAccess.file_exists(BACKUP_PATH):
            import_json(FileAccess.get_file_as_string(BACKUP_PATH), false)

func default_data() -> Dictionary:
    return {
        "settings": {"kcal": 1800, "start": 88.0, "goal": 65.0},
        "foods": [], "entries": [], "activities": [], "weights": [], "notes": {}, "favorites": []
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
    if not obj.has("favorites"):
        obj["favorites"] = []
    if not (obj["favorites"] is Array) or obj["favorites"].size() > 500:
        return false
    for id in obj["favorites"]:
        if not (id is String) or id.length() > 100:
            return false
    if not (obj["settings"] is Dictionary and obj["foods"] is Array and obj["entries"] is Array and obj["activities"] is Array and obj["weights"] is Array and obj["notes"] is Dictionary):
        return false
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
    var barcode = str(details.get("barcode", ""))
    if not _is_barcode(barcode):
        return ""
    for field in ["name", "kcal", "p", "f", "c"]:
        if not details.has(field):
            return ""
    for saved in data["foods"]:
        if saved is Dictionary and str(saved.get("barcode", "")) == barcode:
            return str(saved.get("id", ""))
    var item = {
        "id": "barcode_" + barcode,
        "barcode": barcode,
        "name": str(details["name"]).substr(0, 160),
        "kcal": float(details["kcal"]),
        "p": float(details["p"]),
        "f": float(details["f"]),
        "c": float(details["c"]),
        "source": str(details.get("source", "Пользователь"))
    }
    if item["name"].is_empty():
        return ""
    for field in ["kcal", "p", "f", "c"]:
        if item[field] < 0.0 or item[field] > 1000.0:
            return ""
    data["foods"].append(item)
    if not save():
        data["foods"].erase(item)
        return ""
    return str(item["id"])

func is_favorite(food_id: String) -> bool:
    return data.get("favorites", []).has(food_id)

func toggle_favorite(food_id: String) -> bool:
    if food_by_id(food_id).is_empty():
        return false
    var favorites: Array = data.get("favorites", [])
    if favorites.has(food_id):
        favorites.erase(food_id)
    else:
        favorites.append(food_id)
    data["favorites"] = favorites
    return save()

func repeat_entry(entry: Dictionary, destination_date: String) -> bool:
    if not data["entries"].has(entry):
        return false
    var new_entry: Dictionary = entry.duplicate(true)
    new_entry["id"] = "repeat_" + str(Time.get_ticks_usec()) + "_" + str(data["entries"].size())
    new_entry["date"] = destination_date
    data["entries"].append(new_entry)
    return save()

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
