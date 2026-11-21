extends RefCounted

# Read-only profile metrics, without altering diary or weight history.
static func summarize(settings: Dictionary, weights: Array) -> Dictionary:
    var start: float = float(settings.get("start", 0.0))
    var goal: float = float(settings.get("goal", start))
    var latest: float = start
    var last_date: String = ""
    var has_records = false
    for item in weights:
        if not (item is Dictionary):
            continue
        var when: String = str(item.get("date", ""))
        var value: float = float(item.get("value", start))
        if when.is_empty() or not is_finite(value):
            continue
        if not has_records or when >= last_date:
            last_date = when
            latest = value
            has_records = true
    var span: float = goal - start
    var completion: float = 0.0
    if absf(span) < 0.001:
        completion = 100.0 if absf(latest - goal) < 0.05 else 0.0
    else:
        completion = clampf((latest - start) / span * 100.0, 0.0, 100.0)
    var reached: bool = completion >= 99.999
    return {
        "start": start, "goal": goal, "latest": latest,
        "date": last_date, "has_records": has_records,
        "change": latest - start, "progress": completion,
        "reached": reached,
        "remaining": 0.0 if reached else absf(goal - latest)
    }
