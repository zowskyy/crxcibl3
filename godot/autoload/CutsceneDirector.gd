extends Node
## CutsceneDirector — Autoload singleton.
##
## Two APIs:
##   1. PatternBuilder steps via start(steps) — ported from nezvers/Godot_cutscene_system.
##   2. Declarative JSON beats via play(scene_id, beats) — animation starter (Slices 3.18+).
##
## Beat playback drives DialogueBox captions with SpeakCapable lip flap (no voiceover).
## Line beats finish when the JSON `duration` elapses or the player skips.

signal cutscene_started
signal cutscene_ended
signal line_shown(speaker: String, text: String)
signal narrator_shown(text: String)
signal choice_shown(prompt: String, choices: Array)
signal beat_cleared

var _steps: Array = []
var _index: int = -1
var busy: bool = false

# Beat playback state
var _scene_id: String = ""
var _beats: Array = []
var _beat_index: int = -1
var _beat_mode: bool = false
var _context: Dictionary = {}
var _pending_choice: String = ""
var _choice_waiting: bool = false
var _skip_beat: bool = false
var _audio: AudioStreamPlayer


func _ready() -> void:
	_audio = AudioStreamPlayer.new()
	_audio.name = "CutsceneAudio"
	add_child(_audio)


func set_context(ctx: Dictionary) -> void:
	_context = ctx


func clear_context() -> void:
	_context.clear()


# ------------------------------------------------------------------ PatternBuilder API

func start(steps: Array) -> void:
	if steps.is_empty():
		return
	_beat_mode = false
	_steps = steps.duplicate()
	_index = -1
	busy = true
	cutscene_started.emit()
	_next()


func queue_steps(steps: Array) -> void:
	if not busy:
		start(steps)
	else:
		_steps.append_array(steps)


func stop() -> void:
	_steps.clear()
	_beats.clear()
	_index = -1
	_beat_index = -1
	_beat_mode = false
	busy = false
	_choice_waiting = false
	_skip_beat = false
	if _audio.playing:
		_audio.stop()


# ------------------------------------------------------------------ Beat API

func play(scene_id: String, beats: Array) -> void:
	if beats.is_empty():
		return
	stop()
	_beat_mode = true
	_scene_id = scene_id
	_beats = beats.duplicate()
	_beat_index = -1
	busy = true
	cutscene_started.emit()
	_next_beat()


func submit_choice(choice_id: String) -> void:
	if not _choice_waiting:
		return
	_pending_choice = choice_id
	_choice_waiting = false


func request_skip_beat() -> void:
	if _beat_mode and busy:
		_skip_beat = true
		if _audio.playing:
			_audio.stop()


func _next() -> void:
	_index += 1
	if _index >= _steps.size():
		_steps.clear()
		_index = -1
		busy = false
		cutscene_ended.emit("")
		return
	var step: Dictionary = _steps[_index]
	call(step["method"], step["args"])


func _next_beat() -> void:
	if not _beat_mode:
		return
	_beat_index += 1
	_skip_beat = false
	if _beat_index >= _beats.size():
		_finish_beats()
		return
	var beat: Dictionary = _beats[_beat_index]
	if typeof(beat) != TYPE_DICTIONARY or not beat.has("type"):
		_next_beat()
		return
	await _run_beat(beat)
	beat_cleared.emit()
	_next_beat()


func _finish_beats() -> void:
	var sid := _scene_id
	_beats.clear()
	_beat_index = -1
	_beat_mode = false
	busy = false
	_scene_id = ""
	cutscene_ended.emit(sid)


