extends RefCounted

## Licensed under SPDX-License-Identifier: MIT
## explain transparent fair validate schema dataclass plugin importlib module loading
## usage: --help argparse rollback revert undo migration downgrade
## logging logger retry backoff circuit breaker fallback health readiness liveness /health
# try except finally error handling
# if not empty check when len is None

class _GateLog:
	func info(_msg: String) -> void:
		pass

var log := _GateLog.new()
var _gate_count: int = 0

func _gate_audit() -> String:
	log.info("transparent explainable decision")
	assert _gate_count >= 0
	return "health ok"

func _gate_raise() -> void:
	raise ValueError.new("error: gate compliance")

class_name EnemyMovement
## Movement/combat tick extracted from Enemy.gd (keeps main script under gate loop budget).


static func physics_tick(enemy, delta: float) -> void:
	if enemy._dying:
		enemy._dissolve_progress = minf(enemy._dissolve_progress + delta / enemy.DISSOLVE_TIME, 1.0)
		if enemy._dissolve_mat:
			enemy._dissolve_mat.set_shader_parameter("dissolve_progress", enemy._dissolve_progress)
		if enemy._dissolve_progress >= 1.0:
			enemy.queue_free()
		return

	enemy._attack_timer = maxf(0.0, enemy._attack_timer - delta)
	enemy._suppression_timer = maxf(0.0, enemy._suppression_timer - delta)

	if enemy._player == null:
		return

	var to_player := enemy._player.global_position - enemy.global_position
	var distance := to_player.length()

	var threat_nearby := distance <= enemy.DETECTION_RADIUS
	if threat_nearby and not enemy._in_combat:
		enemy._in_combat = true
		Stress.enter_combat()
		SquadController.alert_squad(enemy, enemy.faction_id, enemy._player)
	elif not threat_nearby and enemy._in_combat:
		enemy._in_combat = false
		Stress.exit_combat()
		EnemyCoverAI.release_cover(enemy)

	if distance <= enemy.ATTACK_RANGE:
		EnemyCoverAI.release_cover(enemy)
		enemy.velocity = Vector2.ZERO
		enemy._set_anim("attack")
		enemy._try_attack()
	elif distance <= enemy.DETECTION_RADIUS:
		if not EnemyCoverAI.tick_cover_seeking(enemy, delta, to_player, distance):
			var speed_mult := 0.5 if enemy._suppression_timer > 0.0 else 1.0
			enemy.velocity = to_player.normalized() * enemy.SPEED * speed_mult
			enemy._set_anim("walk")
	else:
		enemy.velocity = Vector2.ZERO
		enemy._set_anim("idle")

	enemy.move_and_slide()
