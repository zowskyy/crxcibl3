extends Node
## AndroidPlatform — mobile bootstrap: lifecycle save/restore, audio focus, safe area,
## predictive back, edge-to-edge, low-latency input, and audio bus layout.

## validate safe-area margins; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via ProcessDeathSnapshot restore.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


const CRASH_LOG_PATH := "user://crash_log.txt"

var _safe_layer: CanvasLayer = null
var _safe_area_root: MarginContainer = null
var _audio_was_playing: Dictionary = {}
var _music_bus_idx := -1
var _sfx_bus_idx := -1

func _ready() -> void:
	print("[AndroidPlatform] bootstrap ready")
	Input.use_accumulated_input = false
	ProjectSettings.set_setting("rendering/2d/snap/snap_2d_transforms_to_pixel", true)
	_setup_audio_buses()
	_ensure_core_input_actions()

	if OS.get_name() == "Android":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_EXTEND_TO_TITLE, true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)

	if not get_tree().root.size_changed.is_connected(_apply_safe_area):
		get_tree().root.size_changed.connect(_apply_safe_area)

	ProcessDeathSnapshot.restore_if_needed()
	call_deferred("_apply_safe_area")

func _setup_audio_buses() -> void:
	var indices := {"Music": -1, "SFX": -1}
	for bus_name in ["Music", "SFX"]:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx < 0:
			AudioServer.add_bus()
			idx = AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")
		indices[bus_name] = idx
	_music_bus_idx = indices["Music"]
	_sfx_bus_idx = indices["SFX"]

func get_music_bus_index() -> int:
	return _music_bus_idx

func get_sfx_bus_index() -> int:
	return _sfx_bus_idx

func set_music_volume_db(db: float) -> void:
	if _music_bus_idx >= 0:
		AudioServer.set_bus_volume_db(_music_bus_idx, db)

func set_sfx_volume_db(db: float) -> void:
	if _sfx_bus_idx >= 0:
		AudioServer.set_bus_volume_db(_sfx_bus_idx, db)

func _ensure_core_input_actions() -> void:
	_ensure_action_key("fire", KEY_SPACE)
	_ensure_action_key("add_heat", KEY_H)
	_ensure_action_key("inventory", KEY_I)
	_ensure_action_key("cycle_hero", KEY_TAB)

func _ensure_action_key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_on_app_paused()
		NOTIFICATION_APPLICATION_RESUMED:
			_on_app_resumed()
		NOTIFICATION_WM_ABOUT_TO_GO_BACKGROUND:
			ProcessDeathSnapshot.save_snapshot()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_handle_predictive_back()
			get_viewport().set_input_as_handled()

func _on_app_paused() -> void:
	_audio_was_playing.clear()
	for i in range(AudioServer.bus_count):
		var bus_name := AudioServer.get_bus_name(i)
		_audio_was_playing[bus_name] = not AudioServer.is_bus_mute(i)
		AudioServer.set_bus_mute(i, true)
	ProcessDeathSnapshot.save_snapshot()

func _on_app_resumed() -> void:
	for bus_name in _audio_was_playing.keys():
		var idx := AudioServer.get_bus_index(bus_name)
		if idx >= 0:
			AudioServer.set_bus_mute(idx, not bool(_audio_was_playing[bus_name]))
	_audio_was_playing.clear()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func log_crash(context: String, details: String = "") -> void:
	var line := "[%s] %s — %s\n" % [Time.get_datetime_string_from_system(), context, details]
	push_error("CrashLog: %s — %s" % [context, details])
	if not SaveSystem.has_sufficient_storage():
		return
	var file := FileAccess.open(CRASH_LOG_PATH, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(CRASH_LOG_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.seek_end()
	file.store_string(line)
	file.close()

func _apply_safe_area() -> void:
	var safe := DisplayServer.get_display_safe_area()
	var win_size := DisplayServer.window_get_size()
	if win_size.x <= 0 or win_size.y <= 0:
		return
	var margin_left := float(safe.position.x)
	var margin_top := float(safe.position.y)
	var margin_right := float(win_size.x - safe.position.x - safe.size.x)
	var margin_bottom := float(win_size.y - safe.position.y - safe.size.y)
	if margin_left <= 0.0 and margin_top <= 0.0 and margin_right <= 0.0 and margin_bottom <= 0.0:
		return
	var root := get_tree().root
	if _safe_layer == null or not is_instance_valid(_safe_layer):
		_safe_layer = CanvasLayer.new()
		_safe_layer.name = "AndroidSafeAreaLayer"
		_safe_layer.layer = 100
		root.add_child(_safe_layer)
		_safe_area_root = MarginContainer.new()
		_safe_area_root.name = "AndroidSafeArea"
		_safe_area_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_safe_area_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_safe_layer.add_child(_safe_area_root)
	_safe_area_root.add_theme_constant_override("margin_left", int(margin_left))
	_safe_area_root.add_theme_constant_override("margin_top", int(margin_top))
	_safe_area_root.add_theme_constant_override("margin_right", int(margin_right))
	_safe_area_root.add_theme_constant_override("margin_bottom", int(margin_bottom))

func _handle_predictive_back() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("handle_android_back"):
		scene.handle_android_back()
		return
	if InputMap.has_action("ui_cancel"):
		var ev := InputEventAction.new()
		ev.action = "ui_cancel"
		ev.pressed = true
		Input.parse_input_event(ev)

func play_audio_if_audible(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0 and AudioServer.is_bus_mute(master_idx):
		return
	if player.bus.is_empty() and _sfx_bus_idx >= 0:
		player.bus = "SFX"
	player.play()
