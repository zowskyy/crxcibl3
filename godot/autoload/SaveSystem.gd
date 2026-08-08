extends Node
## SaveSystem — Autoload singleton (Project Settings > Autoload, name it "SaveSystem")
## Depends on: GameState (must be listed above this one in Autoload order)
##
## Writes GameState to a small, human-readable .txt file. Godot's "user://" path resolves
## automatically to the correct sandboxed app-storage location per platform — on Android
## that's the app's private files directory, no manual path-hunting and no special
## permissions needed, since it's app-scoped storage.
## Usage: save_game(), load_game(), save_snapshot() — see --help in project docs.

## validate persisted fields; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via restore_snapshot_if_needed().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


const SAVE_VERSION := 1
const SAVE_PATH := "user://crxcibl3_save.txt"
const SAVE_TEMP_PATH := "user://crxcibl3_save.tmp"
const MIN_FREE_BYTES := 8192

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func has_sufficient_storage() -> bool:
	return _has_sufficient_space()

func save_game() -> void:
	if not has_sufficient_storage():
		AndroidPlatform.log_crash(
			"save_game",
			"SaveSystem: insufficient storage for save (need %d bytes free)" % MIN_FREE_BYTES,
		)
		return

	var lines: Array = [
		"save_version=%d" % SAVE_VERSION,
		"heat=%s" % GameState.heat,
		"squad=%s" % ",".join(GameState.squad),
		"current_act=%s" % GameState.current_act,
		"last_scene=%s" % GameState.last_scene,
		"morale=%s" % GameState.morale,
		"reputation_ruthlessness=%s" % GameState.reputation_ruthlessness,
		"reputation_solidarity=%s" % GameState.reputation_solidarity,
		"ghost_count=%s" % GameState.ghost_count,
		"last_ghosted=%s" % GameState.last_ghosted,
		"current_hero_index=%s" % GameState.current_hero_index,
		"permadeath_mode=%s" % str(GameState.permadeath_mode),
		"scarcity=%s" % GameState.get_meta("scarcity", 0.0),
		"alliances_formed=%s" % GameState.alliances_formed,
		"alliances_broken=%s" % GameState.alliances_broken,
		"alliances_betrayed=%s" % GameState.alliances_betrayed,
		"emperor_forgiven=%s" % str(GameState.emperor_forgiven),
	]
	SaveSystemCoopHook.augment_save_lines(lines)
	lines.append_array(SaveSystemSerialize.inventory_lines())
	lines.append_array(SaveSystemSerialize.collection_lines())

	var payload := ""
	for line in lines:
		payload += line + "\n"

	if not _atomic_write(SAVE_TEMP_PATH, SAVE_PATH, payload):
		AndroidPlatform.log_crash("save_game", "SaveSystem: atomic write failed")
		return
	SaveSystemCoopHook.after_save()
	print("[SaveSystem] saved")

func _has_sufficient_space() -> bool:
	var dir := DirAccess.open("user://")
	if dir == null:
		return true
	var free_bytes := dir.get_space_left()
	if free_bytes < 0:
		return true
	return free_bytes >= MIN_FREE_BYTES

func _atomic_write(temp_path: String, final_path: String, content: String) -> bool:
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: could not open temp save file for writing")
		return false
	file.store_string(content)
	file.close()

	if FileAccess.file_exists(final_path):
		var remove_err := DirAccess.remove_absolute(final_path)
		if remove_err != OK:
			push_error("SaveSystem: could not remove previous save (%s)" % str(remove_err))
			DirAccess.remove_absolute(temp_path)
			return false

	var rename_err := DirAccess.rename_absolute(temp_path, final_path)
	if rename_err != OK:
		push_error("SaveSystem: rename to final save failed (%s)" % str(rename_err))
		DirAccess.remove_absolute(temp_path)
		return false
	return true

func load_game() -> bool:
	return SaveSystemLoad.load_from_path(SAVE_PATH)

func delete_save() -> void:
	if not has_save():
		return
	DirAccess.remove_absolute(SAVE_PATH)
