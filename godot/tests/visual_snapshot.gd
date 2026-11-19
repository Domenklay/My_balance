extends SceneTree

# Render actual Godot UI screens at Android reference resolution.
# This script runs in a temporary CI environment, never reads user data.
func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(app: Control, filename: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var shot: Image = app.get_viewport().get_texture().get_image()
    if shot == null or shot.is_empty():
        push_error("Screenshot capture returned an empty image: " + filename)
        quit(1)
        return
    var saved = shot.save_png("res://screenshots/" + filename + ".png")
    if saved != OK:
        push_error("Could not save screenshot: " + filename)
        quit(1)
        return
    print("CAPTURED: ", filename, " ", shot.get_width(), "x", shot.get_height())

func _capture() -> void:
    DisplayServer.window_set_size(Vector2i(420, 900))
    root.gui_embed_subwindows = true
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
    var packed: PackedScene = load("res://main.tscn")
    if packed == null:
        push_error("Missing main.tscn")
        quit(1)
        return
    var app: Control = packed.instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.date = "2026-11-19"
    app.month_shown = "2026-11"
    app.tab = "day"
    app._render()
    await _snapshot(app, "01-day-empty")
    var sample_foods = app.store.all_foods()
    var samples = [
        [0, 75, "Завтрак"],
        [2, 120, "Завтрак"],
        [12, 145, "Обед"],
        [9, 160, "Обед"],
        [3, 180, "Перекус"],
    ]
    for item in samples:
        var food: Dictionary = sample_foods[item[0]]
        app.store.data["entries"].append({
            "id": str(app.store.data["entries"].size()+1),
            "date": app.date,
            "food": food["id"],
            "nutrition": food.duplicate(true),
            "grams": item[1],
            "meal": item[2],
        })
    app.store.data["activities"].append({
        "id": "example-walk", "date": app.date, "type": "walk",
        "minutes": 45, "distance": 3.5, "detail": "Прогулка"
    })
    app.store.data["activities"].append({
        "id": "example-strength", "date": app.date, "type": "strength",
        "minutes": 25, "distance": 0, "detail": "Гантели 3 × 10"
    })
    app.store.data["weights"] = [
        {"date": "2026-11-04", "value": 88.0},
        {"date": "2026-11-11", "value": 87.3},
        {"date": "2026-11-19", "value": 86.8},
    ]
    app.store.data["notes"][app.date] = "Вечером захотелось сладкого после прогулки."
    app._render()
    await _snapshot(app, "02-day-filled-top")
    app.food_form_expanded = true
    app._render()
    await process_frame
    if is_instance_valid(app.food_entry_card):
        app.scroll.ensure_control_visible(app.food_entry_card)
        await _snapshot(app, "03-food-entry-barcode")
    app.food_form_expanded = false
    app._render()
    app.scroll.scroll_vertical = 0
    app._show_barcode_portion(app.store.bundled_foods[0])
    await _snapshot(app, "05-barcode-result-dialog")
    for child in app.get_children():
        if child.name == "ProductSheet":
            child.queue_free()
    await process_frame
    app._confirm_barcode_product({
        "barcode": "3017624010701",
        "name": "Пример продукта",
        "kcal": 220.0, "p": 5.0, "f": 8.0, "c": 30.0,
        "source": "Open Food Facts"
    })
    await _snapshot(app, "06-new-product-dialog")
    for child in app.get_children():
        if child.name == "ProductSheet":
            child.queue_free()
    await process_frame
    var example_custom = {
        "id": "visual_custom", "name": "Йогурт домашний", "barcode": "3017624010701",
        "kcal": 82.0, "p": 6.0, "f": 2.4, "c": 9.0
    }
    app.store.data["foods"].append(example_custom)
    app._edit_custom_food(example_custom)
    await _snapshot(app, "07-edit-own-product")
    for child in app.get_children():
        if child.name == "ProductSheet":
            child.queue_free()
    await process_frame
    for page in ["activity", "weight", "stats", "settings"]:
        app.tab = page
        app._render()
        await _snapshot(app, "04-"+page)
    app.tab = "settings"
    app.settings_page = "foods"
    app._render()
    await _snapshot(app, "08-own-products")
    app.queue_free()
    quit(0)
