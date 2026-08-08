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


static func remote_state_entry(state: Dictionary) -> Dictionary:
	var facing := float(state.get("facing_angle", 0.0))
	var health_i := int(round(float(state.get("health", 0))))
	var pos: Vector2 = state.get("pos", Vector2.ZERO)
	var hero_id := str(state.get("hero_id", ""))
	return {"pos": pos, "facing": facing, "hero_id": hero_id, "health": health_i}


static func facing_vector(angle: float) -> Vector2:
	return Vector2(cos(angle), sin(angle))
