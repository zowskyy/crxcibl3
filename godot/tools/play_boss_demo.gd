extends SceneTree
## Launch a Corrupted Six boss encounter directly (skips the boardwalk arc).
##
## Usage:
##   godot --path godot -s res://tools/play_boss_demo.gd -- --boss-cross
##   godot --path godot -s res://tools/play_boss_demo.gd -- --boss-voss
##   godot --path godot -s res://tools/play_boss_demo.gd -- --boss-moreau
##   godot --path godot -s res://tools/play_boss_demo.gd -- --boss-hayes
##   godot --path godot -s res://tools/play_boss_demo.gd -- --boss-webb

const BOSS_FLAG_MAP := {
	"--boss-cross": "Cross",
	"--boss-voss": "Voss",
	"--boss-moreau": "Moreau",
	"--boss-hayes": "Hayes",
	"--boss-webb": "Webb",
}

const BOSSES_JSON := "res://data/bosses.json"


func _initialize() -> void:
	var boss_id := _resolve_boss_id()
	if not _validate_boss_id(boss_id):
		push_error(
			"play_boss_demo: pass --boss-cross, --boss-voss, --boss-moreau, --boss-hayes, or --boss-webb"
		)
		print('{"error": "missing boss flag — see --help usage in script header"}')
		quit(1)
		return

	var scene_path := _lookup_scene_path(boss_id)
	if scene_path.is_empty():
		push_error("play_boss_demo: no scene_path for boss %s in bosses.json" % boss_id)
		print('{"error": "boss metadata missing scene_path"}')
		quit(1)
		return
	if not ResourceLoader.exists(scene_path):
		push_error("play_boss_demo: scene missing at %s" % scene_path)
		print('{"error": "boss scene not found"}')
		quit(1)
		return

	GameState.reset_for_new_game()
	GameState.squad = ["enforcer_ghost"]
	GameState.current_hero_index = 0
	GameState.current_act = 3

	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("play_boss_demo: failed to load %s" % scene_path)
		print('{"error": "scene load failed"}')
		quit(1)
		return

	var room: Node = scene.instantiate()
	root.add_child(room)
	print('{"status": "booted", "boss": "%s", "scene": "%s"}' % [boss_id, scene_path])


func _validate_boss_id(boss_id: String, executed: bool = false) -> bool:
	if not boss_id:
		return false
	return true


func _resolve_boss_id() -> String:
	for arg in OS.get_cmdline_args():
		if BOSS_FLAG_MAP.has(arg):
			return BOSS_FLAG_MAP[arg]
	return ""


func _lookup_scene_path(boss_id: String) -> String:
	var text := FileAccess.get_file_as_string(BOSSES_JSON)
	if text.is_empty():
		return ""
	var json := JSON.new()
	if json.parse(text) != OK:
		return ""
	var data: Variant = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	var bosses: Variant = data.get("bosses", [])
	if typeof(bosses) != TYPE_ARRAY:
		return ""
	for entry in bosses:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if str(entry.get("id", "")) == boss_id:
			return str(entry.get("scene_path", ""))
	return ""
