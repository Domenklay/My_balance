extends RefCounted

# Encouraging, non-judgmental rewards derived from existing saved habits.
# Nothing is awarded for eating less, staying under a target, or losing weight.
const MEALS = ["Завтрак", "Обед", "Ужин", "Перекус"]
const FRAMES = [
    {"id":"plain", "name":"Обычная", "points":0, "color":"#9AAFA8"},
    {"id":"mint", "name":"Мятная", "points":50, "color":"#68C6AE"},
    {"id":"gold", "name":"Золотая", "points":150, "color":"#F3BF66"},
    {"id":"violet", "name":"Сиреневая", "points":350, "color":"#B69AED"}
]
const AWARDS = [
    {"id":"first", "title":"Первый шаг", "icon":"★", "hint":"Первая запись питания"},
    {"id":"three_days", "title":"Три дня внимания", "icon":"✿", "hint":"Записи в 3 разных дня"},
    {"id":"week", "title":"Неделя заботы", "icon":"☀", "hint":"Записи в 7 разных дней"},
    {"id":"fortnight", "title":"Две недели", "icon":"✦", "hint":"Записи в 14 разных дней"},
    {"id":"month", "title":"Месяц внимания", "icon":"❖", "hint":"Записи в 30 разных дней"},
    {"id":"streak", "title":"7 дней подряд", "icon":"◆", "hint":"Записи 7 дней подряд"},
    {"id":"recipe", "title":"Домашний повар", "icon":"♨", "hint":"Сохранён первый рецепт"},
    {"id":"five_recipes", "title":"Своя коллекция", "icon":"✧", "hint":"Сохранено 5 рецептов"},
    {"id":"activity", "title":"В движении", "icon":"◇", "hint":"Есть запись о движении"},
    {"id":"three_activities", "title":"Активные дни", "icon":"☘", "hint":"Движение отмечено в 3 разных дня"}
]

static func valid_date(value: String) -> bool:
    if value.length() != 10 or value.substr(4, 1) != "-" or value.substr(7, 1) != "-":
        return false
    var chunks: PackedStringArray = value.split("-")
    if chunks.size() != 3:
        return false
    for chunk in chunks:
        if not chunk.is_valid_int():
            return false
    var year = int(chunks[0])
    var month = int(chunks[1])
    var day = int(chunks[2])
    if year < 2000 or year > 2200 or month < 1 or month > 12 or day < 1 or day > 31:
        return false
    var stamp = Time.get_unix_time_from_datetime_string(value + "T00:00:00")
    return Time.get_datetime_string_from_unix_time(stamp).substr(0, 10) == value

static func day_before(day: String) -> String:
    return Time.get_datetime_string_from_unix_time(
        Time.get_unix_time_from_datetime_string(day + "T00:00:00") - 86400
    ).substr(0, 10)

static func frame_by_id(value: String) -> Dictionary:
    for item in FRAMES:
        if str(item["id"]) == value:
            return item
    return {}

static func calculate(data: Dictionary, today: String) -> Dictionary:
    var meal_days: Dictionary = {}
    var activity_days: Dictionary = {}
    var notes: Dictionary = data.get("notes", {})
    for entry in data.get("entries", []):
        if not (entry is Dictionary):
            continue
        var day = str(entry.get("date", ""))
        var meal = str(entry.get("meal", ""))
        if not valid_date(day) or day > today or meal not in MEALS:
            continue
        if not meal_days.has(day):
            meal_days[day] = {}
        meal_days[day][meal] = true
    for a in data.get("activities", []):
        if not (a is Dictionary):
            continue
        var day = str(a.get("date", ""))
        if valid_date(day) and day <= today:
            activity_days[day] = true
    var days: Array = meal_days.keys()
    days.sort()
    var points = 0
    for day in days:
        var count = meal_days[day].size()
        points += 10 # one credit for recording a day's meals, independent of quantity
        if count >= 2: points += 5
        if count >= 3: points += 5
        if count >= 4: points += 5
        if not str(notes.get(day, "")).strip_edges().is_empty():
            points += 3
    points += activity_days.size() * 5 # awarded for any movement log, not duration/intensity
    var recipe_count = data.get("recipes", []).size()
    points += recipe_count * 10
    var streak = 0
    var check_day = today
    if not meal_days.has(check_day):
        check_day = day_before(today)
    while meal_days.has(check_day):
        streak += 1
        check_day = day_before(check_day)
        if streak > 10000: break
    var longest = 0
    var chain = 0
    var prev = ""
    for d in days:
        chain = chain + 1 if prev != "" and day_before(d) == prev else 1
        longest = maxi(longest, chain)
        prev = d
    var badges: Dictionary = {
        "first": days.size() >= 1,
        "three_days": days.size() >= 3,
        "week": days.size() >= 7,
        "fortnight": days.size() >= 14,
        "month": days.size() >= 30,
        "streak": longest >= 7,
        "recipe": recipe_count >= 1,
        "five_recipes": recipe_count >= 5,
        "activity": activity_days.size() >= 1,
        "three_activities": activity_days.size() >= 3
    }
    var achieved = 0
    for v in badges.values():
        if v: achieved += 1
    return {
        "points":points, "level":1 + int(points / 100),
        "level_progress":points % 100,
        "days":days.size(), "active_days":activity_days.size(),
        "streak":streak, "longest_streak":longest,
        "badges":badges, "earned":achieved,
        "recipes":recipe_count
    }
