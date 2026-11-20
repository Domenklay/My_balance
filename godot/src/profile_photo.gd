extends RefCounted

const MAX_SOURCE_BYTES = 16777216
const MAX_PHOTO_BYTES = 180000
const AVATAR_SIZE = 256

static func make_photo(raw: PackedByteArray) -> String:
    if raw.is_empty() or raw.size() > MAX_SOURCE_BYTES:
        return ""
    var image = Image.new()
    var load_error: Error = image.load_jpg_from_buffer(raw)
    if load_error != OK:
        load_error = image.load_png_from_buffer(raw)
    if load_error != OK:
        load_error = image.load_webp_from_buffer(raw)
    if load_error != OK or image.is_empty():
        return ""
    var w: int = image.get_width()
    var h: int = image.get_height()
    if w < 16 or h < 16 or w > 8192 or h > 8192:
        return ""
    var side = mini(w, h)
    # Center-crop to a square; the display additionally applies a round mask.
    var square: Image = image.get_region(Rect2i((w - side) / 2, (h - side) / 2, side, side))
    square.resize(AVATAR_SIZE, AVATAR_SIZE, Image.INTERPOLATE_LANCZOS)
    if square.is_empty():
        return ""
    square.convert(Image.FORMAT_RGB8)
    var saved: PackedByteArray = square.save_jpg_to_buffer(0.83)
    if saved.is_empty() or saved.size() > MAX_PHOTO_BYTES:
        return ""
    return Marshalls.raw_to_base64(saved)

static func decode_photo(encoded: String) -> ImageTexture:
    if encoded.is_empty() or encoded.length() > MAX_PHOTO_BYTES * 2:
        return null
    var bytes: PackedByteArray = Marshalls.base64_to_raw(encoded)
    if bytes.is_empty() or bytes.size() > MAX_PHOTO_BYTES:
        return null
    var image = Image.new()
    if image.load_jpg_from_buffer(bytes) != OK:
        return null
    if image.is_empty() or image.get_width() != AVATAR_SIZE or image.get_height() != AVATAR_SIZE:
        return null
    return ImageTexture.create_from_image(image)

static func valid_photo(encoded: Variant) -> bool:
    if not (encoded is String):
        return false
    if encoded.is_empty():
        return true
    return decode_photo(encoded) != null
