extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _fail(s: String) -> void:
    push_error("FAILED GOOGLE CLOUD BACKUP 0.7.52: " + s)
    quit(1)

func _run() -> void:
    var app = load("res://main.tscn").instantiate()
    root.add_child(app)
    await process_frame
    app.store.data = app.store.default_data()
    app.store.data["settings"]["onboarding_complete"] = true
    app.store.data["notes"]["2026-11-24"] = "До подключения Google"
    app.store.data["weights"] = [{"date": "2026-11-24", "value": 86.0}]
    var original: String = JSON.stringify(app.store.data)
    app.tab = "settings"
    app.settings_page = "main"
    app.settings_section_open = "google"
    app._render()
    await process_frame
    if app.APP_VERSION != "0.7.61" or app.find_child("SettingsSection_google", true, false) == null:
        _fail("cloud settings missing")
        return
    if app.google_plugin != null:
        _fail("Android-only cloud plugin unexpectedly exposed on desktop")
        return
    if app.find_child("GoogleCloudUnavailable", true, false) == null or \
            app.find_child("GoogleCloudUpload", true, false) != null:
        _fail("cloud actions must not be accessible without native plugin")
        return
    app._on_google_status(true, "2026-11-24T16:00:00", "md5-expected", "drive-file-42")
    if not app.google_checked or app.google_file_id != "drive-file-42" or \
            app.google_checksum != "md5-expected":
        _fail("remote file id/checksum not stored together")
        return
    app._on_google_error("Облачная копия изменилась на другом устройстве.")
    if app.google_checked:
        _fail("conflict did not invalidate the remote revision")
        return
    app._on_google_disconnected()
    if app.google_checked or not app.google_file_id.is_empty() or \
            not app.google_checksum.is_empty():
        _fail("disconnect left stale remote revision")
        return
    app._google_connect()
    await process_frame
    if JSON.stringify(app.store.data) != original:
        _fail("missing plugin modified local diary")
        return
    app._google_upload()
    app._google_download()
    app._google_delete()
    if JSON.stringify(app.store.data) != original:
        _fail("unavailable cloud operations modified local diary")
        return
    var raw: String = app.store.export_json()
    if not (JSON.parse_string(raw) is Dictionary) or \
            not raw.contains("До подключения Google"):
        _fail("local JSON export broken during sync integration")
        return
    if app.tab_buttons.size() != 5:
        _fail("Google setting added a new primary tab")
        return
    app.queue_free()
    print("PASS GOOGLE BACKUP 0.7.52: no cloud operations without Android, local data unchanged, existing JSON and tabs intact")
    quit(0)
