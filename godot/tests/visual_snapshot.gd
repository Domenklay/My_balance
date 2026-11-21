extends SceneTree

# Render actual Godot UI screens at Android reference resolution.
# This script runs in a temporary CI environment, never reads user data.
func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(app: Control, filename: String) -> void:
    await process_frame
    await process_frame
    # Some headless/Xvfb drivers never emit frame_post_draw. Force one frame
    # after two process frames instead of hanging the entire visual job.
    RenderingServer.force_draw()
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
    # Dedicated reference shots for the new smart-diary actions.
    app.date = "2026-11-20"
    app.day_tools_expanded = true
    app._render()
    await _snapshot(app, "02-day-smart-tools")
    app._copy_day_sheet()
    await _snapshot(app, "02-day-copy-preview")
    if app.get_node_or_null("ProductSheet") != null:
        app.get_node("ProductSheet").queue_free()
    await process_frame
    app.store.data["meal_templates"].append({
        "id":"visual_template","name":"Мой любимый завтрак",
        "items":[{"food":"d0","meal":"Завтрак","grams":130.0,"unit":"г",
            "nutrition":{"name":"Овсяные хлопья","kcal":370.0,"p":13.0,"f":7.0,"c":62.0}}]
    })
    app._meal_templates_sheet()
    await _snapshot(app, "02-day-saved-templates")
    if app.get_node_or_null("ProductSheet") != null:
        app.get_node("ProductSheet").queue_free()
    await process_frame
    app.day_tools_expanded = false
    app.date = "2026-11-19"
    app._render()
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
    app._confirm_barcode_product({
        "barcode": "3017624010701", "name": "Питьевой йогурт",
        "brand": "Пример марки", "quantity": "330 мл",
        "nutrition_unit": "мл", "unit_certainty": "quantity",
        "kcal": 93.0, "p": -1.0, "f": 2.5, "c": 11.0,
        "missing_fields": ["p"], "source": "Open Food Facts"
    })
    await _snapshot(app, "06-partial-product-review")
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
    app.tab = "stats"
    app.stats_period = "month"
    app.stats_anchor = app.date
    app._render()
    await _snapshot(app, "04-stats-month")
    # Three-month release regression: render the full set of period controls,
    # month-by-month nutrition and a continuous weight trend on a phone screen.
    app.store.data["entries"].append({
        "id":"example-september", "date":"2026-09-10",
        "food":sample_foods[0]["id"], "nutrition":sample_foods[0].duplicate(true),
        "grams":260.0, "meal":"Обед"
    })
    app.store.data["entries"].append({
        "id":"example-october", "date":"2026-10-10",
        "food":sample_foods[0]["id"], "nutrition":sample_foods[0].duplicate(true),
        "grams":180.0, "meal":"Обед"
    })
    app.store.data["weights"].append({"date":"2026-09-10", "value":90.1})
    app.store.data["weights"].append({"date":"2026-10-10", "value":89.0})
    app.stats_period = "quarter"
    app.stats_detail_tab = "nutrition"
    app._render()
    await _snapshot(app, "04-stats-three-months-nutrition")
    app.stats_detail_tab = "weight"
    app._render()
    await _snapshot(app, "04-stats-three-months-weight")
    app.stats_period = "week"
    app.stats_detail_tab = "activity"
    app.tab = "stats"
    app._render()
    await _snapshot(app, "04-stats-activity")
    app.stats_detail_tab = "weight"
    app._render()
    await _snapshot(app, "04-stats-weight")
    app.stats_detail_tab = "nutrition"
    app.tab = "settings"
    app.settings_page = "foods"
    app._render()
    await _snapshot(app, "08-own-products")
    # Test the new Recipes and personal Profile screens with fictional data.
    app.store.data["recipes"].append({
        "id": "visual_recipe",
        "name": "Домашняя запеканка",
        "cooked_weight": 800.0,
        "servings": 4.0,
        "ingredients": [
            {"id":"oats", "name":"Овсяные хлопья", "grams":250.0,
                "kcal":370.0, "p":13.0, "f":7.0, "c":62.0},
            {"id":"milk", "name":"Молоко", "grams":400.0,
                "kcal":50.0, "p":3.2, "f":2.0, "c":4.8}
        ]
    })
    app.store.data["profile"] = {
        "name": "Мой профиль", "avatar": "flower",
        "motto": "Каждый день — маленький шаг вперёд"
    }
    app.tab = "recipes"
    app._render()
    await _snapshot(app, "12-recipes-list")
    app._begin_recipe_editor(app.store.data["recipes"][0])
    await _snapshot(app, "13-recipe-editor")
    app.recipe_editor_open = false
    app.tab = "profile"
    app._render()
    await _snapshot(app, "14-personal-profile")
    app.profile_edit_open = true
    app._render()
    await _snapshot(app, "15-edit-profile")
    app.profile_edit_open = false
    app._render()
    # Optional home widgets are hidden by default; capture opt-in view.
    app.store.data["settings"]["home_widgets"] = {"week":true, "weight":true}
    app.tab = "day"
    app._render()
    await process_frame
    var home_week = app.find_child("HomeWeekWidget", true, false)
    if home_week != null:
        app.scroll.ensure_control_visible(home_week)
        await _snapshot(app, "18-week-widget-enabled")
    app.home_progress_view = "weight"
    app._render()
    await process_frame
    var home_weight = app.find_child("HomeWeightWidget", true, false)
    if home_weight != null:
        app.scroll.ensure_control_visible(home_weight)
        await _snapshot(app, "19-weight-widget-enabled")
    app.home_progress_view = "week"
    app.store.data["settings"]["home_widgets"] = {"week":false, "weight":false}
    # Capture each installed appearance variant for side-by-side review.
    for variant in ["forest", "mint", "sand", "dark", "botanical"]:
        app.store.data["settings"]["theme"] = variant
        app.store.data["settings"]["patterns"] = true
        app._refresh_appearance()
        app.tab = "day"
        app.settings_page = "main"
        app.scroll.scroll_vertical = 0
        app._render()
        await _snapshot(app, "09-" + variant + "-day")
        app.tab = "settings"
        app._render()
        await _snapshot(app, "10-" + variant + "-settings")
    app.store.data["settings"]["theme"] = "dark"
    app.store.data["settings"]["patterns"] = false
    app._refresh_appearance()
    app.tab = "day"
    app._render()
    await _snapshot(app, "11-dark-no-patterns")
    app.tab = "profile"
    app._render()
    await _snapshot(app, "16-dark-profile")
    app.tab = "recipes"
    app._render()
    await _snapshot(app, "17-dark-recipes")
    app.queue_free()
    quit(0)
