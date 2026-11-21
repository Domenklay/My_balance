extends Control

# Crisp vector plate-and-cutlery pictogram, used instead of the unsupported
# Unicode 🍽 glyph on some Godot/Android font stacks.
var line_color: Color = Color("#1E624F")

func _ready() -> void:
    name = "MealPlateIcon"
    custom_minimum_size = Vector2(22, 24)
    size_flags_vertical = Control.SIZE_SHRINK_CENTER
    size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_tint(tint: Color) -> void:
    line_color = tint
    queue_redraw()

func _draw() -> void:
    var c = line_color
    # A round dinner plate, with a thinner inner rim.
    draw_arc(Vector2(11, 12), 6.1, 0.0, TAU, 40, c, 1.8, true)
    draw_arc(Vector2(11, 12), 4.1, 0.0, TAU, 40, c.darkened(0.16), 0.9, true)
    # Fork with three tines.
    draw_line(Vector2(1.6, 4.5), Vector2(1.6, 10.0), c, 1.5, true)
    draw_line(Vector2(3.4, 4.5), Vector2(3.4, 10.0), c, 1.5, true)
    draw_line(Vector2(5.2, 4.5), Vector2(5.2, 10.0), c, 1.5, true)
    draw_line(Vector2(1.6, 10.0), Vector2(5.2, 10.0), c, 1.4, true)
    draw_line(Vector2(3.4, 10.0), Vector2(3.4, 20), c, 1.7, true)
    # Knife, a compact curved blade and handle.
    draw_arc(Vector2(18.5, 8.8), 4.6, PI*0.65, PI*1.2, 10, c, 1.6, true)
    draw_line(Vector2(18.5, 4.5), Vector2(18.5, 20), c, 1.8, true)
