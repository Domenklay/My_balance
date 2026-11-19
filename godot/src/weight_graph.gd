extends Control

var samples: Array = []
var goal: float = 65.0

func set_points(weight_entries: Array, target: float) -> void:
    goal = target
    samples = []
    for item in weight_entries:
        if item is Dictionary and item.has("date") and item.has("value"):
            var val = float(item["value"])
            if val >= 20 and val <= 400:
                samples.append({"date": str(item["date"]), "value": val})
    samples.sort_custom(func(a,b): return str(a["date"]) < str(b["date"]))
    if samples.size() > 30:
        samples = samples.slice(samples.size() - 30)
    queue_redraw()

func _draw() -> void:
    var w = size.x
    var h = size.y
    var left = 25.0
    var right = maxf(left + 1.0, w - 20.0)
    var top = 25.0
    var bottom = maxf(top + 10.0, h - 36.0)
    draw_line(Vector2(left, bottom), Vector2(right, bottom), Color("#d3e3d7"), 2.0)
    if samples.is_empty():
        draw_string(ThemeDB.fallback_font, Vector2(left, h / 2), "Пока нет взвешиваний", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#71877a"))
        return
    var minimum = goal
    var maximum = goal
    for sample in samples:
        minimum = minf(minimum, sample["value"])
        maximum = maxf(maximum, sample["value"])
    minimum -= 1.0
    maximum += 1.0
    var height_range = maxf(1.0, maximum - minimum)
    var count = samples.size()
    var positions = PackedVector2Array()
    for i in range(count):
        var x = (left + right) / 2.0 if count == 1 else lerpf(left, right, float(i) / float(count - 1))
        var y = lerpf(bottom, top, (float(samples[i]["value"]) - minimum) / height_range)
        positions.append(Vector2(x, y))
    if count > 1:
        draw_polyline(positions, Color("#226b55"), 3.0, true)
    for point in positions:
        draw_circle(point, 4.2, Color("#226b55"))
    draw_string(ThemeDB.fallback_font, Vector2(left, 17), str(round(maximum - 1.0)) + " кг", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#71877a"))
    draw_string(ThemeDB.fallback_font, Vector2(left, h - 11), str(samples[0]["date"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#71877a"))
    draw_string(ThemeDB.fallback_font, Vector2(right, h - 11), str(samples[count - 1]["date"]), HORIZONTAL_ALIGNMENT_RIGHT, -1, 12, Color("#71877a"))
