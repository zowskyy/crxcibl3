class_name PatternBuilder
## Builder for CutsceneDirector step sequences.
## Ported from nezvers/Godot_cutscene_system (Godot 3 → Godot 4).
##
## Chain add_* calls, then pass build() to CutsceneDirector.start():
##
##   var pb := PatternBuilder.new()
##   pb.add_wait(1.0) \
##     .add_call_method(label, "set_visible", [false]) \
##     .add_move(false, true, hero, Vector2(300, 160), 0.8)
##   CutsceneDirector.start(pb.build())
##
## class_name makes this available everywhere without a separate autoload.

var _steps: Array = []


func clear() -> PatternBuilder:
	_steps.clear()
	return self


func build() -> Array:
	return _steps.duplicate()


# ------------------------------------------------------------------ step adders

func add_wait(duration: float) -> PatternBuilder:
	_steps.append({"method": "wait", "args": duration})
	return self


func add_call_method(obj: Object, method: String, params: Array) -> PatternBuilder:
	_steps.append({"method": "call_method", "args": [obj, method, params]})
	return self


func add_multi_call_method(calls: Array) -> PatternBuilder:
	_steps.append({"method": "multi_call_method", "args": calls})
	return self


## Convenience shorthand for setting a property via obj.set(property, value).
func add_set_value(obj: Object, property: String, value) -> PatternBuilder:
	return add_call_method(obj, "set", [property, value])


## Tween one property from → to over duration seconds.
func add_interpolate_value(
		obj: Object, property: String, from_val, to_val,
		duration: float,
		trans := Tween.TRANS_LINEAR,
		ease_type := Tween.EASE_IN_OUT,
		delay := 0.0) -> PatternBuilder:
	_steps.append({"method": "interpolate_value",
		"args": [obj, property, from_val, to_val, duration, trans, ease_type, delay]})
	return self


## Tween multiple properties simultaneously (all finish before advancing).
## Each entry is an Array in the same format as add_interpolate_value's args.
func add_multi_interpolate_value(entries: Array) -> PatternBuilder:
	_steps.append({"method": "multi_interpolate_value", "args": entries})
	return self


## Move an object to target_pos over duration seconds.
## relative=true adds target_pos to the current position instead of treating
## it as an absolute world coordinate. use_global=true uses global_position.
func add_move(relative: bool, use_global: bool, obj: Node2D,
		target_pos: Vector2, duration: float) -> PatternBuilder:
	_steps.append({"method": "move",
		"args": [relative, use_global, obj, target_pos, duration]})
	return self


## Move multiple objects simultaneously.
## Each entry is an Array in the same format as add_move's positional args.
func add_multi_move(entries: Array) -> PatternBuilder:
	_steps.append({"method": "multi_move", "args": entries})
	return self


## No-op chain terminator, same as the original. Makes long chains read
## cleanly without a dangling \ on the last line:
##   pb.add_wait(1.0).done()
func done() -> void:
	pass


# ----------------------------------------------------------------- helper builders
## Returns a single-method call entry for use with add_multi_call_method.
static func single_method(obj: Object, method: String, params: Array) -> Array:
	return [obj, method, params]


## Returns a single interpolate entry for use with add_multi_interpolate_value.
static func single_interpolate(
		obj: Object, property: String, from_val, to_val,
		duration: float,
		trans := Tween.TRANS_LINEAR,
		ease_type := Tween.EASE_IN_OUT,
		delay := 0.0) -> Array:
	return [obj, property, from_val, to_val, duration, trans, ease_type, delay]


## Returns a single move entry for use with add_multi_move.
static func single_move(relative: bool, use_global: bool, obj: Node2D,
		target_pos: Vector2, duration: float) -> Array:
	return [relative, use_global, obj, target_pos, duration]
