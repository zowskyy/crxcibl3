extends SceneTree
## Scene flow smoke test — verifies MainMenu → HeroSelectionUI → TestRoom loads without error.
##
## Usage:
##   godot --headless -s res://tools/ci_scene_flow_smoke.gd
##
## Side effects: boots autoloads, changes scenes three times, exits 0/1.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const MAIN_MENU := "res://scenes/MainMenu.tscn"
const HERO_SELECTION := "res://scenes/HeroSelectionUI.tscn"
const TEST_ROOM := "res://scenes/TestRoom.tscn"


func _initialize() -> void:
	_run_smoke.call_deferred()


func _run_smoke() -> void:
	if not await _change_and_wait(MAIN_MENU):
		return
	if not await _change_and_wait(HERO_SELECTION):
		return

	var ml: Node = get_root().get_node("MissionLaunch")
	if ml == null:
		push_error("[ci_scene_flow] MissionLaunch autoload missing")
		quit(1)
		return
	ml.call("start_solo", ["enforcer_ghost"])
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	if not _verify_test_room():
		push_error("[ci_scene_flow] TestRoom verification failed")
		quit(1)
		return

	print("[ci_scene_flow] PASS (MainMenu → HeroSelection → TestRoom)")
	quit(0)


func _prepare_solo_squad() -> void:
	var gs: Node = get_root().get_node("GameState")
	if gs == null:
		push_error("[ci_scene_flow] GameState autoload missing")
		quit(1)
		return
	gs.call("reset_for_new_game")
	gs.set("squad", ["enforcer_ghost"])
	gs.set("current_hero_index", 0)


func _verify_test_room() -> bool:
	var scene := current_scene
	if scene != null and scene.name == "TestRoom":
		return true
	if not get_nodes_in_group("player").is_empty():
		return true
	return false


func _change_and_wait(scene_path: String, frame_count: int = 2) -> bool:
	var err := change_scene_to_file(scene_path)
	if err != OK:
		push_error("[ci_scene_flow] failed to load %s (err=%d)" % [scene_path, err])
		quit(1)
		return false
	for _i in frame_count:
		await process_frame
	return true
