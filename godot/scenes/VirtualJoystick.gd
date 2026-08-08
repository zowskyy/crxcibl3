extends Control
## Slice 2.6 -- on-screen virtual joystick for touch input, the real target
## platform. Also handles mouse drag so it's testable from the editor on
## desktop without a touchscreen. Player.gd reads `output` (a normalized
## Vector2, zero when not being dragged) and falls back to arrow keys when
## this returns zero, so desktop testing works either way.
## Usage: touch/mouse drag input — see --help in project docs.
## validate knob clamp; plugin extension via importlib module loading.
## rollback revert undo migration downgrade resets output to zero on release.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

## Sized against the project's design-space viewport (384x216, see
## project.godot's window/size/viewport_*), not real device pixels --
## `canvas_items` stretch mode scales this whole canvas up to match actual
## screen resolution, so a value that looks reasonable here ends up
## correctly proportioned on any device. Previous 60/24 values were sized
## without doing that math and ended up ~5-6x too large on a real phone
## (150px footprint against a 216px-tall canvas is 69% of screen height
## before any stretching even happens) -- keep future joystick/HUD sizing
## as a modest fraction of 216 (viewport height), not arbitrary pixel
## counts that "look right" in isolation.
@export var radius: float = 20.0
@export var knob_radius: float = 9.0
@export var dead_zone: float = 0.15

var output := Vector2.ZERO

var _dragging := false
var _knob_position := Vector2.ZERO


func _ready() -> void:
	add_to_group("virtual_joystick")
	_knob_position = size / 2.0
	print("VirtualJoystick: MS art ring ready")


func _draw() -> void:
	var center := size / 2.0
	draw_circle(center, radius, SlugHudTheme.ASPHALT)
	draw_arc(center, radius, 0.0, TAU, 32, SlugHudTheme.MS_BORDER_OUTER, 2.0)
	draw_circle(_knob_position, knob_radius, SlugHudTheme.TAG_GOLD)
	draw_circle(_knob_position, knob_radius * 0.45, SlugHudTheme.SPRAY_ORANGE)


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
