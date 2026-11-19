extends RefCounted

# All nutrients in an ingredient are per 100 g of that raw ingredient.
# Finished mass (water loss/gain) changes nutrients per 100 g but never total.
const NUTRIENTS = ["kcal", "p", "f", "c"]

static func valid_ingredient(value: Variant) -> bool:
    if not (value is Dictionary):
        return false
    var name = str(value.get("name", "")).strip_edges()
    if name.is_empty() or name.length() > 160:
        return false
    var grams = value.get("grams")
    if not (grams is float or grams is int):
        return false
    if not is_finite(float(grams)) or float(grams) <= 0 or float(grams) > 10000:
        return false
    for n in NUTRIENTS:
        var v = value.get(n)
        if not (v is float or v is int):
            return false
        if not is_finite(float(v)) or float(v) < 0.0 or float(v) > (1000.0 if n == "kcal" else 100.0):
            return false
    return true

static func calculate(ingredients: Array, cooked_weight: float) -> Dictionary:
    if ingredients.is_empty() or ingredients.size() > 40:
        return {}
    if not is_finite(cooked_weight) or cooked_weight <= 0.0 or cooked_weight > 50000.0:
        return {}
    var result = {"raw_weight": 0.0, "cooked_weight": cooked_weight}
    for n in NUTRIENTS:
        result["total_" + n] = 0.0
    for ingredient in ingredients:
        if not valid_ingredient(ingredient):
            return {}
        var g = float(ingredient["grams"])
        result["raw_weight"] += g
        for n in NUTRIENTS:
            result["total_" + n] += float(ingredient[n]) * g / 100.0
    for n in NUTRIENTS:
        result[n] = result["total_" + n] * 100.0 / cooked_weight
    return result

static func validate_recipe(recipe: Variant) -> bool:
    if not (recipe is Dictionary):
        return false
    if str(recipe.get("id", "")).is_empty() or str(recipe["id"]).length() > 100:
        return false
    var name = str(recipe.get("name", "")).strip_edges()
    if name.is_empty() or name.length() > 160:
        return false
    var cooked = recipe.get("cooked_weight")
    var servings = recipe.get("servings")
    if not (cooked is int or cooked is float) or not (servings is int or servings is float):
        return false
    if not is_finite(float(servings)) or float(servings) < 1.0 or float(servings) > 100.0:
        return false
    var parts = recipe.get("ingredients")
    if not (parts is Array):
        return false
    return not calculate(parts, float(cooked)).is_empty()

static func portion(food_name: String, metrics: Dictionary, grams: float) -> Dictionary:
    if metrics.is_empty() or grams <= 0.0 or grams > 5000.0:
        return {}
    var entry = {"name": food_name, "grams": grams}
    for n in NUTRIENTS:
        entry[n] = float(metrics[n]) * grams / 100.0
    return entry
