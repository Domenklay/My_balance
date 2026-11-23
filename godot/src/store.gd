extends RefCounted

const DATA_PATH = "user://my_balance.json"
const BACKUP_PATH = "user://my_balance.previous.json"
const TEMP_PATH = "user://my_balance.pending.json"
const OFFLINE_CATALOG_PATH = "res://data/barcode_catalog.json"
const UPDATE_CATALOG_PATH = "user://barcode_catalog_verified.json"
const BarcodeScript = preload("res://src/barcode_lookup.gd")
const RecipeMath = preload("res://src/recipe_math.gd")
const PortionMath = preload("res://src/portion_math.gd")
const RewardsScript = preload("res://src/rewards.gd")
const ProfilePhotoScript = preload("res://src/profile_photo.gd")
const OnboardingMath = preload("res://src/onboarding_math.gd")
const ActivityMath = preload("res://src/activity_math.gd")
const BodyMeasurements = preload("res://src/body_measurements.gd")

const MEAL_NAMES = ["Завтрак", "Обед", "Ужин", "Перекус"]
const DEFAULT_MEAL_SHARES = [25, 35, 30, 10]
const DEFAULT_HOME_WIDGETS = {"week": false, "weight": false}

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
        "settings": {"kcal": 1800, "start": 88.0, "goal": 65.0, "theme": "forest", "patterns": true, "high_contrast": false,
            "meal_shares": DEFAULT_MEAL_SHARES.duplicate(), "home_widgets": DEFAULT_HOME_WIDGETS.duplicate(), "onboarding_complete": false,
            "personal": {}},
        "foods": [], "entries": [], "activities": [], "steps": {}, "weights": [], "body_measurements": [], "notes": {}, "favorites": [],
        "recipes": [], "meal_templates": [], "day_copy_undo": {}, "food_portions": [], "profile": {"name": "Мой профиль", "avatar": "leaf", "motto": "Маленькие шаги — большой результат",
            "photo": "", "frame": "plain"}
    }

static func valid_meal_shares(value: Variant) -> bool:
    if not (value is Array) or value.size() != 4:
        return false
    var total = 0
    for share in value:
        if not (share is int or share is float):
            return false
        var number: float = float(share)
        if not is_finite(number) or number < 0.0 or number > 100.0 or not is_equal_approx(number, roundf(number)):
            return false
        total += roundi(number)
    return total == 100

func meal_shares() -> Array:
    var saved = data.get("settings", {}).get("meal_shares", DEFAULT_MEAL_SHARES)
    return saved.duplicate() if valid_meal_shares(saved) else DEFAULT_MEAL_SHARES.duplicate()

func set_meal_shares(shares: Array) -> bool:
    if not valid_meal_shares(shares):
        return false
    var old: Dictionary = data["settings"].duplicate(true)
    data["settings"]["meal_shares"] = shares.duplicate()
    if save():
        return true
    data["settings"] = old
    return false

static func valid_home_widgets(value: Variant) -> bool:
    if not (value is Dictionary):
        return false
    if value.size() != 2 or not value.has("week") or not value.has("weight"):
        return false
    return value["week"] is bool and value["weight"] is bool

func home_widgets() -> Dictionary:
    var widgets = data.get("settings", {}).get("home_widgets", DEFAULT_HOME_WIDGETS)
    return widgets.duplicate(true) if valid_home_widgets(widgets) else DEFAULT_HOME_WIDGETS.duplicate(true)

func set_home_widget(key: String, enabled: bool) -> bool:
    if key not in ["week", "weight"]:
        return false
    var previous: Dictionary = data["settings"].duplicate(true)
    var next: Dictionary = home_widgets()
    next[key] = enabled
    data["settings"]["home_widgets"] = next
    if save():
        return true
    data["settings"] = previous
    return false

func meal_summary(day: String, meal: String) -> Dictionary:
    var result: Dictionary = {"kcal": 0.0, "p": 0.0, "f": 0.0, "c": 0.0, "count": 0}
    if meal not in MEAL_NAMES:
        return result
    for entry in day_entries(day):
        if str(entry.get("meal", "")) != meal:
            continue
        result["count"] = int(result["count"]) + 1
        var food: Dictionary = entry_food(entry)
        var ratio = float(entry.get("grams", 0.0)) / 100.0
        for nutrient in ["kcal", "p", "f", "c"]:
            result[nutrient] = float(result[nutrient]) + float(food.get(nutrient, 0.0)) * ratio
    return result

static func parse_calorie_target(text: String) -> int:
    var input = text.strip_edges()
    if not input.is_valid_int():
        return -1
    var result = input.to_int()
    return result if result >= 1000 and result <= 5000 else -1

func set_daily_calorie_goal(calories: int) -> bool:
    if calories < 1000 or calories > 5000:
        return false
    var previous: Dictionary = data["settings"].duplicate(true)
    data["settings"]["kcal"] = calories
    if save():
        return true
    data["settings"] = previous
    return false

func needs_onboarding() -> bool:
    return not bool(data.get("settings", {}).get("onboarding_complete", false))

