extends RefCounted

# Mifflin–St Jeor adult resting metabolism estimate (kcal/day).
# Population-based formula: only an estimate, not medical nutrition advice.
const ACTIVITY_FACTORS = [1.2, 1.375, 1.55, 1.725]
const ACTIVITY_LABELS = [
    "Мало движения", "Немного активности (1–3 дня)",
    "Умеренно активно (3–5 дней)", "Очень активно"
]
const GOALS = ["Сохранять вес", "Постепенно снизить вес", "Постепенно набрать вес"]
const SEX_LABELS = [
    "Женская формула", "Мужская формула",
    "Не выбирать — норма вручную"
]

static func valid_details(details: Variant) -> bool:
    if not (details is Dictionary):
        return false
    if str(details.get("name", "")).strip_edges().is_empty() or str(details.get("name", "")).length() > 45:
        return false
    for key in ["age", "height", "weight", "goal_weight"]:
        var x = details.get(key)
        if not (x is float or x is int) or not is_finite(float(x)):
            return false
    var age = float(details["age"])
    var height = float(details["height"])
    var weight = float(details["weight"])
    var goal_weight = float(details["goal_weight"])
    if age < 18 or age > 100 or not is_equal_approx(age, roundf(age)):
        return false
    if height < 100 or height > 240 or weight < 25 or weight > 350:
        return false
    if goal_weight < 25 or goal_weight > 350:
        return false
    if str(details.get("formula", "")) not in ["female", "male", "manual"]:
        return false
    var activity = details.get("activity")
    var goal = details.get("goal")
    if not (activity is float or activity is int) or not (goal is float or goal is int):
        return false
    if float(activity) != roundf(float(activity)) or float(goal) != roundf(float(goal)):
        return false
    return int(activity) in range(4) and int(goal) in range(3)

static func estimate(details: Dictionary) -> Dictionary:
    if not valid_details(details):
        return {}
    var mode = str(details["formula"])
    if mode == "manual":
        return {"automatic":false, "kcal":1800.0,
            "message":"Норма вводится вручную — без выбора коэффициента формулы."}
    var age = float(details["age"])
    var height = float(details["height"])
    var weight = float(details["weight"])
    var constant = -161.0 if mode == "female" else 5.0
    var bmr = 10.0 * weight + 6.25 * height - 5.0 * age + constant
    var maintain = bmr * float(ACTIVITY_FACTORS[int(details["activity"])])
    var goal = int(details["goal"])
    var suggested = maintain
    if goal == 1:
        # Small 10% change, up to 300 kcal; do not prescribe a large deficit.
        suggested = maintain - minf(300.0, maintain * 0.10)
        # Do not generate an extreme low calculated target.
        var floor = 1200.0 if mode == "female" else 1500.0
        suggested = maxf(suggested, minf(floor, maintain))
    elif goal == 2:
        suggested = maintain + minf(300.0, maintain * 0.10)
    suggested = clampf(roundf(suggested / 10.0) * 10.0, 1000, 5000)
    return {
        "automatic":true, "bmr":roundf(bmr),
        "maintenance":roundf(maintain),
        "kcal":suggested,
        "message":"Приблизительный расчёт по формуле Миффлина — Сан Жеора. Не медицинское назначение."
    }
