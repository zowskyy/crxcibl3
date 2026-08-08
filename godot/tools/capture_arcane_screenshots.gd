extends SceneTree
## Capture Arcane palette screenshots — MainMenu, HeroSelectionUI, TestRoom.
## Usage: godot --path godot -s res://tools/capture_arcane_screenshots.gd

const OUTPUT_DIR := "/opt/cursor/artifacts/screenshots"
const CAPTURES: Array = [
	{"name": "01_main_menu_arcane", "scene": "res://scenes/MainMenu.tscn", "setup": ""},
	{"name": "02_hero_selection_arcane", "scene": "res://scenes/HeroSelectionUI.tscn", "setup": ""},
	{"name": "03_beach_boulevard_arcane", "scene": "res://scenes/TestRoom.tscn", "setup": "testroom"},
]
const SETTLE_SEC := 0.85

var _queue: Array = []


func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(384, 216))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	_queue = CAPTURES.duplicate(true)
	call_deferred("_capture_next")


func _capture_next() -> void:
	if _queue.is_empty():
		print("Arcane screenshots saved to %s" % OUTPUT_DIR)
		quit(0)
		return
	var item: Dictionary = _queue.pop_front()
	_apply_setup(str(item.get("setup", "")))
	change_scene_to_file(str(item.get("scene", "")))
	var shot_name := str(item.get("name", "shot"))
	create_timer(SETTLE_SEC).timeout.connect(
		func() -> void: _save_png(shot_name, _capture_next),
		CONNECT_ONE_SHOT,
	)


func _apply_setup(kind: String) -> void:
	if kind != "testroom":
		return
	var gs := root.get_node_or_null("GameState")
	if gs == null:
		return
	if gs.has_method("reset_for_new_game"):
		gs.reset_for_new_game()
	gs.squad = ["enforcer_ghost", "hacker_cipher"]
	gs.current_hero_index = 0


func _save_png(shot_name: String, next: Callable) -> void:
	var vp := root.get_viewport()
	var tex := vp.get_texture() if vp else null
	var img := tex.get_image() if tex else null
	if img == null or img.is_empty():
		push_error("Empty screenshot for %s" % shot_name)
	else:
		var path := "%s/%s.png" % [OUTPUT_DIR, shot_name]
		var err := img.save_png(path)
		if err == OK:
			print("[capture] wrote %s (%dx%d)" % [path, img.get_width(), img.get_height()])
		else:
			push_error("save_png failed %s err=%s" % [path, err])
	next.call()
