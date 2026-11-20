extends RefCounted

# Each product has a single explicitly declared nutrient basis: 100 g or 100 ml.
# Never treat 1 ml as 1 g; saved portions convert only to the declared basis.
static func base_unit(food: Dictionary) -> String:
    return "мл" if str(food.get("nutrition_unit", "г")) == "мл" else "г"

static func valid_portion(portion: Variant) -> bool:
    if not (portion is Dictionary):
        return false
    if not (portion.get("id") is String and portion.get("food_id") is String and
            portion.get("label") is String and portion.get("unit") is String):
        return false
    if str(portion["id"]).is_empty() or str(portion["id"]).length() > 100:
        return false
    if str(portion["food_id"]).is_empty() or str(portion["food_id"]).length() > 100:
        return false
    if str(portion["label"]).strip_edges().is_empty() or str(portion["label"]).length() > 36:
        return false
    if str(portion["unit"]) not in ["г", "мл"]:
        return false
    var amount = portion.get("amount")
    return (amount is float or amount is int) and is_finite(float(amount)) and float(amount) > 0.0 and float(amount) <= 5000.0

static func options(food: Dictionary, saved: Array) -> Array:
    var unit = base_unit(food)
    var result: Array = [{"id":"", "label":unit, "amount":1.0, "unit":unit}]
    var food_id = str(food.get("id", ""))
    for record in saved:
        if not valid_portion(record) or str(record.get("food_id", "")) != food_id:
            continue
        if str(record.get("unit", "")) != unit:
            continue
        result.append(record.duplicate(true))
    return result

static func quantity_to_base(option: Dictionary, quantity: float) -> float:
    if not is_finite(quantity) or quantity <= 0.0:
        return 0.0
    var result = quantity * float(option.get("amount", 0.0))
    return result if is_finite(result) and result > 0.0 and result <= 5000.0 else 0.0

static func nutrients(food: Dictionary, base_amount: float) -> Dictionary:
    if not is_finite(base_amount) or base_amount <= 0.0 or base_amount > 5000.0:
        return {}
    var result: Dictionary = {}
    for key in ["kcal", "p", "f", "c"]:
        result[key] = float(food.get(key, 0.0)) * base_amount / 100.0
    return result
