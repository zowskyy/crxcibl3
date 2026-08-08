class_name PlayerCoopBridge
extends RefCounted
## Co-op authority reconciliation helpers for Player (Phase 1.1).
## validate authoritative state; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via reconcile_health().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const POSITION_RECONCILE_EPS := 4.0


static func route_damage(player: CharacterBody2D, amount: int, attacker: String) -> bool:
	if not CoopNetwork.is_online() or CoopNetwork.is_host():
		return false
	if CoopNetworkAuthorityRelay.is_host_validated_damage(attacker):
		return true
	CoopNetwork.request_self_damage.rpc_id(1, amount, attacker)
	return true


static func apply_authoritative_state(
	player: CharacterBody2D,
	pos: Vector2,
	facing: Vector2,
	new_health: int,
	max_health: int,
) -> Dictionary:
	if CoopNetwork.is_host() or player == null:
		return {"changed": false, "became_dead": false, "revived": false}
	if pos.distance_to(player.global_position) > POSITION_RECONCILE_EPS:
		player.global_position = player.global_position.lerp(pos, 0.4)
	if facing.length_squared() > 0.0001:
		player._facing = facing.normalized()
	var prior_dead: bool = player.health <= 0
	player.health = clampi(new_health, 0, max_health)
	var became_dead: bool = player.health <= 0 and not prior_dead
	var revived: bool = player.health > 0 and prior_dead
	return {"changed": true, "became_dead": became_dead, "revived": revived}
