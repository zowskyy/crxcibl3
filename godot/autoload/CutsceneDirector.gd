extends Node
## CutsceneDirector — Autoload singleton.
## Ported from nezvers/Godot_cutscene_system (Godot 3 → Godot 4).
##
## Executes a sequence of named steps in order. Each step calls its own
## method on this node; timed/tweened steps are coroutines that resume
## _next() when they finish. Callers build sequences with PatternBuilder
## and hand the finished Array to start() or queue_steps().
##
## Key Godot 4 differences from the original:
##   - No persistent Tween node: each interpolation step creates a fresh
##     one-shot Tween via create_tween().
##   - No Timer node: wait() uses create_timer() directly.
##   - Method calls use callv() which is stable in Godot 4.

signal cutscene_started
signal cutscene_ended

var _steps: Array = []
var _index: int = -1
var busy: bool = false


func start(steps: Array) -> void:
	if steps.is_empty():
		return
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
	_index = -1
	busy = false


func _next() -> void:
	_index += 1
	if _index >= _steps.size():
		_steps.clear()
		_index = -1
		busy = false
		cutscene_ended.emit()
		return
	var step: Dictionary = _steps[_index]
	call(step["method"], step["args"])


# --- Step implementations ---

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
	_next()


func call_method(args: Array) -> void:
	# args: [object, method_name, params_array]
	args[0].callv(args[1], args[2])
	_next()


func multi_call_method(calls: Array) -> void:
	for c in calls:
		c[0].callv(c[1], c[2])
	_next()


## Tween one property on one object.
## args: [obj, property_string, from_val, to_val, duration,
##        trans_type, ease_type, delay]
## trans_type/ease_type default to TRANS_LINEAR/EASE_IN_OUT if omitted.
func interpolate_value(args: Array) -> void:
	var obj       = args[0]
	var prop: String = args[1]
	var from_val  = args[2]
	var to_val    = args[3]
	var dur: float = args[4]
	var trans: int = args[5] if args.size() > 5 else Tween.TRANS_LINEAR
	var ease_t: int = args[6] if args.size() > 6 else Tween.EASE_IN_OUT
	var delay: float = args[7] if args.size() > 7 else 0.0

	var tween := create_tween()
	tween.tween_property(obj, prop, to_val, dur) \
		.from(from_val) \
		.set_trans(trans) \
		.set_ease(ease_t) \
		.set_delay(delay)
	await tween.finished
	_next()


## Tween multiple properties simultaneously, then advance.
## args: Array of sub-arrays in the same format as interpolate_value.
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


## Move one object to a target position.
## args: [relative, use_global, object, target_pos, duration]
func move(args: Array) -> void:
	var relative: bool   = args[0]
	var use_global: bool = args[1]
	var obj: Node2D      = args[2]
	var target: Vector2  = args[3]
	var dur: float       = args[4]

	var prop := "global_position" if use_global else "position"
	var start: Vector2 = obj.global_position if use_global else obj.position
	var dest: Vector2 = start + target if relative else target

	var tween := create_tween()
	tween.tween_property(obj, prop, dest, dur)
	await tween.finished
	_next()


## Move multiple objects simultaneously.
## args: Array of sub-arrays in the same format as move.
func multi_move(args: Array) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	for a in args:
		var relative: bool   = a[0]
		var use_global: bool = a[1]
		var obj: Node2D      = a[2]
		var target: Vector2  = a[3]
		var dur: float       = a[4]
		var prop := "global_position" if use_global else "position"
		var start: Vector2 = obj.global_position if use_global else obj.position
		var dest: Vector2 = start + target if relative else target
		tween.tween_property(obj, prop, dest, dur)
	await tween.finished
	_next()