func complete_onboarding(personal: Dictionary, calories: float) -> bool:
    if not OnboardingMath.valid_details(personal):
        return false
    if not is_finite(calories) or calories < 1000.0 or calories > 5000.0:
        return false
    var old_settings: Dictionary = data["settings"].duplicate(true)
    var old_profile: Dictionary = data["profile"].duplicate(true)
    var settings: Dictionary = data["settings"]
    settings["personal"] = personal.duplicate(true)
    settings["onboarding_complete"] = true
    settings["kcal"] = roundi(calories)
    settings["start"] = float(personal["weight"])
    settings["goal"] = float(personal["goal_weight"])
    data["profile"]["name"] = str(personal["name"]).strip_edges()
    if save():
        return true
    data["settings"] = old_settings
    data["profile"] = old_profile
    return false

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
    var photo = profile.get("photo", "")
    var frame = profile.get("frame", "plain")
    if not (name is String and motto is String and avatar is String):
        return false
    if name.strip_edges().is_empty() or name.length() > 45 or motto.length() > 140:
        return false
    if avatar not in ["leaf", "star", "moon", "sun", "flower", "heart"]:
        return false
    if not (frame is String) or RewardsScript.frame_by_id(frame).is_empty():
        return false
    return ProfilePhotoScript.valid_photo(photo)

func update_profile(changes: Dictionary) -> bool:
    var previous: Dictionary = data["profile"].duplicate(true)
    var updated: Dictionary = previous.duplicate(true)
    for key in changes:
        updated[key] = changes[key]
    if not _valid_profile(updated):
        return false
    data["profile"] = updated
    if save():
        return true
    data["profile"] = previous
    return false

func update_avatar_photo(encoded: String) -> bool:
    if not ProfilePhotoScript.valid_photo(encoded):
        return false
    return update_profile({"photo": encoded})

func choose_avatar_frame(id: String) -> bool:
    var frame: Dictionary = RewardsScript.frame_by_id(id)
    if frame.is_empty():
        return false
    var points: int = int(RewardsScript.calculate(data, Time.get_date_string_from_system())["points"])
    if points < int(frame["points"]):
        return false
    return update_profile({"frame": id})

func reward_summary() -> Dictionary:
    return RewardsScript.calculate(data, Time.get_date_string_from_system())

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

# Marking a recipe as favorite changes only its recipe metadata; the
# historical diary snapshot is never recalculated.
func toggle_recipe_favorite(recipe_id: String) -> bool:
    var recipe: Dictionary = recipe_by_id(recipe_id)
    if recipe.is_empty():
        return false
    var had_flag: bool = recipe.has("favorite")
    var old: bool = bool(recipe.get("favorite", false))
    recipe["favorite"] = not old
    if save():
        return true
    if had_flag:
        recipe["favorite"] = old
    else:
        recipe.erase("favorite")
    return false


func recent_recipe_portions(limit: int = 10) -> Array:
    var out: Array = []
    if limit <= 0:
        return out
    var seen: Dictionary = {}
    for i in range(data["entries"].size() - 1, -1, -1):
        var entry: Dictionary = data["entries"][i]
        var id: String = str(entry.get("recipe_id", ""))
        if id.is_empty():
            var food_id: String = str(entry.get("food", ""))
            if food_id.begins_with("recipe:"):
                id = food_id.substr(7)
        if id.is_empty() or seen.has(id):
            continue
        var grams: float = float(entry.get("grams", 0))
        var meal: String = str(entry.get("meal", ""))
        if not is_finite(grams) or grams <= 0.0 or grams > 5000.0 or meal not in MEAL_NAMES:
            continue
        if recipe_by_id(id).is_empty():
            continue
        seen[id] = true
        out.append({"recipe_id": id, "grams": grams, "meal": meal,
            "date": str(entry.get("date", ""))})
        if out.size() >= limit:
            break
    return out


func last_recipe_portion(recipe_id: String) -> Dictionary:
    for recent in recent_recipe_portions(500):
        if str(recent.get("recipe_id", "")) == recipe_id:
            return recent
    return {}


