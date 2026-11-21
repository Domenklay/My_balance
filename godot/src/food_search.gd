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
