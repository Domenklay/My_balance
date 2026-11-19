extends RefCounted

const DATA_PATH = "user://my_balance.json"
const BACKUP_PATH = "user://my_balance.previous.json"

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

func _init() -> void:
    data = default_data()
    if FileAccess.file_exists(DATA_PATH):
        var content = FileAccess.get_file_as_string(DATA_PATH)
        if not import_json(content, false) and FileAccess.file_exists(BACKUP_PATH):
            import_json(FileAccess.get_file_as_string(BACKUP_PATH), false)

func default_data() -> Dictionary:
    return {
        "settings": {"kcal": 1800, "start": 88.0, "goal": 65.0},
        "foods": [], "entries": [], "activities": [], "weights": [], "notes": {}
    }

func save() -> void:
    if FileAccess.file_exists(DATA_PATH):
        var previous = FileAccess.get_file_as_string(DATA_PATH)
        if previous.length() > 0:
            var backup = FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
            if backup != null:
                backup.store_string(previous)
                backup.close()
    var file = FileAccess.open(DATA_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))
        file.close()
    else:
        push_error("Не удалось сохранить дневник")

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
    data = obj
    if persist:
        save()
    return true

func export_json() -> String:
    return JSON.stringify(data, "\t")

func all_foods() -> Array:
    var result = []
    for i in range(DEFAULT_PRODUCTS.size()):
        var f: Array = DEFAULT_PRODUCTS[i]
        result.append({"id": "d" + str(i), "name": f[0], "kcal": f[1], "p": f[2], "f": f[3], "c": f[4]})
    for f in data["foods"]:
        if f is Dictionary:
            result.append(f)
    return result

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