func repeat_recipe_portion(recipe_id: String, day: String) -> bool:
    var last: Dictionary = last_recipe_portion(recipe_id)
    if last.is_empty():
        return false
    return add_recipe_portion(recipe_id, float(last["grams"]),
        str(last["meal"]), day)


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
        "grams": grams, "unit": "г", "meal": meal
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
    # Optional body circumferences arrived in 0.7.45. Legacy JSON backups
    # migrate with an empty collection and keep all existing data.
    if not obj.has("body_measurements"):
        obj["body_measurements"] = []
    if not (obj["body_measurements"] is Array) or obj["body_measurements"].size() > 5000:
        return false
    var measurement_dates: Dictionary = {}
    for measurement in obj["body_measurements"]:
        if not BodyMeasurements.valid_record(measurement):
            return false
        var measurement_day: String = str(measurement["date"])
        if measurement_dates.has(measurement_day):
            return false
        measurement_dates[measurement_day] = true
    # Favorites were introduced in 0.5.3; older exports have no such field.
    if not obj.has("recipes"):
        obj["recipes"] = []
    if not obj.has("profile"):
        obj["profile"] = {"name": "Мой профиль", "avatar": "leaf", "motto": "Маленькие шаги — большой результат",
            "photo": "", "frame": "plain"}
    if obj["profile"] is Dictionary:
        var previous_profile: Dictionary = obj["profile"]
        if not previous_profile.has("photo"):
            previous_profile["photo"] = ""
        if not previous_profile.has("frame"):
            previous_profile["frame"] = "plain"
    # v0.7.43 daily step counts are optional for legacy backups.
    if not obj.has("steps"):
        obj["steps"] = {}
    if not (obj["steps"] is Dictionary) or obj["steps"].size() > 10000:
        return false
    for day in obj["steps"]:
        if not (day is String) or not ActivityMath.valid_date(day) or not ActivityMath.valid_steps(obj["steps"][day]):
            return false
    if not obj.has("favorites"):
        obj["favorites"] = []
    if not obj.has("food_portions"):
        obj["food_portions"] = []
    if not (obj["food_portions"] is Array) or obj["food_portions"].size() > 500:
        return false
    var portion_ids: Dictionary = {}
    for portion in obj["food_portions"]:
        if not PortionMath.valid_portion(portion) or portion_ids.has(str(portion["id"])):
            return false
        portion_ids[str(portion["id"])] = true
    if not obj.has("meal_templates"):
        obj["meal_templates"] = []
    if not (obj["meal_templates"] is Array) or obj["meal_templates"].size() > 100:
        return false
    var template_ids: Dictionary = {}
    for template in obj["meal_templates"]:
        if not (template is Dictionary):
            return false
        if not (template.get("id") is String and template.get("name") is String and template.get("items") is Array):
            return false
        var template_id: String = template["id"]
        if template_id.is_empty() or template_id.length() > 100 or template_ids.has(template_id):
            return false
        template_ids[template_id] = true
        if template["name"].strip_edges().is_empty() or template["name"].length() > 70:
            return false
        if template["items"].is_empty() or template["items"].size() > 30:
            return false
        for item in template["items"]:
            if not valid_template_item(item):
                return false
            if str(item.get("meal", "")) not in ["Завтрак", "Обед", "Перекус", "Ужин"]:
                return false
            var grams = item.get("grams", 0)
            if not (grams is float or grams is int) or not is_finite(float(grams)) or float(grams) <= 0.0 or float(grams) > 5000.0:
                return false
            if str(item.get("unit", "г")) not in ["г", "мл"]:
                return false
            if str(item.get("portion_label", "")).length() > 36:
                return false
            if item.has("portion_count"):
                if not (item["portion_count"] is float or item["portion_count"] is int) or \
                        not is_finite(float(item["portion_count"])) or float(item["portion_count"]) < 0.0 or \
                        float(item["portion_count"]) > 5000.0:
                    return false
            if item.has("portion_id"):
                if not (item["portion_id"] is String) or str(item["portion_id"]).length() > 100 or \
                        not item.has("portion_count"):
                    return false
            var nutrition: Dictionary = item["nutrition"]
            if not (nutrition.get("name") is String) or nutrition["name"].is_empty() or nutrition["name"].length() > 160:
                return false
            for nutrient in ["kcal", "p", "f", "c"]:
                var n = nutrition.get(nutrient)
                if not (n is float or n is int) or not is_finite(float(n)) or float(n) < 0.0 or float(n) > (1000.0 if nutrient == "kcal" else 100.0):
                    return false
    # The undo snapshot was introduced in 0.7.41. Legacy JSON imports
    # without it continue to work; malformed undo data cannot be imported.
    if not obj.has("day_copy_undo"):
        obj["day_copy_undo"] = {}
    if not valid_copy_undo(obj["day_copy_undo"]):
        return false
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
    # Backups created before 0.7.9 already represent an established diary.
    # Never show a first-run form to people installing an update.
    if not settings.has("onboarding_complete"):
        settings["onboarding_complete"] = true
    if not (settings["onboarding_complete"] is bool):
        return false
    if not settings.has("personal"):
        settings["personal"] = {}
    if not (settings["personal"] is Dictionary):
        return false
    if not settings["personal"].is_empty() and not OnboardingMath.valid_details(settings["personal"]):
        return false
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
    if not settings.has("meal_shares"):
        settings["meal_shares"] = DEFAULT_MEAL_SHARES.duplicate()
    if not valid_meal_shares(settings["meal_shares"]):
        return false
    # Godot parses all JSON numbers as float. Normalize valid whole
    # percentages to integers so UI and test data use the same format.
    var normalized_shares: Array = []
    for raw_share in settings["meal_shares"]:
        normalized_shares.append(roundi(float(raw_share)))
    settings["meal_shares"] = normalized_shares
    # Optional home widgets arrived in 0.7.29. Keep historical diaries
    # compact by default, and reject malformed widget states on import.
    if not settings.has("home_widgets"):
        settings["home_widgets"] = DEFAULT_HOME_WIDGETS.duplicate(true)
    if not valid_home_widgets(settings["home_widgets"]):
        return false
    # Older diary backups predate appearance controls; import them unchanged
    # and fill in safe defaults. Unknown themes are never applied.
    if not settings.has("theme"):
        settings["theme"] = "forest"
    if not (settings["theme"] is String) or str(settings["theme"]) not in ["forest", "mint", "sand", "dark", "botanical"]:
        return false
    if not settings.has("patterns"):
        settings["patterns"] = true
    if not (settings["patterns"] is bool):
        return false
    # Legacy backups predate the optional readability setting.
    if not settings.has("high_contrast"):
        settings["high_contrast"] = false
    if not (settings["high_contrast"] is bool):
        return false
    if obj["foods"].size() > 10000 or obj["entries"].size() > 50000 or obj["weights"].size() > 5000 or obj["activities"].size() > 50000:
        return false
    # Old activity entries use the same core fields; reject malformed exports
    # before replacing the live journal.
    for activity in obj["activities"]:
        if not ActivityMath.valid_activity(activity):
            return false
    for entry in obj["entries"]:
        if not (entry is Dictionary):
            return false
        var grams = entry.get("grams", 0)
        if not (grams is float or grams is int):
            return false
        if float(grams) <= 0.0 or float(grams) > 5000.0:
            return false
        if str(entry.get("unit", "г")) not in ["г", "мл"]:
            return false
        if str(entry.get("portion_label", "")).length() > 36:
            return false
        # 0.7.35 adds optional serving count and measure id. Legacy JSON
        # backups omit both and remain valid; malformed new values are rejected.
        if entry.has("portion_count"):
            var count = entry["portion_count"]
            if not (count is float or count is int) or \
                    not is_finite(float(count)) or float(count) <= 0.0 or float(count) > 5000.0:
                return false
        if entry.has("portion_id"):
            if not (entry["portion_id"] is String) or str(entry["portion_id"]).length() > 100:
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

