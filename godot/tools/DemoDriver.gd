extends Node
## Automated demo input — walks toward the enemy, fires, bumps heat once.

const STEP_SEC := 0.1
const WALK_FRAMES := 25
const FIRE_COUNT := 8


func _ready() -> void:
	call_deferred("_run_demo")


func _run_demo() -> void:
	await get_tree().create_timer(0.8).timeout
	print("Demo: walking toward enemy...")
	for _i in range(WALK_FRAMES):
		_press_key(KEY_RIGHT)
		_press_key(KEY_DOWN)
		await get_tree().create_timer(STEP_SEC).timeout
		_release_key(KEY_RIGHT)
		_release_key(KEY_DOWN)

	print("Demo: firing...")
	for _i in range(FIRE_COUNT):
		_press_key(KEY_SPACE)
		await get_tree().create_timer(0.05).timeout
		_release_key(KEY_SPACE)
		await get_tree().create_timer(0.3).timeout

	print("Demo: adding heat (H key)...")
	_press_key(KEY_H)
	await get_tree().create_timer(0.05).timeout
	_release_key(KEY_H)

	await get_tree().create_timer(2.0).timeout
	print("Demo: complete — quitting.")
	get_tree().quit()


func _press_key(keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	ev.echo = false
	Input.parse_input_event(ev)


func _release_key(keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = false
	ev.echo = false
	Input.parse_input_event(ev)
