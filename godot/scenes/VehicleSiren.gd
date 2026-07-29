extends Node2D
## Optional vehicle accessory (Vehicle system, wow.txt spec): a blinking
## red/blue siren bar as an attachable child node instead of code baked
## into the vehicle body's own _draw(). Add to any vehicle that should
## read as law enforcement / rival-crew pursuit; omit for a plain car.

const BLINK_INTERVAL := 0.25

@export var bar_size: Vector2 = Vector2(20, 5)
@export var enabled: bool = true

var _timer := 0.0
var _red_left := true


func _process(delta: float) -> void:
	if not enabled:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = BLINK_INTERVAL
		_red_left = not _red_left
		queue_redraw()


func _draw() -> void:
	if not enabled:
		return
	var half_w := bar_size.x * 0.5
	var left_color  := Color(0.9, 0.1, 0.1) if _red_left else Color(0.15, 0.15, 0.85)
	var right_color := Color(0.15, 0.15, 0.85) if _red_left else Color(0.9, 0.1, 0.1)
	draw_rect(Rect2(-half_w, -bar_size.y * 0.5, half_w, bar_size.y), left_color)
	draw_rect(Rect2(0, -bar_size.y * 0.5, half_w, bar_size.y), right_color)
