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
const CoopHostAuthorityScript := preload("res://autoload/CoopHostAuthority.gd")
const CoopNetworkTransportScript := preload("res://autoload/CoopNetworkTransport.gd")
const CoopNetworkAuthorityRelayScript := preload("res://autoload/CoopNetworkAuthorityRelay.gd")
const CoopNetworkDelegatesScript := preload("res://autoload/CoopNetworkDelegates.gd")
const CoopNetworkJoinScript := preload("res://autoload/CoopNetworkJoin.gd")

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
## Host-only: authoritative simulation delegated to CoopHostAuthority.
var _authority = CoopHostAuthorityScript.new()


func _ready() -> void:
	M2MResilienceCore.start()
	_beacon_timer = Timer.new()
	_beacon_timer.wait_time = BEACON_INTERVAL_SEC
	add_child(_beacon_timer)
	CoopNetworkJoinScript.connect_signal_pairs(self, [
		[_beacon_timer.timeout, _send_beacon],
		[multiplayer.peer_connected, _on_peer_connected],
		[multiplayer.peer_disconnected, _on_peer_disconnected],
		[multiplayer.connected_to_server, _on_connected_to_server],
		[multiplayer.connection_failed, _on_connection_failed],
		[multiplayer.server_disconnected, _on_server_disconnected],
		[M2MSession.mobile_ip_caught, _on_mobile_ip_caught],
		[M2MSession.m2m_sessions_updated, _on_m2m_sessions_updated],
		[M2MSession.proximity_match, _on_proximity_match],
	])
	if CoopBluetooth != null:
		CoopNetworkJoinScript.connect_signal_pairs(
			self, [[CoopBluetooth.session_discovered, _on_bluetooth_session]]
		)


func _process(_delta: float) -> void:
	CoopNetworkJoinScript.process_discovery(self)


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
		CoopBluetooth != null and CoopBluetooth.is_available(),
	)
	_emit_transport_changed()

	var err := _start_enet_server()
	if err != OK:
		stop_session()
		return err

	_discovery.start()
	_beacon_timer.start()
	_connected = true
	CoopNetworkDelegatesScript.publish_bluetooth_advert(self)
	session_started.emit()
	return OK


func join_session(address: String, transport: String = "") -> Error:
	return CoopNetworkJoinScript.join_session(self, address, transport)


func join_session_info(session: Dictionary) -> Error:
	var pick: Dictionary = M2MSession.pick_join_address(session)
	return join_session(str(pick.get("address", "")), str(pick.get("transport", "")))


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
	_authority.clear()
	_discovery.stop()
	M2MSession.stop_m2m_watch()
	CoopNetworkJoinScript.stop_bluetooth()
	if _enet_peer:
		_enet_peer.close()
		_enet_peer = null
	multiplayer.multiplayer_peer = null


func is_host() -> bool:
	return _connected and multiplayer.is_server()


func is_online() -> bool:
	return _connected and multiplayer.multiplayer_peer != null


func get_peer_count() -> int:
	return int(is_online()) * maxi(0, multiplayer.get_peers().size())


func get_local_peer_id() -> int:
	return 1 + int(is_online()) * (multiplayer.get_unique_id() - 1)


func get_peer_ids() -> Array:
	return CoopNetworkJoinScript.peer_ids(self)


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


func set_world_bounds(bounds: Rect2) -> void:
	_authority.set_world_bounds(bounds)


func send_player_input(move: Vector2, facing: Vector2, fire_pressed: bool, hero_id: String) -> void:
	CoopNetworkDelegatesScript.send_player_input(self, move, facing, fire_pressed, hero_id)


func tick_authority_simulation(delta: float, host_player: CharacterBody2D) -> void:
	CoopNetworkDelegatesScript.tick_authority_simulation(self, delta, host_player)


func notify_host_player_state(player: CharacterBody2D) -> void:
	CoopNetworkDelegatesScript.notify_host_player_state(self, player)


@rpc("any_peer", "reliable")
func submit_player_input(
	move_x: float,
	move_y: float,
	facing_angle: float,
	fire_pressed: bool,
	hero_id: String,
) -> void:
	if not is_host():
		return
	CoopNetworkAuthorityRelayScript.store_remote_input(
		_authority,
		multiplayer.get_remote_sender_id(),
		move_x,
		move_y,
		facing_angle,
		fire_pressed,
		hero_id,
	)


@rpc("any_peer", "reliable")
func request_self_damage(amount: int, attacker: String) -> void:
	if not is_host():
		return
	var state: Dictionary = CoopNetworkAuthorityRelayScript.apply_remote_damage(
		_authority, multiplayer.get_remote_sender_id(), amount
	)
	CoopNetworkDelegatesScript.publish_authority_state(self, multiplayer.get_remote_sender_id(), state)


@rpc("any_peer", "reliable")
func submit_claimed_player_state(
	_claimed_peer_id: int,
	_pos: Vector2,
	_facing: float,
	_hero_id: String,
	_health: float,
) -> void:
	if not is_host():
		return
	CoopNetworkAuthorityRelayScript.reject_claimed_state(
		multiplayer.get_remote_sender_id(), _claimed_peer_id, _health
	)


@rpc("authority", "call_remote", "reliable")
func sync_player_state(peer_id: int, pos: Vector2, facing: float, hero_id: String, health: float) -> void:
	var facing_vec := CoopNetworkAuthorityRelayScript.facing_vector(facing)
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
	CoopNetworkDelegatesScript.broadcast_player_state(self, pos, facing, hero_id, health)


func broadcast_heat(heat: float) -> void:
	CoopNetworkDelegatesScript.broadcast_heat(self, heat)


func _start_enet_server() -> Error:
	_enet_peer = CoopNetworkTransportScript.create_server()
	if _enet_peer == null:
		return ERR_CANT_CREATE
	multiplayer.multiplayer_peer = _enet_peer
	return OK


func _start_enet_client(address: String) -> Error:
	_enet_peer = CoopNetworkTransportScript.create_client(address)
	if _enet_peer == null:
		return ERR_CANT_CONNECT
	multiplayer.multiplayer_peer = _enet_peer
	return OK


func _send_beacon() -> void:
	CoopNetworkDelegatesScript.send_beacon(self)


func _enrich_and_emit(session: Dictionary) -> void:
	var enriched := CoopNetworkTransportScript.enrich_session(session)
	if enriched.is_empty():
		return
	nearby_session_found.emit(enriched)


func _on_mobile_ip_caught(ip: String) -> void:
	CoopNetworkDelegatesScript.on_mobile_ip_caught(self, ip)


func _on_m2m_sessions_updated(sessions: Array) -> void:
	CoopNetworkDelegatesScript.on_m2m_sessions_updated(self, sessions)


func _on_proximity_match(session: Dictionary) -> void:
	nearby_session_found.emit(session)


func _on_bluetooth_session(session: Dictionary) -> void:
	_enrich_and_emit(session)


func _on_peer_connected(id: int) -> void:
	CoopNetworkDelegatesScript.on_peer_connected(self, id)


func _on_peer_disconnected(id: int) -> void:
	CoopNetworkDelegatesScript.on_peer_disconnected(self, id)


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
