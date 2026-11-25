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

# The exported gallery is deliberately separate from the food diary.
const BACKUP_LIMIT = 112000000
const BACKUP_MANIFEST = "mybalance-progress-v1"

static func valid_payload(value: Variant) -> bool:
    if not valid_meta(value) or not value.get("jpeg") is String:
        return false
    if value["jpeg"].length() > MAX_BYTES * 2:
        return false
    var bytes = Marshalls.base64_to_raw(value["jpeg"])
    if bytes.is_empty() or bytes.size() > MAX_BYTES:
        return false
    var img = Image.new()
    if img.load_jpg_from_buffer(bytes) != OK or img.is_empty():
        return false
    return mini(img.get_width(), img.get_height()) >= 16 and maxi(img.get_width(), img.get_height()) <= MAX_SIDE

func export_backup(path: String) -> bool:
    if folder.is_empty() or records.is_empty():
        return false
    var zip = ZIPPacker.new()
    if zip.open(path) != OK:
        return false
    var ok: bool = zip.start_file("manifest.txt") == OK
    if ok:
        ok = zip.write_file(BACKUP_MANIFEST.to_utf8_buffer()) == OK
        ok = zip.close_file() == OK and ok
    for meta in records:
        if not ok:
            break
        var payload = _read(str(meta["id"]))
        if not valid_payload(payload):
            ok = false
            break
        if zip.start_file(str(meta["id"]) + ".json") != OK:
            ok = false
            break
        ok = zip.write_file(JSON.stringify(payload).to_utf8_buffer()) == OK
        ok = zip.close_file() == OK and ok
    ok = zip.close() == OK and ok
    if not ok:
        DirAccess.remove_absolute(path)
    return ok

# Validate and stage each record before publishing anything. Duplicate IDs
# are skipped, never overwritten; a full gallery rejects the whole import.
func import_backup(path: String) -> int:
    if folder.is_empty():
        return -1
    var f = FileAccess.open(path, FileAccess.READ)
    if f == null:
        return -1
    var length = f.get_length()
    f.close()
    if length <= 0 or length > BACKUP_LIMIT:
        return -1
    var zip = ZIPReader.new()
    if zip.open(path) != OK:
        return -1
    var names = zip.get_files()
    var ok: bool = names.size() <= MAX_PHOTOS + 1 and names.has("manifest.txt")
    # Limit decompressed entry sizes using the ZIP central directory before read_file.
    if ok:
        ok = _safe_zip_sizes(path, names.size())
    if ok:
        ok = zip.read_file("manifest.txt").get_string_from_utf8() == BACKUP_MANIFEST
    var staged: Array[String] = []
    var seen: Dictionary = {}
    for filename in names:
        if not ok:
            break
        if seen.has(filename):
            ok = false
            break
        seen[filename] = true
        if filename == "manifest.txt":
            continue
        var id: String = filename.trim_suffix(".json")
        if not filename.ends_with(".json") or not valid_id(id):
            ok = false
            break
        var raw = zip.read_file(filename)
        if raw.size() > MAX_BYTES * 2:
            ok = false
            break
        var value = JSON.parse_string(raw.get_string_from_utf8())
        if not valid_payload(value) or value["id"] != id:
            ok = false
            break
        if FileAccess.file_exists(_path(id)):
            continue
        if records.size() + staged.size() >= MAX_PHOTOS:
            ok = false
            break
        var temp = folder.path_join(id + ".tmp")
        var out = FileAccess.open(temp, FileAccess.WRITE)
        if out == null:
            ok = false
            break
        staged.append(id)
        out.store_buffer(raw)
        out.flush()
        var status = out.get_error()
        out.close()
        if status != OK:
            ok = false
            break
    zip.close()
    var published: Array[String] = []
    if ok:
        for id in staged:
            if FileAccess.file_exists(_path(id)) or DirAccess.rename_absolute(folder.path_join(id + ".tmp"), _path(id)) != OK:
                ok = false
                break
            published.append(id)
    if not ok:
        for id in published:
            DirAccess.remove_absolute(_path(id))
    for id in staged:
        var temp = folder.path_join(id + ".tmp")
        if FileAccess.file_exists(temp):
            DirAccess.remove_absolute(temp)
    reload()
    return published.size() if ok else -1

# Accept only ordinary bounded ZIP archives, not ZIP64, encrypted or split
# archives. Validate declared uncompressed sizes before calling ZIPReader.
static func _safe_zip_sizes(path: String, expected: int) -> bool:
    var f = FileAccess.open(path, FileAccess.READ)
    if f == null:
        return false
    var length = f.get_length()
    if length < 22:
        f.close()
        return false
    # Our own ZIPPacker writes no archive comment.
    f.seek(length - 22)
    if f.get_32() != 0x06054b50 or f.get_16() != 0 or f.get_16() != 0:
        f.close()
        return false
    var disk_count = f.get_16()
    var total_count = f.get_16()
    var central_size = f.get_32()
    var offset = f.get_32()
    var comment = f.get_16()
    if comment != 0 or total_count != expected or disk_count != total_count or offset + central_size != length - 22:
        f.close()
        return false
    f.seek(offset)
    var total = 0
    for i in range(total_count):
        var start = f.get_position()
        if start + 46 > length - 22 or f.get_32() != 0x02014b50:
            f.close()
            return false
        f.seek(start + 8)
        var flags = f.get_16()
        var method = f.get_16()
        f.seek(start + 20)
        var packed = f.get_32()
        var unpacked = f.get_32()
        var name_len = f.get_16()
        var extra_len = f.get_16()
        var comment_len = f.get_16()
        total += unpacked
        var next = start + 46 + name_len + extra_len + comment_len
        if (flags & 1) != 0 or method not in [0, 8] or packed > BACKUP_LIMIT or unpacked > MAX_BYTES * 2 or total > BACKUP_LIMIT or next > length - 22:
            f.close()
            return false
        f.seek(next)
    var ok = f.get_position() == length - 22
    f.close()
    return ok
