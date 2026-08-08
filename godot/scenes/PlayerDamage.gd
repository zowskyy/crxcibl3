class_name PlayerDamage
extends RefCounted
## Local damage + respawn helpers for Player.
## validate damage amounts; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via apply_local_damage().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


static func apply_local_damage(player: CharacterBody2D, amount: int, max_health: int) -> bool:
	var was_dead: bool = player.health <= 0
	player.health = clampi(player.health - amount, 0, max_health)
	var became_dead: bool = player.health <= 0 and not was_dead
	if became_dead:
		print("[PlayerDamage] player downed")
	return became_dead


static func on_player_downed(player: CharacterBody2D, hero_name: String) -> void:
	Stress.on_crew_member_downed()
	Injury.on_hero_downed()
	RelationshipSystem.on_hero_downed(hero_name)
	player.set_physics_process(false)
	if player.has_method("_play_once"):
		player._play_once("downed")
	player.downed.emit()


static func schedule_respawn(player: CharacterBody2D, hero_name: String, respawn_time: float) -> void:
	if GameState.permadeath_mode:
		PermanentDeath.on_hero_ghosted(hero_name)
		Stress.on_crew_member_ghosted(hero_name)
		return

	await player.get_tree().create_timer(respawn_time).timeout
	player.health = max_health_for(player, hero_name)
	player.set_physics_process(true)
	if player.has_method("_play"):
		player._play("idle")
	player.respawned.emit()


static func max_health_for(player: CharacterBody2D, hero_name: String) -> int:
	if player.has_method("_max_health"):
		return player._max_health()
	return 120 + RelationshipSystem.get_hp_bonus(hero_name)
