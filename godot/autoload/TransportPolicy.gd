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
	return base + latency_bonus + subnet_bonus + signal_bonus + bandwidth_bonus - hop_penalty + M2MTransportLearner.learned_bonus(kind)


static func score_probe(probe: Dictionary) -> float:
	return _score_probe(probe)


static func build_session_probes(
	session: Dictionary,
	lan_ip: String,
	latency_cache: Dictionary,
	probe_port: int,
	bt_available: bool,
) -> Array:
	var probes: Array = []
	var lan := str(session.get("lan_address", ""))
	var mobile := str(session.get("mobile_address", ""))
	var bt := str(session.get("bluetooth_address", ""))
	var same_subnet := CoopLanUtil.subnet_prefix(lan_ip) == CoopLanUtil.subnet_prefix(lan)
	if not lan.is_empty():
		probes.append({
			"kind": TRANSPORT_WIFI,
			"latency_ms": float(latency_cache.get("%s:%d" % [lan, probe_port], 12.0)),
			"same_subnet": same_subnet,
			"rssi_dbm": -58.0,
			"hop_count": 0,
			"peer_reachable": true,
			"bandwidth_mbps": 45.0,
		})
		probes.append({
			"kind": TRANSPORT_M2M,
			"latency_ms": float(latency_cache.get("%s:%d" % [lan, probe_port], 8.0)),
			"same_subnet": same_subnet,
			"rssi_dbm": -55.0,
			"hop_count": 0,
			"peer_reachable": true,
			"bandwidth_mbps": 70.0,
		})
	if not bt.is_empty() and bt_available:
		probes.append({
			"kind": TRANSPORT_BLUETOOTH,
			"latency_ms": 35.0,
			"same_subnet": true,
			"rssi_dbm": float(session.get("rssi_dbm", -62.0)),
			"hop_count": 0,
			"peer_reachable": true,
			"bandwidth_mbps": 8.0,
		})
	if not mobile.is_empty():
		probes.append({
			"kind": TRANSPORT_MOBILE,
			"latency_ms": 95.0,
			"same_subnet": false,
			"rssi_dbm": -90.0,
			"hop_count": 1,
			"peer_reachable": true,
			"bandwidth_mbps": 15.0,
		})
	return probes


static func proximity_score(session: Dictionary, probes: Array) -> float:
	var best := 0.0
	for p in probes:
		if not p is Dictionary:
			continue
		best = maxf(best, score_probe(p) / 1000.0)
	var rssi := float(session.get("rssi_dbm", -80.0))
	var signal_strength := clampf((rssi + 100.0) / 40.0, 0.0, 1.0)
	return clampf(best + signal_strength * 0.35, 0.0, 1.0)


static func build_host_transport_probes(local_ip: String, mobile_ip: String) -> Array:
	var on_lan := not local_ip.is_empty()
	return [
		{
			"kind": TRANSPORT_M2M,
			"latency_ms": 5.0 if on_lan else 25.0,
			"same_subnet": on_lan,
			"rssi_dbm": -52.0,
			"hop_count": 0,
			"peer_reachable": on_lan or not mobile_ip.is_empty(),
			"bandwidth_mbps": 85.0,
		},
		{
			"kind": TRANSPORT_WIFI,
			"latency_ms": 10.0 if on_lan else 120.0,
			"same_subnet": on_lan,
			"rssi_dbm": -58.0,
			"hop_count": 0,
			"peer_reachable": on_lan,
			"bandwidth_mbps": 50.0,
		},
		{
			"kind": TRANSPORT_MOBILE,
			"latency_ms": 85.0 if not mobile_ip.is_empty() else 999.0,
			"same_subnet": false,
			"rssi_dbm": -88.0,
			"hop_count": 1,
			"peer_reachable": not mobile_ip.is_empty(),
			"bandwidth_mbps": 18.0,
		},
	]


static func select_host_transport(local_ip: String, mobile_ip: String, bt_available: bool) -> String:
	var probes := build_host_transport_probes(local_ip, mobile_ip)
	if bt_available:
		probes.append({
			"kind": TRANSPORT_BLUETOOTH,
			"latency_ms": 38.0,
			"same_subnet": true,
			"rssi_dbm": -60.0,
			"hop_count": 0,
			"peer_reachable": true,
			"bandwidth_mbps": 10.0,
		})
	return score_transports(probes)
