extends RefCounted
const RecipeMath = preload("res://src/recipe_math.gd")
const MAX_ITEMS = 100

# Conservative aliases: no substring matches, no raw/cooked substitutions.
static func key(raw: String) -> String:
    var value = raw.strip_edges().to_lower().replace("ё","е")
    for ch in ["(",")",",","-"]:
        value = value.replace(ch," ")
    value = " ".join(value.split(" ",false))
    var aliases = {
        "яйца":"яйцо","яйцо без скорлупы":"яйцо","яйца куриные":"яйцо",
        "яблоки":"яблоко","бананы":"банан","огурцы":"огурец","помидор":"помидоры",
        "томаты":"помидоры","томаты свежие":"помидоры","морковка":"морковь",
        "лук":"лук репчатый","картошка":"картофель","кабачки":"кабачок",
        "шампиньон":"шампиньоны","овсяные хлопья сухие":"овсяные хлопья",
        "мука":"мука пшеничная","растительное масло":"масло растительное",
        "куриная грудка сырая":"куриная грудка","филе куриной грудки сырое":"куриная грудка",
        "рис сухой":"рис","гречка сухая":"гречка","макароны сухие":"макароны",
        "чечевица сухая":"чечевица","груши":"груша","апельсин очищенный":"апельсин",
        "киви очищенный":"киви"
    }
    return str(aliases.get(value,value))

static func valid_list(items: Variant) -> bool:
    if not items is Array or items.size() > MAX_ITEMS:
        return false
    var seen = {}
    for item in items:
        if not item is String or item.strip_edges().is_empty() or item.length() > 120 or key(item).is_empty() or seen.has(key(item)):
            return false
        seen[key(item)] = true
    return true

static func matches(recipes: Array, available: Array, maximum_missing: int, category: String = "") -> Array:
    var result: Array = []
    var have = {}
    for item in available:
        have[key(str(item))] = true
    if have.is_empty():
        return result
    for recipe in recipes:
        if not RecipeMath.validate_recipe(recipe) or (not category.is_empty() and recipe.get("category","other") != category):
            continue
        var present: Array = []
        var missing: Array = []
        var seen = {}
        for ingredient in recipe["ingredients"]:
            var name = str(ingredient["name"])
            var id = key(name)
            if seen.has(id):
                continue
            seen[id] = true
            if have.has(id):
                present.append(name)
            else:
                missing.append(name)
        if present.is_empty() or missing.size() > maximum_missing:
            continue
        result.append({"recipe":recipe,"present":present,"missing":missing,"ratio":float(present.size()) / float(seen.size())})
    result.sort_custom(func(a,b):
        if a["missing"].size() != b["missing"].size():
            return a["missing"].size() < b["missing"].size()
        if not is_equal_approx(float(a["ratio"]),float(b["ratio"])):
            return float(a["ratio"]) > float(b["ratio"])
        return str(a["recipe"]["name"]).nocasecmp_to(str(b["recipe"]["name"])) < 0
    )
    return result
