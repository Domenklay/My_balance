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
    if kind == "botanical":
        _draw_botanical(tint)
        return
    if kind == "hills":
        _draw_hills(tint)
        return
    var spacing = 94.0
    var cols = int(ceil(size.x / spacing)) + 1
    var rows = int(ceil(size.y / spacing)) + 1
    for yy in range(rows):
        for xx in range(cols):
            var c = Vector2(xx * spacing + 16.0 + (yy % 2) * 22.0, yy * spacing + 16.0)
            match kind:
                "dots":
                    draw_arc(c, 8.0, 0, TAU, 24, tint, 1.1, true)
                    draw_arc(c + Vector2(27, 29), 4.0, 0, TAU, 16, tint, 0.9, true)
                    draw_circle(c + Vector2(13, 42), 1.8, tint)
                "grid":
                    for radius in [9.0, 15.0, 21.0]:
                        draw_arc(c, radius, PI, TAU, 24, tint, 0.9, true)
                    draw_circle(c + Vector2(36, 33), 1.5, tint)
                "stars":
                    draw_colored_polygon(PackedVector2Array([
                        c + Vector2(0,-7), c + Vector2(2,-2), c + Vector2(7,0),
                        c + Vector2(2,2), c + Vector2(0,7), c + Vector2(-2,2),
                        c + Vector2(-7,0), c + Vector2(-2,-2)
                    ]), tint)
                    draw_circle(c + Vector2(27, 23), 1.7, tint)
                    draw_circle(c + Vector2(46, 9), 1.0, tint)
                _:
                    draw_line(c, c + Vector2(23, 32), tint, 1.0, true)
                    _draw_leaf(c + Vector2(3, 9), Vector2(-0.75, -0.45), 17.0, tint)
                    _draw_leaf(c + Vector2(16, 17), Vector2(0.8, -0.6), 19.0, tint)
                    _draw_leaf(c + Vector2(20, 27), Vector2(-0.8, -0.3), 15.0, tint)


# Large corner foliage instead of a repeating line-doodle texture. The leaves
# are painted behind interactive controls and never alter touch hitboxes.
func _draw_leaf(center: Vector2, direction: Vector2, length: float, tint: Color) -> void:
    var axis = direction.normalized()
    var side = Vector2(-axis.y, axis.x)
    var start = center - axis * length * 0.5
    var end = center + axis * length * 0.5
    var polygon = PackedVector2Array()
    for i in range(13):
        var fraction: float = float(i) / 12.0
        polygon.append(start.lerp(end, fraction) + side * sin(PI * fraction) * length * 0.23)
    for i in range(11, 0, -1):
        var fraction: float = float(i) / 12.0
        polygon.append(start.lerp(end, fraction) - side * sin(PI * fraction) * length * 0.23)
    draw_colored_polygon(polygon, tint)
    draw_line(start, end, tint.lightened(0.08), 0.85, true)


func _draw_branch(root: Vector2, mirror: float, tint: Color) -> void:
    var p1 = root
    var p2 = root + Vector2(38.0 * mirror, 31.0)
    var p3 = root + Vector2(79.0 * mirror, 50.0)
    draw_line(p1, p2, tint, 2.0, true)
    draw_line(p2, p3, tint, 1.8, true)
    _draw_leaf(root + Vector2(20.0 * mirror, 12.0), Vector2(0.45 * mirror, -1.0), 33.0, tint)
    _draw_leaf(root + Vector2(38.0 * mirror, 33.0), Vector2(0.95 * mirror, 0.4), 39.0, tint)
    _draw_leaf(root + Vector2(59.0 * mirror, 32.0), Vector2(0.3 * mirror, -1.0), 28.0, tint)
    _draw_leaf(root + Vector2(75.0 * mirror, 50.0), Vector2(0.9 * mirror, 0.25), 30.0, tint)


func _draw_botanical(tint: Color) -> void:
    var width = size.x
    var height = size.y
    if width < 56.0 or height < 45.0:
        return
    var top = Color(tint.r, tint.g, tint.b, minf(tint.a * 1.7, 0.28))
    _draw_branch(Vector2(-3.0, 1.0), 1.0, top)
    _draw_branch(Vector2(width + 3.0, -8.0), -1.0, top)
    # Bottom corner clusters are kept off the main text column.
    if height > 190.0:
        _draw_branch(Vector2(-5.0, height - 78.0), 1.0, tint)
        _draw_branch(Vector2(width + 4.0, height - 105.0), -1.0, tint)


# Small distant peaks only in the top-right, outside the headline,
# activity totals and bottom actions. Keep it ornamental, not informational.
func _draw_hills(tint: Color) -> void:
    if size.x < 180.0 or size.y < 75.0:
        return
    var w = size.x
    var h = size.y
    var far = Color(tint.r, tint.g, tint.b, minf(0.14, tint.a * 0.9))
    var near = Color(tint.r, tint.g, tint.b, minf(0.18, tint.a * 1.1))
    draw_colored_polygon(PackedVector2Array([
        Vector2(w * 0.79, h * 0.30), Vector2(w * 0.86, h * 0.12),
        Vector2(w * 0.91, h * 0.23), Vector2(w * 0.96, h * 0.09),
        Vector2(w, h * 0.23), Vector2(w, h * 0.34)
    ]), far)
    draw_colored_polygon(PackedVector2Array([
        Vector2(w * 0.84, h * 0.37), Vector2(w * 0.91, h * 0.22),
        Vector2(w * 0.96, h * 0.34), Vector2(w, h * 0.18),
        Vector2(w, h * 0.39)
    ]), near)
