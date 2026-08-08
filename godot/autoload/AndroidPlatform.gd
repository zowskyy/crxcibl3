extends Node
## AndroidPlatform — mobile bootstrap: lifecycle save/restore, audio focus, safe area,
## predictive back, edge-to-edge, and low-latency input settings.

var _safe_layer: CanvasLayer = null
var _safe_area_root: MarginContainer = null
var _audio_was_playing: Dictionary = {}


func _ready() -> void:
	Input.use_accumulated_input = false
	ProjectSettings.set_setting("rendering/2d/snap/snap_2d_transforms_to_pixel", true)

	if OS.get_name() == "Android":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_EXTEND_TO_TITLE, true)

	if not get_tree().root.size_changed.is_connected(_apply_safe_area):
		get_tree().root.size_changed.connect(_apply_safe_area)

	if SaveSystem.has_method("restore_snapshot_if_needed"):
		SaveSystem.restore_snapshot_if_needed()

	call_deferred("_apply_safe_area")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			_on_app_paused()
		NOTIFICATION_APPLICATION_RESUMED:
			_on_app_resumed()
		NOTIFICATION_WM_ABOUT_TO_GO_BACKGROUND:
			if SaveSystem.has_method("save_snapshot"):
				SaveSystem.save_snapshot()
			else:
				SaveSystem.save_game()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_handle_predictive_back()
			get_viewport().set_input_as_handled()


func _on_app_paused() -> void:
	_audio_was_playing.clear()
	for i in range(AudioServer.bus_count):
		var bus_name := AudioServer.get_bus_name(i)
		_audio_was_playing[bus_name] = not AudioServer.is_bus_mute(i)
		AudioServer.set_bus_mute(i, true)
	if SaveSystem.has_method("save_snapshot"):
		SaveSystem.save_snapshot()
	else:
		SaveSystem.save_game()


func _on_app_resumed() -> void:
	for bus_name in _audio_was_playing.keys():
		var idx := AudioServer.get_bus_index(bus_name)
		if idx >= 0:
			AudioServer.set_bus_mute(idx, not bool(_audio_was_playing[bus_name]))
	_audio_was_playing.clear()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _apply_safe_area() -> void:
	if not is_inside_tree():
		return
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
	player.play()
