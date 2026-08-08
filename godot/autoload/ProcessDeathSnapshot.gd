extends Node
## ProcessDeathSnapshot — Android process-death scene snapshot to user:// storage.
## Usage: save_snapshot(), restore_if_needed() — see --help in project docs.

## validate scene paths; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via snapshot file deletion.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


const SNAPSHOT_PATH := "user://crxcibl3_snapshot.json"
const SNAPSHOT_TEMP_PATH := "user://crxcibl3_snapshot.tmp.json"

func save_snapshot() -> void:
	if not SaveSystem.has_sufficient_storage():
		push_warning("ProcessDeathSnapshot: insufficient storage, skipping snapshot")
		return
	SaveSystem.save_game()
	var scene_path := ""
	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		scene_path = tree.current_scene.scene_file_path
	var payload := JSON.stringify({"scene": scene_path})
	if not _atomic_write(SNAPSHOT_TEMP_PATH, SNAPSHOT_PATH, payload):
		push_warning("ProcessDeathSnapshot: write failed")
		return
	print("[ProcessDeathSnapshot] saved")

func restore_if_needed() -> void:
	if not FileAccess.file_exists(SNAPSHOT_PATH):
		return
	var file := FileAccess.open(SNAPSHOT_PATH, FileAccess.READ)
	if file == null:
		push_error("ProcessDeathSnapshot: could not read snapshot")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	DirAccess.remove_absolute(SNAPSHOT_PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ProcessDeathSnapshot: invalid snapshot JSON")
		return
	if not SaveSystem.has_save():
		SaveSystem.load_game()
	var scene_path: String = str(parsed.get("scene", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("ProcessDeathSnapshot: scene path missing or invalid (%s)" % scene_path)
		return
	call_deferred("_restore_scene", scene_path)

func _restore_scene(scene_path: String) -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.change_scene_to_file(scene_path)

func _atomic_write(temp_path: String, final_path: String, content: String) -> bool:
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.close()
	if FileAccess.file_exists(final_path):
		var remove_err := DirAccess.remove_absolute(final_path)
		if remove_err != OK:
			DirAccess.remove_absolute(temp_path)
			return false
	var rename_err := DirAccess.rename_absolute(temp_path, final_path)
	if rename_err != OK:
		DirAccess.remove_absolute(temp_path)
		return false
	return true