# Derived from existing diary data: no migration or separate sensitive history.
func recent_foods(limit: int = 8) -> Array:
    var seen: Dictionary = {}
    var result: Array = []
    var food_index: Dictionary = {}
    for food in all_foods():
        food_index[str(food.get("id", ""))] = food
    for i in range(data["entries"].size() - 1, -1, -1):
        var entry: Dictionary = data["entries"][i]
        var id = str(entry.get("food", ""))
        if id.is_empty() or seen.has(id):
            continue
        seen[id] = true
        if food_index.has(id):
            result.append(food_index[id])
        elif entry.get("nutrition") is Dictionary:
            var snapshot: Dictionary = entry["nutrition"].duplicate(true)
            snapshot["id"] = id
            result.append(snapshot)
        if result.size() >= limit:
            break
    return result


# Last distinct products with the actual portion last logged. Derived from the
# journal itself, so upgrades require no new storage fields or migration.
func recent_food_entries(limit: int = 6) -> Array:
    var result: Array = []
    if limit <= 0:
        return result
    var index: Dictionary = {}
    for food in all_foods():
        index[str(food.get("id", ""))] = food
    var seen: Dictionary = {}
    for i in range(data["entries"].size() - 1, -1, -1):
        var entry: Dictionary = data["entries"][i]
        var food_id = str(entry.get("food", ""))
        if food_id.is_empty() or seen.has(food_id):
            continue
        var amount = float(entry.get("grams", 0))
        if not is_finite(amount) or amount <= 0 or amount > 5000:
            continue
        var food: Dictionary = index.get(food_id, {})
        if food.is_empty() and entry.get("nutrition") is Dictionary:
            food = entry["nutrition"].duplicate(true)
            food["id"] = food_id
            food["nutrition_unit"] = str(entry.get("unit", "г"))
        if food.is_empty() or str(food.get("name", "")).strip_edges().is_empty():
            continue
        seen[food_id] = true
        result.append({
            "food": food, "grams": amount,
            "unit": str(entry.get("unit", PortionMath.base_unit(food))),
            "portion_label": str(entry.get("portion_label", "")),
            "date": str(entry.get("date", "")),
            "meal": str(entry.get("meal", "")),
            "portion_count": entry.get("portion_count", 0.0),
            "portion_id": str(entry.get("portion_id", ""))
        })
        if result.size() >= limit:
            break
    return result

func frequent_foods(limit: int = 8, min_uses: int = 1) -> Array:
    # Only products entered repeatedly appear in the frequent shortcuts.
    if limit <= 0:
        return []
    var counts: Dictionary = {}
    var last_used: Dictionary = {}
    var examples: Dictionary = {}
    for i in range(data["entries"].size()):
        var entry: Dictionary = data["entries"][i]
        var id = str(entry.get("food", ""))
        if id.is_empty():
            continue
        counts[id] = int(counts.get(id, 0)) + 1
        last_used[id] = i
        examples[id] = entry
    var ids: Array = counts.keys()
    ids.sort_custom(func(a, b):
        if counts[a] != counts[b]:
            return counts[a] > counts[b]
        return last_used[a] > last_used[b]
    )
    var food_index: Dictionary = {}
    for food in all_foods():
        food_index[str(food.get("id", ""))] = food
    var result: Array = []
    for id in ids:
        if int(counts[id]) < min_uses:
            continue
        if food_index.has(id):
            result.append(food_index[id])
        elif examples[id].get("nutrition") is Dictionary:
            var snapshot: Dictionary = examples[id]["nutrition"].duplicate(true)
            snapshot["id"] = str(id)
            result.append(snapshot)
        if result.size() >= limit:
            break
    return result

# Based entirely on the existing diary; no new personal history is stored.
func food_usage_counts() -> Dictionary:
    var counts: Dictionary = {}
    for entry in data["entries"]:
        if not (entry is Dictionary):
            continue
        var food_id: String = str(entry.get("food", ""))
        if not food_id.is_empty():
            counts[food_id] = int(counts.get(food_id, 0)) + 1
    return counts


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
    if str(details.get("nutrition_unit", "г")) not in ["г", "мл"]:
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
        saved["brand"] = str(details.get("brand", saved.get("brand", ""))).strip_edges().substr(0, 80)
        saved["quantity"] = str(details.get("quantity", saved.get("quantity", ""))).strip_edges().substr(0, 80)
        saved["image_url"] = BarcodeScript.safe_image_url(
            str(details.get("image_url", saved.get("image_url", ""))))
        if str(saved.get("nutrition_unit", "г")) != str(details.get("nutrition_unit", "г")):
            # Existing custom sizes refer to a defined measurement basis.
            for portion in data["food_portions"]:
                if str(portion.get("food_id", "")) == str(saved.get("id", "")):
                    saved.clear()
                    saved.merge(previous, true)
                    return ""
        saved["nutrition_unit"] = str(details.get("nutrition_unit", "г"))
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
        "source": str(details.get("source", "Пользователь")),
        "brand": str(details.get("brand", "")).strip_edges().substr(0, 80),
        "quantity": str(details.get("quantity", "")).strip_edges().substr(0, 80),
        "image_url": BarcodeScript.safe_image_url(str(details.get("image_url", ""))),
        "nutrition_unit": str(details.get("nutrition_unit", "г"))
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
    if str(food.get("nutrition_unit", "г")) not in ["г", "мл"]:
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

