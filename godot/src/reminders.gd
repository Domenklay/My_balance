extends RefCounted
# Only reminder type, local clock time and weekday are persisted.
const ITEMS = [
    ["water","Вода","12:00",0],
    ["breakfast","Завтрак","08:00",0],
    ["lunch","Обед","13:00",0],
    ["dinner","Ужин","19:00",0],
    ["snack","Перекус","16:00",0],
    ["weight","Взвешивание","09:00",1],
    ["workout","Тренировка","18:00",0]
]
const DAYS = ["Каждый день","Понедельник","Вторник","Среда","Четверг","Пятница","Суббота","Воскресенье"]

static func defaults() -> Dictionary:
    var result: Dictionary = {}
    for item in ITEMS:
        result[item[0]] = {"enabled":false,"time":item[2],"day":item[3]}
    return result

static func valid_time(value: Variant) -> bool:
    if not value is String or value.length() != 5 or value.substr(2,1) != ":":
        return false
    var h = value.substr(0,2)
    var m = value.substr(3,2)
    for character in h + m:
        if character not in "0123456789":
            return false
    return h.to_int() < 24 and m.to_int() < 60

static func valid(value: Variant) -> bool:
    if not value is Dictionary or value.size() != ITEMS.size():
        return false
    for item in ITEMS:
        var entry = value.get(item[0])
        if not entry is Dictionary or not entry.get("enabled") is bool or not valid_time(entry.get("time")):
            return false
        var day = entry.get("day")
        if not (day is int or day is float) or not is_finite(float(day)) or float(day) != roundf(float(day)) or int(day) not in range(8):
            return false
    return true

static func enabled_count(value: Dictionary) -> int:
    var count = 0
    for item in ITEMS:
        if bool(value.get(item[0], {}).get("enabled",false)):
            count += 1
    return count
