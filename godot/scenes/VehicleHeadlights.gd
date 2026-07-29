extends Node2D
## Optional vehicle accessory (Vehicle system, wow.txt spec): headlights as
## an attachable child node instead of code baked into the vehicle body's
## own _draw(). Add as a child of any vehicle CharacterBody2D, positioned
## at the front bumper; omit the node entirely for a vehicle with no lights.

@export var light_color: Color = Color(0.95, 0.92, 0.6)
@export var spacing: float = 17.0     # distance between the two light centers
@export var light_size: Vector2 = Vector2(5, 3)
@export var on: bool = true


func _draw() -> void:
	if not on:
		return
	var half := spacing * 0.5
	draw_rect(Rect2(-half - light_size.x * 0.5, -light_size.y * 0.5, light_size.x, light_size.y), light_color)
	draw_rect(Rect2(half - light_size.x * 0.5, -light_size.y * 0.5, light_size.x, light_size.y), light_color)
