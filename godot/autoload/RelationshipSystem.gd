extends Node
## RelationshipSystem — Autoload singleton (Slice 3.6)
##
## Wires GameState's pairwise relationships (-10..+10) into real gameplay effects.
## Two categories:
##   1. Synergy bonuses — active when two heroes with relationship ≥ 5 are in the same
##      squad. Applied per-frame via get_active_bonuses() queried by Player.gd.
##   2. Event triggers — modify relationships when crew events happen (boss killed,
##      friendly fire, crew downed, quest completed). Feeds into Morale via
##      Morale.on_relationship_changed() which already scales ±20 per ±10 delta.
##
## Lore pairings (from KNOWLEDGE_BASE.md relationship web):
##   enforcer_big_body  ↔ enforcer_ghost      (oldest + operator)
##   enforcer_ghost     ↔ street_rat_slink     (operator + scout, blood relation)
##   wheelman_slick     ↔ wheelman_grinder     (driver + mechanic, best duo)
##   hacker_byte        ↔ hacker_hacktivist    (coder + activist, shared politics)

signal relationship_changed(hero_a: String, hero_b: String, new_value: int)

# Known synergy pairs — [hero_a, hero_b, description, speed_mult_bonus, damage_bonus]
const SYNERGY_PAIRS := [
	["enforcer_big_body",  "enforcer_ghost",    "big_body_ghost",    0.0,  3],
	["enforcer_ghost",     "street_rat_slink",  "ghost_slink",       0.05, 0],
	["wheelman_slick",     "wheelman_grinder",  "slick_grinder",     0.0,  0],
	["hacker_byte",        "hacker_hacktivist", "byte_hacktivist",   0.0,  5],
]

# Minimum relationship to activate a synergy
const SYNERGY_THRESHOLD := 5


func _ready() -> void:
	# Seed lore-canon starting relationships if not already set
	# These are warm defaults — the crew trusts each other going in.
	_seed_if_unset("enforcer_big_body",  "enforcer_ghost",    6)
	_seed_if_unset("enforcer_ghost",     "street_rat_slink",  7)
	_seed_if_unset("wheelman_slick",     "wheelman_grinder",  5)
	_seed_if_unset("hacker_byte",        "hacker_hacktivist", 4)


func _seed_if_unset(a: String, b: String, value: int) -> void:
	var key := GameState.relationship_key(a, b)
	if not GameState.relationships.has(key):
		GameState.relationships[key] = value


## Returns the combined damage bonus for a given hero based on active synergies
## with other squad members. Called by Player.gd when computing bullet damage.
func get_damage_bonus(hero_name: String) -> int:
	var bonus := 0
	for pair in SYNERGY_PAIRS:
		if pair[4] <= 0:
			continue
		var other := ""
		if pair[0] == hero_name:
			other = pair[1]
		elif pair[1] == hero_name:
			other = pair[0]
		else:
			continue
		if GameState.squad.has(other):
			if GameState.get_relationship(hero_name, other) >= SYNERGY_THRESHOLD:
				bonus += pair[4]
	return bonus


## Returns the combined speed multiplier bonus for a given hero based on active synergies.
## Additive on top of the base 1.0 multiplier (e.g. 0.05 → 1.05× speed).
func get_speed_bonus(hero_name: String) -> float:
	var bonus := 0.0
	for pair in SYNERGY_PAIRS:
		if pair[3] <= 0.0:
			continue
		var other := ""
		if pair[0] == hero_name:
			other = pair[1]
		elif pair[1] == hero_name:
			other = pair[0]
		else:
			continue
		if GameState.squad.has(other):
			if GameState.get_relationship(hero_name, other) >= SYNERGY_THRESHOLD:
				bonus += pair[3]
	return bonus


## Call when any hero in the squad kills an enemy — small trust boost between
## crew members who fought together.
func on_kill_together(killer: String) -> void:
	for other in GameState.squad:
		if other == killer:
			continue
		_modify(killer, other, 1)


## Call when a boss is defeated — larger boost; shared victory.
func on_boss_defeated_together() -> void:
	var squad := GameState.squad
	for i in range(squad.size()):
		for j in range(i + 1, squad.size()):
			_modify(squad[i], squad[j], 2)


## Call when a hero is downed — crew feels the loss; small bond boost.
func on_hero_downed(hero_name: String) -> void:
	for other in GameState.squad:
		if other == hero_name:
			continue
		_modify(hero_name, other, 1)


func _modify(a: String, b: String, delta: int) -> void:
	if a.is_empty() or b.is_empty():
		return
	GameState.modify_relationship(a, b, delta)
	var new_val := GameState.get_relationship(a, b)
	relationship_changed.emit(a, b, new_val)
	Morale.on_relationship_changed(delta)


func reset() -> void:
	pass  # Relationship values live in GameState.relationships — reset_for_new_game clears them.
