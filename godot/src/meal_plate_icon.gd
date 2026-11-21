extends Control

# Crisp, resolution-independent dinner plate with fork and knife. This avoids
# missing Unicode 🍽 glyphs on Android while staying in the current theme.
var line_color: Color = Color("#1E624F")

func _ready() -> void:
    name = "MealPlateIcon"
    custom_minimum_size = Vector2(30, 26)
    size_flags_vertical = Control.SIZE_SHRINK_CENTER
    size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_tint(tint: Color) -> void:
    line_color = tint
    queue_redraw()

func _draw() -> void:
    var c = line_color
    # Plate: two distinct rings; utensils sit outside the rings.
    draw_arc(Vector2(15.0, 13.0), 7.2, 0.0, TAU, 48, c, 1.5, true)
    draw_arc(Vector2(15.0, 13.0), 4.8, 0.0, TAU, 48, c, 1.0, true)
    # Fork left of the plate: separate tines and long handle.
    draw_line(Vector2(1.5, 5), Vector2(1.5, 10), c, 1.3, true)
    draw_line(Vector2(3.7, 5), Vector2(3.7, 10), c, 1.3, true)
    draw_line(Vector2(5.8, 5), Vector2(5.8, 10), c, 1.3, true)
    draw_line(Vector2(1.5, 10), Vector2(5.8, 10), c, 1.2, true)
    draw_line(Vector2(3.7, 10), Vector2(3.7, 21), c, 1.5, true)
    # Knife to the right, outside the plate rim.
    draw_line(Vector2(26.4, 5), Vector2(26.4, 21), c, 1.8, true)
    draw_line(Vector2(26.4, 5), Vector2(28.5, 12), c, 1.4, true)
    draw_line(Vector2(26.4, 12), Vector2(28.5, 12), c, 1.4, true)
