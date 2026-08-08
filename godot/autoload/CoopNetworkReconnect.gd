class_name CoopNetworkReconnect
extends RefCounted
## Mid-match reconnect + host session sync helpers (Phase 1.2 / 6.2).
## validate reconnect payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via load_host_session_sync().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const CoopNetworkDelegatesScript := preload("res://autoload/CoopNetworkDelegates.gd")


static func hold_peer_on_disconnect(network, peer_id: int) -> void:
	if not network.is_host():
		return
	var machine_id := str(network._peer_machine_ids.get(peer_id, ""))
	var state: Dictionary = network._authority.authoritative_state.get(peer_id, {}).duplicate(true)
	if machine_id.is_empty() or state.is_empty():
		network._authority.authoritative_state.erase(peer_id)
		network._peer_machine_ids.erase(peer_id)
		return
	M2MResiliencePeerHold.hold_disconnected_peer(machine_id, {
		"peer_id": peer_id,
		"state": state,
		"relationships": CoopSessionSync.relationship_snapshot_for_hero(str(state.get("hero_id", ""))),
	})
	network._authority.authoritative_state.erase(peer_id)
	network._peer_machine_ids.erase(peer_id)
	print("[CoopNetworkReconnect] held peer %d machine=%s" % [peer_id, machine_id.substr(0, 8)])


static func on_machine_announced(network, peer_id: int, machine_id: String) -> void:
	if not network.is_host():
		return
	network._peer_machine_ids[peer_id] = machine_id
	var held := M2MResiliencePeerHold.take_held_peer(machine_id)
	if held.is_empty():
		_init_fresh_peer(network, peer_id)
	else:
		_restore_held_peer(network, peer_id, held)
		network.peer_reconnected.emit(peer_id, machine_id)
	_broadcast_session_sync_to_peer(network, peer_id)


static func persist_host_session_state(network) -> void:
	if not network.is_host():
		return
	var payload := CoopSessionSync.build_payload()
	M2MResiliencePeerHold.save_host_session_sync(payload)
	network._host_session_sync = payload.duplicate(true)
	print("[CoopNetworkReconnect] host session sync persisted")


static func load_host_session_sync(network) -> void:
	network._host_session_sync = M2MResiliencePeerHold.get_host_session_sync().duplicate(true)


static func apply_session_sync(payload: Dictionary) -> void:
	CoopSessionSync.apply(payload)


static func request_machine_announce(network) -> void:
	if not network.is_online() or network.is_host():
		return
	var machine_id := M2MMachineIdentity.get_machine_id()
	if machine_id.is_empty():
		return
	network.announce_machine_id.rpc_id(1, machine_id)


static func save_line_for_host() -> String:
	if not CoopNetwork.is_online() or not CoopNetwork.is_host():
		return ""
	return "coop_session_state=%s" % JSON.stringify(CoopSessionSync.build_payload())


static func _init_fresh_peer(network, peer_id: int) -> void:
	network._authority.init_peer(
		peer_id,
		GameState.get_active_hero(),
		network._authority.DEFAULT_SPAWN + network._authority.spawn_offset_for_peer(peer_id),
	)


static func _restore_held_peer(network, peer_id: int, held: Dictionary) -> void:
	var state: Dictionary = held.get("state", {}).duplicate(true)
	if state.is_empty():
		_init_fresh_peer(network, peer_id)
		return
	network._authority.authoritative_state[peer_id] = state
	CoopSessionSync.apply_relationship_snapshot(held.get("relationships", {}))
	CoopNetworkDelegatesScript.publish_authority_state(network, peer_id, state)
	network.restore_reconnected_peer.rpc_id(
		peer_id,
		state.get("pos", Vector2.ZERO),
		float(state.get("facing_angle", 0.0)),
		str(state.get("hero_id", "")),
		float(state.get("health", 0)),
	)
	print("[CoopNetworkReconnect] restored peer %d hero=%s" % [peer_id, state.get("hero_id", "")])


static func _broadcast_session_sync_to_peer(network, peer_id: int) -> void:
	if not network.is_host():
		return
	var payload: Dictionary = network._host_session_sync
	if payload.is_empty():
		payload = M2MResiliencePeerHold.get_host_session_sync()
	if payload.is_empty():
		return
	network.sync_coop_session_state.rpc_id(peer_id, payload)
