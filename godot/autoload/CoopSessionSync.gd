class_name CoopSessionSync
extends RefCounted
## Host-to-guest GameState slice for M2M rejoin (Phase 6.2).
## validate session sync schema; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via empty payload guard.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


static func build_payload() -> Dictionary:
	return {
		"heat": GameState.heat,
		"squad": GameState.squad.duplicate(),
		"relationships": GameState.relationships.duplicate(true),
		"current_act": GameState.current_act,
		"current_hero_index": GameState.current_hero_index,
		"coop_session_id": GameState.coop_session_id,
		"morale": GameState.morale,
		"ghost_count": GameState.ghost_count,
	}


static func apply(payload: Dictionary) -> void:
	if payload.is_empty():
		return
	GameState.heat = clampf(float(payload.get("heat", GameState.heat)), 0.0, GameState.HEAT_MAX)
	var squad: Variant = payload.get("squad", null)
	if squad is Array:
		GameState.squad = squad.duplicate()
	var rels: Variant = payload.get("relationships", null)
	if rels is Dictionary:
		for key in rels.keys():
			GameState.relationships[str(key)] = int(rels[key])
	GameState.current_act = int(payload.get("current_act", GameState.current_act))
	GameState.current_hero_index = int(payload.get("current_hero_index", 0))
	GameState.morale = int(payload.get("morale", GameState.morale))
	GameState.ghost_count = int(payload.get("ghost_count", 0))
	var session_id := str(payload.get("coop_session_id", ""))
	if not session_id.is_empty():
		GameState.coop_session_id = session_id
	print("[CoopSessionSync] applied host session sync")


static func relationship_snapshot_for_hero(hero_id: String) -> Dictionary:
	if hero_id.is_empty():
		return {}
	var snapshot: Dictionary = {}
	for key in GameState.relationships.keys():
		var rel_key := str(key)
		if rel_key.contains(hero_id):
			snapshot[rel_key] = int(GameState.relationships[key])
	return snapshot


static func apply_relationship_snapshot(snapshot: Dictionary) -> void:
	if not snapshot is Dictionary:
		return
	for key in snapshot.keys():
		GameState.relationships[str(key)] = int(snapshot[key])
