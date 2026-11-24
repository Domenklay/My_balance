extends SceneTree

const StoreScript = preload("res://src/store.gd")
const RewardScript = preload("res://src/rewards.gd")
const PhotoScript = preload("res://src/profile_photo.gd")
const FailingStore = preload("res://tests/failing_store.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(reason: String) -> void:
    push_error("FAILED REWARDS/AVATAR: " + reason)
    quit(1)

func _has_button(node: Node, phrase: String) -> Button:
    if node is Button and node.text.contains(phrase):
        return node
    for child in node.get_children():
        var got = _has_button(child, phrase)
        if got != null:
            return got
    return null

func _run() -> void:
    var today = Time.get_date_string_from_system()
    var store = StoreScript.new()
    store.data = store.default_data()
    var initial = RewardScript.calculate(store.data, today)
    if initial["points"] != 0 or initial["level"] != 1 or initial["days"] != 0 or initial["earned"] != 0:
        _fail("new diary has rewards before any actions")
        return
    if RewardScript.valid_date("2026-02-30") or RewardScript.valid_date("not-a-date"):
        _fail("invalid date accepted")
        return
    var egg = store.food_by_id("d16")
    if egg.is_empty():
        _fail("missing food fixture")
        return
    var days: Array = []
    var date_cursor = today
    for i in range(7):
        days.push_front(date_cursor)
        date_cursor = RewardScript.day_before(date_cursor)
    for day in days:
        if not store.add_food_entry(egg, 100, "Завтрак", day):
            _fail("cannot seed seven-day history")
            return
    var after_week = RewardScript.calculate(store.data, today)
    if int(after_week["points"]) != 70 or int(after_week["days"]) != 7 or \
            int(after_week["streak"]) != 7 or not bool(after_week["badges"]["streak"]) or \
            not bool(after_week["badges"]["week"]):
        _fail("seven unique days should earn 70 stars and week badge")
        return
    # Multiple products in the same meal cannot produce unlimited stars.
    if not store.add_food_entry(egg, 100, "Завтрак", today):
        _fail("cannot seed repeated product")
        return
    if int(store.reward_summary()["points"]) != 70:
        _fail("repeating the same meal created extra stars")
        return
    if not store.add_food_entry(egg, 100, "Обед", today):
        _fail("cannot seed second meal")
        return
    if int(store.reward_summary()["points"]) != 75:
        _fail("second distinct meal did not give exactly five more stars")
        return
    store.data["entries"].append({
        "id":"future_record", "date":"2199-01-01", "meal":"Завтрак", "grams":100.0
    })
    if int(store.reward_summary()["points"]) != 75:
        _fail("future diary item could be used to farm rewards")
        return
    store.data["entries"].pop_back()
    if not store.choose_avatar_frame("mint") or str(store.data["profile"]["frame"]) != "mint":
        _fail("unlocked mint frame unavailable")
        return
    if store.choose_avatar_frame("gold") or str(store.data["profile"]["frame"]) != "mint":
        _fail("locked gold frame could be selected")
        return

    var drawing = Image.create(400, 300, false, Image.FORMAT_RGB8)
    drawing.fill(Color("#314D77"))
    var raw = drawing.save_png_to_buffer()
    var encoded: String = PhotoScript.make_photo(raw)
    if encoded.is_empty() or not PhotoScript.valid_photo(encoded):
        _fail("PNG did not produce valid compressed avatar")
        return
    var avatar = PhotoScript.decode_photo(encoded)
    if avatar == null or avatar.get_width() != 256 or avatar.get_height() != 256:
        _fail("photo not cropped/resized to 256 square")
        return
    if PhotoScript.make_photo(PackedByteArray([1, 2, 3])) != "":
        _fail("garbage image accepted")
        return
    if not store.update_avatar_photo(encoded):
        _fail("photo not persisted in user profile")
        return
    var readback = StoreScript.new()
    if str(readback.data["profile"].get("photo", "")) != encoded:
        _fail("avatar photo lost after restart")
        return
    if not readback.update_profile({"name":"Новое имя", "avatar":"star", "motto":"Небольшие шаги"}):
        _fail("editing profile with photo failed")
        return
    if str(readback.data["profile"].get("photo", "")) != encoded or \
            str(readback.data["profile"].get("frame", "")) != "mint":
        _fail("editing name reset saved photo or frame")
        return
    var backup = readback.export_json()
    var restored = StoreScript.new()
    if not restored.import_json(backup) or str(restored.data["profile"].get("photo", "")) != encoded:
        _fail("avatar photo missing from JSON export/import")
        return
    var old_backup = JSON.parse_string(backup)
    old_backup["profile"].erase("photo")
    old_backup["profile"].erase("frame")
    if not restored.import_json(JSON.stringify(old_backup)) or \
            str(restored.data["profile"].get("photo", "-")) != "" or \
            str(restored.data["profile"].get("frame", "")) != "plain":
        _fail("legacy profile backup did not migrate")
        return
    if restored.update_avatar_photo("not a valid base64 jpeg") or \
            str(restored.data["profile"].get("photo", "-")) != "":
        _fail("bad photo data was accepted")
        return
    var fail = FailingStore.new()
    fail.data = fail.default_data()
    if fail.update_avatar_photo(encoded) or str(fail.data["profile"].get("photo", "")) != "":
        _fail("failed photo save was not rolled back")
        return

    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.tab = "profile"
    app._render()
    await process_frame
    if _has_button(app, "Моя анкета") == null or \
            _has_button(app, "Показать все достижения") == null:
        _fail("profile lacks avatar picker or reward badges")
        return
    if not app._apply_avatar_photo_bytes(raw):
        _fail("avatar photo selection callback failed")
        return
    await process_frame
    if app.find_child("ProfileAvatarPhoto", true, false) == null:
        _fail("profile photo is not rendered")
        return
    if not app.store.update_avatar_photo(""):
        _fail("cannot reset avatar to symbol")
        return
    app._render()
    await process_frame
    if app.find_child("ProfileAvatarPhoto", true, false) != null:
        _fail("deleted photo still rendered")
        return

    print("PASS REWARDS AVATAR: fair streaks, no duplicate points, milestones, frames, JPG photo persistence, JSON migration, UI and failures")
    app.queue_free()
    quit(0)
