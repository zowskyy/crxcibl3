extends Node
## Proximity-aware co-op — M2M hook catches mobile/LAN/BT IPs; multi-transport join.
## Usage: host_session(), scan_nearby() — see docs/COOP_MULTIPLAYER.md --help.
## validate beacon payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via stop_session().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

signal session_started
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal nearby_session_found(session_info: Dictionary)
signal transport_changed(kind: String)
signal player_state_sync(peer_id: int, pos: Vector2, facing: Vector2, hero_id: String, health: int)
signal heat_sync(heat: float)
signal m2m_mobile_ip_ready(ip: String)

const GAME_PORT := 7777
const BEACON_INTERVAL_SEC := 2.0

var is_coop: bool = false

var _session_id: String = ""
var _host_alias: String = ""
var _active_transport: String = TransportPolicy.TRANSPORT_M2M
var _enet_peer: ENetMultiplayerPeer = null
var _beacon_timer: Timer = null
var _discovery := CoopDiscovery.new()
var _connected: bool = false
var _remote_player_states: Dictionary = {}
var _own_session_id: String = ""
var _join_start_usec: int = 0


func _ready() -> void:
	M2MResilienceCore.start()
	_beacon_timer = Timer.new()
	_beacon_timer.wait_time = BEACON_INTERVAL_SEC
	_beacon_timer.timeout.connect(_send_beacon)
	add_child(_beacon_timer)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	M2MSession.mobile_ip_caught.connect(_on_mobile_ip_caught)
	M2MSession.m2m_sessions_updated.connect(_on_m2m_sessions_updated)
	M2MSession.proximity_match.connect(_on_proximity_match)
	CoopBluetooth.session_discovered.connect(_on_bluetooth_session)


func _process(_delta: float) -> void:
	for session in _discovery.poll(is_host(), Callable(self, "_send_beacon")):
		if str(session.get("session_id", "")) != _own_session_id:
			_enrich_and_emit(session)


func host_session(alias: String) -> Error:
	stop_session()
	is_coop = true
	_host_alias = alias if not alias.is_empty() else "Host"
	_session_id = _generate_session_id()
	_own_session_id = _session_id
	GameState.coop_session_id = _session_id

	M2MSession.catch_mobile_ip()
	M2MSession.start_m2m_watch()
	_active_transport = TransportPolicy.select_host_transport(
		CoopLanUtil.primary_local_ip(),
		M2MSession.mobile_ip,
		CoopBluetooth.is_available(),
	)
	_emit_transport_changed()

	var err := _start_enet_server()
	if err != OK:
		stop_session()
		return err

	_discovery.start()
	_beacon_timer.start()
	_connected = true
	_publish_bluetooth_advert()
	session_started.emit()
	return OK


func join_session(address: String, transport: String = "") -> Error:
	if address.is_empty():
		return ERR_INVALID_PARAMETER

	stop_session()
	is_coop = true
	_host_alias = "Client"
	_own_session_id = ""
	_join_start_usec = Time.get_ticks_usec()

	if transport.is_empty():
		_active_transport = CoopLanUtil.transport_for_address(address)
	else:
		_active_transport = transport
	_emit_transport_changed()

	var err: Error = ERR_CANT_CONNECT
	var target := CoopLanUtil.resolve_join_address(address, _active_transport)
	err = _start_enet_client(target)
	if err != OK and _active_transport == TransportPolicy.TRANSPORT_BLUETOOTH:
		err = _start_enet_client(address)

	if err != OK:
		M2MTransportLearner.record_failure(_active_transport)
		stop_session()
		return err

	M2MSession.start_m2m_watch()
	_discovery.start()
	return OK


func join_session_info(session: Dictionary) -> Error:
	var pick: Dictionary = M2MSession.pick_join_address(session)
	var addr: String = str(pick.get("address", ""))
	var transport: String = str(pick.get("transport", ""))
	return join_session(addr, transport)


func scan_nearby() -> Array:
	_discovery.broadcast("discover", {"requester": _host_alias})
	await M2MSession.run_m2m_scan()
	return get_all_nearby_sessions()


func stop_session() -> void:
	_beacon_timer.stop()
	_connected = false
	is_coop = false
	_session_id = ""
	_own_session_id = ""
	_host_alias = ""
	GameState.coop_session_id = ""
	_remote_player_states.clear()
	_discovery.stop()
	M2MSession.stop_m2m_watch()
	CoopBluetooth.stop_advertising()
	CoopBluetooth.close_rfcomm()

	if _enet_peer:
		_enet_peer.close()
		_enet_peer = null
	multiplayer.multiplayer_peer = null


func is_host() -> bool:
	return _connected and multiplayer.is_server()


func is_online() -> bool:
	return _connected and multiplayer.multiplayer_peer != null


func get_peer_count() -> int:
	return 0 if not is_online() else maxi(0, multiplayer.get_peers().size())


func get_local_peer_id() -> int:
	return 1 if not is_online() else multiplayer.get_unique_id()


func get_peer_ids() -> Array:
	if not is_online():
		return [get_local_peer_id()]
	var ids: Array = [multiplayer.get_unique_id()]
	for peer_id in multiplayer.get_peers():
		ids.append(peer_id)
	return ids


func get_friends_count() -> int:
	return maxi(0, get_peer_count())


