extends RefCounted

# Only aggregate values for today's widget. No names, photos or food records.
static func make(store: Object, day: String) -> Dictionary:
    var settings: Dictionary = store.data["settings"]
    var goal: int = roundi(float(settings.get("kcal",1800)))
    var eaten: int = roundi(store.day_calories(day))
    var targets: Dictionary = store.macro_targets()
    var macros: Dictionary = {}
    for key in ["p","f","c"]:
        if targets.has(key):
            macros[key] = {"used":roundi(store.day_macro(day,key)), "goal":roundi(float(targets[key]))}
    return {"date":day,"goal":goal,"eaten":eaten,"remaining":maxi(0,goal-eaten),
        "macros":macros,"water":store.day_water_ml(day),"water_goal":store.water_goal_ml(),
        "steps":store.day_steps(day),"step_source":store.step_source(day),
        "theme":str(settings.get("theme","forest")),"language":str(settings.get("language","ru")),
        "ready":not store.needs_onboarding()}

# Cache today's and the next two dates, including any already-entered diary rows.
static func window(store: Object, day: String) -> Dictionary:
    var start = Time.get_unix_time_from_datetime_string(day+"T00:00:00")
    var days: Dictionary = {}
    for offset in range(3):
        var key = Time.get_date_string_from_unix_time(start + offset*86400)
        days[key] = make(store,key)
    return {"date":day,"days":days}
