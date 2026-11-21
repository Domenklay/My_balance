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

# Restore an actual last-used amount without silently guessing the mass of a
# spoon, piece or household cup. Entries made before 0.7.35 have no saved
# count: reconstruct only exactly representable 0.1-step quantities.
static func recalled_choice(options: Array, last: Dictionary) -> Dictionary:
    var empty: Dictionary = {"index": 0, "quantity": 100.0, "restored": false}
    if last.is_empty() or options.is_empty():
        return empty
    var raw_amount = last.get("grams", 0.0)
    if not (raw_amount is int or raw_amount is float):
        return empty
    var amount: float = float(raw_amount)
    if not is_finite(amount) or amount <= 0.0 or amount > 5000.0 or \
            str(last.get("unit", "")) != str(options[0].get("unit", "")):
        return empty
    var fallback: Dictionary = {"index": 0, "quantity": amount, "restored": true}
    var label: String = str(last.get("portion_label", ""))
    if label.is_empty():
        return fallback
    var recorded_id: String = str(last.get("portion_id", ""))
    for i in range(1, options.size()):
        var option: Dictionary = options[i]
        if str(option.get("label", "")) != label:
            continue
        if not recorded_id.is_empty() and recorded_id != str(option.get("id", "")):
            continue
        var one: float = float(option.get("amount", 0.0))
        if not is_finite(one) or one <= 0.0:
            continue
        var count: float = amount / one
        var saved_count: Variant = last.get("portion_count", 0.0)
        if (saved_count is int or saved_count is float) and \
                is_finite(float(saved_count)) and float(saved_count) > 0.0 and \
                absf(float(saved_count) * one - amount) < 0.001:
            count = float(saved_count)
        elif absf(snappedf(count, 0.1) - count) > 0.00001:
            # Old diary rows have no unit-count metadata. Prefer exact grams
            # rather than rounding the remembered serving to another weight.
            continue
        if count >= 0.1 and count <= 5000.0 and \
                absf(quantity_to_base(option, count) - amount) < 0.001:
            return {"index": i, "quantity": count, "restored": true}
    return fallback
