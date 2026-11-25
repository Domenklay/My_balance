extends RefCounted
# Conservative extraction. Multiple bases/columns are left for manual review.
static func _regex(pattern: String) -> RegEx:
    var r = RegEx.new()
    r.compile(pattern)
    return r

static func parse(raw: String) -> Dictionary:
    var result: Dictionary = {"name":"","source":"Фото этикетки","ocr_review":true,"nutrition_unit":"г"}
    var normalized = raw.left(12000).to_lower().replace("ё","е").replace("\u00a0"," ").replace("\u202f"," ")
    var ml = _regex("\\b100\\s*(?:мл|ml)\\b").search(normalized)
    var gram = _regex("\\b100\\s*(?:г|g)\\b").search(normalized)
    if ml != null and gram == null:
        result["nutrition_unit"] = "мл"
    if (ml == null and gram == null) or (ml != null and gram != null):
        return result
    # Do not guess which column belongs to the 100 g basis.
    if _regex("(?:на\\s+порци|в\\s+порци|per\\s+serving|per\\s+portion|w\\s+porcji|na\\s+porcję|%\\s*(?:ri|dv))").search(normalized) != null:
        return result
    var patterns = {
        "p":"^\\s*(?:белки|белок|protein(?:s)?|białko)\\s*[:=\\-]?\\s*",
        "f":"^\\s*(?:жиры|жир|fat|total fat|tłuszcz)\\s*[:=\\-]?\\s*",
        "c":"^\\s*(?:углеводы|carbohydrates?|total carbohydrate|węglowodany)\\s*[:=\\-]?\\s*"
    }
    var number = _regex("^([0-9]+(?:[.,][0-9]+)?)\\s*(?:г|g)?\\s*$")
    var kcal_pattern = _regex("([0-9]+(?:[.,][0-9]+)?)\\s*(?:ккал|kcal)\\b")
    var kj_pattern = _regex("([0-9]+(?:[.,][0-9]+)?)\\s*(?:кдж|kj)\\b")
    var energy_label = _regex("^\\s*(?:энергетическая ценность|энергия|energy|wartość energetyczna|калорийность|калории)\\s*[:=\\-]?\\s*")
    var conflicts = {}
    for raw_line in normalized.split("\n"):
        var line = raw_line.strip_edges()
        for key in patterns:
            var label = _regex(patterns[key]).search(line)
            if label == null:
                continue
            var rest = line.substr(label.get_end()).strip_edges()
            var value_match = number.search(rest)
            if value_match != null:
                _put(result,conflicts,key,float(value_match.get_string(1).replace(",",".")),100.0)
        var energy = energy_label.search(line)
        if energy != null:
            line = line.substr(energy.get_end()).strip_edges()
        var kc = kcal_pattern.search_all(line)
        var kj = kj_pattern.search_all(line)
        # An energy row may contain one kJ and one kcal value, but not two
        # values for either unit. Require a full row of energy tokens.
        var energy_tokens = _regex("^\\s*(?:[0-9]+(?:[.,][0-9]+)?\\s*(?:кдж|kj|ккал|kcal)\\s*[/,;|]?\\s*){1,2}$")
        if energy_tokens.search(line) != null:
            if kc.size() == 1 and kj.size() <= 1:
                _put(result,conflicts,"kcal",float(kc[0].get_string(1).replace(",",".")),1000.0)
            elif kc.is_empty() and kj.size() == 1:
                _put(result,conflicts,"kcal",snappedf(float(kj[0].get_string(1).replace(",","."))/4.184,0.1),1000.0)
    return result

static func _put(result: Dictionary, conflicts: Dictionary, key: String, value: float, maximum: float) -> void:
    if not is_finite(value) or value < 0 or value > maximum or conflicts.has(key):
        return
    if result.has(key) and not is_equal_approx(float(result[key]),value):
        result.erase(key)
        conflicts[key] = true
    else:
        result[key] = value
