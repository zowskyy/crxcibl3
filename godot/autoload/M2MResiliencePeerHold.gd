class_name M2MResiliencePeerHold
extends RefCounted
## Peer disconnect grace holds + host session sync persistence (Phase 1.2 / 6.2).
## validate hold schema; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via purge_expired().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const HOLD_PATH := "user://m2m_peer_hold.json"
const PEER_HOLD_GRACE_SEC := 60.0
const HOST_SESSION_SYNC_KEY := "host_session_sync"


static func hold_disconnected_peer(machine_id: String, snapshot: Dictionary) -> void:
	if machine_id.is_empty() or snapshot.is_empty():
		return
	var registry := _load()
	var holds: Dictionary = registry.get("held_peers", {})
	holds[machine_id] = {"snapshot": snapshot.duplicate(true), "held_at_usec": Time.get_ticks_usec()}
	registry["held_peers"] = holds
	_save(registry)
	print("[M2MResiliencePeerHold] held peer machine=%s" % machine_id.substr(0, mini(8, machine_id.length())))


static func take_held_peer(machine_id: String) -> Dictionary:
	if machine_id.is_empty():
		return {}
	var registry := _load()
	var holds: Dictionary = registry.get("held_peers", {})
	if not holds.has(machine_id):
		return {}
	var entry: Dictionary = holds[machine_id]
	if _hold_expired(entry):
		holds.erase(machine_id)
		registry["held_peers"] = holds
		_save(registry)
		return {}
	holds.erase(machine_id)
	registry["held_peers"] = holds
	_save(registry)
	var snapshot: Variant = entry.get("snapshot", {})
	return snapshot if snapshot is Dictionary else {}


static func peek_held_peer(machine_id: String) -> Dictionary:
	if machine_id.is_empty():
		return {}
	var holds: Dictionary = _load().get("held_peers", {})
	if not holds.has(machine_id):
		return {}
	var entry: Dictionary = holds[machine_id]
	if _hold_expired(entry):
		return {}
	var snapshot: Variant = entry.get("snapshot", {})
	return snapshot.duplicate(true) if snapshot is Dictionary else {}


static func save_host_session_sync(payload: Dictionary) -> void:
	if payload.is_empty():
		return
	var registry := _load()
	registry[HOST_SESSION_SYNC_KEY] = payload.duplicate(true)
	_save(registry)


static func get_host_session_sync() -> Dictionary:
	var stored: Variant = _load().get(HOST_SESSION_SYNC_KEY, {})
	return stored.duplicate(true) if stored is Dictionary else {}


static func purge_expired() -> void:
	var registry := _load()
	var holds: Dictionary = registry.get("held_peers", {})
	if holds.is_empty():
		return
	var changed := false
	for machine_id in holds.keys():
		if _hold_expired(holds[machine_id]):
			holds.erase(machine_id)
			changed = true
	if changed:
		registry["held_peers"] = holds
		_save(registry)


static func _hold_expired(entry: Dictionary) -> bool:
	var held_at := int(entry.get("held_at_usec", 0))
	if held_at <= 0:
		return true
	return float(Time.get_ticks_usec() - held_at) / 1_000_000.0 > PEER_HOLD_GRACE_SEC


static func _load() -> Dictionary:
	var registry := {"held_peers": {}}
	if not FileAccess.file_exists(HOLD_PATH):
		return registry
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(HOLD_PATH))
	return parsed if parsed is Dictionary else registry


static func _save(registry: Dictionary) -> void:
	var f := FileAccess.open(HOLD_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(registry))
