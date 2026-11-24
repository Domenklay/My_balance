extends RefCounted
const RecipeMath = preload("res://src/recipe_math.gd")

# Explicit targets only. Never infer a macro goal or change the diary.
static func remaining(target_kcal: float, consumed_kcal: float, targets: Dictionary, consumed: Dictionary) -> Dictionary:
    var result = {"kcal": maxf(0.0, target_kcal - consumed_kcal)}
    for key in ["p", "f", "c"]:
        if float(targets.get(key, 0)) > 0:
            result[key] = maxf(0.0, float(targets[key]) - float(consumed.get(key, 0)))
    return result

static func recommend(recipes: Array, budget: Dictionary, factor: float = 1.0, category: String = "") -> Array:
    var found: Array = []
    if float(budget.get("kcal", 0)) <= 0 or factor not in [0.5, 1.0, 1.5, 2.0]:
        return found
    for recipe in recipes:
        if not RecipeMath.validate_recipe(recipe):
            continue
        if not category.is_empty() and recipe.get("category", "other") != category:
            continue
        var metrics = RecipeMath.calculate(recipe["ingredients"], float(recipe["cooked_weight"]))
        var grams = roundf(float(recipe["cooked_weight"]) / float(recipe["servings"]) * factor)
        if grams < 1 or grams > 5000:
            continue
        var portion = RecipeMath.portion(str(recipe["name"]), metrics, grams)
        if float(portion["kcal"]) <= 0 or float(portion["kcal"]) > float(budget["kcal"]) + 0.00001:
            continue
        var fits = true
        var macro_score = 0.0
        var count = 0
        for key in ["p", "f", "c"]:
            if not budget.has(key):
                continue
            var left = float(budget[key])
            if float(portion[key]) > left + 0.00001:
                fits = false
                break
            if left > 0:
                macro_score += float(portion[key]) / left
                count += 1
        if not fits:
            continue
        var energy_score = float(portion["kcal"]) / float(budget["kcal"])
        var score = energy_score if count == 0 else 0.4 * energy_score + 0.6 * macro_score / count
        found.append({"recipe": recipe, "portion": portion, "grams": grams, "score": score})
    found.sort_custom(func(a,b):
        if is_equal_approx(float(a["score"]), float(b["score"])):
            return str(a["recipe"]["id"]) < str(b["recipe"]["id"])
        return float(a["score"]) > float(b["score"])
    )
    return found
