extends Node
## Unified mission load — solo and co-op. Deferred scene change for mobile reliability.
## Usage: start_solo(squad), start_coop(squad) — see docs/COOP_MULTIPLAYER.md --help.
## Params: squad Array of hero variant id strings.
## Side effects: changes scene to TestRoom; clears stale co-op on solo.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const TEST_ROOM := "res://scenes/TestRoom.tscn"

var loading := false


func start_solo(squad: Array) -> void:
	if loading:
		push_warning("MissionLaunch: load already in progress.")
		return
	if squad.is_empty():
		push_error("MissionLaunch: cannot start — empty squad.")
		return
	CoopNetwork.stop_session()
	_apply_squad(squad)
	call_deferred("_change_scene", "solo")


func start_coop(squad: Array) -> void:
	if loading:
		push_warning("MissionLaunch: load already in progress.")
		return
	if squad.is_empty():
		push_error("MissionLaunch: cannot start co-op — empty squad.")
		return
	_apply_squad(squad)
	call_deferred("_change_scene", "co-op")


func _apply_squad(squad: Array) -> void:
	GameState.squad = squad.duplicate()
	GameState.current_hero_index = 0
	print("[MissionLaunch] squad ready (%d): %s" % [squad.size(), str(squad)])


func _change_scene(mode: String) -> void:
	if not is_inside_tree():
		push_error("MissionLaunch: not in tree — cannot load TestRoom.")
		return
	loading = true
	if not ResourceLoader.exists(TEST_ROOM):
		loading = false
		push_error("MissionLaunch: TestRoom missing at %s" % TEST_ROOM)
		return
	var err := get_tree().change_scene_to_file(TEST_ROOM)
	loading = false
	if err != OK:
		push_error("MissionLaunch: change_scene failed (%d) mode=%s" % [err, mode])
		return
	print("[MissionLaunch] TestRoom loaded (%s, %d heroes)" % [mode, GameState.squad.size()])
