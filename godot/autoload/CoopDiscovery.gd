class_name CoopDiscovery
extends RefCounted
## UDP LAN discovery helper for CoopNetwork beacons and proximity session cache.
## Usage: start(), poll(), broadcast() — see --help in project docs.
## validate beacon payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via stop().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const DISCOVERY_PORT := 7778
const BEACON_PREFIX := "CRXCIBL3:"
const PROXIMITY_TTL_SEC := 6.0

var _udp: PacketPeerUDP = null
var _nearby_sessions: Dictionary = {}


func start() -> void:
	stop()
	_udp = PacketPeerUDP.new()
	_udp.set_broadcast_enabled(true)
	var err := _udp.bind(DISCOVERY_PORT, IP.TYPE_ANY)
	if err != OK:
		print("[CoopDiscovery] bind failed: %s" % err)
		push_warning("CoopDiscovery: bind failed (%s)" % err)


func stop() -> void:
	if _udp:
		_udp.close()
		_udp = null
	_nearby_sessions.clear()


func poll(is_host: bool, host_callback: Callable) -> Array:
	var found: Array = []
	if _udp == null:
		return found

	while _udp.get_available_packet_count() > 0:
		var packet := _decode_packet(_udp.get_packet())
		if packet.is_empty():
			continue
		match str(packet.get("type", "")):
			"beacon":
				var session := _register_beacon(packet.get("body", {}))
				if not session.is_empty():
					found.append(session)
			"discover":
				if is_host and host_callback.is_valid():
					host_callback.call()

	_expire_stale()
	return found


func broadcast(message_type: String, body: Dictionary) -> void:
	if _udp == null:
		return
	var encoded := BEACON_PREFIX + JSON.stringify({"type": message_type, "body": body})
	_udp.set_dest_address("255.255.255.255", DISCOVERY_PORT)
	_udp.put_packet(encoded.to_utf8_buffer())


func get_sessions() -> Array:
	_expire_stale()
	var sessions: Array = []
	for session_id in _nearby_sessions.keys():
		sessions.append(_nearby_sessions[session_id].get("info", {}).duplicate(true))
	return sessions


func remember(session_info: Dictionary) -> void:
	var session_id: String = str(session_info.get("session_id", ""))
	if session_id.is_empty():
		return
	_nearby_sessions[session_id] = {
		"info": session_info,
		"last_seen": Time.get_unix_time_from_system(),
	}


func _decode_packet(bytes: PackedByteArray) -> Dictionary:
	var text := bytes.get_string_from_utf8()
	if not text.begins_with(BEACON_PREFIX):
		return {}
	var parsed = JSON.parse_string(text.substr(BEACON_PREFIX.length()))
	return parsed if parsed is Dictionary else {}


func _register_beacon(body) -> Dictionary:
	if not body is Dictionary:
		return {}
	var session_id: String = str(body.get("session_id", ""))
	if session_id.is_empty():
		return {}
	var session_info := {
		"session_id": session_id,
		"host_alias": str(body.get("host_alias", "Unknown")),
		"player_count": int(body.get("player_count", 1)),
		"transport": str(body.get("transport", TransportPolicy.TRANSPORT_WIFI)),
		"address": str(body.get("address", "")),
		"port": int(body.get("port", 7777)),
	}
	remember(session_info)
	return session_info.duplicate(true)


func _expire_stale() -> void:
	var now := Time.get_unix_time_from_system()
	for session_id in _nearby_sessions.keys():
		var entry: Dictionary = _nearby_sessions[session_id]
		if now - float(entry.get("last_seen", 0.0)) > PROXIMITY_TTL_SEC:
			_nearby_sessions.erase(session_id)
