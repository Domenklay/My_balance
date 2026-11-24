extends SceneTree
const Photo = preload("res://src/profile_photo.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(reason: String) -> void:
    push_error("HEADER AVATAR 0.7.67: " + reason)
    quit(1)
func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.store.data["profile"]["name"] = "Александр Александрович"
    app.store.data["profile"]["avatar"] = "moon"
    app.tab = "day"
    app._render()
    await process_frame
    var button = app.find_child("HeaderAvatarButton",true,false) as Button
    var name_label = app.find_child("HeaderAvatarName",true,false) as Label
    var photo = app.find_child("HeaderAvatarPhoto",true,false) as TextureRect
    if button == null or name_label == null or photo == null or button.text != "☾" or photo.visible or not name_label.visible:
        _fail("profile icon or name missing")
        return
    if app.header_panel.get_combined_minimum_size().x > 420.0:
        _fail("header too wide")
        return
    var img = Image.create(64,64,false,Image.FORMAT_RGB8)
    img.fill(Color.BLUE)
    app.store.data["profile"]["photo"] = Photo.make_photo(img.save_png_to_buffer())
    app._render()
    await process_frame
    if not photo.visible or photo.texture == null or button.text != "":
        _fail("photo not displayed")
        return
    button.pressed.emit()
    await process_frame
    if app.tab != "profile":
        _fail("profile shortcut")
        return
    app._begin_onboarding(true)
    await process_frame
    if not button.disabled:
        _fail("questionnaire can be abandoned accidentally")
        return
    app.store.data["profile"]["photo"] = ""
    app.tab = "day"
    app._render()
    await process_frame
    if photo.visible or button.text != "☾" or button.disabled:
        _fail("photo removal did not update header")
        return
    app.queue_free()
    print("PASS HEADER AVATAR: saved photo, icon, clipped name, profile navigation and questionnaire safety")
    quit(0)
