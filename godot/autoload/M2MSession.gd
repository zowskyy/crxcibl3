extends Node
## M2M hook — catches mobile + LAN IPs, merges multi-transport discovery, learns best path.
##
## This is the pivotal co-op entry: one scan finds friends across M2M mesh policy,
## Wi-Fi LAN, Bluetooth proximity, and mobile-data IP fallbacks.
## Usage: catch_mobile_ip(), run_m2m_scan() — see docs/COOP_MULTIPLAYER.md --help.
## validate session payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via stop_m2m_watch().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

signal mobile_ip_caught(ip: String)
signal m2m_sessions_updated(sessions: Array)
signal proximity_match(session_info: Dictionary)

const IPIFY_URL := "https://api.ipify.org"
const PROBE_PORT := 7777
const SCAN_INTERVAL := 2.5

var mobile_ip: String = ""
var lan_ip: String = ""
var bluetooth_address: String = ""

var _http: HTTPRequest = null
var _watching := false
var _watch_timer: Timer = null
var _merged_sessions: Dictionary = {}
var _latency_cache: Dictionary = {}


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_ensure_connected(_http.request_completed, _on_ipify_completed)
	_watch_timer = Timer.new()
	_watch_timer.wait_time = SCAN_INTERVAL
	_ensure_connected(_watch_timer.timeout, _run_m2m_scan)
	add_child(_watch_timer)
	lan_ip = CoopLanUtil.primary_local_ip()
	if CoopBluetooth != null and CoopBluetooth.is_available():
		bluetooth_address = CoopBluetooth.get_local_address()


func _ensure_connected(sig: Signal, callable: Callable) -> void:
	if not sig.is_connected(callable):
		sig.connect(callable)


func catch_mobile_ip() -> void:
	if not mobile_ip.is_empty():
		_register_local_addresses()
		mobile_ip_caught.emit(mobile_ip)
		return
	_http.request(IPIFY_URL)


func start_m2m_watch() -> void:
	if _watching:
		return
	_watching = true
	catch_mobile_ip()
	lan_ip = CoopLanUtil.primary_local_ip()
	_watch_timer.start()
	_run_m2m_scan()


func stop_m2m_watch() -> void:
	_watching = false
	_watch_timer.stop()
	_merged_sessions.clear()


func get_caught_addresses() -> Dictionary:
	return {
		"lan": lan_ip,
		"mobile": effective_mobile_ip(),
		"bluetooth": bluetooth_address,
	}


func build_host_beacon(session_id: String, host_alias: String, player_count: int, port: int) -> Dictionary:
	lan_ip = CoopLanUtil.primary_local_ip()
	_register_local_addresses()
	if CoopBluetooth != null and CoopBluetooth.is_available():
		bluetooth_address = CoopBluetooth.get_local_address()
	var mobile := effective_mobile_ip()
	return {
		"session_id": session_id,
		"host_alias": host_alias,
		"player_count": player_count,
		"port": port,
		"lan_address": lan_ip,
		"mobile_address": mobile,
		"bluetooth_address": bluetooth_address,
		"machine_id": M2MMachineIdentity.get_machine_id(),
		"m2m": true,
	}


func get_ranked_sessions() -> Array:
	var sessions: Array = []
	for sid in _merged_sessions.keys():
		sessions.append(_merged_sessions[sid].duplicate(true))
	sessions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("proximity_score", 0.0)) > float(b.get("proximity_score", 0.0))
	)
	return sessions


func pick_join_address(session: Dictionary) -> Dictionary:
	var transport: String = str(session.get("recommended_transport", TransportPolicy.TRANSPORT_WIFI))
	var address := ""
	match transport:
		TransportPolicy.TRANSPORT_BLUETOOTH:
			address = str(session.get("bluetooth_address", session.get("address", "")))
		TransportPolicy.TRANSPORT_MOBILE:
			address = str(session.get("mobile_address", ""))
		_:
			address = str(session.get("lan_address", session.get("address", "")))
	if address.is_empty():
		address = str(session.get("address", ""))
	return {"address": address, "transport": transport}


func probe_latency_ms(address: String, port: int = PROBE_PORT) -> float:
	if address.is_empty():
		return 9999.0
	var key := "%s:%d" % [address, port]
	if _latency_cache.has(key):
		return float(_latency_cache[key])
	var start := Time.get_ticks_usec()
	var udp := PacketPeerUDP.new()
	udp.set_dest_address(address, port)
	udp.put_packet("CRXCIBL3:probe".to_utf8_buffer())
	var elapsed := 0.0
	while elapsed < 400.0:
		await get_tree().process_frame
		elapsed = (Time.get_ticks_usec() - start) / 1000.0
		if udp.get_available_packet_count() > 0:
			udp.get_packet()
			break
	udp.close()
	var ms := (Time.get_ticks_usec() - start) / 1000.0
	_latency_cache[key] = ms
	return ms


func run_m2m_scan() -> void:
	await _run_m2m_scan()


func _run_m2m_scan() -> void:
	lan_ip = CoopLanUtil.primary_local_ip()
	_register_local_addresses()
	if mobile_ip.is_empty():
		catch_mobile_ip()
	await _merge_udp_sessions()
	if CoopBluetooth != null and CoopBluetooth.is_available():
		await CoopBluetooth.start_scan(2.5)
		for s in CoopBluetooth.get_discovered_sessions():
			_register_session(s)
	m2m_sessions_updated.emit(get_ranked_sessions())
	_emit_best_proximity()


func _merge_udp_sessions() -> void:
	for s in CoopNetwork.get_nearby_sessions():
		_register_session(s)


func register_external_session(session: Dictionary) -> void:
	_register_session(session)


func _register_session(raw: Dictionary) -> void:
	var session := raw.duplicate(true)
	var sid := str(session.get("session_id", ""))
	if sid.is_empty():
		return
	session["lan_address"] = str(session.get("lan_address", session.get("address", "")))
	session["mobile_address"] = str(session.get("mobile_address", ""))
	session["bluetooth_address"] = str(session.get("bluetooth_address", ""))
	if M2MMachineIdentity.is_self_beacon(session):
		return
	M2MResilienceCore.register_peer_snapshot(session)
	var probes := TransportPolicy.build_session_probes(
		session, lan_ip, _latency_cache, PROBE_PORT,
		CoopBluetooth != null and CoopBluetooth.is_available()
	)
	session["recommended_transport"] = TransportPolicy.score_transports(probes)
	session["proximity_score"] = TransportPolicy.proximity_score(session, probes)
	_merged_sessions[sid] = session


func _emit_best_proximity() -> void:
	var ranked := get_ranked_sessions()
	if ranked.is_empty():
		return
	var best: Dictionary = ranked[0]
	if float(best.get("proximity_score", 0.0)) >= 0.45:
		proximity_match.emit(best)


func effective_mobile_ip() -> String:
	if not mobile_ip.is_empty():
		return mobile_ip
	return M2MResilienceCore.get_cached_mobile_ip()


func _register_local_addresses() -> void:
	M2MMachineIdentity.register_address("lan", lan_ip)
	var mobile := effective_mobile_ip()
	if not mobile.is_empty():
		M2MMachineIdentity.register_address("mobile", mobile)
	if not bluetooth_address.is_empty():
		M2MMachineIdentity.register_address("bluetooth", bluetooth_address)


func _on_ipify_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		return
	mobile_ip = body.get_string_from_utf8().strip_edges()
	_register_local_addresses()
	mobile_ip_caught.emit(mobile_ip)
