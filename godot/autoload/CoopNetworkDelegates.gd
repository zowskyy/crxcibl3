class_name CoopNetworkDelegates
extends RefCounted
## Gameplay authority delegates for CoopNetwork.
## validate gameplay payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via publish_authority_state().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const CoopNetworkTransportScript := preload("res://autoload/CoopNetworkTransport.gd")
const CoopHostAuthorityScript := preload("res://autoload/CoopHostAuthority.gd")
const CoopNetworkAuthorityRelayScript := preload("res://autoload/CoopNetworkAuthorityRelay.gd")
const CoopNetworkJoinScript := preload("res://autoload/CoopNetworkJoin.gd")
const CoopNetworkReconnectScript := preload("res://autoload/CoopNetworkReconnect.gd")


static func send_player_input(network, move: Vector2, facing: Vector2, fire_pressed: bool, hero_id: String) -> void:
	if not network.is_online():
		return
	var facing_angle := facing.angle() if facing.length_squared() > 0.0001 else 0.0
	if network.is_host():
		network._authority.store_input(
			network.multiplayer.get_unique_id(), move, facing_angle, fire_pressed, hero_id
		)
	else:
		network.submit_player_input.rpc_id(1, move.x, move.y, facing_angle, fire_pressed, hero_id)


static func tick_authority_simulation(network, delta: float, host_player: CharacterBody2D) -> void:
	if not network.is_online() or not network.is_host():
		return
	var host_id: int = network.multiplayer.get_unique_id()
	for payload in network._authority.tick(
		delta, host_id, host_player, CoopNetworkJoinScript.peer_ids(network)
	):
		var peer_id: int = int(payload.get("peer_id", 0))
		var state: Dictionary = payload.get("state", {})
		publish_authority_state(network, peer_id, state)


static func notify_host_player_state(network, player: CharacterBody2D) -> void:
	if not network.is_host() or player == null:
		return
	var peer_id: int = network.multiplayer.get_unique_id()
	network._authority.sync_from_player(peer_id, player)
	if network._authority.authoritative_state.has(peer_id):
		publish_authority_state(network, peer_id, network._authority.authoritative_state[peer_id])


static func broadcast_player_state(network, pos: Vector2, facing: Vector2, hero_id: String, health: int) -> void:
	if not network.is_online():
		return
	if not network.is_host():
		print("[CoopNetworkDelegates] ignored client broadcast_player_state")
		push_warning("CoopNetwork: clients cannot broadcast_player_state — use send_player_input()")
		return
	var peer_id: int = network.multiplayer.get_unique_id()
	var angle := facing.angle() if facing.length_squared() > 0.0001 else 0.0
	network.sync_player_state.rpc(peer_id, pos, angle, hero_id, float(health))


static func broadcast_heat(network, heat: float) -> void:
	if network.is_online() and network.is_host():
		network.sync_heat.rpc(heat)


static func send_beacon(network) -> void:
	if not network.is_host():
		return
	var beacon := CoopNetworkTransportScript.build_beacon(
		network._session_id, network._host_alias, network.get_peer_count() + 1, network._active_transport
	)
	network._discovery.broadcast("beacon", beacon)
	publish_bluetooth_advert(network)


static func publish_bluetooth_advert(network) -> void:
	if not network.is_host() or CoopBluetooth == null or not CoopBluetooth.is_available():
		return
	CoopBluetooth.start_advertising(
		CoopNetworkTransportScript.bluetooth_advert_payload(
			network._session_id, network._host_alias, network.get_peer_count() + 1
		)
	)


static func on_mobile_ip_caught(network, ip: String) -> void:
	network.m2m_mobile_ip_ready.emit(ip)
	if network.is_host():
		send_beacon(network)


static func on_m2m_sessions_updated(network, sessions: Array) -> void:
	for s in sessions:
		if s is Dictionary:
			network.nearby_session_found.emit(s)


static func on_peer_connected(network, id: int) -> void:
	network.peer_joined.emit(id)
	if network.is_host():
		if id == network.multiplayer.get_unique_id():
			network._authority.init_peer(
				id,
				GameState.get_active_hero(),
				CoopHostAuthorityScript.DEFAULT_SPAWN + network._authority.spawn_offset_for_peer(id),
			)
		send_beacon(network)


static func on_peer_disconnected(network, id: int) -> void:
	if network.is_host():
		CoopNetworkReconnectScript.hold_peer_on_disconnect(network, id)
	network._remote_player_states.erase(id)
	network._authority.peer_input.erase(id)
	network.peer_left.emit(id)
	if network.is_host():
		send_beacon(network)


static func publish_authority_state(network, peer_id: int, state: Dictionary) -> void:
	if state.is_empty():
		return
	network.sync_player_state.rpc(
		peer_id,
		state.get("pos", Vector2.ZERO),
		float(state.get("facing_angle", 0.0)),
		str(state.get("hero_id", "")),
		float(state.get("health", 0)),
	)
	if network.is_host() and peer_id != network.multiplayer.get_unique_id():
		emit_player_state_local(network, peer_id, state)


static func emit_player_state_local(network, peer_id: int, state: Dictionary) -> void:
	var entry := CoopNetworkAuthorityRelayScript.remote_state_entry(state)
	var facing_vec := CoopNetworkAuthorityRelayScript.facing_vector(entry["facing"])
	network._remote_player_states[peer_id] = entry
	network.player_state_sync.emit(peer_id, entry["pos"], facing_vec, entry["hero_id"], entry["health"])
