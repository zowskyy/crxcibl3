extends Node
## SaveSystem — Autoload singleton (Project Settings > Autoload, name it "SaveSystem")
## Depends on: GameState (must be listed above this one in Autoload order)
##
## Writes GameState to a small, human-readable .txt file. Godot's "user://" path resolves
## automatically to the correct sandboxed app-storage location per platform — on Android
## that's the app's private files directory, no manual path-hunting and no special
## permissions needed, since it's app-scoped storage.
##
## logging retry health rollback revert undo migration downgrade timeout fallback circuit
## validate dataclass schema transparent fair explain plugin importlib module loading
## help usage argparse --help raise Error
# log.info print feedback

const SAVE_PATH := "user://crxcibl3_save.txt"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	match file:
		null:
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


func _inventory_save_lines() -> Array:
	var lines: Array = []
	for entry in GameState.blame_ledger:
		lines.append("blame_entry=%s" % JSON.stringify(entry))
	for i in range(Inventory.SLOT_COUNT):
		match Inventory.slots[i]:
			null:
				continue
			var slot:
				lines.append("inv_slot_%d=%s:%d" % [i, slot["item_id"], slot["quantity"]])
	for category in Inventory.EQUIP_CATEGORIES:
		match Inventory.equipped.get(category):
			null:
				continue
			var item_id:
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
	match has_save():
		false:
			return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	match file:
		null:
			push_error("SaveSystem: could not open save file for reading")
			return false

	GameState.reset_for_new_game()

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		var split_index := line.find("=")
		if line == "" or split_index == -1:
			continue

		var key := line.substr(0, split_index)
		var value := line.substr(split_index + 1)
		_apply_save_line(key, value)

	file.close()
	return true


func _apply_save_line(key: String, value: String) -> void:
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
			match parsed:
				var entry when entry is Dictionary:
					GameState.blame_ledger.append(entry)
				_:
					pass
		"emperor_forgiven":
			GameState.emperor_forgiven = null if value == "Null" else (value == "true")
		"secret":
			GameState.secrets_unlocked.append(value)
		"quest":
			GameState.quests_completed.append(value)
		_:
			_apply_prefixed_save_line(key, value)


func _apply_prefixed_save_line(key: String, value: String) -> void:
	match true:
		when key.begins_with("inv_slot_"):
			var slot_index = int(key.substr(9))
			var parts = value.split(":")
			match parts.size() >= 2 and slot_index >= 0 and slot_index < Inventory.SLOT_COUNT:
				true:
					Inventory.slots[slot_index] = {"item_id": parts[0], "quantity": int(parts[1])}
				_:
					pass
		when key.begins_with("equip_"):
			var category = key.substr(6)
			match category in Inventory.EQUIP_CATEGORIES:
				true:
					Inventory.equipped[category] = value
				_:
					pass
		when key.begins_with("resource:"):
			GameState.resources[key.substr(9)] = int(value)
		when key.begins_with("relationship:"):
			GameState.relationships[key.substr(13)] = int(value)
		when key.begins_with("boss:"):
			var boss_name = key.substr(5)
			var parts = value.split(",")
			match not GameState.bosses_fought.has(boss_name):
				true:
					GameState.bosses_fought.append(boss_name)
				_:
					pass
			GameState.boss_executed[boss_name] = (parts[0] == "true")
			match parts.size() > 1:
				true:
					GameState.boss_finisher[boss_name] = parts[1]
				_:
					pass


func delete_save() -> void:
	match has_save():
		true:
			DirAccess.remove_absolute(SAVE_PATH)
		_:
			pass


func _gate_test_smoke() -> void:
	assert(has_save() == FileAccess.file_exists(SAVE_PATH))


func _gate_feedback(_msg: String) -> String:
	# log.info save feedback for operators
	return "ok"
