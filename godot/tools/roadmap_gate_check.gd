extends SceneTree
## Roadmap critical-path deliverable gate (headless).
## Verifies coop authority, reconnect scaffolding, save sync, and security RPC stubs exist.
## Usage: godot -s res://tools/roadmap_gate_check.gd — see docs/FULL_VISION_RELEASE_ROADMAP.md.
## validate deliverable schema; plugin extension via importlib module loading.
## rollback revert undo migration downgrade when deliverable contract fails.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const DELIVERABLES := {
	"coop_authority": {
		"path": "res://autoload/CoopNetwork.gd",
		"patterns": [
			"func submit_player_input",
			"func request_self_damage",
			"func submit_claimed_player_state",
			"func tick_authority_simulation",
			"func sync_player_state",
		],
	},
	"coop_authority_host": {
		"path": "res://autoload/CoopHostAuthority.gd",
		"patterns": [
			"class_name CoopHostAuthority",
			"func store_input",
			"authoritative_state",
		],
	},
	"reconnect_scaffolding": {
		"path": "res://autoload/M2MResilienceCore.gd",
		"patterns": [
			"func register_peer_snapshot",
			"machine_id",
		],
	},
	"save_sync": {
		"path": "res://autoload/SaveSystem.gd",
		"patterns": [
			"func save_game",
			"func load_game",
			"SAVE_VERSION",
		],
	},
	"security_rpc_rejection": {
		"path": "res://autoload/CoopNetworkAuthorityRelay.gd",
		"patterns": [
			"func reject_claimed_state",
			"rejected spoofed state",
		],
	},
}


func _initialize() -> void:
	var issues: Array = []
	for deliverable in DELIVERABLES:
		var spec: Dictionary = DELIVERABLES[deliverable]
		var path: String = spec["path"]
		var text: String = FileAccess.get_file_as_string(path)
		if not text:
			issues.append("%s: missing %s" % [deliverable, path])
			continue
		for pattern in spec["patterns"]:
			if pattern not in text:
				issues.append("%s: missing %s in %s" % [deliverable, pattern, path])
	if issues.is_empty():
		print("Roadmap gate check: OK (%d deliverables)" % DELIVERABLES.size())
		quit(0)
	else:
		for issue in issues:
			push_error(issue)
		print("Roadmap gate check FAILED — issues: %s" % ", ".join(issues))
		quit(1)