func add_food_entry(food: Dictionary, grams: float, meal: String, day: String,
        portion_label: String = "", portion_count: float = 0.0,
        portion_id: String = "") -> bool:
    if food.is_empty() or not is_finite(grams) or grams <= 0.0 or grams > 5000.0:
        return false
    if meal not in ["Завтрак", "Обед", "Перекус", "Ужин"] or portion_label.length() > 36:
        return false
    if not is_finite(portion_count) or portion_count < 0.0 or portion_count > 5000.0 or \
            portion_id.length() > 100 or (portion_count == 0.0 and not portion_id.is_empty()):
        return false
    var base_unit: String = PortionMath.base_unit(food)
    var entry = {
        "id": str(Time.get_ticks_usec()) + "_" + str(data["entries"].size()),
        "date": day,
        "food": str(food.get("id", "")),
        "nutrition": {
            "nutrition_unit": base_unit,
            "name": str(food.get("name", "")),
            "kcal": float(food.get("kcal", 0)),
            "p": float(food.get("p", 0)),
            "f": float(food.get("f", 0)),
            "c": float(food.get("c", 0))
        },
        "grams": grams,
        "unit": base_unit,
        "portion_label": portion_label,
        "meal": meal
    }
    if portion_count > 0.0:
        entry["portion_count"] = portion_count
        entry["portion_id"] = portion_id
    data["entries"].append(entry)
    if not save():
        data["entries"].erase(entry)
        return false
    return true

func update_custom_food(id: String, changes: Dictionary) -> bool:
    var name = str(changes.get("name", "")).strip_edges()
    if name.is_empty() or name.length() > 160:
        return false
    var base_unit = str(changes.get("nutrition_unit", "г"))
    if base_unit not in ["г", "мл"]:
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
        if str(food.get("nutrition_unit", "г")) != base_unit:
            for portion in data["food_portions"]:
                if str(portion.get("food_id", "")) == id:
                    return false
        var old = food.duplicate(true)
        for key in ["name", "kcal", "p", "f", "c"]:
            food[key] = changes[key]
        food["nutrition_unit"] = base_unit
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
    var previous_portions = data["food_portions"].duplicate(true)
    data["food_portions"] = data["food_portions"].filter(func(p): return str(p.get("food_id", "")) != id)
    data["foods"].erase(found)
    data["favorites"].erase(id)
    if save():
        return true
    data["foods"] = original
    data["favorites"] = previous_favorites
    data["food_portions"] = previous_portions
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

# Duplicate a complete meal in one atomic save, preserving nutrition snapshots.
func repeat_meal(source_date: String, meal: String, destination_date: String) -> int:
    if source_date == destination_date or meal not in ["Завтрак", "Обед", "Перекус", "Ужин"] or \
            not valid_diary_date(source_date) or not valid_diary_date(destination_date):
        return 0
    var source: Array = day_entries(source_date).filter(
        func(e): return str(e.get("meal", "")) == meal
    )
    if source.is_empty() or data["entries"].size() + source.size() > 50000:
        return 0
    var duplicates: Array = []
    for i in range(source.size()):
        var entry: Dictionary = source[i].duplicate(true)
        entry["id"] = "meal_" + str(Time.get_ticks_usec()) + "_" + str(data["entries"].size() + i)
        entry["date"] = destination_date
        duplicates.append(entry)
    data["entries"].append_array(duplicates)
    if save():
        return duplicates.size()
    for entry in duplicates:
        data["entries"].erase(entry)
    return 0

# Copies only food records; activity, body weight and notes never get erased.
# Returns the number of copied items, or 0 when no change was committed.
# Saving once after the complete mutation makes the operation atomic.
static func valid_diary_date(day: String) -> bool:
    if day.length() != 10 or day.substr(4, 1) != "-" or day.substr(7, 1) != "-":
        return false
    if not day.substr(0, 4).is_valid_int() or not day.substr(5, 2).is_valid_int() or \
            not day.substr(8, 2).is_valid_int():
        return false
    var stamp: int = int(Time.get_unix_time_from_datetime_string(day + "T12:00:00"))
    return Time.get_date_string_from_unix_time(stamp) == day


# One-record identity ignoring the generated entry id/date. Keep snapshots
# in the signature so changed catalog values do not falsely match historical food.
static func food_entry_signature(entry: Dictionary) -> String:
    var nutrition: Dictionary = entry.get("nutrition", {})
    return JSON.stringify([
        str(entry.get("food", "")), str(entry.get("meal", "")),
        float(entry.get("grams", 0)), str(entry.get("unit", "г")),
        str(entry.get("portion_label", "")),
        float(entry.get("portion_count", 0)), str(entry.get("portion_id", "")),
        str(nutrition.get("name", "")), str(nutrition.get("nutrition_unit", "г")),
        float(nutrition.get("kcal", 0)), float(nutrition.get("p", 0)),
        float(nutrition.get("f", 0)), float(nutrition.get("c", 0))
    ])


