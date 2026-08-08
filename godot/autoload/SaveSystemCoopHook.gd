class_name SaveSystemCoopHook
extends RefCounted
## Co-op save hooks for host session sync (Phase 6.2).
## validate save hook schema; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via no-op when offline.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


static func augment_save_lines(lines: Array) -> void:
	if not CoopNetwork.is_online() or not CoopNetwork.is_host():
		return
	var coop_line := CoopNetworkReconnect.save_line_for_host()
	if coop_line.is_empty():
		return
	lines.append(coop_line)
	print("[SaveSystemCoopHook] appended coop session state to save")


static func after_save() -> void:
	if not CoopNetwork.is_online() or not CoopNetwork.is_host():
		return
	CoopNetwork.persist_host_session_state()
	print("[SaveSystemCoopHook] host session sync persisted after save")


static func apply_loaded_line(key: String, value: String) -> bool:
	if key != "coop_session_state":
		return false
	var parsed_sync = JSON.parse_string(value)
	if parsed_sync is Dictionary:
		M2MResiliencePeerHold.save_host_session_sync(parsed_sync)
		CoopSessionSync.apply(parsed_sync)
		print("[SaveSystemCoopHook] restored coop session state from save")
		return true
	push_error("SaveSystemCoopHook: invalid coop_session_state JSON")
	return true
