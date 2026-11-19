extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var StoreScript = load("res://src/store.gd")
    var first = StoreScript.new()
    first.data = first.default_data()
    first.data["notes"]["2026-11-19"] = "Первый тест сохранения"
    if not first.save():
        push_error("FAILED: first atomic save")
        quit(1)
        return
    var second = StoreScript.new()
    if str(second.data["notes"].get("2026-11-19", "")) != "Первый тест сохранения":
        push_error("FAILED: reload saved content")
        quit(1)
        return
    second.data["notes"]["2026-11-19"] = "Второй тест сохранения"
    if not second.save():
        push_error("FAILED: subsequent atomic save")
        quit(1)
        return
    if not FileAccess.file_exists("user://my_balance.previous.json"):
        push_error("FAILED: previous backup missing")
        quit(1)
        return
    var third = StoreScript.new()
    if str(third.data["notes"].get("2026-11-19", "")) != "Второй тест сохранения":
        push_error("FAILED: new save cannot be reloaded")
        quit(1)
        return
    if third.import_json('{"broken": true}'):
        push_error("FAILED: invalid JSON accepted")
        quit(1)
        return
    if not third.import_json(first.export_json()):
        push_error("FAILED: valid JSON restore")
        quit(1)
        return
    var restored = StoreScript.new()
    if str(restored.data["notes"].get("2026-11-19", "")) != "Первый тест сохранения":
        push_error("FAILED: restored journal not persisted")
        quit(1)
        return
    print("PASS: JSON save, reload, previous backup, import validation, and restore")
    quit(0)
