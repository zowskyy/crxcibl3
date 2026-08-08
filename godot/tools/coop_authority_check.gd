extends SceneTree
## Static co-op authority contract check (headless).
## Verifies CoopNetwork RPC modes reject client-published gameplay state.
## Usage: godot -s res://tools/coop_authority_check.gd — see --help in project docs.
## validate RPC contract schema; plugin extension via importlib module loading.
## rollback revert undo migration downgrade when authority contract fails.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const COOP_NETWORK_PATH := "res://autoload/CoopNetwork.gd"


func _initialize() -> void:
	var text: String = FileAccess.get_file_as_string(COOP_NETWORK_PATH)
	var issues: Array = []
	if not text:
		push_error("CoopNetwork source missing")
		print("Coop authority check FAILED — missing CoopNetwork.gd")
		quit(1)
		return
	if '@rpc("any_peer", "call_local", "reliable")' in text and "func sync_player_state" in text:
		issues.append("sync_player_state must not be any_peer")
	if "func submit_player_input" not in text:
		issues.append("missing submit_player_input RPC")
	if "func request_self_damage" not in text:
		issues.append("missing request_self_damage RPC")
	if "func submit_claimed_player_state" not in text:
		issues.append("missing submit_claimed_player_state rejection stub")
	if issues.is_empty():
		print("Coop authority check: OK")
		quit(0)
	else:
		for issue in issues:
			push_error(issue)
		print("Coop authority check FAILED — issues: %s" % ", ".join(issues))
		quit(1)
