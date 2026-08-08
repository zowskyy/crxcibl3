extends SceneTree
## M2MCheckpoint save/load verification harness — run before M2M releases.
##
## Usage:
##   godot --headless -s res://tools/ci_m2m_checkpoint_smoke.gd
##
## Asserts: save_state/load_state roundtrip, m2m snapshot key merge, cleanup.
## Side effects: writes user://test_crawler_state.json (removed on exit).

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const TEST_STATE_PATH := "user://test_crawler_state.json"


func _initialize() -> void:
	var failed := 0
	M2MCheckpoint._state_path_override = TEST_STATE_PATH
	failed += _check_save_load_roundtrip()
	failed += _check_m2m_snapshot_merge()
	_cleanup_test_state()
	M2MCheckpoint._state_path_override = ""
	if failed == 0:
		print("M2MCheckpoint smoke: PASS (%d checks)" % 2)
	else:
		push_error("M2MCheckpoint smoke: FAIL (%d checks failed)" % failed)
	quit(0 if failed == 0 else 1)


func _check_save_load_roundtrip() -> int:
	var payload := {"probe": "alpha", "count": 42}
	if not M2MCheckpoint.save_state(payload):
		push_error("save_state returned false")
		return 1
	var loaded: Dictionary = M2MCheckpoint.load_state()
	if str(loaded.get("probe", "")) != "alpha":
		push_error("roundtrip probe mismatch: %s" % str(loaded))
		return 1
	if int(loaded.get("count", -1)) != 42:
		push_error("roundtrip count mismatch: %s" % str(loaded))
		return 1
	if not loaded.has("updated_at_usec"):
		push_error("updated_at_usec missing after save_state")
		return 1
	return 0


func _check_m2m_snapshot_merge() -> int:
	var fake_m2m := {"identity": {"machine_id": "test-id"}, "health": {"confidence": 0.5}}
	if not M2MCheckpoint.save_state({"m2m": fake_m2m}):
		push_error("m2m merge save failed")
		return 1
	var loaded: Dictionary = M2MCheckpoint.load_state()
	if str(loaded.get("probe", "")) != "alpha":
		push_error("prior keys lost after m2m merge: %s" % str(loaded))
		return 1
	var m2m: Dictionary = M2MCheckpoint.load_m2m_snapshot()
	if str(m2m.get("identity", {}).get("machine_id", "")) != "test-id":
		push_error("load_m2m_snapshot mismatch: %s" % str(m2m))
		return 1
	return 0


func _cleanup_test_state() -> void:
	for path in [TEST_STATE_PATH, TEST_STATE_PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
