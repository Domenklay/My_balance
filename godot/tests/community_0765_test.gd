extends SceneTree
const Client = preload("res://src/community_client.gd")
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.community.endpoint = ""
    app.community.token = ""
    app.tab = "recipes"
    app._render()
    await process_frame
    var button = app.find_child("RecipesCommunity",true,false) as Button
    if button == null:
        quit(1)
        return
    button.pressed.emit()
    await process_frame
    if app.find_child("CommunityEndpoint",true,false) == null or Client.valid_endpoint("http://test.com") or Client.valid_endpoint("https://test.com@evil.com"):
        quit(1)
        return
    var data = Client.public_recipe({"name":"Soup","photo":"private","profile":"private","ingredients":[{"name":"Salt","grams":1,"kcal":0,"p":0,"f":0,"c":0,"secret":"private"}]})
    if data.has("photo") or data.has("profile") or data["ingredients"][0].has("secret"):
        quit(1)
        return
    print("PASS COMMUNITY UI: offline setup, HTTPS-only endpoint, sanitized payload")
    app.queue_free()
    quit(0)
