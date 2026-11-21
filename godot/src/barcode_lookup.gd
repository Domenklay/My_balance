extends RefCounted

# Open Food Facts barcode response adapter. Values are per 100 g / 100 ml.
const OFF_BASE = "https://world.openfoodfacts.org/api/v2/product/"
const OFF_FIELDS = "code,product_name,product_name_ru,brands,nutriments,quantity,product_quantity_unit,serving_size,nutrition_data_per,image_front_small_url,image_front_url"

const SEARCH_BASE = "https://world.openfoodfacts.org/cgi/search.pl"

# Free-text lookup is only available via the legacy OFF search endpoint.
static func search_url(terms: String) -> String:
    var query = terms.strip_edges()
    if query.length() < 2 or query.length() > 70:
        return ""
    return SEARCH_BASE + "?search_terms=" + query.uri_encode() + \
        "&search_simple=1&action=process&json=1&page=1&page_size=24" + \
        "&fields=" + OFF_FIELDS

static func parse_search_results(payload: Variant, limit: int = 12) -> Array:
    var results: Array = []
    if not (payload is Dictionary and payload.get("products") is Array):
        return results
    var seen: Dictionary = {}
    for product in payload["products"]:
        if not (product is Dictionary):
            continue
        var code = normalize_code(str(product.get("code", "")))
        if code.is_empty() or seen.has(code):
            continue
        var parsed: Dictionary = parse_product({"status": 1, "product": product}, code)
        if parsed.has("error"):
            continue
        parsed["id"] = "barcode_" + code
        # Metadata and nutrient completeness are both preserved by parse_product.
        # Never label open-database contents as independently verified.
        # Keep the nutrient basis detected during product parsing.
        # Never overwrite it with a hard-coded gram basis.
        seen[code] = true
        results.append(parsed)
        if results.size() >= limit:
            break
    return results

static func normalize_code(raw: String) -> String:
    var code = raw.strip_edges()
    if code.length() not in [8, 12, 13, 14]:
        return ""
    for i in range(code.length()):
        var ch = code.unicode_at(i)
        if ch < 48 or ch > 57:
            return ""
    var sum = 0
    var weight = 3
    for index in range(code.length() - 2, -1, -1):
        sum += (code.unicode_at(index) - 48) * weight
        weight = 1 if weight == 3 else 3
    var check_digit = (10 - (sum % 10)) % 10
    if check_digit != code.unicode_at(code.length() - 1) - 48:
        return ""
    return code

static func nutrition_warning(product: Dictionary) -> String:
    var kcal = float(product.get("kcal", -1.0))
    var p = float(product.get("p", -1.0))
    var f = float(product.get("f", -1.0))
    var c = float(product.get("c", -1.0))
    if kcal < 0.0 or p < 0.0 or f < 0.0 or c < 0.0:
        return "Указаны неполные сведения о пищевой ценности."
    if kcal == 0.0 and (p > 1.0 or f > 1.0 or c > 1.0):
        return "Нулевая калорийность противоречит указанным БЖУ."
    # Approximation only: fibre, polyols, organic acids and labelling rules
    # can legitimately make this differ from the conventional 4-9-4 formula.
    var approximation = p * 4.0 + f * 9.0 + c * 4.0
    if absf(kcal - approximation) > maxf(90.0, kcal * 0.5):
        return "Калории и БЖУ заметно различаются. Проверь этикетку (возможны полиолы)."
    return ""

# Display remote product photos only from the OFF image CDN. Never let
# arbitrary response URLs make network requests from the app.
static func safe_image_url(raw: String) -> String:
    var url = raw.strip_edges()
    if url.length() > 512 or not url.begins_with(
            "https://images.openfoodfacts.org/images/products/"):
        return ""
    var pattern = RegEx.new()
    pattern.compile("^https://images[.]openfoodfacts[.]org/images/products/[A-Za-z0-9_./-]+[.](jpg|jpeg|png)$")
    return url if pattern.search(url) != null else ""


static func image_url_for(product: Dictionary) -> String:
    for key in ["image_front_small_url", "image_front_url"]:
        var safe = safe_image_url(str(product.get(key, "")))
        if not safe.is_empty():
            return safe
    return ""


static func needs_nutrition_review(product: Dictionary) -> bool:
    return not product.get("missing_fields", []).is_empty() or \
        not nutrition_warning(product).is_empty() or \
        str(product.get("unit_certainty", "unknown")) in ["serving", "unknown"]


static func nutrition_review_label(product: Dictionary) -> String:
    var missing: Array = product.get("missing_fields", [])
    if not missing.is_empty():
        var text_names: Array = []
        for field in missing:
            match str(field):
                "kcal": text_names.append("калории")
                "p": text_names.append("белки")
                "f": text_names.append("жиры")
                "c": text_names.append("углеводы")
        return "КБЖУ неполные: " + ", ".join(text_names) + ". Введи значения с упаковки."
    var warning = nutrition_warning(product)
    if not warning.is_empty():
        return "Нужна проверка по этикетке: " + warning
    return "КБЖУ заполнены, но открытая база не гарантирует точность. Сверь с этикеткой."


