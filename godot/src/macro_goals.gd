extends RefCounted

# Optional adult planning example, not a diagnosis or a clinical prescription.
# Energy shares are explicit and do not depend on sex or body size.
const KEYS = ["p", "f", "c"]

static func defaults() -> Dictionary:
    return {"mode":"off", "manual":{"p":90,"f":60,"c":225}}

static func valid(value: Variant) -> bool:
    if not (value is Dictionary) or str(value.get("mode", "")) not in ["off","auto","manual"]:
        return false
    var manual = value.get("manual", {})
    if not (manual is Dictionary):
        return false
    for key in KEYS:
        var number = manual.get(key)
        if not (number is float or number is int) or not is_finite(float(number)):
            return false
        if float(number) < 1.0 or float(number) > 1000.0 or float(number) != roundf(float(number)):
            return false
    return true

static func automatic(kcal: float) -> Dictionary:
    var protein = roundi(kcal * 0.20 / 4.0)
    var fat = roundi(kcal * 0.30 / 9.0)
    var carbs = roundi((kcal - protein * 4.0 - fat * 9.0) / 4.0)
    return {"p":maxi(1,protein),"f":maxi(1,fat),"c":maxi(1,carbs)}

static func targets(settings: Dictionary) -> Dictionary:
    var choice = settings.get("macro_goals", defaults())
    if not valid(choice) or choice["mode"] == "off":
        return {}
    if choice["mode"] == "auto":
        return automatic(float(settings.get("kcal",1800)))
    return choice["manual"].duplicate(true)

static func energy(values: Dictionary) -> int:
    return roundi(float(values.get("p",0))*4.0 + float(values.get("f",0))*9.0 + float(values.get("c",0))*4.0)
