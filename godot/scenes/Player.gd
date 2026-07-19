extends Node2D
## Placeholder player for Slice 2.5 -- a drawn square standing in for real
## art, just enough to confirm movement works. Touch controls replace this
## input scheme in a later slice; arrow keys are a stopgap for testing on
## desktop in the meantime.

const SPEED := 120.0
const SIZE := 16.0

func _process(delta: float) -> void:
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	position += input_vector * SPEED * delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-SIZE / 2, -SIZE / 2, SIZE, SIZE), Color.CRIMSON)
