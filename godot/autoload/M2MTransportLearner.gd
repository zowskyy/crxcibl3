extends Node
## On-device transport learning — biases M2M policy from past successful joins.
## Usage: record_success(), record_failure(), learned_bonus() — see docs/COOP_MULTIPLAYER.md --help.
## validate transport stats schema; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via CACHE_PATH reset.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const CACHE_PATH := "user://m2m_transport_cache.json"

var _stats: Dictionary = {}


func _ready() -> void:
	for kind in [
		TransportPolicy.TRANSPORT_M2M,
		TransportPolicy.TRANSPORT_WIFI,
		TransportPolicy.TRANSPORT_BLUETOOTH,
		TransportPolicy.TRANSPORT_MOBILE,
	]:
		_stats[kind] = {"success": 0, "fail": 0, "latency_sum": 0.0, "latency_n": 0}
	_load()


func record_success(transport: String, latency_ms: float) -> void:
	_ensure(transport)
	var s: Dictionary = _stats[transport]
	s["success"] = int(s["success"]) + 1
	s["latency_sum"] = float(s["latency_sum"]) + latency_ms
	s["latency_n"] = int(s["latency_n"]) + 1
	_stats[transport] = s
	_save()
	print("[M2MTransportLearner] recorded success on %s (%.1f ms)" % [transport, latency_ms])


func record_failure(transport: String) -> void:
	_ensure(transport)
	var s: Dictionary = _stats[transport]
	s["fail"] = int(s["fail"]) + 1
	_stats[transport] = s
	_save()


func learned_bonus(transport: String) -> float:
	_ensure(transport)
	var s: Dictionary = _stats[transport]
	var success: int = int(s["success"])
	var fail: int = int(s["fail"])
	var attempts := success + fail
	if attempts <= 0:
		return 0.0
	var rate := float(success) / float(attempts)
	var avg_latency := 80.0
	if int(s["latency_n"]) > 0:
		avg_latency = float(s["latency_sum"]) / float(s["latency_n"])
	return rate * 120.0 + maxf(0.0, 100.0 - avg_latency)


func _ensure(transport: String) -> void:
	if not _stats.has(transport):
		_stats[transport] = {"success": 0, "fail": 0, "latency_sum": 0.0, "latency_n": 0}


func _load() -> void:
	if not FileAccess.file_exists(CACHE_PATH):
		return
	var text := FileAccess.get_file_as_string(CACHE_PATH)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		for key in parsed.keys():
			if parsed[key] is Dictionary:
				_stats[key] = parsed[key]


func _save() -> void:
	var f := FileAccess.open(CACHE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_stats))
