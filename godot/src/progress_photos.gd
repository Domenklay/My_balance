extends RefCounted
const Body = preload("res://src/body_measurements.gd")
const MAX_PHOTOS = 200
const MAX_BYTES = 400000
const MAX_SIDE = 1440
var folder: String
var records: Array = []

func _init(path: String = "") -> void:
    folder = path
    if not folder.is_empty():
        if DirAccess.make_dir_recursive_absolute(folder) != OK:
            folder = ""
        else:
            reload()

static func compact(raw: PackedByteArray) -> PackedByteArray:
    if raw.is_empty() or raw.size() > 16777216:
        return PackedByteArray()
    var image = Image.new()
    var err: Error = image.load_jpg_from_buffer(raw)
    if err != OK:
        err = image.load_png_from_buffer(raw)
    if err != OK:
        err = image.load_webp_from_buffer(raw)
    if err != OK or image.is_empty():
        return PackedByteArray()
    var side = maxi(image.get_width(),image.get_height())
    if mini(image.get_width(),image.get_height()) < 16 or side > 8192:
        return PackedByteArray()
    if side > MAX_SIDE:
        var scale = float(MAX_SIDE)/float(side)
        image.resize(maxi(1,roundi(image.get_width()*scale)),maxi(1,roundi(image.get_height()*scale)),Image.INTERPOLATE_LANCZOS)
    image.convert(Image.FORMAT_RGB8)
    for quality in [0.85,0.75,0.65,0.5,0.35]:
        var bytes = image.save_jpg_to_buffer(quality)
        if not bytes.is_empty() and bytes.size() <= MAX_BYTES:
            return bytes
    return PackedByteArray()

static func valid_id(id: String) -> bool:
    if id.length()!=32:
        return false
    for letter in id:
        if not "0123456789abcdef".contains(letter):
            return false
    return true

static func valid_meta(record: Variant) -> bool:
    if not record is Dictionary or not record.get("id") is String or not valid_id(record["id"]) or not record.get("date") is String or not Body.valid_date(record["date"]):
        return false
    if record.has("weight") and (not (record["weight"] is int or record["weight"] is float) or not is_finite(float(record["weight"])) or float(record["weight"])<20 or float(record["weight"])>400):
        return false
    if not record.get("measurements") is Dictionary:
        return false
    if not record["measurements"].is_empty() and not Body.valid_record({"date":record["date"],"values":record["measurements"]}):
        return false
    return record.get("note","") is String and str(record.get("note","")).length()<=200

func _path(id: String) -> String:
    return folder.path_join(id+".json")

func _read(id: String) -> Dictionary:
    if folder.is_empty() or not valid_id(id):
        return {}
    var f = FileAccess.open(_path(id),FileAccess.READ)
    if f == null:
        return {}
    if f.get_length() > MAX_BYTES*2:
        f.close()
        return {}
    var record = JSON.parse_string(f.get_as_text())
    f.close()
    if not valid_meta(record) or record["id"]!=id or not record.get("jpeg") is String or record["jpeg"].length()>MAX_BYTES*2:
        return {}
    return record

func reload() -> void:
    records.clear()
    if folder.is_empty():
        return
    var dir = DirAccess.open(folder)
    if dir == null:
        return
    for filename in dir.get_files():
        if filename.ends_with(".tmp") and valid_id(filename.trim_suffix(".tmp")):
            dir.remove(filename)
        elif filename.ends_with(".json") and records.size()<MAX_PHOTOS:
            var record = _read(filename.trim_suffix(".json"))
            if not record.is_empty():
                record.erase("jpeg")
                records.append(record)
    _sort()

func _sort() -> void:
    records.sort_custom(func(a,b):
        if a["date"] != b["date"]:
            return str(a["date"]) > str(b["date"])
        return str(a["id"]) > str(b["id"])
    )

func list() -> Array:
    return records.duplicate(true)

func add(raw: PackedByteArray,day: String,weight: Variant,measurements: Dictionary,note: String = "") -> String:
    if folder.is_empty() or records.size()>=MAX_PHOTOS:
        return ""
    var bytes = compact(raw)
    if bytes.is_empty():
        return ""
    var id = Crypto.new().generate_random_bytes(16).hex_encode()
    var record = {"id":id,"date":day,"measurements":measurements.duplicate(true),"note":note.strip_edges().left(200)}
    if weight != null:
        record["weight"] = weight
    if not valid_meta(record) or FileAccess.file_exists(_path(id)):
        return ""
    var payload = record.duplicate(true)
    payload["jpeg"] = Marshalls.raw_to_base64(bytes)
    var temp = folder.path_join(id+".tmp")
    var f = FileAccess.open(temp,FileAccess.WRITE)
    if f == null:
        return ""
    f.store_string(JSON.stringify(payload))
    f.flush()
    var err = f.get_error()
    f.close()
    if err != OK or DirAccess.rename_absolute(temp,_path(id)) != OK:
        DirAccess.remove_absolute(temp)
        return ""
    records.append(record)
    _sort()
    return id

func texture(id: String,thumb: bool = false) -> ImageTexture:
    var record = _read(id)
    if record.is_empty():
        return null
    var bytes = Marshalls.base64_to_raw(record["jpeg"])
    if bytes.is_empty() or bytes.size()>MAX_BYTES:
        return null
    var image = Image.new()
    if image.load_jpg_from_buffer(bytes)!=OK or image.is_empty():
        return null
    var side = maxi(image.get_width(),image.get_height())
    if side>MAX_SIDE:
        return null
    if thumb and side>420:
        var scale = 420.0/float(side)
        image.resize(maxi(1,roundi(image.get_width()*scale)),maxi(1,roundi(image.get_height()*scale)),Image.INTERPOLATE_LANCZOS)
    return ImageTexture.create_from_image(image)

func remove(id: String) -> bool:
    if folder.is_empty() or not valid_id(id):
        return false
    if DirAccess.remove_absolute(_path(id))!=OK:
        return false
    records = records.filter(func(record): return record["id"]!=id)
    return true
