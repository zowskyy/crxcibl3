extends Node2D
## Blackwood's black luxury town car — visual only in CarChaseScene.
## Faces away from the player (rear of the car is toward camera).
## CarChaseScene moves this node; no logic here, just art.

func _draw() -> void:
	# Body — black with slight purple tint (preacher's colours)
	draw_rect(Rect2(-13, -22, 26, 44), Color(0.05, 0.04, 0.08))
	# Rear window (facing player)
	draw_rect(Rect2(-10, -8, 20, 10), Color(0.35, 0.5, 0.75, 0.5))
	# Front window (away from player)
	draw_rect(Rect2(-10, 10, 20, 9), Color(0.35, 0.5, 0.75, 0.3))
	# Gold trim stripe (The Priest's brand)
	draw_rect(Rect2(-13, -2, 26, 3), Color(0.88, 0.72, 0.1))
	# Rear brake lights — pulsing red would be ideal; static for now
	draw_rect(Rect2(-13, -22, 6, 5), Color(0.92, 0.1, 0.1))
	draw_rect(Rect2(7,   -22, 6, 5), Color(0.92, 0.1, 0.1))
	# Wheels
	draw_rect(Rect2(-18, -18, 6, 10), Color(0.08, 0.08, 0.08))
	draw_rect(Rect2(12,  -18, 6, 10), Color(0.08, 0.08, 0.08))
	draw_rect(Rect2(-18, 10,  6, 10), Color(0.08, 0.08, 0.08))
	draw_rect(Rect2(12,  10,  6, 10), Color(0.08, 0.08, 0.08))
