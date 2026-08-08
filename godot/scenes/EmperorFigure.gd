extends Node2D
## The Emperor — caption-driven figure with simple lip flap (no VO).

var speaking := false
var _lip_phase := 0.0


func _process(delta: float) -> void:
	if speaking:
		_lip_phase += delta * 14.0
		queue_redraw()


func set_speaking(active: bool) -> void:
	speaking = active
	if not speaking:
		_lip_phase = 0.0
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-10, -18, 20, 36), Color(0.15, 0.13, 0.18))
	draw_circle(Vector2(0, -24), 7.0, Color(0.75, 0.65, 0.55))
	draw_rect(Rect2(-7, -14, 14, 3), Color(0.85, 0.7, 0.2))
	if speaking:
		var open := absf(sin(_lip_phase)) > 0.35
		var mouth_h := 3.0 if open else 1.0
		draw_rect(Rect2(-3, -22, 6, mouth_h), Color(0.15, 0.08, 0.08))


func play_gesture(name: String) -> void:
	match name:
		"lookaside", "hands_open", "leaning_forward", "slump_final", "talk":
			modulate = Color(1.05, 1.0, 0.95, 1.0)
	queue_redraw()


func play_dissolve(from_a: float, to_a: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(_set_dissolve, from_a, to_a, duration)
	await tween.finished


func _set_dissolve(alpha: float) -> void:
	modulate.a = alpha
