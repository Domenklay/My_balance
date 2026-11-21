extends SceneTree

const Store = preload("res://src/store.gd")
const RecipeMath = preload("res://src/recipe_math.gd")
const Photo = preload("res://src/profile_photo.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED RECIPE CARDS 0.7.26: " + reason)
    quit(1)

func _button(node: Node, caption: String) -> Button:
    if node is Button and node.text == caption:
        return node
    for child in node.get_children():
        var item: Button = _button(child, caption)
        if item != null:
            return item
    return null

func _run() -> void:
    var image = Image.create(96, 96, false, Image.FORMAT_RGB8)
    image.fill(Color("#91bd91"))
    var photo = Photo.make_photo(image.save_jpg_to_buffer(0.86))
    if photo.is_empty() or not Photo.valid_photo(photo):
        _fail("could not prepare bounded image")
        return
    var sample = {"id":"r_visual_sample", "name":"Домашняя запеканка",
        "cooked_weight":800.0, "servings":4.0, "photo":photo,
        "ingredients":[
            {"id":"test", "name":"Творог", "grams":400.0, "kcal":120.0,
             "p":18.0, "f":5.0, "c":3.0}
        ]}
    if not RecipeMath.validate_recipe(sample):
        _fail("valid photo should be accepted without changing food data")
        return
    var invalid = sample.duplicate(true)
    invalid["photo"] = "not a valid compressed photo"
    if RecipeMath.validate_recipe(invalid):
        _fail("corrupt photo should not be stored in JSON")
        return
    var store = Store.new()
    store.data = store.default_data()
    if store.save_recipe(sample) != "r_visual_sample":
        _fail("photo recipe failed to save")
        return
    var reread = Store.new()
    if not Photo.valid_photo(str(reread.recipe_by_id("r_visual_sample").get("photo", ""))):
        _fail("photo not persisted through store restart")
        return
    if store.save_recipe(invalid) != "" or \
            str(store.recipe_by_id("r_visual_sample").get("photo", "")) != photo:
        _fail("invalid edit damaged saved recipe")
        return
    var totals = RecipeMath.calculate(sample["ingredients"], 800.0)
    if absf(float(totals["total_kcal"]) - 480.0) > 0.01:
        _fail("photo changed nutrition math")
        return
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.store.data["recipes"].append(sample.duplicate(true))
    app.tab = "recipes"
    for theme in ["forest", "botanical", "dark"]:
        app.store.data["settings"]["theme"] = theme
        app._refresh_appearance()
        app._render()
        await process_frame
        var card = app.find_child("RecipeCard_r_visual_sample", true, false)
        var title = app.find_child("RecipeCardTitle", true, false) as Label
        var calories = app.find_child("RecipeCardKcal", true, false) as Label
        var macros = app.find_child("RecipeCardMacros", true, false) as Label
        var picture = app.find_child("RecipePhotoImage", true, false) as TextureRect
        if card == null or title == null or calories == null or macros == null or picture == null:
            _fail("recipe card is not complete in " + theme)
            return
        if title.text != sample["name"] or not calories.text.contains("120 ккал / порция") or \
                not macros.text.contains("Б "):
            _fail("card must show exact per-serving energy and macros in " + theme)
            return
        if picture.texture == null or picture.texture.get_width() != Photo.AVATAR_SIZE:
            _fail("own image is not shown in " + theme)
            return
        if _button(card, "+ Добавить порцию в дневник") == null or \
                _button(card, "⋯") == null:
            _fail("compact recipe actions are missing in " + theme)
            return
        if _button(card, "Удалить") != null:
            _fail("rare destructive actions should be hidden initially")
            return
    _button(app.find_child("RecipeCard_r_visual_sample", true, false), "⋯").pressed.emit()
    await process_frame
    var opened = app.find_child("RecipeCard_r_visual_sample", true, false)
    if _button(opened, "Удалить") == null or _button(opened, "✎ Изменить") == null:
        _fail("expandable actions missing")
        return
    _button(opened, "✎ Изменить").pressed.emit()
    await process_frame
    var photo_button = app.find_child("RecipeChoosePhoto", true, false)
    var remove_button = app.find_child("RecipeRemovePhoto", true, false)
    if not app.recipe_editor_open or photo_button == null or remove_button == null:
        _fail("photo controls missing from existing recipe editor")
        return
    remove_button.pressed.emit()
    await process_frame
    if str(app.recipe_draft.get("photo", "unexpected")) != "":
        _fail("photo not removable from draft")
        return
    if not app._apply_recipe_photo_bytes(image.save_jpg_to_buffer(0.85)):
        _fail("photo could not be added back to recipe draft")
        return
    if not Photo.valid_photo(str(app.recipe_draft.get("photo", ""))):
        _fail("recipe photo bytes not processed")
        return
    var save = _button(app, "Сохранить рецепт")
    if save == null:
        _fail("recipe photo draft cannot be saved")
        return
    save.pressed.emit()
    await process_frame
    if app.recipe_editor_open or not Photo.valid_photo(
            str(app.store.recipe_by_id("r_visual_sample").get("photo", ""))):
        _fail("recipe photo did not survive save")
        return
    print("PASS RECIPE CARDS 0.7.26: safe photo, old schema, per-serving BJU, themes, hidden actions, photo save")
    app.queue_free()
    quit(0)
