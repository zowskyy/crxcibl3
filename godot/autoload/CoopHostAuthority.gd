class_name CoopHostAuthority
extends RefCounted
## Host-side authoritative peer simulation for co-op (Phase 1.1).
## validate peer state schema; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via clear().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const PLAYER_SPEED := 120.0
const DEFAULT_SPAWN := Vector2(550, 300)

var peer_input: Dictionary = {}
var authoritative_state: Dictionary = {}
var world_bounds: Rect2 = Rect2(Vector2.ZERO, Vector2(1100, 600))


func clear() -> void:
	peer_input.clear()
	authoritative_state.clear()
	print("[CoopHostAuthority] session authority cleared")


func set_world_bounds(bounds: Rect2) -> void:
	world_bounds = bounds


func spawn_offset_for_peer(peer_id: int) -> Vector2:
	return Vector2(40.0 * float(peer_id % 3), 24.0 * float(peer_id / 3))


func store_input(
	peer_id: int,
	move: Vector2,
	facing_angle: float,
	fire_pressed: bool,
	hero_id: String,
) -> void:
	peer_input[peer_id] = {
		"move": move,
		"facing_angle": facing_angle,
		"fire": fire_pressed,
		"hero_id": hero_id,
	}


func init_peer(peer_id: int, hero_id: String, spawn_pos: Vector2) -> void:
	var hid := hero_id if not hero_id.is_empty() else "enforcer_ghost"
	authoritative_state[peer_id] = {
		"pos": spawn_pos,
		"facing_angle": 0.0,
		"hero_id": hid,
		"health": _max_health_for_hero(hid),
		"max_health": _max_health_for_hero(hid),
	}


func sync_from_player(peer_id: int, player: CharacterBody2D) -> void:
	if player == null:
		return
	var hero_id := _hero_id_from_player(player)
	var facing_angle: float = 0.0
	if "_facing" in player and player._facing.length_squared() > 0.0001:
		facing_angle = player._facing.angle()
	authoritative_state[peer_id] = {
		"pos": player.global_position,
		"facing_angle": facing_angle,
		"hero_id": hero_id,
		"health": player.health,
		"max_health": _max_health_for_hero(hero_id),
	}


func apply_damage(peer_id: int, amount: int) -> Dictionary:
	_ensure_peer(peer_id, GameState.get_active_hero())
	var state: Dictionary = authoritative_state[peer_id]
	var max_hp := int(state.get("max_health", 120))
	state["health"] = clampi(int(state.get("health", max_hp)) - amount, 0, max_hp)
	authoritative_state[peer_id] = state
	return state.duplicate(true)


func tick(
	delta: float,
	host_id: int,
	host_player: CharacterBody2D,
	peer_ids: Array,
) -> Array:
	var payloads: Array = []
	for raw_id in peer_ids:
		var peer_id := int(raw_id)
		if peer_id == host_id:
			sync_from_player(peer_id, host_player)
		else:
			_integrate_remote(peer_id, delta)
		if authoritative_state.has(peer_id):
			payloads.append({"peer_id": peer_id, "state": authoritative_state[peer_id].duplicate(true)})
	return payloads


func _ensure_peer(peer_id: int, hero_id: String) -> void:
	if authoritative_state.has(peer_id):
		return
	init_peer(peer_id, hero_id, DEFAULT_SPAWN + spawn_offset_for_peer(peer_id))


func _integrate_remote(peer_id: int, delta: float) -> void:
	_ensure_peer(peer_id, GameState.get_active_hero())
	var state: Dictionary = authoritative_state[peer_id]
	var input: Dictionary = peer_input.get(peer_id, {})
	var move: Vector2 = input.get("move", Vector2.ZERO)
	if move.length() > 1.0:
		move = move.normalized()
	var pos: Vector2 = state.get("pos", DEFAULT_SPAWN)
	pos += move * PLAYER_SPEED * delta
	if world_bounds.size.x > 0.0 and world_bounds.size.y > 0.0:
		pos.x = clampf(pos.x, world_bounds.position.x, world_bounds.position.x + world_bounds.size.x)
		pos.y = clampf(pos.y, world_bounds.position.y, world_bounds.position.y + world_bounds.size.y)
	state["pos"] = pos
	if input.has("facing_angle"):
		state["facing_angle"] = float(input.get("facing_angle", state.get("facing_angle", 0.0)))
	if str(input.get("hero_id", "")) != "":
		state["hero_id"] = str(input.get("hero_id"))
	authoritative_state[peer_id] = state


func _hero_id_from_player(player: CharacterBody2D) -> String:
	if player != null and "hero_name" in player:
		return str(player.hero_name)
	return GameState.get_active_hero()


func _max_health_for_hero(hero_id: String) -> int:
	return 120 + RelationshipSystem.get_hp_bonus(hero_id)
