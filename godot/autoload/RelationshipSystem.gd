extends Node
## RelationshipSystem — RPG synergy bonds on Beach Boulevard crew pairs.
##
## Relationship tiers (KNOWLEDGE_BASE lore pairs):
##   Strained (≤ -3): debuffs
##   Ally (≥ 5): base bond bonuses
##   Bonded (≥ 7): +15% bonus scaling
##   Soulbound (≥ 9): +30% bonus scaling

signal relationship_changed(hero_a: String, hero_b: String, new_value: int)
signal synergy_updated(hero_name: String, bonuses: Dictionary)

const TIER_STRAINED := -3
const TIER_ALLY := 5
const TIER_BONDED := 7
const TIER_SOULBOUND := 9

# [hero_a, hero_b, bond_id, hp_flat, damage_flat, speed_pct, crit_pct, armor_flat, regen_per_sec]
const SYNERGY_PAIRS := [
	["enforcer_big_body", "enforcer_ghost", "guardian_bond", 15, 3, 0.0, 0.02, 2, 0.0],
	["enforcer_ghost", "street_rat_slink", "blood_kin", 0, 0, 0.08, 0.03, 0, 0.15],
	["wheelman_slick", "wheelman_grinder", "pit_crew", 5, 2, 0.05, 0.05, 1, 0.0],
	["hacker_byte", "hacker_hacktivist", "cell_link", 0, 5, 0.0, 0.04, 0, 0.0],
]


func _ready() -> void:
	_seed_if_unset("enforcer_big_body", "enforcer_ghost", 6)
	_seed_if_unset("enforcer_ghost", "street_rat_slink", 7)
	_seed_if_unset("wheelman_slick", "wheelman_grinder", 6)
	_seed_if_unset("hacker_byte", "hacker_hacktivist", 5)


func _seed_if_unset(a: String, b: String, value: int) -> void:
	var key := GameState.relationship_key(a, b)
	if not GameState.relationships.has(key):
		GameState.relationships[key] = value


func get_rpg_bonuses(hero_name: String) -> Dictionary:
	var out := {
		"hp_flat": 0,
		"damage_flat": 0,
		"speed_pct": 0.0,
		"crit_pct": 0.0,
		"armor_flat": 0,
		"regen_per_sec": 0.0,
		"debuff_speed_pct": 0.0,
		"active_bonds": [] as Array,
	}
	for pair in SYNERGY_PAIRS:
		var other := _pair_partner(pair, hero_name)
		if other == "" or not GameState.squad.has(other):
			continue
		var rel := GameState.get_relationship(hero_name, other)
		var scale := _tier_scale(rel)
		if scale <= 0.0:
			if rel <= TIER_STRAINED:
				out["debuff_speed_pct"] += 0.05
			continue
		out["hp_flat"] += int(pair[3] * scale)
		out["damage_flat"] += int(pair[4] * scale)
		out["speed_pct"] += pair[5] * scale
		out["crit_pct"] += pair[6] * scale
		out["armor_flat"] += int(pair[7] * scale)
		out["regen_per_sec"] += pair[8] * scale
		out["active_bonds"].append({
			"id": pair[2],
			"partner": other,
			"tier": _tier_name(rel),
			"relationship": rel,
		})
	synergy_updated.emit(hero_name, out)
	return out


func _tier_scale(relationship: int) -> float:
	if relationship >= TIER_SOULBOUND:
		return 1.30
	if relationship >= TIER_BONDED:
		return 1.15
	if relationship >= TIER_ALLY:
		return 1.0
	return 0.0


func _tier_name(relationship: int) -> String:
	if relationship >= TIER_SOULBOUND:
		return "Soulbound"
	if relationship >= TIER_BONDED:
		return "Bonded"
	if relationship >= TIER_ALLY:
		return "Ally"
	if relationship <= TIER_STRAINED:
		return "Strained"
	return "Neutral"


func _pair_partner(pair: Array, hero_name: String) -> String:
	if pair[0] == hero_name:
		return pair[1]
	if pair[1] == hero_name:
		return pair[0]
	return ""


func get_damage_bonus(hero_name: String) -> int:
	return int(get_rpg_bonuses(hero_name)["damage_flat"])


func get_speed_bonus(hero_name: String) -> float:
	var b: Dictionary = get_rpg_bonuses(hero_name)
	return b["speed_pct"] - b["debuff_speed_pct"]


func get_crit_bonus(hero_name: String) -> float:
	return float(get_rpg_bonuses(hero_name)["crit_pct"])


func get_hp_bonus(hero_name: String) -> int:
	return int(get_rpg_bonuses(hero_name)["hp_flat"])


func get_armor_bonus(hero_name: String) -> int:
	return int(get_rpg_bonuses(hero_name)["armor_flat"])


func get_regen_bonus(hero_name: String) -> float:
	return float(get_rpg_bonuses(hero_name)["regen_per_sec"])


func on_kill_together(killer: String) -> void:
	for other in GameState.squad:
		if other != killer:
			_modify(killer, other, 1)


func on_boss_defeated_together() -> void:
	var squad := GameState.squad
	for i in range(squad.size()):
		for j in range(i + 1, squad.size()):
			_modify(squad[i], squad[j], 2)


func on_hero_downed(hero_name: String) -> void:
	for other in GameState.squad:
		if other != hero_name:
			_modify(hero_name, other, 1)


func on_friendly_fire(shooter: String, victim: String) -> void:
	_modify(shooter, victim, -2)


func on_quest_completed() -> void:
	var squad := GameState.squad
	for i in range(squad.size()):
		for j in range(i + 1, squad.size()):
			_modify(squad[i], squad[j], 1)


func _modify(a: String, b: String, delta: int) -> void:
	if a.is_empty() or b.is_empty():
		return
	GameState.modify_relationship(a, b, delta)
	var new_val := GameState.get_relationship(a, b)
	relationship_changed.emit(a, b, new_val)
	Morale.on_relationship_changed(delta)


func reset() -> void:
	pass
