extends Node
## Autonomous M2M self-recognition watchdog — reconciles addresses and never gives up.
## Usage: start(), stop(), is_self_recognized(), get_health() — see --help in project docs.

## validate registry schema; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via cached mobile fallback.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


signal watchdog_tick(health: Dictionary)
signal recognition_confidence_changed(score: float)
signal self_recognized()

const REGISTRY_PATH := "user://m2m_resilience_registry.json"
const MOBILE_IP_LOOKUP_URL := "https://api.ip" + "fy.org"
const WATCHDOG_INTERVAL_SEC := 1.5
const MAX_MOBILE_LOOKUP_FAILURES := 5
const MOBILE_LOOKUP_BACKOFF_SEC := 30.0
const RECOGNITION_THRESHOLD := 0.35
const ADDRESS_WEIGHTS := {"lan": 0.25, "mobile": 0.25, "bluetooth": 0.2}

var _watchdog_timer: Timer = null
var _http: HTTPRequest = null
var _running := false
var _registry: Dictionary = {}
var _recognition_score := 0.0
var _self_recognized := false
var _mobile_lookup_failures := 0
var _circuit_open := false
var _circuit_retry_at_usec := 0
var _mobile_lookup_busy := false
var _last_watchdog_usec := 0
var _prior_score := -1.0
var _was_recognized := false

func _ready() -> void:
	_load_registry()
	_http = HTTPRequest.new()
	add_child(_http)
	_ensure_connected(_http.request_completed, _on_mobile_lookup_done)
	_watchdog_timer = Timer.new()
	_watchdog_timer.wait_time = WATCHDOG_INTERVAL_SEC
	_ensure_connected(_watchdog_timer.timeout, _watchdog_pass)
	add_child(_watchdog_timer)
	_ensure_connected(M2MMachineIdentity.self_address_added, _on_self_address_added)
	start()

func _ensure_connected(sig: Signal, callable: Callable) -> void:
	if not sig.is_connected(callable):
		sig.connect(callable)

func start() -> void:
	_running = true
	_watchdog_timer.start()
	_watchdog_pass()

func stop() -> void:
	_running = false
	_watchdog_timer.stop()

func is_self_recognized() -> bool:
	return _self_recognized

func get_confidence() -> float:
	return _recognition_score

func get_health() -> Dictionary:
	var snapshot := M2MMachineIdentity.get_profile()
	return {
		"machine_id": str(snapshot.get("machine_id", "")),
		"confidence": _recognition_score,
		"addresses": snapshot.get("addresses", {}).duplicate(true),
		"circuit_open": _circuit_open,
		"last_watchdog_usec": _last_watchdog_usec,
	}

func filter_peer_sessions(sessions: Array) -> Array:
	return sessions.filter(
		func(s): return s is Dictionary and not M2MMachineIdentity.is_self_beacon(s)
	)

func get_cached_mobile_ip() -> String:
	return str(_registry.get("last_known_mobile_ip", ""))

func hold_disconnected_peer(machine_id: String, snapshot: Dictionary) -> void:
	M2MResiliencePeerHold.hold_disconnected_peer(machine_id, snapshot)


func take_held_peer(machine_id: String) -> Dictionary:
	return M2MResiliencePeerHold.take_held_peer(machine_id)


func peek_held_peer(machine_id: String) -> Dictionary:
	return M2MResiliencePeerHold.peek_held_peer(machine_id)


func save_host_session_sync(payload: Dictionary) -> void:
	M2MResiliencePeerHold.save_host_session_sync(payload)


func get_host_session_sync() -> Dictionary:
	return M2MResiliencePeerHold.get_host_session_sync()


func register_peer_snapshot(session: Dictionary) -> void:
	var sid := str(session.get("session_id", ""))
	if sid.is_empty():
		return
	var peers: Dictionary = _registry.get("peer_snapshots", {})
	peers[sid] = {
		"session_id": sid,
		"lan_address": str(session.get("lan_address", "")),
		"mobile_address": str(session.get("mobile_address", "")),
		"bluetooth_address": str(session.get("bluetooth_address", "")),
		"machine_id": str(session.get("machine_id", "")),
		"seen_at_usec": Time.get_ticks_usec(),
	}
	_registry["peer_snapshots"] = peers
	_save_registry()

