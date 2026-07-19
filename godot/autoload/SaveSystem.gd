extends Node
## SaveSystem — Autoload singleton (Project Settings > Autoload, name it "SaveSystem")
## Depends on: GameState (must be listed above this one in Autoload order)
##
## Writes GameState to a small, human-readable .txt file. Godot's "user://" path resolves
## automatically to the correct sandboxed app-storage location per platform — on Android
## that's the app's private files directory, no manual path-hunting and no special
## permissions needed, since it's app-scoped storage.

const SAVE_PATH := "user://crxcibl3_save.txt"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: could not open save file for writing")
		return

	file.store_line("heat=%s" % GameState.heat)
	file.store_line("squad=%s" % ",".join(GameState.squad))
	file.store_line("current_act=%s" % GameState.current_act)
	file.store_line("last_scene=%s" % GameState.last_scene)
	file.store_line("morale=%s" % GameState.morale)
	file.store_line("reputation_ruthlessness=%s" % GameState.reputation_ruthlessness)
	file.store_line("reputation_solidarity=%s" % GameState.reputation_solidarity)
	file.store_line("ghost_count=%s" % GameState.ghost_count)
	file.store_line("last_ghosted=%s" % GameState.last_ghosted)

	for kind in GameState.resources.keys():
		file.store_line("resource:%s=%s" % [kind, GameState.resources[kind]])

	for key in GameState.relationships.keys():
		file.store_line("relationship:%s=%s" % [key, GameState.relationships[key]])

	for secret in GameState.secrets_unlocked:
		file.store_line("secret=%s" % secret)

	for quest in GameState.quests_completed:
		file.store_line("quest=%s" % quest)

	for boss in GameState.bosses_fought:
		var executed = GameState.boss_executed.get(boss, false)
		var finisher = GameState.boss_finisher.get(boss, "")
		file.store_line("boss:%s=%s,%s" % [boss, executed, finisher])

	file.store_line("emperor_forgiven=%s" % str(GameState.emperor_forgiven))

	file.close()


func load_game() -> bool:
	if not has_save():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: could not open save file for reading")
		return false

	GameState.reset_for_new_game()

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "":
			continue

		var split_index := line.find("=")
		if split_index == -1:
			continue

		var key := line.substr(0, split_index)
		var value := line.substr(split_index + 1)

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
			"emperor_forgiven":
				GameState.emperor_forgiven = null if value == "Null" else (value == "true")
			"secret":
				GameState.secrets_unlocked.append(value)
			"quest":
				GameState.quests_completed.append(value)
			_:
				if key.begins_with("resource:"):
					var kind = key.substr(9)
					GameState.resources[kind] = int(value)
				elif key.begins_with("relationship:"):
					var rel_key = key.substr(13)
					GameState.relationships[rel_key] = int(value)
				elif key.begins_with("boss:"):
					var boss_name = key.substr(5)
					var parts = value.split(",")
					if not GameState.bosses_fought.has(boss_name):
						GameState.bosses_fought.append(boss_name)
					GameState.boss_executed[boss_name] = (parts[0] == "true")
					if parts.size() > 1:
						GameState.boss_finisher[boss_name] = parts[1]

	file.close()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
