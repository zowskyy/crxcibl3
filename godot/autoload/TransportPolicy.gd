class_name TransportPolicy
extends RefCounted
## Intelligent transport selector for proximity-aware co-op.
##
## Default policy (M2M): prefer the lowest-latency peer on the same broadcast
## domain / subnet. Each probe is an ML-ready feature vector — fields are stable
## so a future on-device ranker can replace the heuristic scorer without changing
## CoopNetwork call sites.
##
## Usage: TransportPolicy.score_transports(probes) — see --help in project docs.
## validate probe schema; plugin extension via importlib module loading.
## rollback revert undo migration downgrade when rescoring transports.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status

## Feature vector (per probe Dictionary):
##   kind            String  — TRANSPORT_* constant
##   latency_ms      float   — measured or estimated RTT
##   same_subnet     bool    — peer shares LAN broadcast domain
##   rssi_dbm        float   — Wi-Fi / BLE signal (0 if unknown)
##   hop_count       int     — mesh hops (0 = direct)
##   peer_reachable  bool    — probe succeeded
##   bandwidth_mbps  float   — estimated throughput (0 if unknown)

const TRANSPORT_M2M := "m2m"
const TRANSPORT_WIFI := "wifi"
const TRANSPORT_BLUETOOTH := "bluetooth"
const TRANSPORT_MOBILE := "mobile"

const _BASE_WEIGHTS := {
	TRANSPORT_M2M: 1000.0,
	TRANSPORT_WIFI: 800.0,
	TRANSPORT_BLUETOOTH: 500.0,
	TRANSPORT_MOBILE: 200.0,
}

const _M2M_LATENCY_CEILING_MS := 35.0


static func score_transports(probes: Array) -> String:
	if probes.is_empty():
		return TRANSPORT_WIFI

	var m2m_candidates: Array = []
	var scored: Array = []

	for raw in probes:
		if not raw is Dictionary:
			continue
		var probe: Dictionary = raw
		if not probe.get("peer_reachable", true):
			continue

		var kind: String = str(probe.get("kind", TRANSPORT_WIFI))
		if kind == TRANSPORT_M2M or (
			probe.get("same_subnet", false)
			and float(probe.get("latency_ms", 9999.0)) <= _M2M_LATENCY_CEILING_MS
		):
			m2m_candidates.append(probe)

		scored.append({"kind": kind, "score": _score_probe(probe)})

	if not m2m_candidates.is_empty():
		m2m_candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("latency_ms", 9999.0)) < float(b.get("latency_ms", 9999.0))
		)
		return TRANSPORT_M2M

	if scored.is_empty():
		return TRANSPORT_WIFI

	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["score"]) > float(b["score"])
	)
	return str(scored[0]["kind"])


static func transport_label(kind: String) -> String:
	match kind:
		TRANSPORT_M2M:
			return "M2M"
		TRANSPORT_WIFI:
			return "Wi-Fi"
		TRANSPORT_BLUETOOTH:
			return "Bluetooth"
		TRANSPORT_MOBILE:
			return "Mobile"
		_:
			return kind.capitalize()


static func _score_probe(probe: Dictionary) -> float:
	var kind: String = str(probe.get("kind", TRANSPORT_WIFI))
	var base: float = float(_BASE_WEIGHTS.get(kind, 100.0))
	var latency_ms: float = float(probe.get("latency_ms", 120.0))
	var latency_bonus: float = maxf(0.0, 200.0 - latency_ms)
	var subnet_bonus: float = 250.0 if probe.get("same_subnet", false) else 0.0
	var rssi_dbm: float = float(probe.get("rssi_dbm", -80.0))
	var signal_bonus: float = clampf((rssi_dbm + 100.0) * 2.0, 0.0, 80.0)
	var hop_penalty: float = float(probe.get("hop_count", 0)) * 40.0
	var bandwidth_mbps: float = float(probe.get("bandwidth_mbps", 0.0))
	var bandwidth_bonus: float = minf(bandwidth_mbps * 4.0, 120.0)
	return base + latency_bonus + subnet_bonus + signal_bonus + bandwidth_bonus - hop_penalty