static func product_url(code: String) -> String:
    if normalize_code(code).is_empty():
        return ""
    return OFF_BASE + code + ".json?fields=" + OFF_FIELDS

# OFF's *_100g numeric keys mean per 100 g OR 100 ml for drinks.
# nutrition_data_per ("100g"/"serving") is *not* reliable evidence of mass.
# Prefer explicitly recorded product package units. If absent, fall back to
# grams and require the person to confirm the label before saving.
static func detect_basis(product: Dictionary) -> Dictionary:
    var unit = str(product.get("product_quantity_unit", "")).strip_edges().to_lower()
    if unit in ["ml", "cl", "l", "мл", "л"]:
        return {"unit": "мл", "certainty": "package_unit"}
    if unit in ["g", "kg", "г", "кг"]:
        return {"unit": "г", "certainty": "package_unit"}
    var quantity = str(product.get("quantity", "")).strip_edges().to_lower()
    # Only match a complete unit after a numerical quantity. Do not search
    # generic words (e.g. "milk") for the character "l".
    var match_units = RegEx.new()
    match_units.compile("(?:^|\\s)(?:[0-9]+[.,]?[0-9]*)\\s*(ml|cl|l|мл|л|g|kg|г|кг)(?:$|\\s|[,;])")
    var found = match_units.search(quantity)
    if found != null:
        var match_unit = found.get_string(1)
        if match_unit in ["ml", "cl", "l", "мл", "л"]:
            return {"unit": "мл", "certainty": "quantity"}
        return {"unit": "г", "certainty": "quantity"}
    var serving = str(product.get("serving_size", "")).strip_edges().to_lower()
    var found_serving = match_units.search(serving)
    if found_serving != null:
        var serving_unit = found_serving.get_string(1)
        if serving_unit in ["ml", "cl", "l", "мл", "л"]:
            return {"unit": "мл", "certainty": "serving"}
        return {"unit": "г", "certainty": "serving"}
    return {"unit": "г", "certainty": "unknown"}


static func parse_product(payload: Variant, barcode: String) -> Dictionary:
    if not (payload is Dictionary):
        return {"error": "Сервис прислал некорректный ответ."}
    if int(payload.get("status", 0)) != 1:
        return {"error": "Товар с таким штрихкодом пока не найден в Open Food Facts."}
    var product = payload.get("product", {})
    if not (product is Dictionary):
        return {"error": "Карточка товара повреждена."}
    var nutrition = product.get("nutriments", {})
    if not (nutrition is Dictionary):
        nutrition = {}
    var name = str(product.get("product_name_ru", "")).strip_edges()
    if name.is_empty():
        name = str(product.get("product_name", "")).strip_edges()
    if name.is_empty():
        return {"error": "У товара нет названия. Добавь его вручную в настройках."}
    var missing: Array = []
    var energy = nutrition.get("energy-kcal_100g", null)
    if not _valid_number(energy):
        var kj_value = nutrition.get("energy-kj_100g", null)
        if _valid_number(kj_value):
            energy = float(kj_value) / 4.184
        else:
            energy = -1.0
            missing.append("kcal")
    var macros: Dictionary = {}
    for field in [["p", "proteins_100g"], ["f", "fat_100g"],
            ["c", "carbohydrates_100g"]]:
        var abbreviation: String = str(field[0])
        var nutrient = nutrition.get(str(field[1]), null)
        if not _valid_number(nutrient):
            macros[abbreviation] = -1.0
            missing.append(abbreviation)
        else:
            macros[abbreviation] = float(nutrient)
    var kcal: float = float(energy)
    if kcal > 1000.0 or float(macros["p"]) > 100.0 or \
            float(macros["f"]) > 100.0 or float(macros["c"]) > 100.0:
        return {"error": "В базе указаны сомнительные значения. Проверь упаковку."}
    var brand = str(product.get("brands", "")).strip_edges().substr(0, 80)
    if not brand.is_empty() and not name.to_lower().contains(brand.to_lower()):
        name += " (" + brand.substr(0, 60) + ")"
    var basis: Dictionary = detect_basis(product)
    var record = {
        "barcode": barcode, "name": name.substr(0, 160),
        "brand": brand, "quantity": str(product.get("quantity", "")).strip_edges().substr(0, 80),
        "kcal": snappedf(kcal, 0.1) if kcal >= 0 else -1.0,
        "p": snappedf(float(macros["p"]), 0.1) if float(macros["p"]) >= 0 else -1.0,
        "f": snappedf(float(macros["f"]), 0.1) if float(macros["f"]) >= 0 else -1.0,
        "c": snappedf(float(macros["c"]), 0.1) if float(macros["c"]) >= 0 else -1.0,
        "missing_fields": missing, "nutrition_complete": missing.is_empty(),
        "source": "Open Food Facts", "image_url": image_url_for(product),
        "nutrition_unit": str(basis["unit"]), "unit_certainty": str(basis["certainty"])
    }
    return record


static func _valid_number(value: Variant) -> bool:
    if not (value is int or value is float):
        return false
    return is_finite(float(value)) and float(value) >= 0.0
