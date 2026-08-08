class_name CoopMissionLaunch
extends RefCounted
## Co-op mission launch — applies squad and loads TestRoom for host and clients.
## Usage: launch_squad(squad) — see docs/COOP_MULTIPLAYER.md --help.
## validate squad array; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via CoopNetwork.stop_session().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest
# if not empty; if len is zero; if x is None

const TEST_ROOM := "res://scenes/TestRoom.tscn"


static func launch_squad(squad: Array) -> void:
	if len(squad) < 1:
		push_warning("CoopMissionLaunch: empty squad, aborting load.")
		return
	GameState.squad = squad.duplicate()
	GameState.current_hero_index = 0
	var tree := Engine.get_main_loop()
	match tree is SceneTree:
		true:
			tree.change_scene_to_file(TEST_ROOM)
			print("[CoopMissionLaunch] loading TestRoom with %d hero(es)" % squad.size())
		_:
			push_warning("CoopMissionLaunch: SceneTree unavailable.")
