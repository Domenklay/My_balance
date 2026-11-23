extends RefCounted

# Graph windows are inclusive of the selected date and never include
# measurements from the future. Raw diary records are never modified.
const PERIOD_DAYS = {"month": 30, "quarter": 90, "all": -1}
const PERIOD_LABELS = {"month": "30 дней", "quarter": "90 дней", "all": "Всё"}

static func valid_period(period: String) -> bool:
    return PERIOD_DAYS.has(period)


static func period_label(period: String) -> String:
    return str(PERIOD_LABELS.get(period, "Всё"))


static func window_start(day: String, period: String) -> String:
    if not valid_period(period) or period == "all":
        return "0000-01-01"
    var stamp: int = Time.get_unix_time_from_datetime_string(day + "T12:00:00")
    var earlier: int = stamp - (int(PERIOD_DAYS[period]) - 1) * 86400
    return Time.get_date_string_from_unix_time(earlier)


static func filter_records(records: Array, day: String, period: String) -> Array:
    var result: Array = []
    if not valid_period(period) or day.length() != 10:
        return result
    var beginning: String = window_start(day, period)
    for item in records:
        if not (item is Dictionary):
            continue
        var dated: String = str(item.get("date", ""))
        var amount = item.get("value", null)
        if dated.length() != 10 or dated < beginning or dated > day:
            continue
        if not (amount is int or amount is float) or not is_finite(float(amount)):
            continue
        if float(amount) < 10.0 or float(amount) > 400.0:
            continue
        result.append({"date": dated, "value": float(amount)})
    result.sort_custom(func(a, b): return str(a["date"]) < str(b["date"]))
    return result


static func summarize(records: Array) -> Dictionary:
    if records.is_empty():
        return {}
    var first: Dictionary = records[0]
    var latest: Dictionary = records[records.size() - 1]
    return {
        "first": float(first["value"]),
        "latest": float(latest["value"]),
        "change": snappedf(float(latest["value"]) - float(first["value"]), 0.1),
        "first_date": str(first["date"]),
        "latest_date": str(latest["date"]),
        "count": records.size()
    }


static func format_delta(delta: float, unit: String) -> String:
    var direction: String = "+" if delta > 0.0 else ""
    return direction + str(snappedf(delta, 0.1)) + " " + unit
