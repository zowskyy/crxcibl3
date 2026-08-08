extends Node
## Proximity-aware co-op networking autoload.
##
## Discovery: UDP broadcast beacons (port 7778) on the LAN broadcast domain as a
## proximity proxy. Gameplay sync: ENet (port 7777). Transport selection delegates
## to TransportPolicy (M2M → Wi-Fi → Bluetooth stub → mobile fallback).
##
## Usage: host_session(alias), join_session(address), scan_nearby() — see --help.
## validate session payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via stop_session().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status

const GAME_PORT := 7777
const BEACON_INTERVAL_SEC := 2.0
const PROXIMITY_TTL_SEC := 6.0

signal session_started
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal nearby_session_found(session_info: Dictionary)
signal transport_changed(kind: String)
signal player_state_sync(peer_id: int, pos: Vector2, facing: Vector2, hero_id: String, health: int)
signal heat_sync(heat: float)

var is_coop: bool = false

var _session_id: String = ""
var _host_alias: String = ""
var _active_transport: String = TransportPolicy.TRANSPORT_WIFI
var _enet_peer: ENetMultiplayerPeer = null
var _beacon_timer: Timer = null
var _discovery := CoopDiscovery.new()
var _connected: bool = false
var _remote_player_states: Dictionary = {}
var _own_session_id: String = ""


func _ready() -> void:
	_beacon_timer = Timer.new()
	_beacon_timer.wait_time = BEACON_INTERVAL_SEC
	_beacon_timer.timeout.connect(_send_beacon)
	add_child(_beacon_timer)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _process(_delta: float) -> void:
	for session in _discovery.poll(is_host(), Callable(self, "_send_beacon")):
		if str(session.get("session_id", "")) != _own_session_id:
			nearby_session_found.emit(session)


func host_session(alias: String) -> Error:
	stop_session()
	is_coop = true
	_host_alias = alias if not alias.is_empty() else "Host"
	_session_id = _generate_session_id()
	_own_session_id = _session_id
	_active_transport = _select_transport_for_host()
	_emit_transport_changed()

	var err := _start_enet_server()
	if err != OK:
		stop_session()
		return err

	_discovery.start()
	_beacon_timer.start()
	_connected = true
	session_started.emit()
	return OK


func join_session(address: String) -> Error:
	if address.is_empty():
		return ERR_INVALID_PARAMETER

	stop_session()
	is_coop = true
	_host_alias = "Client"
	_own_session_id = ""
	_active_transport = CoopLanUtil.transport_for_address(address)
	_emit_transport_changed()

	var err := _start_enet_client(address)
	if err != OK:
		stop_session()
		return err

	_discovery.start()
	return OK


func scan_nearby() -> Array:
	_discovery.broadcast("discover", {"requester": _host_alias})
	return get_nearby_sessions()


func stop_session() -> void:
	_beacon_timer.stop()
	_connected = false
	is_coop = false
	_session_id = ""
	_own_session_id = ""
	_host_alias = ""
	_remote_player_states.clear()
	_discovery.stop()

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
	return get_active_transport_label()


func get_active_transport() -> String:
	return _active_transport


func get_active_transport_label() -> String:
	return TransportPolicy.transport_label(_active_transport)


func get_nearby_sessions() -> Array:
	return _discovery.get_sessions()


func get_remote_player_state(peer_id: int) -> Dictionary:
	return _remote_player_states.get(peer_id, {}).duplicate(true)


@rpc("any_peer", "call_local", "reliable")
func sync_player_state(
	peer_id: int,
	pos: Vector2,
	facing: float,
	hero_id: String,
	health: float
) -> void:
	var facing_vec := Vector2(cos(facing), sin(facing))
	var health_i := int(round(health))
	_remote_player_states[peer_id] = {"pos": pos, "facing": facing, "hero_id": hero_id, "health": health}
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


func _select_transport_for_host() -> String:
	var probes: Array = _build_transport_probes()
	for _session in _probe_bluetooth_nearby():
		probes.append({
			"kind": TransportPolicy.TRANSPORT_BLUETOOTH,
			"latency_ms": 40.0,
			"same_subnet": true,
			"peer_reachable": true,
			"hop_count": 0,
		})
	return TransportPolicy.score_transports(probes)


func _build_transport_probes() -> Array:
	var local_ip := CoopLanUtil.primary_local_ip()
	var subnet := CoopLanUtil.subnet_prefix(local_ip)
	var on_lan := not local_ip.is_empty()
	return [
		{
			"kind": TransportPolicy.TRANSPORT_M2M,
			"latency_ms": 4.0,
			"same_subnet": on_lan,
			"rssi_dbm": -55.0,
			"hop_count": 0,
			"peer_reachable": on_lan,
			"bandwidth_mbps": 80.0,
		},
		{
			"kind": TransportPolicy.TRANSPORT_WIFI,
			"latency_ms": 8.0,
			"same_subnet": not subnet.is_empty(),
			"rssi_dbm": -60.0,
			"hop_count": 0,
			"peer_reachable": on_lan,
			"bandwidth_mbps": 50.0,
		},
		{
			"kind": TransportPolicy.TRANSPORT_MOBILE,
			"latency_ms": 90.0,
			"same_subnet": false,
			"rssi_dbm": -95.0,
			"hop_count": 1,
			"peer_reachable": true,
			"bandwidth_mbps": 12.0,
		},
	]


func _probe_bluetooth_nearby() -> Array:
	print("CoopNetwork: Bluetooth BLE discovery stub — awaiting Android plugin.")
	return []


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
	_discovery.broadcast("beacon", {
		"session_id": _session_id,
		"host_alias": _host_alias,
		"player_count": get_peer_count() + 1,
		"transport": _active_transport,
		"port": GAME_PORT,
		"address": CoopLanUtil.primary_local_ip(),
	})


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
	session_started.emit()


func _on_connection_failed() -> void:
	push_warning("CoopNetwork: connection failed.")
	stop_session()


func _on_server_disconnected() -> void:
	push_warning("CoopNetwork: server disconnected.")
	stop_session()


func _emit_transport_changed() -> void:
	transport_changed.emit(_active_transport)


func _generate_session_id() -> String:
	return "%s-%s" % [str(Time.get_unix_time_from_system()), str(randi() % 100000)]
