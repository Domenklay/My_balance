extends RefCounted

const Dates = preload("res://src/body_measurements.gd")
const DEFAULT_GOAL_ML = 2000
const MIN_GOAL_ML = 250
const MAX_GOAL_ML = 6000
const MIN_SERVING_ML = 25
const MAX_SERVING_ML = 2000
const MAX_DAY_ML = 20000

static func whole_number(value: Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and \
        is_equal_approx(float(value), roundf(float(value)))

static func valid_goal(value: Variant) -> bool:
    return whole_number(value) and int(value) >= MIN_GOAL_ML and \
        int(value) <= MAX_GOAL_ML

static func valid_amount(value: Variant) -> bool:
    return whole_number(value) and int(value) >= MIN_SERVING_ML and \
        int(value) <= MAX_SERVING_ML

static func valid_entry(raw: Variant) -> bool:
    if not (raw is Dictionary):
        return false
    var e: Dictionary = raw
    return e.get("id") is String and str(e["id"]).length() > 0 and \
        str(e["id"]).length() <= 100 and e.get("date") is String and \
        Dates.valid_date(str(e["date"])) and valid_amount(e.get("ml", null))

static func daily_total(records: Array, day: String) -> int:
    var result: int = 0
    for item in records:
        if valid_entry(item) and str(item["date"]) == day:
            result += int(item["ml"])
    return result

static func daily_summary(records: Array, day: String, goal: int) -> Dictionary:
    var taken: int = daily_total(records, day)
    return {
        "ml": taken, "goal": goal, "remaining": maxi(goal - taken, 0),
        "percent": 0.0 if goal <= 0 else minf(100.0, 100.0 * float(taken) / float(goal))
    }
