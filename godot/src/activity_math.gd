extends RefCounted

# MET values are approximate intensity factors for an adult at an ordinary pace.
# This is a reference estimate, not a measurement from a fitness sensor.
const MET_VALUES = {
    "walk": 3.5, "run": 8.0, "cycling": 6.0,
    "strength": 3.5, "yoga": 2.5, "swim": 6.0, "other": 3.0
}
const TYPE_NAMES = {
    "walk": "🚶 Ходьба", "run": "🏃 Бег", "cycling": "🚴 Велосипед",
    "strength": "🏋 Силовая", "yoga": "🧘 Йога",
    "swim": "🏊 Плавание", "other": "Другая активность"
}

static func valid_date(day: String) -> bool:
    if day.length() != 10 or day.substr(4, 1) != "-" or day.substr(7, 1) != "-":
        return false
    if not (day.substr(0, 4).is_valid_int() and day.substr(5, 2).is_valid_int() and day.substr(8, 2).is_valid_int()):
        return false
    return int(day.substr(0, 4)) > 1900 and int(day.substr(5, 2)) in range(1, 13) and int(day.substr(8, 2)) in range(1, 32)

static func valid_steps(value: Variant) -> bool:
    if not (value is int or value is float):
        return false
    var number: float = float(value)
    return is_finite(number) and number >= 0.0 and number <= 100000.0 and is_equal_approx(number, roundf(number))

static func valid_activity(record: Variant) -> bool:
    if not (record is Dictionary):
        return false
    var item: Dictionary = record
    # Entries from pre-0.7.43 journals could omit the optional id.
    # Keep them readable, editable and eligible for estimates on import.
    if not (item.get("date") is String and item.get("type") is String):
        return false
    if item.has("id") and (not (item["id"] is String) or str(item["id"]).length() > 100):
        return false
    if not valid_date(str(item["date"])):
        return false
    if not MET_VALUES.has(item["type"]):
        return false
    var duration = item.get("minutes")
    var distance = item.get("distance", 0.0)
    if not (duration is int or duration is float) or not (distance is int or distance is float):
        return false
    if not is_finite(float(duration)) or float(duration) < 1.0 or float(duration) > 1440.0:
        return false
    if not is_finite(float(distance)) or float(distance) < 0.0 or float(distance) > 100.0:
        return false
    return item.get("detail", "") is String and str(item.get("detail", "")).length() <= 500

static func type_name(kind: String) -> String:
    return str(TYPE_NAMES.get(kind, "Другая активность"))

static func estimate_kcal(activity: Dictionary, weight_kg: float) -> int:
    if not valid_activity(activity) or not is_finite(weight_kg) or weight_kg < 20.0 or weight_kg > 400.0:
        return 0
    # MET x 3.5 mL/kg/min x body weight / 200 gives gross kcal/minute.
    # No calorie allowance is added to the food diary from this estimate.
    var met: float = float(MET_VALUES.get(str(activity["type"]), 3.0))
    return maxi(0, roundi(met * 3.5 * weight_kg * float(activity["minutes"]) / 200.0))

static func summarize(activities: Array, weight_kg: float, steps: int = 0) -> Dictionary:
    var result: Dictionary = {
        "count": 0, "minutes": 0, "estimated_kcal": 0,
        "distance": 0.0, "steps": maxi(steps, 0)
    }
    for item in activities:
        if not valid_activity(item):
            continue
        result["count"] = int(result["count"]) + 1
        result["minutes"] = int(result["minutes"]) + roundi(float(item["minutes"]))
        result["distance"] = float(result["distance"]) + float(item.get("distance", 0.0))
        result["estimated_kcal"] = int(result["estimated_kcal"]) + estimate_kcal(item, weight_kg)
    return result
