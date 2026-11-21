extends RefCounted

# Read-only period aggregates. Empty days never contribute to mean calories.
# Nutrition is taken from stored entry snapshots, preserving historical edits.
static func shifted_month(month: String, amount: int) -> String:
    var index: int = int(month.substr(0, 4)) * 12 + int(month.substr(5, 2)) - 1 + amount
    var year: int = floori(float(index) / 12.0)
    var month_number: int = posmod(index, 12) + 1
    return str(year) + "-" + str(month_number).pad_zeros(2)


# Matching full calendar periods. For multi-month reports the comparison is
# the preceding three complete calendar months, not a rolling 90-day guess.
static func previous_anchor(store, anchor: String, mode: String) -> String:
    if mode == "week":
        return store.change_date(anchor, -7)
    return shifted_month(anchor.substr(0, 7), -3 if mode == "quarter" else -1) + "-15"


static func dates_for(store, anchor: String, mode: String) -> Array:
    if mode == "week":
        return store.week_dates(anchor)
    var month: String = anchor.substr(0, 7)
    var first_month: String = shifted_month(month, -2) if mode == "quarter" else month
    var after_last_month: String = shifted_month(month, 1)
    var unix: int = int(Time.get_unix_time_from_datetime_string(first_month + "-01T12:00:00"))
    var days: Array = []
    for offset in range(100 if mode == "quarter" else 31):
        var day: String = Time.get_date_string_from_unix_time(unix + offset * 86400)
        if mode == "quarter":
            if day.substr(0, 7) == after_last_month:
                break
        elif not day.begins_with(month):
            break
        days.append(day)
    return days

static func summarize(store, anchor: String, mode: String) -> Dictionary:
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
    elif mode == "quarter":
        # Exactly three full calendar months; each bar uses the mean of days
        # with entries, so empty days cannot appear as zero-calorie readings.
        var month_groups: Array = []
        for value in calendar:
            var month_key: String = str(value["date"]).substr(0, 7)
            if month_groups.is_empty() or str(month_groups[month_groups.size() - 1]["month"]) != month_key:
                month_groups.append({
                    "month": month_key, "total": 0.0, "logged": 0,
                    "walk": 0, "exercise": 0, "activity": 0
                })
            var group: Dictionary = month_groups[month_groups.size() - 1]
            if int(value["entries"]) > 0:
                group["logged"] += 1
                group["total"] += float(value["kcal"])
            group["walk"] += int(value["walk"])
            group["exercise"] += int(value["exercise"])
            group["activity"] += int(value["activities"])
        for group in month_groups:
            columns.append({
                "label": str(group["month"]).substr(5, 2) + "." +
                    str(group["month"]).substr(2, 2),
                "kcal": (float(group["total"]) / float(group["logged"])
                    if int(group["logged"]) > 0 else 0.0),
                "recorded": int(group["logged"]) > 0,
                "walk": int(group["walk"]), "exercise": int(group["exercise"]),
                "activity": int(group["activity"]) > 0
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
                "kcal": (float(group["total"]) / float(group["logged"])
                    if int(group["logged"]) > 0 else 0.0),
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
    if mode == "quarter":
        return str(dates[0]).substr(5, 2) + "." + str(dates[0]).substr(0, 4) + \
            " – " + str(dates[dates.size() - 1]).substr(5, 2) +
            "." + str(dates[dates.size() - 1]).substr(0, 4)
    if mode == "month":
        var year: String = str(dates[0]).substr(0, 4)
        var month: String = str(dates[0]).substr(5, 2)
        return month + "." + year
    var a: String = str(dates[0])
    var b: String = str(dates[dates.size() - 1])
    return a.substr(8, 2) + "." + a.substr(5, 2) + \
        " – " + b.substr(8, 2) + "." + b.substr(5, 2) + "." + b.substr(0, 4)
