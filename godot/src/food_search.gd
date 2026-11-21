extends RefCounted

# A permissive search for local Russian and international product names.
const LETTERS = {
    "а":"a","б":"b","в":"v","г":"g","д":"d","е":"e",
    "ж":"zh","з":"z","и":"i","й":"y","к":"k","л":"l",
    "м":"m","н":"n","о":"o","п":"p","р":"r","с":"s",
    "т":"t","у":"u","ф":"f","х":"kh","ц":"ts","ч":"ch",
    "ш":"sh","щ":"shch","ъ":"","ы":"y","ь":"","э":"e",
    "ю":"yu","я":"ya"
}
const KEY_EN = "qwertyuiop[]asdfghjkl;'zxcvbnm,."
const KEY_RU = "йцукенгшщзхъфывапролджэячсмитьбю"

static func normalize(s: String) -> String:
    var result = s.to_lower().replace("ё", "е").strip_edges()
    for mark in ["(",")","[","]",",",".",";",":","!","?","-","_","/"]:
        result = result.replace(mark, " ")
    return " ".join(result.split(" ", false))

static func transliterate(s: String) -> String:
    var out = ""
    for i in range(s.length()):
        var c = s.substr(i, 1)
        out += str(LETTERS.get(c, c))
    return out

static func fix_keyboard(s: String) -> String:
    var out = ""
    for i in range(s.length()):
        var c = s.substr(i, 1)
        var pos = KEY_EN.find(c)
        out += KEY_RU.substr(pos, 1) if pos >= 0 else c
    return out

static func matches(food: Dictionary, query: String) -> bool:
    var needle = normalize(query)
    if needle.is_empty():
        return true
    var target = normalize(str(food.get("name", "")) + " " +
        str(food.get("brand", "")) + " " + str(food.get("barcode", "")))
    var roman = transliterate(target)
    for token in needle.split(" ", false):
        if token in target or token in roman or fix_keyboard(token) in target:
            continue
        return false
    return true

# Text relevance is checked only after matches(), so a brand-only match is
# still returned but ranks below a direct product-name match.
static func relevance(food: Dictionary, query: String) -> int:
    var needle: String = normalize(query)
    if needle.is_empty():
        return 0
    if str(food.get("barcode", "")) == needle:
        return 0
    var name: String = normalize(str(food.get("name", "")))
    if name == needle:
        return 0
    if name.begins_with(needle):
        return 1
    if name.contains(" " + needle):
        return 2
    if name.contains(needle):
        return 3
    return 4


# Modes: 0=relevance, 1=frequency, 2=name, 3=calories asc, 4=calories desc.
# Stable name and id tie-breakers avoid random order and flickering between searches.
static func sort_before(a: Dictionary, b: Dictionary, query: String, mode: int,
        counts: Dictionary, favorites: Dictionary) -> bool:
    var a_id: String = str(a.get("id", ""))
    var b_id: String = str(b.get("id", ""))
    var a_count: int = int(counts.get(a_id, 0))
    var b_count: int = int(counts.get(b_id, 0))
    if mode == 3 or mode == 4:
        var a_kcal: float = float(a.get("kcal", 0))
        var b_kcal: float = float(b.get("kcal", 0))
        if not is_equal_approx(a_kcal, b_kcal):
            return a_kcal < b_kcal if mode == 3 else a_kcal > b_kcal
    elif mode == 1:
        if a_count != b_count:
            return a_count > b_count
    elif mode == 0:
        var a_rank: int = relevance(a, query)
        var b_rank: int = relevance(b, query)
        if a_rank != b_rank:
            return a_rank < b_rank
        var a_favorite: bool = favorites.has(a_id)
        var b_favorite: bool = favorites.has(b_id)
        if a_favorite != b_favorite:
            return a_favorite
        if a_count != b_count:
            return a_count > b_count
    var a_name: String = str(a.get("name", ""))
    var b_name: String = str(b.get("name", ""))
    var name_cmp: int = a_name.nocasecmp_to(b_name)
    if name_cmp != 0:
        return name_cmp < 0
    return a_id < b_id