func day_copy_plan(source_date: String, destination_date: String,
        replace_destination: bool = false, skip_duplicates: bool = false) -> Dictionary:
    var result: Dictionary = {"entries": [], "source_count": 0, "duplicates": 0,
        "target_count": 0}
    if not valid_diary_date(source_date) or not valid_diary_date(destination_date) or \
            source_date == destination_date:
        return result
    var source: Array = day_entries(source_date)
    var target: Array = day_entries(destination_date)
    result["source_count"] = source.size()
    result["target_count"] = target.size()
    var existing_signatures: Dictionary = {}
    if not replace_destination:
        for record in target:
            existing_signatures[food_entry_signature(record)] = true
    var selected: Array = []
    for record in source:
        if existing_signatures.has(food_entry_signature(record)):
            result["duplicates"] += 1
            if skip_duplicates:
                continue
        selected.append(record)
    result["entries"] = selected
    return result


# Undo survives an app restart, but only when the copied destination has not
# changed since the copy. Never revert subsequent manual edits.
static func valid_copy_undo(value: Variant) -> bool:
    if not (value is Dictionary):
        return false
    if value.is_empty():
        return true
    if value.size() != 3 or not (value.get("date") is String and \
            value.get("before") is Array and value.get("after") is Array):
        return false
    var day: String = value["date"]
    if not valid_diary_date(day) or value["before"].size() > 1500 or \
            value["after"].size() > 1500:
        return false
    for collection in [value["before"], value["after"]]:
        for record in collection:
            if not (record is Dictionary):
                return false
            if str(record.get("date", "")) != day or \
                    not (record.get("id") is String) or str(record["id"]).is_empty() or \
                    str(record.get("meal", "")) not in MEAL_NAMES:
                return false
            var grams = record.get("grams", 0)
            if not (grams is int or grams is float) or not is_finite(float(grams)) or \
                    float(grams) <= 0.0 or float(grams) > 5000.0:
                return false
    return true


func can_undo_day_copy(day: String = "") -> bool:
    var undo: Dictionary = data.get("day_copy_undo", {})
    if undo.is_empty() or not valid_copy_undo(undo):
        return false
    var chosen: String = str(undo["date"])
    return (day.is_empty() or chosen == day) and day_entries(chosen) == undo["after"]


func undo_day_copy() -> bool:
    if not can_undo_day_copy():
        return false
    var undo: Dictionary = data["day_copy_undo"]
    var chosen: String = str(undo["date"])
    var original_entries: Array = data["entries"].duplicate(true)
    var original_undo: Dictionary = undo.duplicate(true)
    data["entries"] = data["entries"].filter(func(e):
        return str(e.get("date", "")) != chosen)
    data["entries"].append_array(undo["before"].duplicate(true))
    data["day_copy_undo"] = {}
    if save():
        return true
    data["entries"] = original_entries
    data["day_copy_undo"] = original_undo
    return false


# Append and replace are one filesystem write, with matching previous state
# retained for a one-step undo. Skipped duplicates never overwrite anything.
func copy_day(source_date: String, destination_date: String,
        replace_destination: bool = false, skip_duplicates: bool = false) -> int:
    var plan: Dictionary = day_copy_plan(
        source_date, destination_date, replace_destination, skip_duplicates)
    var sources: Array = plan["entries"]
    if sources.is_empty():
        return 0
    var destination: Array = day_entries(destination_date)
    var after_size: int = (data["entries"].size() -
        (destination.size() if replace_destination else 0) + sources.size())
    if after_size > 50000 or destination.size() > 1500 or \
            destination.size() + sources.size() > 1500:
        return 0
    var before: Array = data["entries"].duplicate(true)
    var previous_undo: Dictionary = data.get("day_copy_undo", {}).duplicate(true)
    if replace_destination:
        data["entries"] = data["entries"].filter(func(e):
            return str(e.get("date", "")) != destination_date)
    var serial: String = str(Time.get_ticks_usec())
    for i in range(sources.size()):
        var snapshot: Dictionary = sources[i].duplicate(true)
        snapshot["id"] = "day_copy_" + serial + "_" + str(i)
        snapshot["date"] = destination_date
        data["entries"].append(snapshot)
    data["day_copy_undo"] = {"date": destination_date,
        "before": destination.duplicate(true),
        "after": day_entries(destination_date).duplicate(true)}
    if save():
        return sources.size()
    data["entries"] = before
    data["day_copy_undo"] = previous_undo
    return 0


# Meal templates store a snapshot of each item's nutrition, independent of
# later edits or deletion of source foods and recipes.
func save_meal_template(source_date: String, meal: String, title: String) -> bool:
    var name = title.strip_edges()
    if name.is_empty() or name.length() > 70 or data["meal_templates"].size() >= 100:
        return false
    if meal not in ["Завтрак", "Обед", "Перекус", "Ужин"]:
        return false
    var source: Array = day_entries(source_date).filter(
        func(e): return str(e.get("meal", "")) == meal
    )
    if source.is_empty() or source.size() > 30 or not valid_diary_date(source_date):
        return false
    var items: Array = []
    for entry in source:
        var snapshot: Dictionary = entry_food(entry)
        if snapshot.is_empty():
            return false
        items.append({
            "food": str(entry.get("food", "")),
            "meal": meal,
            "grams": float(entry["grams"]),
            "unit": str(entry.get("unit", "г")),
            "portion_label": str(entry.get("portion_label", "")),
            "nutrition": snapshot.duplicate(true),
            "portion_count": float(entry.get("portion_count", 0.0)),
            "portion_id": str(entry.get("portion_id", ""))
        })
    var record = {
        "id": "template_" + str(Time.get_ticks_usec()) + "_" + str(data["meal_templates"].size()),
        "name": name,
        "items": items
    }
    data["meal_templates"].append(record)
    if save():
        return true
    data["meal_templates"].erase(record)
    return false

