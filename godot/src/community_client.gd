extends Node
# Community credentials are device-local and excluded from diary/cloud backups.
const PATH = "user://community_account.json"
var endpoint: String = ""
var token: String = ""
var busy: bool = false

static func valid_endpoint(value: String) -> bool:
    var pattern = RegEx.new()
    pattern.compile("^https://[A-Za-z0-9.-]+(:[0-9]{1,5})?$")
    return pattern.search(value) != null

func load_config() -> void:
    if FileAccess.file_exists(PATH):
        var file = FileAccess.open(PATH, FileAccess.READ)
        if file != null:
            var data = JSON.parse_string(file.get_as_text())
            if data is Dictionary and valid_endpoint(str(data.get("endpoint",""))):
                endpoint = str(data["endpoint"])
                token = str(data.get("token",""))
    if endpoint.is_empty():
        var configured = str(ProjectSettings.get_setting("mybalance/community_url",""))
        if valid_endpoint(configured):
            endpoint = configured

func persist() -> bool:
    var file = FileAccess.open(PATH, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify({"endpoint":endpoint,"token":token}))
    file.close()
    return true

func configure(url: String) -> bool:
    if not valid_endpoint(url) or busy or (not token.is_empty() and endpoint != url):
        return false
    var previous = endpoint
    endpoint = url
    if not persist():
        endpoint = previous
        return false
    return true

func send(path: String, method: int, payload: Dictionary, callback: Callable) -> void:
    if busy or endpoint.is_empty():
        callback.call(false, {"error":"not_connected"})
        return
    busy = true
    var http = HTTPRequest.new()
    http.timeout = 18.0
    http.max_redirects = 0
    http.body_size_limit = 3000000
    add_child(http)
    var headers = PackedStringArray(["Content-Type: application/json","Accept: application/json"])
    if not token.is_empty():
        headers.append("Authorization: Bearer " + token)
    http.request_completed.connect(func(result: int, status: int, _headers: PackedStringArray, body: PackedByteArray):
        busy = false
        http.queue_free()
        var decoded = JSON.parse_string(body.get_string_from_utf8())
        var ok = result == HTTPRequest.RESULT_SUCCESS and status == 200 and decoded is Dictionary
        callback.call(ok, decoded if decoded is Dictionary else {"error":"network_error"})
    )
    var error = http.request(endpoint + path, headers, method, JSON.stringify(payload) if method == HTTPClient.METHOD_POST else "")
    if error != OK:
        busy = false
        http.queue_free()
        callback.call(false, {"error":"network_error"})

func ensure_account(callback: Callable) -> void:
    if not token.is_empty():
        callback.call(true, {})
        return
    send("/v1/accounts", HTTPClient.METHOD_POST, {}, func(ok: bool, result: Dictionary):
        if ok and str(result.get("token","")).length() == 64:
            token = str(result["token"])
            if persist():
                callback.call(true, {})
                return
            token = ""
        callback.call(false, result)
    )

static func public_recipe(recipe: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for key in ["name","category","instructions","cooked_weight","servings"]:
        if recipe.has(key):
            result[key] = recipe[key]
    var parts: Array = []
    for item in recipe.get("ingredients",[]):
        var part: Dictionary = {}
        for key in ["name","grams","unit","kcal","p","f","c"]:
            if item.has(key):
                part[key] = item[key]
        parts.append(part)
    result["ingredients"] = parts
    return result
