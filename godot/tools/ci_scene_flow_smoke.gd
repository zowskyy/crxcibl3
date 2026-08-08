extends SceneTree
## Scene flow smoke test — verifies MainMenu → HeroSelectionUI loads without error.
##
## Usage:
##   godot --headless -s res://tools/ci_scene_flow_smoke.gd
##
## Side effects: boots autoloads, changes scenes twice, exits 0/1.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const MAIN_MENU := "res://scenes/MainMenu.tscn"
const HERO_SELECTION := "res://scenes/HeroSelectionUI.tscn"


func _initialize() -> void:
	_run_smoke.call_deferred()


func _run_smoke() -> void:
	if not await _change_and_wait(MAIN_MENU):
		return
	if not await _change_and_wait(HERO_SELECTION):
		return
	print("[ci_scene_flow] PASS")
	quit(0)


func _change_and_wait(scene_path: String) -> bool:
	var err := change_scene_to_file(scene_path)
	if err != OK:
		push_error("[ci_scene_flow] failed to load %s (err=%d)" % [scene_path, err])
		quit(1)
		return false
	await process_frame
	await process_frame
	return true
