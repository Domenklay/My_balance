extends Control

# Interactive, scale-independent body diagram used only for viewing a metric.
# Native focusable buttons provide touch targets; no saved journal data changes.
signal metric_selected(metric: String)

const METRICS = preload("res://src/body_measurements.gd")
const FIGURE = preload("res://assets/body/measurement_figure.svg")
const PINS = {
    "neck":      {"side": "left",  "y": 14.0,  "target": Vector2(0, 60)},
    "chest":     {"side": "left",  "y": 73.0,  "target": Vector2(-22, 114)},
    "upper_arm": {"side": "right", "y": 108.0, "target": Vector2(46, 136)},
    "waist":     {"side": "left",  "y": 135.0, "target": Vector2(-23, 163)},
    "abdomen":   {"side": "left",  "y": 185.0, "target": Vector2(-20, 184)},
    "hips":      {"side": "right", "y": 213.0, "target": Vector2(29, 204)},
    "thigh":     {"side": "left",  "y": 267.0, "target": Vector2(-20, 255)},
    "calf":      {"side": "right", "y": 280.0, "target": Vector2(18, 293)}
}
var selected_metric: String = "waist"
var recorded_values: Dictionary = {}
var text_color: Color = Color("#254C3A")
var soft_color: Color = Color("#E4F0E7")
var border_color: Color = Color("#C7D9C8")
var active_color: Color = Color("#125842")
var figure_color: Color = Color("#BBD8C3")
var figure_outline: Color = Color("#4E8A6B")
var dark_mode: bool = false
var high_contrast: bool = false
var metric_buttons: Dictionary = {}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    custom_minimum_size = Vector2(0, 338)
    size_flags_horizontal = Control.SIZE_EXPAND_FILL
    for field in METRICS.FIELDS:
        var metric: String = str(field[0])
        var button = Button.new()
        button.name = "BodyMap_" + metric
        button.tooltip_text = "Показать график: " + str(field[1])
        button.text = str(field[1])
        button.mouse_filter = Control.MOUSE_FILTER_PASS
        button.focus_mode = Control.FOCUS_ALL
        button.custom_minimum_size = Vector2(0, 38)
        button.add_theme_font_size_override("font_size", 12)
        button.clip_text = true
        add_child(button)
        button.pressed.connect(func(): metric_selected.emit(metric))
        metric_buttons[metric] = button
    resized.connect(_arrange_buttons)
    _arrange_buttons()
    _update_button_styles()


func configure(metric: String, values: Dictionary, text: Color, soft: Color,
        border: Color, accent: Color, is_dark: bool, contrast: bool) -> void:
    selected_metric = metric if METRICS.is_metric(metric) else "waist"
    recorded_values = values.duplicate(true)
    text_color = text
    soft_color = soft
    border_color = border
    active_color = accent
    dark_mode = is_dark
    high_contrast = contrast
    figure_color = accent.lerp(Color.WHITE, 0.44 if dark_mode else 0.69)
    figure_outline = accent.lerp(text, 0.65 if dark_mode else 0.22)
    _update_button_styles()
    queue_redraw()


func _arrange_buttons() -> void:
    var width: float = size.x
    if width <= 0.0:
        return
    var button_width: float = clampf(width * 0.305, 78.0, 112.0)
    for metric in metric_buttons:
        var button: Button = metric_buttons[metric]
        var pin: Dictionary = PINS[metric]
        var x: float = 2.0 if pin["side"] == "left" else width - button_width - 2.0
        button.position = Vector2(x, float(pin["y"]))
        button.size = Vector2(button_width, 38.0)
    queue_redraw()


func _update_button_styles() -> void:
    for field in METRICS.FIELDS:
        var key: String = str(field[0])
        if not metric_buttons.has(key):
            continue
        var button: Button = metric_buttons[key]
        button.text = str(field[1]) + "\n" + (str(snappedf(float(recorded_values[key]), 0.1)) + " см" if recorded_values.has(key) else "—")
        button.add_theme_font_size_override("font_size", 11)
        var active: bool = key == selected_metric
        var background: Color = active_color if active else soft_color
        var foreground: Color = Color.WHITE if active else text_color
        for state in ["normal", "hover", "pressed"]:
            var style = StyleBoxFlat.new()
            style.bg_color = background
            if state == "hover":
                style.bg_color = background.lightened(0.055)
            elif state == "pressed":
                style.bg_color = background.darkened(0.07)
            style.border_color = active_color if active else border_color
            style.set_border_width_all(2 if high_contrast and active else 1)
            style.set_corner_radius_all(11)
            style.content_margin_left = 3
            style.content_margin_right = 3
            style.content_margin_top = 5
            style.content_margin_bottom = 5
            button.add_theme_stylebox_override(state, style)
        for state in ["font_color", "font_hover_color", "font_pressed_color",
                "font_focus_color"]:
            button.add_theme_color_override(state, foreground)
        button.add_theme_color_override("font_disabled_color", foreground)


func _poly(center: Vector2, points: Array, fill: Color) -> void:
    var shape = PackedVector2Array()
    for point in points:
        shape.append(center + point)
    draw_colored_polygon(shape, fill)
    draw_polyline(shape, figure_outline, 1.2, true)


func _draw() -> void:
    var center = Vector2(size.x * 0.5, 0.0)
    if size.x < 240.0 or size.y < 310.0:
        return
    # Smooth, neutral front-facing vector illustration. It does not infer
    # the user's shape from circumference measurements.
    draw_texture_rect(FIGURE, Rect2(center.x - 61.0, 13.0, 122.0, 310.0), false, figure_color)

    var button_width: float = clampf(size.x * 0.305, 78.0, 112.0)
    for field in METRICS.FIELDS:
        var metric: String = str(field[0])
        var pin: Dictionary = PINS[metric]
        var target: Vector2 = center + pin["target"]
        var left: bool = pin["side"] == "left"
        var end_x: float = button_width + 5 if left else size.x - button_width - 5
        var end: Vector2 = Vector2(end_x, float(pin["y"]) + 19.0)
        var chosen: bool = metric == selected_metric
        var line_color: Color = active_color if chosen else figure_outline
        draw_line(target, end, line_color, 2.0 if chosen else 1.2, true)
        if chosen:
            draw_circle(target, 9.0, figure_color)
            draw_arc(target, 9.0, 0, TAU, 24, line_color, 1.7, true)
        draw_circle(target, 4.5 if chosen else 3.5, line_color)
        if recorded_values.has(metric):
            draw_arc(target, 5.8, 0, TAU, 18, line_color, 1.2, true)
