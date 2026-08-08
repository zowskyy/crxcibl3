extends Node2D
## The Emperor — non-combat reckoning figure (Slice 2.20 / animation starter).
## Placeholder drawn silhouette until final art lands.


func _draw() -> void:
	draw_rect(Rect2(-10, -18, 20, 36), Color(0.15, 0.13, 0.18))
	draw_circle(Vector2(0, -24), 7.0, Color(0.75, 0.65, 0.55))
	draw_rect(Rect2(-7, -14, 14, 3), Color(0.85, 0.7, 0.2))


func play_gesture(name: String) -> void:
	queue_redraw()
	match name:
		"lookaside", "hands_open", "leaning_forward", "slump_final":
			modulate = Color(1, 1, 1, 1)
		_:
			pass


func play_dissolve(from_a: float, to_a: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(_set_dissolve, from_a, to_a, duration)
	await tween.finished


func _set_dissolve(alpha: float) -> void:
	modulate.a = alpha
