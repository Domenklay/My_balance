extends Control

# Theme-aware 7-day bars / 4–6 calendar-week groups. Missing dietary
# recordings are visually empty, never zero-height recorded-calorie values.
var columns: Array = []
var kind: String = "calories"
var target: float = 1800.0
var primary: Color = Color("#195b4a")
var secondary: Color = Color("#bf7e43")
var muted: Color = Color("#678376")
var grid: Color = Color("#e2ece5")

func setup(data: Array, metric: String, goal: float,
        first: Color, second: Color, text: Color, grid_color: Color) -> void:
    columns = data
    kind = metric
    target = maxf(1.0, goal)
    primary = first
    secondary = second
    muted = text
    grid = grid_color
    queue_redraw()

func _draw() -> void:
    var w: float = size.x
    var h: float = size.y
    if w < 140 or h < 90 or columns.is_empty():
        return
    var font = ThemeDB.fallback_font
    var left: float = 42.0
    var right: float = w - 8.0
    var top: float = 13.0
    var bottom: float = h - 28.0
    var area: float = bottom - top
    var maximum: float = target * 1.15 if kind == "calories" else 60.0
    var recorded_any: bool = false
    for item in columns:
        if kind == "calories":
            if bool(item.get("recorded", false)):
                recorded_any = true
                maximum = maxf(maximum, float(item.get("kcal", 0)) * 1.12)
        else:
            if bool(item.get("activity", false)):
                recorded_any = true
                maximum = maxf(maximum, float(item.get("walk", 0)) +
                    float(item.get("exercise", 0)))
    if not recorded_any:
        draw_string(font, Vector2(left, h * 0.53),
            "Пока нет записей за этот период", HORIZONTAL_ALIGNMENT_LEFT,
            w - left - 12, 13, muted)
        return
    maximum = maxf(1.0, maximum)
    for fraction in [0.0, 0.5, 1.0]:
        var y: float = bottom - area * fraction
        draw_line(Vector2(left, y), Vector2(right, y), grid, 1.0)
        draw_string(font, Vector2(0, y + 4), str(roundi(maximum * fraction)),
            HORIZONTAL_ALIGNMENT_LEFT, 39, 11, muted)
    if kind == "calories" and target <= maximum:
        var target_y: float = bottom - area * target / maximum
        draw_dashed_line(Vector2(left, target_y),
            Vector2(right, target_y), secondary, 1.2, 5.0)
    var step: float = (right - left) / float(columns.size())
    var bar_w: float = minf(25.0, step * 0.53)
    for i in range(columns.size()):
        var item: Dictionary = columns[i]
        var center: float = left + (float(i) + 0.5) * step
        var x: float = center - bar_w * 0.5
        var height_primary: float = 0.0
        var height_secondary: float = 0.0
        if kind == "calories" and bool(item.get("recorded", false)):
            height_primary = maxf(2.0, area * float(item.get("kcal", 0)) / maximum)
        elif kind == "activity" and bool(item.get("activity", false)):
            height_primary = maxf(0.0, area * float(item.get("walk", 0)) / maximum)
            height_secondary = maxf(0.0, area * float(item.get("exercise", 0)) / maximum)
        if height_primary > 0:
            draw_rect(Rect2(x, bottom - height_primary, bar_w, height_primary), primary, true)
        if height_secondary > 0:
            draw_rect(Rect2(x, bottom - height_primary - height_secondary,
                bar_w, height_secondary), secondary, true)
        var tag: String = str(item.get("label", ""))
        draw_string(font, Vector2(center - step * 0.5, h - 9.0), tag,
            HORIZONTAL_ALIGNMENT_CENTER, step, 11, muted)
