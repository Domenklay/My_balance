extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _fail(msg: String) -> void:
    push_error("LAUNCHER ICON REGRESSION FAILED: " + msg)
    quit(1)

func _run() -> void:
    var image_path = "res://assets/launcher_icon.png"
    if str(ProjectSettings.get_setting("application/config/icon", "")) != image_path:
        _fail("project is still using the previous icon")
        return
    var icon_image: Image = Image.load_from_file(image_path)
    if icon_image == null or icon_image.is_empty():
        _fail("new launcher image cannot be loaded")
        return
    if icon_image.get_width() != 192 or icon_image.get_height() != 192:
        _fail("launcher image dimensions mismatch")
        return
    var cfg = ConfigFile.new()
    if cfg.load("res://export_presets.cfg") != OK:
        _fail("cannot read Android export settings")
        return
    if cfg.get_value("preset.0.options", "launcher_icons/main_192x192", "") != image_path:
        _fail("Android launcher icon path not set")
        return
    if cfg.get_value("preset.0.options", "package/unique_name", "") != "com.domenklay.mybalance.godot":
        _fail("Android package identifier changed unexpectedly")
        return
    if int(cfg.get_value("preset.0.options", "version/code", 0)) != 49:
        _fail("Android versionCode not updated")
        return
    print("PASS LAUNCHER ICON: chosen illustration loaded and Android icon paths updated")
    quit(0)
