extends Node2D
class_name CoverPoint
## Cover marker (Gang squad AI + cover system, wow.txt spec). Placed by
## hand near obstacles/walls in level scenes. Enemies in combat search
## nearby cover points (group "cover_point") and score them by proximity,
## alignment with the threat, and flanking spread relative to squad mates
## already dug in, per SquadController.ally_cover_angles().

@export var high_cover: bool = false            # true = blocks LOS fully; false = crouch-only
@export var block_normal: Vector2 = Vector2.UP  # which side of the point blocks incoming fire

var occupied_by: Node2D = null


func _ready() -> void:
	add_to_group("cover_point")


func is_free() -> bool:
	return occupied_by == null or not is_instance_valid(occupied_by)


func claim(who: Node2D) -> void:
	occupied_by = who


func release(who: Node2D) -> void:
	if occupied_by == who:
		occupied_by = null


## Higher is better. ally_angles are threat-relative angles (radians) of
## cover points already held by this seeker's squad mates -- spreads the
## squad out instead of everyone diving behind the same rock.
func score(seeker_pos: Vector2, threat_pos: Vector2, ally_angles: Array) -> float:
	var to_threat := threat_pos - global_position
	if to_threat.length() < 0.01:
		return -INF

	var proximity := 1.0 / (1.0 + seeker_pos.distance_to(global_position) / 100.0)

	var alignment := clampf(block_normal.normalized().dot(to_threat.normalized()), 0.0, 1.0)

	var my_angle := to_threat.normalized().angle()
	var flank := 1.0
	for a in ally_angles:
		var diff: float = absf(wrapf(my_angle - float(a), -PI, PI))
		flank = minf(flank, diff / PI)

	return proximity * 0.4 + alignment * 0.4 + flank * 0.2


func _draw() -> void:
	var color := Color(0.35, 0.35, 0.55) if not high_cover else Color(0.35, 0.35, 0.7)
	draw_rect(Rect2(-8, -8, 16, 16), color)
	draw_line(Vector2.ZERO, block_normal.normalized() * 14.0, Color(0.8, 0.8, 1.0), 2.0)
