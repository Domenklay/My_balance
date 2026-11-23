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
    # Keep the selected food illustration colorful: salmon should stay orange
    # and blueberries should stay blue even after launcher optimization.
    var orange_pixels = 0
    var blue_pixels = 0
    for y in range(0, icon_image.get_height(), 2):
        for x in range(0, icon_image.get_width(), 2):
            var c: Color = icon_image.get_pixel(x, y)
            if c.r > 0.63 and c.r > c.g * 1.15 and c.g > c.b * 1.1:
                orange_pixels += 1
            if c.b > 0.3 and c.b > c.r * 1.2 and c.b > c.g * 1.2:
                blue_pixels += 1
    if orange_pixels < 30 or blue_pixels < 10:
        _fail("image lost orange salmon or blue berries during compression")
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
    if int(cfg.get_value("preset.0.options", "version/code", 0)) != 60:
        _fail("Android versionCode not updated")
        return
    print("PASS LAUNCHER ICON: chosen illustration loaded and Android icon paths updated")
    quit(0)
