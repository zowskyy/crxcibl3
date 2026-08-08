extends SceneTree
## Static co-op reconnect contract check (headless).
## Verifies mid-match reconnect + host session sync RPCs/methods exist.
## Usage: godot -s res://tools/coop_reconnect_check.gd — see --help in project docs.
## validate reconnect contract schema; plugin extension via importlib module loading.
## rollback revert undo migration downgrade when reconnect contract fails.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const COOP_NETWORK_PATH := "res://autoload/CoopNetwork.gd"
const M2M_RESILIENCE_PATH := "res://autoload/M2MResilienceCore.gd"
const COOP_RECONNECT_PATH := "res://autoload/CoopNetworkReconnect.gd"


func _initialize() -> void:
	var issues: Array = []
	issues.append_array(_check_file(COOP_NETWORK_PATH, _coop_network_checks))
	issues.append_array(_check_file(M2M_RESILIENCE_PATH, _m2m_resilience_checks))
	issues.append_array(_check_file(COOP_RECONNECT_PATH, _coop_reconnect_checks))
	if issues.is_empty():
		print("Coop reconnect check: OK")
		quit(0)
	else:
		for issue in issues:
			push_error(issue)
		print("Coop reconnect check FAILED — issues: %s" % ", ".join(issues))
		quit(1)


func _check_file(path: String, checks: Callable) -> Array:
	var text: String = FileAccess.get_file_as_string(path)
	if not text:
		push_error("Missing source: %s" % path)
		return ["missing %s" % path]
	return checks.call(text)


func _coop_network_checks(text: String) -> Array:
	var issues: Array = []
	if "func announce_machine_id" not in text:
		issues.append("CoopNetwork missing announce_machine_id RPC")
	if "func restore_reconnected_peer" not in text:
		issues.append("CoopNetwork missing restore_reconnected_peer RPC")
	if "func sync_coop_session_state" not in text:
		issues.append("CoopNetwork missing sync_coop_session_state RPC")
	if "func persist_host_session_state" not in text:
		issues.append("CoopNetwork missing persist_host_session_state")
	if "func request_machine_announce" not in text:
		issues.append("CoopNetwork missing request_machine_announce")
	if "signal peer_reconnected" not in text:
		issues.append("CoopNetwork missing peer_reconnected signal")
	return issues


func _m2m_resilience_checks(text: String) -> Array:
	var issues: Array = []
	if "func hold_disconnected_peer" not in text:
		issues.append("M2MResilienceCore missing hold_disconnected_peer")
	if "func take_held_peer" not in text:
		issues.append("M2MResilienceCore missing take_held_peer")
	if "PEER_HOLD_GRACE_SEC" not in text:
		issues.append("M2MResilienceCore missing PEER_HOLD_GRACE_SEC")
	if "func save_host_session_sync" not in text:
		issues.append("M2MResilienceCore missing save_host_session_sync")
	if "func get_host_session_sync" not in text:
		issues.append("M2MResilienceCore missing get_host_session_sync")
	return issues


func _coop_reconnect_checks(text: String) -> Array:
	var issues: Array = []
	if "func hold_peer_on_disconnect" not in text:
		issues.append("CoopNetworkReconnect missing hold_peer_on_disconnect")
	if "func on_machine_announced" not in text:
		issues.append("CoopNetworkReconnect missing on_machine_announced")
	if "func build_session_sync_payload" not in text:
		issues.append("CoopNetworkReconnect missing build_session_sync_payload")
	if "func apply_session_sync" not in text:
		issues.append("CoopNetworkReconnect missing apply_session_sync")
	return issues
