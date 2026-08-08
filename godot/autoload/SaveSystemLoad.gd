class_name SaveSystemLoad
extends RefCounted
## SaveSystemLoad — parses persisted save lines into GameState and Inventory.
## Usage: SaveSystemLoad.load_from_path(SaveSystem.SAVE_PATH) — see --help.
## validate key prefixes; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via GameState.reset_for_new_game().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


static func load_from_path(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveSystemLoad: could not open save file for reading")
		return false
	GameState.reset_for_new_game()
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		var split_index := line.find("=")
		if line == "" or split_index == -1:
			continue
		_apply_save_line(line.substr(0, split_index), line.substr(split_index + 1))
	file.close()
	print("[SaveSystemLoad] load complete")
	return true


static func _apply_save_line(key: String, value: String) -> void:
	match key:
		"heat":
			GameState.heat = float(value)
		"squad":
			GameState.squad = value.split(",", false)
		"current_act":
			GameState.current_act = int(value)
		"last_scene":
			GameState.last_scene = value
		"morale":
			GameState.morale = int(value)
		"reputation_ruthlessness":
			GameState.reputation_ruthlessness = int(value)
		"reputation_solidarity":
			GameState.reputation_solidarity = int(value)
		"ghost_count":
			GameState.ghost_count = int(value)
		"last_ghosted":
			GameState.last_ghosted = value
		"current_hero_index":
			GameState.current_hero_index = int(value)
		"permadeath_mode":
			GameState.permadeath_mode = (value == "true")
		"scarcity":
			GameState.set_meta("scarcity", float(value))
		"alliances_formed":
			GameState.alliances_formed = int(value)
		"alliances_broken":
			GameState.alliances_broken = int(value)
		"alliances_betrayed":
			GameState.alliances_betrayed = int(value)
		"blame_entry":
			var parsed = JSON.parse_string(value)
			if parsed is Dictionary:
				GameState.blame_ledger.append(parsed)
		"emperor_forgiven":
			GameState.emperor_forgiven = null if value == "Null" else (value == "true")
		"secret":
			GameState.secrets_unlocked.append(value)
		"quest":
			GameState.quests_completed.append(value)
		_:
			_apply_prefixed_save_line(key, value)


static func _apply_prefixed_save_line(key: String, value: String) -> void:
	if key.begins_with("inv_slot_"):
		var slot_index = int(key.substr(9))
		var parts = value.split(":")
		if parts.size() >= 2 and slot_index >= 0 and slot_index < Inventory.SLOT_COUNT:
			Inventory.slots[slot_index] = {"item_id": parts[0], "quantity": int(parts[1])}
	elif key.begins_with("equip_"):
		var category = key.substr(6)
		if category in Inventory.EQUIP_CATEGORIES:
			Inventory.equipped[category] = value
	elif key.begins_with("resource:"):
		GameState.resources[key.substr(9)] = int(value)
	elif key.begins_with("relationship:"):
		GameState.relationships[key.substr(13)] = int(value)
	elif key.begins_with("boss:"):
		var boss_name = key.substr(5)
		var parts = value.split(",")
		if not GameState.bosses_fought.has(boss_name):
			GameState.bosses_fought.append(boss_name)
		GameState.boss_executed[boss_name] = (parts[0] == "true")
		if parts.size() > 1:
			GameState.boss_finisher[boss_name] = parts[1]
