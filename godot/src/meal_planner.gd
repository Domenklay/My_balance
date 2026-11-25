extends RefCounted

const RecipeMath = preload("res://src/recipe_math.gd")
const PortionMath = preload("res://src/portion_math.gd")
const BodyMeasurements = preload("res://src/body_measurements.gd")

const MAX_ITEMS = 3000
const MAX_DAY_ITEMS = 30
const MAX_INGREDIENTS = 40
const MEALS = ["Завтрак", "Обед", "Ужин", "Перекус"]
const NUTRIENTS = ["kcal", "p", "f", "c"]

static func valid_item(value: Variant) -> bool:
    if not (value is Dictionary):
        return false
    var item: Dictionary = value
    if not (item.get("id") is String and str(item["id"]).length() > 0 and \
            str(item["id"]).length() <= 110 and item.get("date") is String and \
            BodyMeasurements.valid_date(str(item["date"]))):
        return false
    if str(item.get("meal", "")) not in MEALS:
        return false
    if str(item.get("source", "")) not in ["recipe", "food"] or \
            not (item.get("source_id") is String) or \
            str(item["source_id"]).length() > 120:
        return false
    if not (item.get("name") is String) or \
            str(item["name"]).strip_edges().is_empty() or \
            str(item["name"]).length() > 160:
        return false
    if not (item.get("grams") is float or item.get("grams") is int):
        return false
    if not is_finite(float(item["grams"])) or float(item["grams"]) <= 0.0 or \
            float(item["grams"]) > 5000.0 or str(item.get("unit", "")) not in ["г", "мл"]:
        return false
    if not (item.get("nutrition") is Dictionary and item.get("ingredients") is Array):
        return false
    var nutrition: Dictionary = item["nutrition"]
    if str(nutrition.get("name", "")) != str(item["name"]):
        return false
    for nutrient in NUTRIENTS:
        if not (nutrition.get(nutrient) is float or nutrition.get(nutrient) is int):
            return false
        if not is_finite(float(nutrition[nutrient])) or float(nutrition[nutrient]) < 0.0 or \
                float(nutrition[nutrient]) > (20000.0 if nutrient == "kcal" else 1000.0):
            return false
    var ingredients: Array = item["ingredients"]
    if ingredients.is_empty() or ingredients.size() > MAX_INGREDIENTS:
        return false
    for ingredient in ingredients:
        if not (ingredient is Dictionary) or not (ingredient.get("name") is String):
            return false
        var name: String = str(ingredient["name"]).strip_edges()
        if name.is_empty() or name.length() > 160 or \
                str(ingredient.get("unit", "")) not in ["г", "мл"]:
            return false
        var amount = ingredient.get("grams")
        if not (amount is float or amount is int) or \
                not is_finite(float(amount)) or float(amount) <= 0.0 or float(amount) > 50000.0:
            return false
    return true


static func recipe_snapshot(recipe: Dictionary, day: String, meal: String, grams: float) -> Dictionary:
    if not BodyMeasurements.valid_date(day) or meal not in MEALS or \
            not is_finite(grams) or grams <= 0.0 or grams > 5000.0 or \
            not RecipeMath.validate_recipe(recipe):
        return {}
    var metrics: Dictionary = RecipeMath.calculate(recipe["ingredients"],
        float(recipe["cooked_weight"]))
    if metrics.is_empty():
        return {}
    var factor: float = grams / float(recipe["cooked_weight"])
    var ingredient_snapshots: Array = []
    for ingredient in recipe["ingredients"]:
        ingredient_snapshots.append({
            "name": str(ingredient["name"]).strip_edges(),
            "unit": str(ingredient.get("unit", "г")),
            "grams": snappedf(float(ingredient["grams"]) * factor, 0.01)
        })
    var nutrition: Dictionary = {"name": str(recipe["name"])}
    for nutrient in NUTRIENTS:
        nutrition[nutrient] = float(metrics[nutrient])
    var planned: Dictionary = {
        "id": "preview", "date": day, "meal": meal, "name": str(recipe["name"]),
        "source": "recipe", "source_id": str(recipe["id"]), "grams": grams,
        "unit": "г", "nutrition": nutrition, "ingredients": ingredient_snapshots
    }
    return planned if valid_item(planned) else {}


