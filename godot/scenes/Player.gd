extends Node2D
## Placeholder player -- a drawn square standing in for real art, just
## enough to confirm movement works. Reads from the virtual joystick
## (touch or mouse drag) when present, falling back to arrow keys so
## desktop testing in the editor still works without dragging it.

const SPEED := 120.0
const SIZE := 16.0

var _joystick: Control = null


func _ready() -> void:
	# Deferred: Player is declared before CanvasLayer/VirtualJoystick in the
	# scene tree, so at _ready() time the joystick hasn't added itself to
	# the group yet (sibling _ready() order follows scene declaration
	# order). Deferring to the end of the frame runs this after the whole
	# tree has finished its _ready() pass.
	call_deferred("_find_joystick")


func _find_joystick() -> void:
	_joystick = get_tree().get_first_node_in_group("virtual_joystick")


func _process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	if _joystick and _joystick.output.length() > 0.0:
		input_vector = _joystick.output
	else:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	position += input_vector * SPEED * delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-SIZE / 2, -SIZE / 2, SIZE, SIZE), Color.CRIMSON)