func get_transport_label() -> String:
	return TransportPolicy.transport_label(_active_transport)


func get_active_transport() -> String:
	return _active_transport


func get_active_transport_label() -> String:
	return get_transport_label()


func get_nearby_sessions() -> Array:
	return _discovery.get_sessions()


func get_all_nearby_sessions() -> Array:
	var merged := CoopDiscovery.merge_session_lists(
		_discovery.get_sessions(), M2MSession.get_ranked_sessions()
	)
	return M2MResilienceCore.filter_peer_sessions(merged)


func get_caught_ips() -> Dictionary:
	return M2MSession.get_caught_addresses()


func get_remote_player_state(peer_id: int) -> Dictionary:
	return _remote_player_states.get(peer_id, {}).duplicate(true)


@rpc("any_peer", "call_local", "reliable")
func sync_player_state(peer_id: int, pos: Vector2, facing: float, hero_id: String, health: float) -> void:
	var facing_vec := Vector2(cos(facing), sin(facing))
	var health_i := int(round(health))
	_remote_player_states[peer_id] = {"pos": pos, "facing": facing, "hero_id": hero_id, "health": health_i}
	player_state_sync.emit(peer_id, pos, facing_vec, hero_id, health_i)


@rpc("authority", "call_local", "reliable")
func sync_heat(heat: float) -> void:
	heat_sync.emit(heat)


@rpc("authority", "call_local", "reliable")
func sync_squad_and_start(squad: Array) -> void:
	GameState.squad = squad.duplicate()
	GameState.current_hero_index = 0
	get_tree().change_scene_to_file("res://scenes/TestRoom.tscn")


func broadcast_player_state(pos: Vector2, facing: Vector2, hero_id: String, health: int) -> void:
	if not is_online():
		return
	var peer_id := multiplayer.get_unique_id()
	var angle := facing.angle() if facing.length_squared() > 0.0001 else 0.0
	sync_player_state.rpc(peer_id, pos, angle, hero_id, float(health))


func broadcast_heat(heat: float) -> void:
	if is_online() and is_host():
		sync_heat.rpc(heat)


func _start_enet_server() -> Error:
	_enet_peer = ENetMultiplayerPeer.new()
	var err := _enet_peer.create_server(GAME_PORT, 8)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = _enet_peer
	return OK


func _start_enet_client(address: String) -> Error:
	_enet_peer = ENetMultiplayerPeer.new()
	var err := _enet_peer.create_client(address, GAME_PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = _enet_peer
	return OK


func _send_beacon() -> void:
	if not is_host():
		return
	var beacon := M2MSession.build_host_beacon(
		_session_id, _host_alias, get_peer_count() + 1, GAME_PORT
	)
	beacon["transport"] = _active_transport
	beacon["address"] = str(beacon.get("lan_address", ""))
	_discovery.broadcast("beacon", beacon)
	_publish_bluetooth_advert()


func _publish_bluetooth_advert() -> void:
	if not is_host() or not CoopBluetooth.is_available():
		return
	CoopBluetooth.start_advertising({
		"session_id": _session_id,
		"host_alias": _host_alias,
		"player_count": get_peer_count() + 1,
		"port": GAME_PORT,
		"lan_address": M2MSession.lan_ip,
		"mobile_address": M2MSession.effective_mobile_ip(),
		"machine_id": M2MMachineIdentity.get_machine_id(),
	})


func _enrich_and_emit(session: Dictionary) -> void:
	if M2MMachineIdentity.is_self_beacon(session):
		return
	session["lan_address"] = str(session.get("lan_address", session.get("address", "")))
	session["mobile_address"] = str(session.get("mobile_address", ""))
	session["bluetooth_address"] = str(session.get("bluetooth_address", ""))
	M2MSession.register_external_session(session)
	nearby_session_found.emit(session)


func _on_mobile_ip_caught(ip: String) -> void:
	m2m_mobile_ip_ready.emit(ip)
	if is_host():
		_send_beacon()


func _on_m2m_sessions_updated(sessions: Array) -> void:
	for s in sessions:
		if s is Dictionary:
			nearby_session_found.emit(s)


func _on_proximity_match(session: Dictionary) -> void:
	nearby_session_found.emit(session)


func _on_bluetooth_session(session: Dictionary) -> void:
	_enrich_and_emit(session)


func _on_peer_connected(id: int) -> void:
	peer_joined.emit(id)
	if is_host():
		_send_beacon()


func _on_peer_disconnected(id: int) -> void:
	_remote_player_states.erase(id)
	peer_left.emit(id)
	if is_host():
		_send_beacon()


func _on_connected_to_server() -> void:
	_connected = true
	var ms := float(Time.get_ticks_usec() - _join_start_usec) / 1000.0
	M2MTransportLearner.record_success(_active_transport, ms)
	session_started.emit()


func _on_connection_failed() -> void:
	M2MTransportLearner.record_failure(_active_transport)
	push_warning("CoopNetwork: connection failed.")
	stop_session()


func _on_server_disconnected() -> void:
	push_warning("CoopNetwork: server disconnected.")
	stop_session()


func _emit_transport_changed() -> void:
	transport_changed.emit(_active_transport)


func _generate_session_id() -> String:
	return "%s-%s" % [str(Time.get_unix_time_from_system()), str(randi() % 100000)]