static func food_snapshot(food: Dictionary, day: String, meal: String, grams: float) -> Dictionary:
    if not BodyMeasurements.valid_date(day) or meal not in MEALS or \
            not is_finite(grams) or grams <= 0.0 or grams > 5000.0:
        return {}
    var name: String = str(food.get("name", "")).strip_edges()
    var unit: String = PortionMath.base_unit(food)
    if name.is_empty() or unit not in ["г", "мл"]:
        return {}
    var nutrition: Dictionary = {"name": name}
    for nutrient in NUTRIENTS:
        nutrition[nutrient] = food.get(nutrient)
    var planned: Dictionary = {
        "id": "preview", "date": day, "meal": meal, "name": name,
        "source": "food", "source_id": str(food.get("id", "")),
        "grams": grams, "unit": unit, "nutrition": nutrition,
        "ingredients": [{"name": name, "unit": unit, "grams": grams}]
    }
    return planned if valid_item(planned) else {}


static func item_kcal(item: Dictionary) -> float:
    return float(item["nutrition"]["kcal"]) * float(item["grams"]) / 100.0


static func nutrition_totals(items: Array) -> Dictionary:
    var totals: Dictionary = {"kcal":0.0, "p":0.0, "f":0.0, "c":0.0}
    for item in items:
        if not valid_item(item):
            continue
        var factor: float = float(item["grams"]) / 100.0
        for nutrient in NUTRIENTS:
            totals[nutrient] += float(item["nutrition"][nutrient]) * factor
    return totals


# Presentation only; neither filtering nor copying mutates the checklist.
static func filter_shopping(items: Array, mode: int) -> Array:
    return items.filter(func(item):
        return mode == 0 or bool(item["bought"]) == (mode == 2))


static func shopping_text(items: Array, extra: Array) -> String:
    var lines: PackedStringArray = ["Список покупок"]
    for item in filter_shopping(items, 1):
        lines.append("☐ " + str(item["name"]) + " — " + str(snappedf(float(item["grams"]), 0.1)) + " " + str(item["unit"]))
    if not extra.is_empty():
        lines.append("")
        lines.append("Дополнительные покупки (без количества):")
        for title in extra:
            lines.append("☐ " + str(title))
    return "\n".join(lines)


static func items_for_day(items: Array, day: String) -> Array:
    var out: Array = []
    for item in items:
        if valid_item(item) and str(item["date"]) == day:
            out.append(item)
    out.sort_custom(func(a, b):
        if MEALS.find(str(a["meal"])) != MEALS.find(str(b["meal"])):
            return MEALS.find(str(a["meal"])) < MEALS.find(str(b["meal"]))
        return str(a["id"]) < str(b["id"]))
    return out


static func shopping_key(name: String, unit: String) -> String:
    return name.strip_edges().to_lower() + "|" + unit


static func shopping_for_week(items: Array, dates: Array, bought: Array = []) -> Array:
    var selected_dates: Dictionary = {}
    for day in dates:
        selected_dates[str(day)] = true
    var combined: Dictionary = {}
    for item in items:
        if not valid_item(item) or not selected_dates.has(str(item["date"])):
            continue
        for part in item["ingredients"]:
            var key: String = shopping_key(str(part["name"]), str(part["unit"]))
            if not combined.has(key):
                combined[key] = {"key": key, "name": str(part["name"]),
                    "unit": str(part["unit"]), "grams": 0.0, "bought": false}
            combined[key]["grams"] = float(combined[key]["grams"]) + float(part["grams"])
    var result: Array = []
    for key in combined.keys():
        var info: Dictionary = combined[key]
        info["grams"] = snappedf(float(info["grams"]), 0.1)
        info["bought"] = key in bought
        result.append(info)
    result.sort_custom(func(a, b): return str(a["name"]).nocasecmp_to(str(b["name"])) < 0)
    return result


static func valid_checked_state(value: Variant) -> bool:
    if not (value is Dictionary) or value.size() > 400:
        return false
    for week in value:
        if not (week is String) or not BodyMeasurements.valid_date(week) or \
                not (value[week] is Array) or value[week].size() > 800:
            return false
        var keys: Dictionary = {}
        for key in value[week]:
            if not (key is String) or str(key).is_empty() or str(key).length() > 200 or \
                    keys.has(key):
                return false
            keys[key] = true
    return true