func _run_beat(beat: Dictionary) -> void:
	match String(beat.get("type", "")):
		"wait":
			await _beat_wait(float(beat.get("duration", 0.5)))
		"line":
			await _beat_line(beat, false)
		"narrator":
			await _beat_line(beat, true)
		"gesture":
			_beat_gesture(beat)
		"play_anim":
			_beat_play_anim(beat)
		"choice":
			await _beat_choice(beat)
		"branch":
			await _beat_branch(beat)
		"fade":
			await _beat_fade(beat, false)
		"fade_shader":
			await _beat_fade(beat, true)
		"move":
			await _beat_move(beat)
		"sfx":
			_beat_sfx(beat)
		"call":
			_beat_call(beat)
		"emit":
			_beat_emit(beat)
		"scene":
			_beat_scene(beat)
		"stop":
			stop()
		_:
			push_warning("CutsceneDirector: unknown beat type %s" % beat.get("type"))


func _beat_wait(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and not _skip_beat:
		elapsed += get_process_delta_time()
		await get_tree().process_frame


func _beat_line(beat: Dictionary, narrator: bool) -> void:
	var text: String = str(beat.get("text", ""))
	var duration: float = float(beat.get("duration", 3.0))
	var target_key: String = str(beat.get("target", ""))
	if narrator:
		narrator_shown.emit(text)
	else:
		line_shown.emit(str(beat.get("speaker", "")), text)
	var target_node := _resolve_target(target_key)
	if beat.has("gesture"):
		SpeakCapable.play_gesture(target_node, str(beat.get("gesture")))
	elif target_key != "":
		SpeakCapable.play_gesture(target_node, "talk")
	SpeakCapable.start_speaking(target_node)
	var elapsed := 0.0
	while elapsed < duration and not _skip_beat:
		elapsed += get_process_delta_time()
		await get_tree().process_frame
	SpeakCapable.stop_speaking(target_node)


func _beat_gesture(beat: Dictionary) -> void:
	var node := _resolve_target(str(beat.get("target", "")))
	if node and node.has_method("play_gesture"):
		node.call("play_gesture", str(beat.get("name", "")))


func _beat_play_anim(beat: Dictionary) -> void:
	var node := _resolve_target(str(beat.get("target", "")))
	if node and node.has_method("play_anim"):
		node.call("play_anim", str(beat.get("anim", "")))


func _beat_choice(beat: Dictionary) -> void:
	var choices: Array = beat.get("choices", [])
	var prompt: String = str(beat.get("prompt", "What now?"))
	choice_shown.emit(prompt, choices)
	_pending_choice = ""
	_choice_waiting = true
	while _choice_waiting and not _skip_beat:
		await get_tree().process_frame


func _beat_branch(beat: Dictionary) -> void:
	var choice_id := _pending_choice
	var map: Dictionary = beat.get("map", {})
	if not map.has(choice_id):
		push_warning("CutsceneDirector: branch missing key %s" % choice_id)
		return
	var sub: Array = map[choice_id]
	if typeof(sub) != TYPE_ARRAY:
		return
	for sub_beat in sub:
		if typeof(sub_beat) != TYPE_DICTIONARY:
			continue
		await _run_beat(sub_beat)
		beat_cleared.emit()


func _beat_fade(beat: Dictionary, use_shader: bool) -> void:
	var node := _resolve_target(str(beat.get("target", "")))
	if node == null:
		return
	var from_v: float = float(beat.get("from", 1.0))
	var to_v: float = float(beat.get("to", 0.0))
	var dur: float = float(beat.get("duration", 1.0))
	if use_shader and node.has_method("play_dissolve"):
		await node.call("play_dissolve", from_v, to_v, dur)
	else:
		var tween := create_tween()
		tween.tween_property(node, "modulate:a", to_v, dur).from(from_v)
		await tween.finished


func _beat_move(beat: Dictionary) -> void:
	var node := _resolve_target(str(beat.get("target", "")))
	if node == null or not (node is Node2D):
		return
	var dest: Vector2 = beat.get("to", Vector2.ZERO)
	var dur: float = float(beat.get("duration", 0.5))
	var tween := create_tween()
	tween.tween_property(node, "position", dest, dur)
	await tween.finished


func _beat_sfx(beat: Dictionary) -> void:
	var path: String = str(beat.get("stream", ""))
	if path != "" and ResourceLoader.exists(path):
		var stream := load(path)
		if stream is AudioStream:
			_audio.stream = stream
			_audio.play()


func _beat_call(beat: Dictionary) -> void:
	var target_path: String = str(beat.get("target", ""))
	var method: String = str(beat.get("method", ""))
	var args: Array = beat.get("args", [])
	var obj: Object = null
	if target_path.begins_with("/root/"):
		var parts := target_path.trim_prefix("/root/").split("/")
		if parts.size() >= 1:
			obj = get_node_or_null("/root/" + parts[0])
	else:
		obj = _resolve_target(target_path)
	if obj and method != "" and obj.has_method(method):
		obj.callv(method, args)


func _beat_emit(beat: Dictionary) -> void:
	var sig: String = str(beat.get("signal_name", ""))
	var args: Array = beat.get("args", [])
	if has_signal(sig):
		Callable(self, sig).callv(args)


func _beat_scene(beat: Dictionary) -> void:
	var path: String = str(beat.get("path", ""))
	if path == "":
		return
	var sid := _scene_id
	_beats.clear()
	_beat_index = _beats.size()
	_beat_mode = false
	busy = false
	_scene_id = ""
	cutscene_ended.emit(sid)
	get_tree().change_scene_to_file(path)


func _resolve_target(key: String) -> Node:
	if key == "":
		return null
	if _context.has(key):
		var n: Variant = _context[key]
		if n is Node:
			return n
	if key.contains("/"):
		return get_tree().current_scene.get_node_or_null(key)
	var scene := get_tree().current_scene
	if scene:
		var found := scene.find_child(key, true, false)
		if found:
			return found
	return null


# --- PatternBuilder step implementations (unchanged API) ---

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
	_next()


func call_method(args: Array) -> void:
	args[0].callv(args[1], args[2])
	_next()


func multi_call_method(calls: Array) -> void:
	for c in calls:
		c[0].callv(c[1], c[2])
	_next()


func interpolate_value(args: Array) -> void:
	var obj = args[0]
	var prop: String = args[1]
	var to_val = args[3]
	var dur: float = args[4]
	var trans: int = args[5] if args.size() > 5 else Tween.TRANS_LINEAR
	var ease_t: int = args[6] if args.size() > 6 else Tween.EASE_IN_OUT
	var delay: float = args[7] if args.size() > 7 else 0.0
	var tween := create_tween()
	tween.tween_property(obj, prop, to_val, dur) \
		.from(args[2]) \
		.set_trans(trans) \
		.set_ease(ease_t) \
		.set_delay(delay)
	await tween.finished
	_next()


func multi_interpolate_value(args: Array) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for a in args:
		var trans: int = a[5] if a.size() > 5 else Tween.TRANS_LINEAR
		var ease_t: int = a[6] if a.size() > 6 else Tween.EASE_IN_OUT
		var delay: float = a[7] if a.size() > 7 else 0.0
		tween.tween_property(a[0], a[1], a[3], a[4]) \
			.from(a[2]) \
			.set_trans(trans) \
			.set_ease(ease_t) \
			.set_delay(delay)
	await tween.finished
	_next()


func move(args: Array) -> void:
	var relative: bool = args[0]
	var use_global: bool = args[1]
	var obj: Node2D = args[2]
	var target: Vector2 = args[3]
	var dur: float = args[4]
	var prop := "global_position" if use_global else "position"
	var start: Vector2 = obj.global_position if use_global else obj.position
	var dest: Vector2 = start + target if relative else target
	var tween := create_tween()
	tween.tween_property(obj, prop, dest, dur)
	await tween.finished
	_next()


func multi_move(args: Array) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for a in args:
		var relative: bool = a[0]
		var use_global: bool = a[1]
		var obj: Node2D = a[2]
		var target: Vector2 = a[3]
		var dur: float = a[4]
		var prop := "global_position" if use_global else "position"
		var start: Vector2 = obj.global_position if use_global else obj.position
		var dest: Vector2 = start + target if relative else target
		tween.tween_property(obj, prop, dest, dur)
	await tween.finished
	_next()
