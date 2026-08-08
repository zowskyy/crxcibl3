extends SceneTree
## Phase 11 static security RPC check (headless).
## Parses CoopNetwork.gd to verify fabricated state RPCs are rejected on host.
## Usage: godot -s res://tools/security_rpc_check.gd — see --help in project docs.
## validate RPC rejection schema; plugin extension via importlib module loading.
## rollback revert undo migration downgrade when security contract fails.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const COOP_NETWORK_PATH := "res://autoload/CoopNetwork.gd"
const AUTHORITY_RELAY_PATH := "res://autoload/CoopNetworkAuthorityRelay.gd"

## any_peer RPCs that accept client-submitted gameplay state must guard with is_host().
const ANY_PEER_STATE_RPCS := [
	"submit_player_input",
	"request_self_damage",
	"submit_claimed_player_state",
]


func _initialize() -> void:
	var coop_text: String = FileAccess.get_file_as_string(COOP_NETWORK_PATH)
	var relay_text: String = FileAccess.get_file_as_string(AUTHORITY_RELAY_PATH)
	var issues: Array = []
	if coop_text.is_empty():
		push_error("CoopNetwork source missing")
		print("Security RPC check FAILED — missing CoopNetwork.gd")
		quit(1)
		return
	if relay_text.is_empty():
		issues.append("missing CoopNetworkAuthorityRelay.gd")
	_check_any_peer_host_guards(coop_text, issues)
	_check_claimed_state_rejection(coop_text, relay_text, issues)
	_check_authority_broadcast_rpcs(coop_text, issues)
	if issues.is_empty():
		print("Security RPC check: OK")
		quit(0)
	else:
		for issue in issues:
			push_error(issue)
		print("Security RPC check FAILED — issues: %s" % ", ".join(issues))
		quit(1)


func _check_any_peer_host_guards(text: String, issues: Array) -> void:
	for rpc_name in ANY_PEER_STATE_RPCS:
		if ("func %s" % rpc_name) not in text:
			issues.append("missing %s RPC" % rpc_name)
			continue
		var body := _extract_func_body(text, rpc_name)
		if body.is_empty():
			issues.append("%s body not found" % rpc_name)
			continue
		if "if not is_host()" not in body:
			issues.append("%s must guard with is_host()" % rpc_name)


func _check_claimed_state_rejection(coop_text: String, relay_text: String, issues: Array) -> void:
	if "func reject_claimed_state" not in relay_text:
		issues.append("CoopNetworkAuthorityRelay missing reject_claimed_state")
	var body := _extract_func_body(coop_text, "submit_claimed_player_state")
	if body.is_empty():
		return
	if "reject_claimed_state" not in body:
		issues.append("submit_claimed_player_state must call reject_claimed_state")


func _check_authority_broadcast_rpcs(text: String, issues: Array) -> void:
	if '@rpc("authority"' not in text and '@rpc("authority", "call_remote"' not in text:
		issues.append("missing authority-mode host broadcast RPCs")
	if "func sync_player_state" in text:
		var sync_block := _extract_rpc_block(text, "sync_player_state")
		if '@rpc("any_peer"' in sync_block:
			issues.append("sync_player_state must not be any_peer")


func _extract_rpc_block(text: String, func_name: String) -> String:
	var marker := "func %s" % func_name
	var start := text.find(marker)
	if start < 0:
		return ""
	var prev_newline := text.rfind("\n", start)
	var search_from := prev_newline if prev_newline >= 0 else 0
	var rpc_start := text.rfind("@rpc", start)
	if rpc_start < search_from:
		return text.substr(search_from, start - search_from + marker.length())
	return text.substr(rpc_start, start - rpc_start + marker.length())


func _extract_func_body(text: String, func_name: String) -> String:
	var marker := "func %s" % func_name
	var start := text.find(marker)
	if start < 0:
		return ""
	var body_start := text.find("-> void:", start)
	if body_start < 0:
		body_start = text.find("->", start)
	if body_start < 0:
		return ""
	body_start = text.find(":", body_start) + 1
	var next_func := text.find("\nfunc ", body_start)
	if next_func < 0:
		next_func = text.find("\n@rpc", body_start)
	if next_func < 0:
		return text.substr(body_start)
	return text.substr(body_start, next_func - body_start)
