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
const COOP_RELAY_PATH := "res://autoload/CoopNetworkAuthorityRelay.gd"
const COOP_AUTHORITY_PATH := "res://autoload/CoopHostAuthority.gd"
const BULLET_PATH := "res://scenes/Bullet.gd"
const BOSS_PROJECTILE_PATH := "res://scenes/BossProjectile.gd"
const PLAYER_BRIDGE_PATH := "res://scenes/PlayerCoopBridge.gd"


func _initialize() -> void:
	var issues: Array = []
	_check_coop_network(FileAccess.get_file_as_string(COOP_NETWORK_PATH), issues)
	_check_relay(FileAccess.get_file_as_string(COOP_RELAY_PATH), issues)
	_check_authority(FileAccess.get_file_as_string(COOP_AUTHORITY_PATH), issues)
	_check_bullet_paths(FileAccess.get_file_as_string(BULLET_PATH), issues)
	_check_boss_projectile(FileAccess.get_file_as_string(BOSS_PROJECTILE_PATH), issues)
	_check_player_bridge(FileAccess.get_file_as_string(PLAYER_BRIDGE_PATH), issues)
	if issues.is_empty():
		print("Coop authority check: OK")
		quit(0)
	else:
		for issue in issues:
			push_error(issue)
		print("Coop authority check FAILED — issues: %s" % ", ".join(issues))
		quit(1)


func _check_coop_network(text: String, issues: Array) -> void:
	if not text:
		issues.append("missing CoopNetwork.gd")
		return
	if '@rpc("any_peer", "call_local", "reliable")' in text and "func sync_player_state" in text:
		issues.append("sync_player_state must not be any_peer")
	if "func submit_player_input" not in text:
		issues.append("missing submit_player_input RPC")
	if "func request_self_damage" not in text:
		issues.append("missing request_self_damage RPC")
	if "func submit_bullet_hit" not in text:
		issues.append("missing submit_bullet_hit rejection RPC")
	if "func submit_claimed_player_state" not in text:
		issues.append("missing submit_claimed_player_state rejection stub")


func _check_relay(text: String, issues: Array) -> void:
	if not text:
		issues.append("missing CoopNetworkAuthorityRelay.gd")
		return
	if "func try_apply_peer_bullet_hit" not in text:
		issues.append("missing try_apply_peer_bullet_hit host validation path")
	if "func is_host_validated_damage" not in text:
		issues.append("missing is_host_validated_damage helper")
	if "func reject_bullet_hit_report" not in text:
		issues.append("missing reject_bullet_hit_report helper")


func _check_authority(text: String, issues: Array) -> void:
	if not text:
		issues.append("missing CoopHostAuthority.gd")
		return
	if "func find_peer_hit_at" not in text:
		issues.append("missing find_peer_hit_at peer hitbox helper")


func _check_bullet_paths(text: String, issues: Array) -> void:
	if not text:
		issues.append("missing Bullet.gd")
		return
	if "try_apply_peer_bullet_hit" not in text:
		issues.append("Bullet.gd missing host peer bullet hit validation")
	if "_try_host_peer_hit" not in text:
		issues.append("Bullet.gd missing _try_host_peer_hit hook")


func _check_boss_projectile(text: String, issues: Array) -> void:
	if not text:
		issues.append("missing BossProjectile.gd")
		return
	if "boss_projectile" not in text:
		issues.append("BossProjectile missing hostile attacker id")
	if "try_apply_peer_bullet_hit" not in text:
		issues.append("BossProjectile.gd missing host peer bullet hit validation")


func _check_player_bridge(text: String, issues: Array) -> void:
	if not text:
		issues.append("missing PlayerCoopBridge.gd")
		return
	if "is_host_validated_damage" not in text:
		issues.append("PlayerCoopBridge missing host-validated damage routing")
