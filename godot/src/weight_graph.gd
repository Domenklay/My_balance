extends Control

var samples: Array = []
var goal: float = 65.0
const GREEN = Color("#226b55")
const GRID = Color("#dce8df")
const MUTED = Color("#71877a")
const GOLD = Color("#b57a27")

func set_points(weight_entries: Array, target: float) -> void:
    goal = target
    samples = []
    for item in weight_entries:
        if item is Dictionary and item.has("date") and item.has("value"):
            var val = float(item["value"])
            if val >= 20.0 and val <= 400.0:
                samples.append({"date": str(item["date"]), "value": val})
    samples.sort_custom(func(a, b): return str(a["date"]) < str(b["date"]))
    if samples.size() > 30:
        samples = samples.slice(samples.size() - 30)
    queue_redraw()

func _date_label(iso_date: String) -> String:
    if iso_date.length() >= 10:
        return iso_date.substr(8, 2) + "." + iso_date.substr(5, 2)
    return iso_date

func _draw() -> void:
    var w = size.x
    var h = size.y
    if w < 140.0 or h < 100.0:
        return
    var font = ThemeDB.fallback_font
    var left = 51.0
    var right = w - 22.0
    var top = 30.0
    var bottom = h - 34.0
    if samples.is_empty():
        draw_string(font, Vector2(left, h * 0.52), "Пока нет взвешиваний",
            HORIZONTAL_ALIGNMENT_LEFT, w - left - 12, 15, MUTED)
        return
    var minimum = float(samples[0]["value"])
    var maximum = minimum
    for sample in samples:
        minimum = minf(minimum, float(sample["value"]))
        maximum = maxf(maximum, float(sample["value"]))
    var spread = maxf(1.0, maximum - minimum)
    minimum -= maxf(0.3, spread * 0.25)
    maximum += maxf(0.3, spread * 0.25)
    if goal >= minimum - 2.0 and goal <= maximum + 2.0:
        minimum = minf(minimum, goal - 0.25)
        maximum = maxf(maximum, goal + 0.25)
    var range_y = maxf(0.1, maximum - minimum)
    for i in range(3):
        var fraction = float(i) / 2.0
        var line_y = lerpf(bottom, top, fraction)
        draw_line(Vector2(left, line_y), Vector2(right, line_y), GRID, 1.0)
        var value = minimum + range_y * fraction
        draw_string(font, Vector2(3, line_y + 5), str(snappedf(value, 0.1)),
            HORIZONTAL_ALIGNMENT_LEFT, 45, 12, MUTED)
    if goal >= minimum and goal <= maximum:
        var goal_y = lerpf(bottom, top, (goal - minimum) / range_y)
        draw_dashed_line(Vector2(left, goal_y), Vector2(right, goal_y), GOLD, 1.4, 5.0)
    var positions = PackedVector2Array()
    var count = samples.size()
    for i in range(count):
        var x = (left + right) * 0.5 if count == 1 else lerpf(left, right, float(i) / float(count - 1))
        var y = lerpf(bottom, top, (float(samples[i]["value"]) - minimum) / range_y)
        positions.append(Vector2(x, y))
    if positions.size() > 1:
        draw_polyline(positions, GREEN, 3.0, true)
    for point in positions:
        draw_circle(point, 4.2, Color.WHITE)
        draw_arc(point, 4.2, 0, TAU, 16, GREEN, 2.0, true)
    draw_string(font, Vector2(left, h - 11), _date_label(str(samples[0]["date"])),
        HORIZONTAL_ALIGNMENT_LEFT, 52, 12, MUTED)
    if count > 1:
        draw_string(font, Vector2(right, h - 11), _date_label(str(samples[count - 1]["date"])),
            HORIZONTAL_ALIGNMENT_RIGHT, 56, 12, MUTED)
