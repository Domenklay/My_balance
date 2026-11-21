extends RefCounted

# Read-only period aggregates. Empty days never contribute to mean calories.
# Nutrition is taken from stored entry snapshots, preserving historical edits.
static func dates_for(store: RefCounted, anchor: String, mode: String) -> Array:
    if mode == "week":
        return store.week_dates(anchor)
    var month: String = anchor.substr(0, 7)
    var first: String = month + "-01"
    var unix: int = int(Time.get_unix_time_from_datetime_string(first + "T12:00:00"))
    var days: Array = []
    for offset in range(31):
        var date: String = Time.get_date_string_from_unix_time(unix + offset * 86400)
        if not date.begins_with(month):
            break
        days.append(date)
    return days

static func summarize(store: RefCounted, anchor: String, mode: String) -> Dictionary:
    var dates: Array = dates_for(store, anchor, mode)
    var indexed: Dictionary = {}
    for date in dates:
        indexed[str(date)] = {
            "date": str(date), "kcal": 0.0, "p": 0.0, "f": 0.0,
            "c": 0.0, "entries": 0, "walk": 0, "exercise": 0,
            "activities": 0, "workouts": 0
        }
    for entry in store.data.get("entries", []):
        if not (entry is Dictionary):
            continue
        var day: String = str(entry.get("date", ""))
        if not indexed.has(day):
            continue
        var bucket: Dictionary = indexed[day]
        var factor: float = maxf(0.0, float(entry.get("grams", 0))) / 100.0
        var food: Dictionary = store.entry_food(entry)
        bucket["entries"] += 1
        for nutrient in ["kcal", "p", "f", "c"]:
            bucket[nutrient] += maxf(0.0, float(food.get(nutrient, 0.0))) * factor
    for activity in store.data.get("activities", []):
        if not (activity is Dictionary):
            continue
        var day: String = str(activity.get("date", ""))
        if not indexed.has(day):
            continue
        var bucket: Dictionary = indexed[day]
        var minutes: int = maxi(0, int(activity.get("minutes", 0)))
        bucket["activities"] += 1
        if str(activity.get("type", "")) == "walk":
            bucket["walk"] += minutes
        else:
            bucket["exercise"] += minutes
            bucket["workouts"] += 1
    var calendar: Array = []
    var count: int = 0
    var kcal_total: float = 0.0
    var p_total: float = 0.0
    var f_total: float = 0.0
    var c_total: float = 0.0
    var walks: int = 0
    var exercises: int = 0
    var workouts: int = 0
    for day in dates:
        var value: Dictionary = indexed[str(day)]
        calendar.append(value)
        walks += int(value["walk"])
        exercises += int(value["exercise"])
        workouts += int(value["workouts"])
        if int(value["entries"]) > 0:
            count += 1
            kcal_total += float(value["kcal"])
            p_total += float(value["p"])
            f_total += float(value["f"])
            c_total += float(value["c"])
    var columns: Array = []
    if mode == "week":
        for value in calendar:
            columns.append({
                "label": str(value["date"]).substr(8, 2),
                "kcal": float(value["kcal"]),
                "recorded": int(value["entries"]) > 0,
                "walk": int(value["walk"]),
                "exercise": int(value["exercise"]),
                "activity": int(value["activities"]) > 0
            })
    else:
        # Calendar Monday–Sunday weeks, clipped to this calendar month.
        var first_weekday: int = int(Time.get_datetime_dict_from_datetime_string(
            str(dates[0]) + "T12:00:00", true).get("weekday", 1))
        var offset: int = (first_weekday + 6) % 7
        var groups: Array = []
        for i in range(calendar.size()):
            var group_index: int = (i + offset) / 7
            while groups.size() <= group_index:
                groups.append({
                    "first": str(calendar[i]["date"]).substr(8, 2),
                    "last": str(calendar[i]["date"]).substr(8, 2),
                    "total": 0.0, "logged": 0,
                    "walk": 0, "exercise": 0, "activity": 0
                })
            var group: Dictionary = groups[group_index]
            var value: Dictionary = calendar[i]
            group["last"] = str(value["date"]).substr(8, 2)
            if int(value["entries"]) > 0:
                group["logged"] += 1
                group["total"] += float(value["kcal"])
            group["walk"] += int(value["walk"])
            group["exercise"] += int(value["exercise"])
            group["activity"] += int(value["activities"])
        for group in groups:
            columns.append({
                "label": str(int(group["first"])) + "–" + str(int(group["last"])),
                "kcal": float(group["total"]) / float(group["logged"])
                    if int(group["logged"]) > 0 else 0.0,
                "recorded": int(group["logged"]) > 0,
                "walk": int(group["walk"]),
                "exercise": int(group["exercise"]),
                "activity": int(group["activity"]) > 0
            })
    var weights: Array = []
    for record in store.data.get("weights", []):
        if not (record is Dictionary):
            continue
        if indexed.has(str(record.get("date", ""))):
            weights.append(record)
    weights.sort_custom(func(a,b): return str(a.get("date", "")) < str(b.get("date", "")))
    var divisor: float = float(count) if count > 0 else 1.0
    return {
        "mode": mode, "dates": dates, "calendar": calendar,
        "columns": columns, "recorded": count, "total_days": dates.size(),
        "avg_kcal": kcal_total / divisor,
        "avg_p": p_total / divisor, "avg_f": f_total / divisor,
        "avg_c": c_total / divisor,
        "walking": walks, "exercise": exercises, "workouts": workouts,
        "weights": weights
    }

static func label_for(dates: Array, mode: String) -> String:
    if dates.is_empty():
        return "Период"
    if mode == "month":
        var year: String = str(dates[0]).substr(0, 4)
        var month: String = str(dates[0]).substr(5, 2)
        return month + "." + year
    var a: String = str(dates[0])
    var b: String = str(dates[dates.size() - 1])
    return a.substr(8, 2) + "." + a.substr(5, 2) +
        " – " + b.substr(8, 2) + "." + b.substr(5, 2) + "." + b.substr(0, 4)
