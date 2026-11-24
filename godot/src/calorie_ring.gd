extends Control

# Lightweight native Godot vector ring: never requires a bitmap or internet.
var progress: float = 0.0
var displayed_progress: float = 0.0
var sweep: Tween
var goal_text: String = ""
var track_color: Color = Color("#417969")
var fill_color: Color = Color("#dbefbb")
var label_color: Color = Color.WHITE

func set_palette(track: Color, fill: Color, label: Color) -> void:
    track_color = track
    fill_color = fill
    label_color = label
    queue_redraw()

func set_value(value: float, goal: float) -> void:
    if sweep != null and sweep.is_valid():
        sweep.kill()
    progress = clampf(value / maxf(1.0, goal), 0.0, 1.0)
    displayed_progress = progress
    goal_text = str(roundi(100.0 * value / maxf(1.0, goal))) + "%"
    queue_redraw()

func _set_visual_progress(amount: float) -> void:
    displayed_progress = amount
    queue_redraw()


func animate_from(previous: float) -> void:
    if not is_inside_tree() or absf(previous - progress) < 0.001:
        return
    if sweep != null and sweep.is_valid():
        sweep.kill()
    _set_visual_progress(clampf(previous, 0.0, 1.0))
    sweep = create_tween()
    sweep.tween_method(_set_visual_progress, displayed_progress, progress, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
    var center = size * 0.5
    var radius = minf(size.x, size.y) * 0.37
    if radius < 20:
        return
    draw_arc(center, radius, -PI / 2.0, PI * 1.5, 100,
        track_color, 10.0, true)
    if displayed_progress > 0.0:
        draw_arc(center, radius, -PI / 2.0, -PI / 2.0 + TAU * displayed_progress,
            100, fill_color, 10.0, true)
    var font = ThemeDB.fallback_font
    var font_size = 19
    var display = goal_text if not goal_text.is_empty() else "0%"
    var measured = font.get_string_size(display, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
    draw_string(font, Vector2(center.x - measured.x * 0.5,
        center.y + measured.y * 0.32), display,
        HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)