# Edit existing templates without changing their id or applying to the diary.
# All items are snapshots; no dependency on current product catalog.
static func valid_template_item(item: Variant) -> bool:
    if not (item is Dictionary and item.get("nutrition") is Dictionary):
        return false
    if str(item.get("meal", "")) not in MEAL_NAMES or \
            str(item.get("unit", "г")) not in ["г", "мл"] or \
            str(item.get("portion_label", "")).length() > 36 or \
            str(item.get("portion_id", "")).length() > 100:
        return false
    var grams = item.get("grams", 0)
    if not (grams is int or grams is float) or not is_finite(float(grams)) or \
            float(grams) <= 0.0 or float(grams) > 5000.0:
        return false
    var count = item.get("portion_count", 0.0)
    if not (count is int or count is float) or not is_finite(float(count)) or \
            float(count) < 0.0 or float(count) > 5000.0:
        return false
    if str(item.get("portion_id", "")) != "" and float(count) <= 0.0:
        return false
    var nutrition: Dictionary = item["nutrition"]
    if not (nutrition.get("name") is String) or \
            str(nutrition["name"]).is_empty() or str(nutrition["name"]).length() > 160:
        return false
    for key in ["kcal", "p", "f", "c"]:
        var v = nutrition.get(key)
        if not (v is int or v is float) or not is_finite(float(v)) or \
                float(v) < 0.0 or float(v) > (1000.0 if key == "kcal" else 100.0):
            return false
    return true


func update_meal_template(template_id: String, name: String, items: Array) -> bool:
    var label: String = name.strip_edges()
    if label.is_empty() or label.length() > 70 or items.is_empty() or items.size() > 30:
        return false
    for item in items:
        if not valid_template_item(item):
            return false
    var target: Dictionary = {}
    for template in data.get("meal_templates", []):
        if str(template.get("id", "")) == template_id:
            target = template
            break
    if target.is_empty():
        return false
    var previous: Dictionary = target.duplicate(true)
    target["name"] = label
    target["items"] = items.duplicate(true)
    if save():
        return true
    target.clear()
    target.merge(previous, true)
    return false


func apply_meal_template(template_id: String, destination_date: String) -> int:
    for template in data["meal_templates"]:
        if str(template.get("id", "")) != template_id:
            continue
        var created: Array = []
        if not valid_diary_date(destination_date) or \
                data["entries"].size() + template["items"].size() > 50000:
            return 0
        for item in template["items"]:
            created.append({
                "id": "template_entry_" + str(Time.get_ticks_usec()) + "_" + str(data["entries"].size() + created.size()),
                "date": destination_date,
                "food": str(item.get("food", "")),
                "meal": str(item["meal"]),
                "grams": float(item["grams"]),
                "unit": str(item.get("unit", "г")),
                "portion_label": str(item.get("portion_label", "")),
                "nutrition": item["nutrition"].duplicate(true)
            })
            if float(item.get("portion_count", 0.0)) > 0.0:
                created[created.size() - 1]["portion_count"] = float(item["portion_count"])
                created[created.size() - 1]["portion_id"] = str(item.get("portion_id", ""))
        data["entries"].append_array(created)
        if save():
            return created.size()
        for record in created:
            data["entries"].erase(record)
        return 0
    return 0

func delete_meal_template(template_id: String) -> bool:
    for i in range(data["meal_templates"].size()):
        if str(data["meal_templates"][i].get("id", "")) != template_id:
            continue
        var record = data["meal_templates"][i]
        data["meal_templates"].remove_at(i)
        if save():
            return true
        data["meal_templates"].insert(i, record)
        return false
    return false

func portion_options(food: Dictionary) -> Array:
    return PortionMath.options(food, data["food_portions"])

# Last recorded serving per food id: computed from the diary so upgrades
# restore old entries automatically, without a parallel per-food cache.
func last_food_portion(food: Dictionary) -> Dictionary:
    var food_id: String = str(food.get("id", ""))
    if food_id.is_empty():
        return {}
    var unit: String = PortionMath.base_unit(food)
    for i in range(data["entries"].size() - 1, -1, -1):
        var entry: Dictionary = data["entries"][i]
        if str(entry.get("food", "")) != food_id or \
                str(entry.get("unit", "г")) != unit:
            continue
        var amount: float = float(entry.get("grams", 0.0))
        if not is_finite(amount) or amount <= 0.0 or amount > 5000.0:
            continue
        return {
            "grams": amount, "unit": unit,
            "portion_label": str(entry.get("portion_label", "")),
            "portion_count": entry.get("portion_count", 0.0),
            "portion_id": str(entry.get("portion_id", ""))
        }
    return {}


func save_food_portion(food_id: String, label: String, amount: float) -> bool:
    var food: Dictionary = food_by_id(food_id)
    var title = label.strip_edges()
    if food.is_empty() or title.is_empty() or data["food_portions"].size() >= 500:
        return false
    var existing_count = 0
    for p in data["food_portions"]:
        if str(p.get("food_id", "")) == food_id:
            existing_count += 1
            if str(p.get("label", "")).to_lower() == title.to_lower():
                return false
    if existing_count >= 12:
        return false
    var record: Dictionary = {
        "id": "size_" + str(Time.get_ticks_usec()) + "_" + str(data["food_portions"].size()),
        "food_id": food_id, "label": title, "amount": amount,
        "unit": PortionMath.base_unit(food)
    }
    if not PortionMath.valid_portion(record):
        return false
    data["food_portions"].append(record)
    if save():
        return true
    data["food_portions"].erase(record)
    return false

