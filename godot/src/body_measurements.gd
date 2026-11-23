extends RefCounted

# Independent optional circumference measurements in centimetres.
const FIELDS = [
    ["chest", "Грудь"],
    ["waist", "Талия"],
    ["abdomen", "Живот"],
    ["hips", "Бёдра"],
    ["upper_arm", "Рука"],
    ["thigh", "Бедро"],
    ["calf", "Икра"],
    ["neck", "Шея"]
]

static func valid_date(day: String) -> bool:
    if day.length() != 10 or day.substr(4, 1) != "-" or day.substr(7, 1) != "-":
        return false
    var yr = day.substr(0, 4)
    var mn = day.substr(5, 2)
    var dn = day.substr(8, 2)
    if not (yr.is_valid_int() and mn.is_valid_int() and dn.is_valid_int()):
        return false
    var year: int = int(yr)
    var month: int = int(mn)
    var number: int = int(dn)
    if year < 1900 or year > 2200 or month < 1 or month > 12:
        return false
    var last_days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    var max_day: int = last_days[month - 1]
    if month == 2 and (year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)):
        max_day = 29
    return number >= 1 and number <= max_day


static func is_metric(key: String) -> bool:
    for entry in FIELDS:
        if entry[0] == key:
            return true
    return false


static func display_name(key: String) -> String:
    for entry in FIELDS:
        if entry[0] == key:
            return str(entry[1])
    return key


static func valid_value(value: Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and \
        float(value) >= 10.0 and float(value) <= 300.0


static func valid_record(value: Variant) -> bool:
    if not (value is Dictionary):
        return false
    var record: Dictionary = value
    if not (record.get("date") is String and record.get("values") is Dictionary):
        return false
    if not valid_date(str(record["date"])):
        return false
    var fields: Dictionary = record["values"]
    if fields.is_empty() or fields.size() > FIELDS.size():
        return false
    for key in fields:
        if not (key is String) or not is_metric(key) or not valid_value(fields[key]):
            return false
    return true


static func metric_history(records: Array, key: String, max_date: String = "9999-12-31") -> Array:
    var result: Array = []
    if not is_metric(key):
        return result
    for item in records:
        if not valid_record(item):
            continue
        if str(item["date"]) > max_date:
            continue
        if item["values"].has(key):
            result.append({"date": str(item["date"]), "value": float(item["values"][key])})
    result.sort_custom(func(a, b): return str(a["date"]) < str(b["date"]))
    return result


static func metric_summary(records: Array, key: String, max_date: String = "9999-12-31") -> Dictionary:
    var entries: Array = metric_history(records, key, max_date)
    if entries.is_empty():
        return {}
    var first: Dictionary = entries[0]
    var recent: Dictionary = entries[entries.size() - 1]
    var previous: Dictionary = entries[entries.size() - 2] if entries.size() > 1 else recent
    return {
        "first": float(first["value"]), "first_date": str(first["date"]),
        "latest": float(recent["value"]), "latest_date": str(recent["date"]),
        "change": float(recent["value"]) - float(first["value"]),
        "previous_change": float(recent["value"]) - float(previous["value"]),
        "count": entries.size()
    }


static func as_of(records: Array, day: String) -> Dictionary:
    var result: Dictionary = {}
    for field in FIELDS:
        var metric: Dictionary = metric_summary(records, str(field[0]), day)
        if not metric.is_empty():
            result[str(field[0])] = metric
    return result
