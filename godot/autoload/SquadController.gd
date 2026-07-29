extends Node
## SquadController — Autoload singleton.
## Gang squad system (wow.txt spec): groups Enemy.gd grunts into faction
## squads. When one member spots the player or takes damage, alerts nearby
## squad mates within the same faction so they engage together instead of
## reacting independently -- "when one squad member is threatened, nearby
## members are alerted and engage together."
##
## Also tracks which cover point each member currently holds, so the cover
## system (CoverPoint.gd) can score flanking spread against squad mates
## already dug in.

const ALERT_RADIUS := 220.0

var _squads: Dictionary = {}  # faction_id (String) -> Array[Node2D]


func join_squad(member: Node2D, faction_id: String) -> void:
	if not _squads.has(faction_id):
		_squads[faction_id] = []
	_squads[faction_id].append(member)
	member.tree_exiting.connect(func():
		if _squads.has(faction_id):
			_squads[faction_id].erase(member)
	, CONNECT_ONE_SHOT)


## Called by a squad member when it spots the player or takes damage.
## Nearby, not-yet-engaged squad mates get told about the threat
## immediately instead of waiting on their own detection radius.
func alert_squad(member: Node2D, faction_id: String, threat: Node2D) -> void:
	if faction_id == "" or not _squads.has(faction_id):
		return
	for mate in _squads[faction_id]:
		if mate == member or not is_instance_valid(mate):
			continue
		if mate.global_position.distance_to(member.global_position) <= ALERT_RADIUS:
			if mate.has_method("on_squad_alert"):
				mate.on_squad_alert(threat)


## Threat-relative angles (radians) of cover points already claimed by this
## member's squad mates -- used by CoverPoint.score() for flanking spread.
func ally_cover_angles(member: Node2D, faction_id: String, threat_pos: Vector2) -> Array:
	var angles: Array = []
	if faction_id == "" or not _squads.has(faction_id):
		return angles
	for mate in _squads[faction_id]:
		if mate == member or not is_instance_valid(mate):
			continue
		if mate.has_method("get_cover_point"):
			var cp = mate.get_cover_point()
			if cp != null and is_instance_valid(cp):
				angles.append((cp.global_position - threat_pos).angle())
	return angles


func squad_size(faction_id: String) -> int:
	return _squads.get(faction_id, []).size()
