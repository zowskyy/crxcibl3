extends Node2D
## The Emperor (Slice 2.20) — the non-combat figure at the estate reckoning.
## Placeholder drawn silhouette ("behavior before art", same as every other
## character so far): an old man in a dark suit, sitting slumped — broken,
## not regal. No collision, no HP — he is never a combat target; the scene
## script drives everything he "does" (which is confess, and fade).


func _draw() -> void:
	draw_rect(Rect2(-10, -18, 20, 36), Color(0.15, 0.13, 0.18))   # dark suit
	draw_circle(Vector2(0, -24), 7.0, Color(0.75, 0.65, 0.55))    # head
	draw_rect(Rect2(-7, -14, 14, 3), Color(0.85, 0.7, 0.2))       # gold chain