func delete_food_portion(portion_id: String) -> bool:
    for i in range(data["food_portions"].size()):
        if str(data["food_portions"][i].get("id", "")) == portion_id:
            var old = data["food_portions"][i]
            data["food_portions"].remove_at(i)
            if save():
                return true
            data["food_portions"].insert(i, old)
            return false
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

# Use the latest measurement on or before the selected day. Never prefill a
# historical date with a future measurement or revert silently to start weight.
func weight_prefill(day: String) -> float:
    var selected: float = float(data.get("settings", {}).get("start", 88.0))
    var latest_day: String = ""
    for record in data.get("weights", []):
        if not (record is Dictionary):
            continue
        var record_day: String = str(record.get("date", ""))
        var amount: float = float(record.get("value", 0.0))
        if record_day.is_empty() or record_day > day or record_day < latest_day or \
                not is_finite(amount) or amount < 20.0 or amount > 400.0:
            continue
        latest_day = record_day
        selected = amount
    return selected


func save_weight_entry(day: String, value: float) -> bool:
    var valid_day: bool = day.length() == 10 and day.substr(4, 1) == "-" and \
        day.substr(7, 1) == "-" and day.substr(0, 4).is_valid_int() and \
        day.substr(5, 2).is_valid_int() and day.substr(8, 2).is_valid_int()
    if not valid_day or not is_finite(value) or value < 20.0 or value > 400.0:
        return false
    var previous: Array = data["weights"].duplicate(true)
    data["weights"] = data["weights"].filter(func(record):
        return str(record.get("date", "")) != day)
    data["weights"].append({"id": "w" + day, "date": day, "value": value})
    if save():
        return true
    data["weights"] = previous
    return false


func body_measurements_on(day: String) -> Dictionary:
    for record in data.get("body_measurements", []):
        if record is Dictionary and str(record.get("date", "")) == day:
            return record.get("values", {}).duplicate(true)
    return {}


func body_metric_summary(key: String, max_date: String = "9999-12-31") -> Dictionary:
    return BodyMeasurements.metric_summary(data.get("body_measurements", []), key, max_date)


func body_metric_history(key: String, max_date: String = "9999-12-31") -> Array:
    return BodyMeasurements.metric_history(data.get("body_measurements", []), key, max_date)


func save_body_measurements(day: String, values: Dictionary) -> bool:
    var record: Dictionary = {"date": day, "values": values.duplicate(true)}
    if not BodyMeasurements.valid_record(record):
        return false
    var previous: Array = data["body_measurements"].duplicate(true)
    data["body_measurements"] = data["body_measurements"].filter(func(item):
        return str(item.get("date", "")) != day)
    data["body_measurements"].append(record)
    if save():
        return true
    data["body_measurements"] = previous
    return false


func delete_body_measurements(day: String) -> bool:
    if not BodyMeasurements.valid_date(day):
        return false
    var previous: Array = data["body_measurements"].duplicate(true)
    var kept: Array = data["body_measurements"].filter(func(item):
        return str(item.get("date", "")) != day)
    if kept.size() == previous.size():
        return false
    data["body_measurements"] = kept
    if save():
        return true
    data["body_measurements"] = previous
    return false


func day_entries(date: String) -> Array:
    return data["entries"].filter(func(e): return e is Dictionary and str(e.get("date", "")) == date)

func day_activities(date: String) -> Array:
    return data["activities"].filter(func(e): return e is Dictionary and str(e.get("date", "")) == date)

func day_steps(day: String) -> int:
    return roundi(float(data.get("steps", {}).get(day, 0)))

func set_day_steps(day: String, count: int) -> bool:
    if not ActivityMath.valid_date(day) or not ActivityMath.valid_steps(count):
        return false
    var before: Dictionary = data.get("steps", {}).duplicate(true)
    if count == 0:
        data["steps"].erase(day)
    else:
        data["steps"][day] = count
    if save():
        return true
    data["steps"] = before
    return false

func add_activity(day: String, kind: String, minutes: float,
        distance: float = 0.0, detail: String = "") -> bool:
    var record: Dictionary = {
        "id": "a" + str(Time.get_ticks_usec()) + "_" + str(data["activities"].size()),
        "date": day, "type": kind, "minutes": minutes,
        "distance": distance, "detail": detail.strip_edges()
    }
    if not ActivityMath.valid_activity(record):
        return false
    data["activities"].append(record)
    if save():
        return true
    data["activities"].erase(record)
    return false

func update_activity(record: Dictionary, changes: Dictionary) -> bool:
    if not data["activities"].has(record):
        return false
    var previous: Dictionary = record.duplicate(true)
    for key in ["type", "minutes", "distance", "detail"]:
        if changes.has(key):
            record[key] = changes[key]
    if not ActivityMath.valid_activity(record):
        record.clear()
        record.merge(previous, true)
        return false
    if save():
        return true
    record.clear()
    record.merge(previous, true)
    return false

func day_activity_summary(day: String) -> Dictionary:
    return ActivityMath.summarize(day_activities(day), weight_prefill(day), day_steps(day))

func week_activity_summary(day: String) -> Dictionary:
    var combined: Dictionary = {"count": 0, "minutes": 0, "estimated_kcal": 0, "steps": 0, "distance": 0.0}
    for item in week_dates(day):
        var daily: Dictionary = day_activity_summary(str(item))
        for key in combined:
            combined[key] = combined[key] + daily[key]
    return combined

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
