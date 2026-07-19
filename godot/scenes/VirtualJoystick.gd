extends Control
## Slice 2.6 -- on-screen virtual joystick for touch input, the real target
## platform. Also handles mouse drag so it's testable from the editor on
## desktop without a touchscreen. Player.gd reads `output` (a normalized
## Vector2, zero when not being dragged) and falls back to arrow keys when
## this returns zero, so desktop testing works either way.

@export var radius: float = 60.0
@export var knob_radius: float = 24.0
@export var dead_zone: float = 0.15

var output := Vector2.ZERO

var _dragging := false
var _knob_position := Vector2.ZERO


func _ready() -> void:
	add_to_group("virtual_joystick")
	_knob_position = size / 2.0


func _draw() -> void:
	var center := size / 2.0
	draw_circle(center, radius, Color(1, 1, 1, 0.15))
	draw_circle(_knob_position, knob_radius, Color(1, 1, 1, 0.35))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_dragging = true
			_update_knob(event.position)
		else:
			_dragging = false
			_reset_knob()
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _dragging:
			_update_knob(event.position)


func _update_knob(pos: Vector2) -> void:
	var center := size / 2.0
	var delta_vec := pos - center
	var clamped := delta_vec.limit_length(radius)
	_knob_position = center + clamped

	var raw := clamped / radius
	output = raw if raw.length() > dead_zone else Vector2.ZERO
	queue_redraw()


func _reset_knob() -> void:
	_knob_position = size / 2.0
	output = Vector2.ZERO
	queue_redraw()
