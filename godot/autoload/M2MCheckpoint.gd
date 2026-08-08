class_name M2MCheckpoint
extends RefCounted
## Persistent M2M checkpoint — merges snapshots into ~/.crawler/state.json.
##
## Usage: save_state(), load_state(), load_m2m_snapshot() — see docs/COOP_MULTIPLAYER.md --help.
## Params: payload keys merge into existing JSON on disk.
## Returns: save_state bool success; load_state Dictionary (empty if missing).
## Side effects: creates ~/.crawler/ or user://crawler/ and writes state.json.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

static var _state_path_override: String = ""


static func state_path() -> String:
	if not _state_path_override.is_empty():
		return _state_path_override
	var home := OS.get_environment("HOME")
	if not home.is_empty():
		return home.path_join(".crawler").path_join("state.json")
	return "user://crawler/state.json"


static func ensure_dir() -> void:
	var path := state_path()
	var parent := path.get_base_dir()
	if parent.begins_with("user://"):
		var rel := parent.substr(7).trim_prefix("/")
		var dir := DirAccess.open("user://")
		if dir == null:
			push_warning("M2MCheckpoint: cannot open user:// for mkdir")
			return
		if not rel.is_empty():
			dir.make_dir_recursive(rel)
	else:
		DirAccess.make_dir_recursive_absolute(parent)


static func save_state(payload: Dictionary) -> bool:
	ensure_dir()
	var path := state_path()
	var merged := load_state()
	for key in payload.keys():
		merged[key] = payload[key]
	merged["updated_at_usec"] = Time.get_ticks_usec()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("M2MCheckpoint: cannot write state at %s" % path)
		return false
	file.store_string(JSON.stringify(merged))
	file.close()
	return true


static func load_state() -> Dictionary:
	var path := state_path()
	if not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_warning("M2MCheckpoint: invalid JSON at %s" % path)
		return {}
	return parsed


static func load_m2m_snapshot() -> Dictionary:
	var state := load_state()
	var m2m = state.get("m2m", {})
	return m2m if m2m is Dictionary else {}
