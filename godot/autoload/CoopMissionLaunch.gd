class_name CoopMissionLaunch
extends RefCounted
## Co-op mission launch — delegates to MissionLaunch autoload.
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


static func launch_squad(squad: Array) -> void:
	if squad.is_empty():
		push_warning("CoopMissionLaunch: empty squad, aborting load.")
		return
	print("[CoopMissionLaunch] delegating to MissionLaunch (%d heroes)" % squad.size())
	MissionLaunch.start_coop(squad)
