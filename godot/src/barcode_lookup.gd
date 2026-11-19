extends RefCounted

# Open Food Facts barcode response adapter. Values are per 100 g / 100 ml.
const OFF_BASE = "https://world.openfoodfacts.org/api/v2/product/"
const OFF_FIELDS = "code,product_name,product_name_ru,brands,nutriments,quantity,nutrition_data_per"

static func normalize_code(raw: String) -> String:
    var code = raw.strip_edges()
    if code.length() < 8 or code.length() > 14:
        return ""
    for i in range(code.length()):
        var ch = code.unicode_at(i)
        if ch < 48 or ch > 57:
            return ""
    return code

static func product_url(code: String) -> String:
    if normalize_code(code).is_empty():
        return ""
    return OFF_BASE + code + ".json?fields=" + OFF_FIELDS

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
        return {"error": "Для этого товара нет данных о пищевой ценности."}
    var name = str(product.get("product_name_ru", "")).strip_edges()
    if name.is_empty():
        name = str(product.get("product_name", "")).strip_edges()
    if name.is_empty():
        return {"error": "У товара нет названия. Добавь его вручную в настройках."}
    var kcal_value = nutrition.get("energy-kcal_100g", null)
    if not _valid_number(kcal_value):
        var kj_value = nutrition.get("energy-kj_100g", null)
        if _valid_number(kj_value):
            kcal_value = float(kj_value) / 4.184
        else:
            return {"error": "В базе нет калорий на 100 г. Проверь упаковку и добавь товар вручную."}
    for key in ["proteins_100g", "fat_100g", "carbohydrates_100g"]:
        if not _valid_number(nutrition.get(key, null)):
            return {"error": "У товара неполные данные БЖУ. Проверь упаковку и добавь вручную."}
    var kcal = float(kcal_value)
    var protein = float(nutrition["proteins_100g"])
    var fat = float(nutrition["fat_100g"])
    var carbs = float(nutrition["carbohydrates_100g"])
    if kcal < 0.0 or kcal > 1000.0 or protein > 100.0 or fat > 100.0 or carbs > 100.0:
        return {"error": "В базе указаны сомнительные значения. Проверь упаковку."}
    var brand = str(product.get("brands", "")).strip_edges()
    if not brand.is_empty() and not name.to_lower().contains(brand.to_lower()):
        name += " (" + brand.substr(0, 60) + ")"
    return {
        "barcode": barcode, "name": name.substr(0, 160),
        "kcal": snappedf(kcal, 0.1), "p": snappedf(protein, 0.1),
        "f": snappedf(fat, 0.1), "c": snappedf(carbs, 0.1),
        "source": "Open Food Facts", "quantity": str(product.get("quantity", "")),
    }

static func _valid_number(value: Variant) -> bool:
    if not (value is int or value is float):
        return false
    return is_finite(float(value)) and float(value) >= 0.0
