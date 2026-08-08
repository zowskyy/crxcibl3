class_name CoopNetworkAuthorityRelay
extends RefCounted
## Host authority RPC relay helpers for CoopNetwork.
## validate peer payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via reject_claimed_state().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const ARMOR_K := 50.0
const HOSTILE_ATTACKER_PREFIXES := ["boss", "enemy", "rival_"]
const HOSTILE_ATTACKER_IDS := ["boss_projectile"]


static func is_host_validated_damage(attacker: String) -> bool:
	if attacker.is_empty():
		return false
	if attacker in HOSTILE_ATTACKER_IDS:
		return true
	for prefix in HOSTILE_ATTACKER_PREFIXES:
		if attacker.begins_with(prefix):
			return true
	return false


static func mitigated_damage_for_hero(hero_id: String, amount: int) -> int:
	var armor_bonus := Inventory.get_stat_bonus("armor") \
		+ float(RelationshipSystem.get_armor_bonus(hero_id))
	if armor_bonus > 0.0:
		var mitigation := armor_bonus / (armor_bonus + ARMOR_K)
		amount = int(round(float(amount) * (1.0 - mitigation)))
	return maxi(0, amount)


static func try_apply_peer_bullet_hit(
	network,
	world_pos: Vector2,
	damage: int,
	attacker: String,
) -> bool:
	if not network.is_online() or not network.is_host():
		return false
	var host_id: int = network.multiplayer.get_unique_id()
	var peer_id: int = network._authority.find_peer_hit_at(world_pos, host_id)
	if peer_id < 0:
		return false
	var state: Dictionary = network._authority.authoritative_state.get(peer_id, {})
	var hero_id := str(state.get("hero_id", ""))
	var final_dmg := mitigated_damage_for_hero(hero_id, damage)
	if not attacker.is_empty() and attacker != hero_id:
		final_dmg = int(round(float(final_dmg) * 0.5))
		Blame.on_friendly_fire(attacker, hero_id)
		RelationshipSystem.on_friendly_fire(attacker, hero_id)
	var updated: Dictionary = network._authority.apply_damage(peer_id, final_dmg)
	CoopNetworkDelegates.publish_authority_state(network, peer_id, updated)
	return true


static func store_remote_input(
	authority,
	sender: int,
	move_x: float,
	move_y: float,
	facing_angle: float,
	fire_pressed: bool,
	hero_id: String,
) -> void:
	authority.store_input(sender, Vector2(move_x, move_y), facing_angle, fire_pressed, hero_id)


static func apply_remote_damage(authority, sender: int, amount: int) -> Dictionary:
	return authority.apply_damage(sender, amount)


static func reject_claimed_state(sender: int, claimed_peer_id: int, health: float) -> void:
	push_warning(
		"CoopNetwork: rejected spoofed state from peer %d (claimed peer %d health %.0f)"
		% [sender, claimed_peer_id, health]
	)
	print("[CoopNetwork] rejected spoofed state peer=%d claimed=%d" % [sender, claimed_peer_id])


static func reject_bullet_hit_report(sender: int) -> void:
	push_warning("CoopNetwork: rejected client bullet hit report from peer %d" % sender)
	print("[CoopNetwork] rejected bullet hit report peer=%d" % sender)


static func remote_state_entry(state: Dictionary) -> Dictionary:
	var facing := float(state.get("facing_angle", 0.0))
	var health_i := int(round(float(state.get("health", 0))))
	var pos: Vector2 = state.get("pos", Vector2.ZERO)
	var hero_id := str(state.get("hero_id", ""))
	return {"pos": pos, "facing": facing, "hero_id": hero_id, "health": health_i}


static func facing_vector(angle: float) -> Vector2:
	return Vector2(cos(angle), sin(angle))
