extends Control

# Lightweight native Godot vector ring: never requires a bitmap or internet.
var progress: float = 0.0
var goal_text: String = ""

func set_value(value: float, goal: float) -> void:
    progress = clampf(value / maxf(1.0, goal), 0.0, 1.0)
    goal_text = str(roundi(100.0 * value / maxf(1.0, goal))) + "%"
    queue_redraw()

func _draw() -> void:
    var center = size * 0.5
    var radius = minf(size.x, size.y) * 0.37
    if radius < 20:
        return
    draw_arc(center, radius, -PI / 2.0, PI * 1.5, 100,
        Color("#417969"), 10.0, true)
    if progress > 0.0:
        draw_arc(center, radius, -PI / 2.0, -PI / 2.0 + TAU * progress,
            100, Color("#dbefbb"), 10.0, true)
    var font = ThemeDB.fallback_font
    var font_size = 19
    var display = goal_text if not goal_text.is_empty() else "0%"
    var measured = font.get_string_size(display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
    draw_string(font, Vector2(center.x - measured.x * 0.5,
        center.y + measured.y * 0.32), display,
        HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#ffffff"))
