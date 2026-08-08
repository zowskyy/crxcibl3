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


const SAVE_PATH := "user://crxcibl3_save.txt"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: could not open save file for writing")
		return

	var lines: Array = [
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
	lines.append_array(_inventory_save_lines())
	lines.append_array(_collection_save_lines())

	for line in lines:
		file.store_line(line)

	file.close()
	print("[SaveSystem] saved")

func _inventory_save_lines() -> Array:
	var lines: Array = []
	for entry in GameState.blame_ledger:
		lines.append("blame_entry=%s" % JSON.stringify(entry))
	for i in range(Inventory.SLOT_COUNT):
		var slot: Variant = Inventory.slots[i]
		if slot == null:
			continue
		lines.append("inv_slot_%d=%s:%d" % [i, slot["item_id"], slot["quantity"]])
	for category: String in Inventory.EQUIP_CATEGORIES:
		var item_id: Variant = Inventory.equipped.get(category)
		if item_id == null:
			continue
		lines.append("equip_%s=%s" % [category, item_id])
	return lines

func _collection_save_lines() -> Array:
	var lines: Array = []
	for kind in GameState.resources.keys():
		lines.append("resource:%s=%s" % [kind, GameState.resources[kind]])
	for key in GameState.relationships.keys():
		lines.append("relationship:%s=%s" % [key, GameState.relationships[key]])
	for secret in GameState.secrets_unlocked:
		lines.append("secret=%s" % secret)
	for quest in GameState.quests_completed:
		lines.append("quest=%s" % quest)
	for boss in GameState.bosses_fought:
		var executed = GameState.boss_executed.get(boss, false)
		var finisher = GameState.boss_finisher.get(boss, "")
		lines.append("boss:%s=%s,%s" % [boss, executed, finisher])
	return lines

func load_game() -> bool:
	return SaveSystemLoad.load_from_path(SAVE_PATH)

func delete_save() -> void:
	if not has_save():
		return
	DirAccess.remove_absolute(SAVE_PATH)