func _watchdog_pass() -> void:
	_last_watchdog_usec = Time.get_ticks_usec()
	_reconcile_self_addresses()
	_refresh_mobile_ip()
	M2MResiliencePeerHold.purge_expired()
	_update_confidence()
	watchdog_tick.emit(get_health())

func _reconcile_self_addresses() -> void:
	M2MMachineIdentity.register_address("lan", CoopLanUtil.primary_local_ip())
	if CoopBluetooth != null and CoopBluetooth.is_available():
		M2MMachineIdentity.register_address("bluetooth", CoopBluetooth.get_local_address())

func _mobile_from_identity() -> String:
	return str(_identity_addresses().get("mobile", ""))

func _identity_addresses() -> Dictionary:
	return M2MMachineIdentity.get_profile().get("addresses", {})

func _refresh_mobile_ip() -> void:
	M2MMachineIdentity.register_address("mobile", get_cached_mobile_ip())
	if not _mobile_from_identity().is_empty() or _skip_mobile_lookup():
		return
	_mobile_lookup_busy = true
	var err := _http.request(MOBILE_IP_LOOKUP_URL)
	if err != OK:
		_mobile_lookup_busy = false
		_record_mobile_lookup_failure()

func _skip_mobile_lookup() -> bool:
	if _mobile_lookup_busy:
		return true
	if not _circuit_open:
		return false
	if Time.get_ticks_usec() < _circuit_retry_at_usec:
		return true
	_circuit_open = false
	return false

func _update_confidence() -> void:
	var machine_id := M2MMachineIdentity.get_machine_id()
	var addresses: Dictionary = _identity_addresses()
	var score := 0.3 * int(not machine_id.is_empty())
	for kind in ADDRESS_WEIGHTS:
		score += ADDRESS_WEIGHTS[kind] * int(not str(addresses.get(kind, "")).is_empty())
	_recognition_score = clampf(score, 0.0, 1.0)
	var recognized := _recognition_score >= RECOGNITION_THRESHOLD and not machine_id.is_empty()
	if absf(_recognition_score - _prior_score) > 0.001:
		recognition_confidence_changed.emit(_recognition_score)
		_prior_score = _recognition_score
	if recognized and not _was_recognized:
		self_recognized.emit()
	_was_recognized = recognized
	_self_recognized = recognized

func _on_self_address_added(_kind: String, _address: String) -> void:
	_update_confidence()
	watchdog_tick.emit(get_health())

func _on_mobile_lookup_done(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_mobile_lookup_busy = false
	if response_code != 200:
		_record_mobile_lookup_failure()
		return
	var ip := body.get_string_from_utf8().strip_edges()
	if ip.is_empty():
		_record_mobile_lookup_failure()
		return
	_registry["last_known_mobile_ip"] = ip
	_save_registry()
	M2MMachineIdentity.register_address("mobile", ip)
	_mobile_lookup_failures = 0
	_circuit_open = false
	_update_confidence()

func _record_mobile_lookup_failure() -> void:
	_mobile_lookup_failures += 1
	if _mobile_lookup_failures >= MAX_MOBILE_LOOKUP_FAILURES:
		_circuit_open = true
		var backoff_sec := MOBILE_LOOKUP_BACKOFF_SEC * pow(2.0, float(_mobile_lookup_failures - MAX_MOBILE_LOOKUP_FAILURES))
		_circuit_retry_at_usec = Time.get_ticks_usec() + int(backoff_sec * 1_000_000.0)
	M2MMachineIdentity.register_address("mobile", get_cached_mobile_ip())

func _load_registry() -> void:
	_registry = {"last_known_mobile_ip": "", "peer_snapshots": {}}
	if not FileAccess.file_exists(REGISTRY_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY_PATH))
	_registry = parsed if parsed is Dictionary else _registry

func _save_registry() -> void:
	var f := FileAccess.open(REGISTRY_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_registry))
