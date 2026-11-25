extends SceneTree
const Photos = preload("res://src/progress_photos.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(message: String) -> void:
    push_error("PROGRESS PHOTOS: " + message)
    quit(1)
func _run() -> void:
    var folder = "user://progress_photo_test_" + Crypto.new().generate_random_bytes(8).hex_encode()
    var gallery = Photos.new(folder)
    var image = Image.create(1600,800,false,Image.FORMAT_RGB8)
    image.fill(Color(0.2,0.5,0.6))
    var bytes = image.save_png_to_buffer()
    var a: String = gallery.add(bytes,"2026-11-24",88.0,{"waist":90.0},"Первый")
    var b: String = gallery.add(bytes,"2026-11-25",null,{},"Второй")
    if a.is_empty() or b.is_empty() or gallery.add(bytes,"invalid",88.0,{} )!="" or gallery.add(PackedByteArray([1,2,3]),"2026-11-25",null,{})!="":
        _fail("save and validation")
        return
    var restored = Photos.new(folder)
    var rows = restored.list()
    if rows.size()!=2 or rows[0]["id"]!=b or rows[0].has("weight") or rows[1]["weight"]!=88.0 or rows[1]["measurements"]["waist"]!=90.0:
        _fail("persistence, order and exact snapshot")
        return
    var texture = restored.texture(a)
    if texture==null or texture.get_width()!=1440 or texture.get_height()!=720 or restored.texture(a,true).get_width()!=420:
        _fail("aspect ratio and size limits")
        return
    var archive = folder.path_join("gallery.zip")
    var target_folder = folder + "_restored"
    var target = Photos.new(target_folder)
    if not restored.export_backup(archive) or target.import_backup(archive) != 2 or target.import_backup(archive) != 0:
        _fail("backup export, merge and duplicate prevention")
        return
    if target.list() != restored.list() or target.texture(a) == null:
        _fail("backup metadata or image mismatch")
        return
    var bad = folder.path_join("invalid.zip")
    var pack = ZIPPacker.new()
    pack.open(bad)
    pack.start_file("manifest.txt")
    pack.write_file(Photos.BACKUP_MANIFEST.to_utf8_buffer())
    pack.close_file()
    pack.start_file("invalid.json")
    pack.write_file("{}".to_utf8_buffer())
    pack.close_file()
    pack.close()
    if target.import_backup(bad) != -1 or target.list().size() != 2:
        _fail("invalid archive changed existing gallery")
        return
    target.remove(a)
    target.remove(b)
    DirAccess.remove_absolute(target_folder)
    DirAccess.remove_absolute(archive)
    DirAccess.remove_absolute(bad)
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.progress_photos = restored
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app._set_progress_section("photos")
    await process_frame
    if app.find_child("ProgressPhotoGrid",true,false)==null or app.store.export_json().contains(a) or app.store.export_json().contains("jpeg"):
        _fail("gallery missing or private data in diary")
        return
    if app.find_child("ProgressPhotoBackup",true,false) == null:
        _fail("photo backup button missing")
        return
    (app.find_child("ProgressPhotoCompare",true,false) as Button).pressed.emit()
    await process_frame
    var pair = app.find_child("ProgressComparePair",true,false)
    if pair==null or pair.get_child_count()!=2:
        _fail("comparison")
        return
    if not restored.remove(a) or restored.texture(a)!=null or Photos.new(folder).list().size()!=1:
        _fail("permanent deletion")
        return
    restored.remove(b)
    DirAccess.remove_absolute(folder)
    print("PASS PROGRESS PHOTOS: separate private files, compression, snapshots, comparison, export exclusion and deletion")
    app.queue_free()
    quit(0)
