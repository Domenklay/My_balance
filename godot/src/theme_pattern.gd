extends Control

# Simple scalable procedural ornament. No image assets and no layout interception.
var kind: String = "leaves"
var ink: Color = Color("#6da48b")
var enabled: bool = true
var opacity: float = 0.09

func configure(which: String, color: Color, show_pattern: bool, strength: float = 0.09) -> void:
    kind = which
    ink = color
    enabled = show_pattern
    opacity = strength
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func _draw() -> void:
    if not enabled or size.x <= 0.0 or size.y <= 0.0:
        return
    var tint = Color(ink.r, ink.g, ink.b, opacity)
    var spacing = 72.0
    var cols = int(ceil(size.x / spacing)) + 1
    var rows = int(ceil(size.y / spacing)) + 1
    for yy in range(rows):
        for xx in range(cols):
            var c = Vector2(xx * spacing + 16.0 + (yy % 2) * 22.0, yy * spacing + 16.0)
            match kind:
                "dots":
                    draw_circle(c, 2.0, tint)
                    draw_circle(c + Vector2(19, 23), 1.2, tint)
                    draw_circle(c + Vector2(6, 37), 1.0, tint)
                "grid":
                    draw_line(c - Vector2(16, 16), c + Vector2(56, -16), tint, 0.65)
                    draw_line(c - Vector2(16, 56), c + Vector2(-16, 16), tint, 0.65)
                "stars":
                    draw_line(c + Vector2(-4, 0), c + Vector2(4, 0), tint, 1.0)
                    draw_line(c + Vector2(0, -4), c + Vector2(0, 4), tint, 1.0)
                    draw_circle(c + Vector2(27, 23), 1.3, tint)
                _:
                    draw_line(c, c + Vector2(22, 28), tint, 1.1, true)
                    draw_arc(c + Vector2(4, 11), 8.0, -2.8, -0.35, 15, tint, 1.0, true)
                    draw_arc(c + Vector2(14, 22), 8.0, -2.8, -0.35, 15, tint, 1.0, true)
