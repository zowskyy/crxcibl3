class_name EnemyCoverAI
extends RefCounted
## Cover-seeking AI extracted from Enemy.gd.

const COVER_SEARCH_RADIUS := 180.0
const COVER_CLOSE_ENOUGH  := 10.0
const CROUCH_TIME         := 1.2
const POP_TIME            := 0.6
const SUPPRESSION_BONUS   := 1.0


static func get_cover_point(enemy) -> Node2D:
	return enemy._cover_point


static func release_cover(enemy) -> void:
	if enemy._cover_point:
		enemy._cover_point.release(enemy)
		enemy._cover_point = null
	enemy._in_cover = false
	enemy._popped_up = false
	enemy._cover_cycle_timer = 0.0


static func tick_cover_seeking(enemy, delta: float, to_player: Vector2, distance: float) -> bool:
	if enemy._cover_point != null and not is_instance_valid(enemy._cover_point):
		release_cover(enemy)

	if enemy._cover_point == null:
		enemy._cover_point = find_best_cover(enemy, distance)
		if enemy._cover_point == null:
			return false
		enemy._cover_point.claim(enemy)
		enemy._in_cover = false
		enemy._popped_up = false
		enemy._cover_cycle_timer = 0.0

	var to_cover: Vector2 = enemy._cover_point.global_position - enemy.global_position
	if to_cover.length() > COVER_CLOSE_ENOUGH:
		enemy._in_cover = false
		enemy.velocity = to_cover.normalized() * enemy.SPEED
		enemy._set_anim("walk")
		return true

	enemy._in_cover = true
	enemy._cover_cycle_timer += delta
	if enemy._popped_up:
		if enemy._cover_cycle_timer >= POP_TIME:
			enemy._popped_up = false
			enemy._cover_cycle_timer = 0.0
			release_cover(enemy)
			return true
		enemy.velocity = to_player.normalized() * enemy.SPEED * 0.5
		enemy._set_anim("walk")
	else:
		enemy.velocity = Vector2.ZERO
		enemy._set_anim("idle")
		if enemy._cover_cycle_timer >= CROUCH_TIME:
			enemy._popped_up = true
			enemy._cover_cycle_timer = 0.0
	return true


static func find_best_cover(enemy, threat_distance: float) -> Node2D:
	if threat_distance <= enemy.ATTACK_RANGE * 2.0:
		return null
	var candidates: Array = enemy.get_tree().get_nodes_in_group("cover_point")
	var ally_angles := SquadController.ally_cover_angles(
		enemy, enemy.faction_id, enemy._player.global_position)

	var best: Node2D = null
	var best_score := -INF
	for cp in candidates:
		if enemy.global_position.distance_to(cp.global_position) > COVER_SEARCH_RADIUS:
			continue
		if not (cp.is_free() or cp.occupied_by == enemy):
			continue
		var s: float = cp.score(enemy.global_position, enemy._player.global_position, ally_angles)
		if s > best_score:
			best_score = s
			best = cp
	return best


static func apply_cover_damage(enemy, amount: int) -> int:
	if enemy._in_cover and is_instance_valid(enemy._cover_point):
		if enemy._popped_up:
			enemy._popped_up = false
			enemy._cover_cycle_timer = -SUPPRESSION_BONUS
		elif enemy._cover_point.high_cover:
			return 0
		else:
			return int(amount * 0.5)
	enemy._suppression_timer = enemy.OPEN_SUPPRESSION_TIME
	return amount
