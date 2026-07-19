extends CharacterBody2D
## The Priest — Reverend Isaiah Blackwood (Slice 2.18).
## Encountered on the rooftop of Building3, surprised and unguarded.
## Three phases:
##   SURPRISED  — stands still 2s, plays idle, doesn't attack (players get first shots in)
##   FIGHT      — moves to keep distance, spawns Deacon grunts periodically,
##                fires "divine light" projectiles. Tuned to challenge without overwhelming.
##   FLEE       — triggered at FLEE_THRESHOLD HP. Fires a screen-blinding flashbang,
##                sprints to the exit marker, emits fled signal for the scene to catch.
##
## Fake "divine" illusion kit maps cleanly onto The Priest's lore moves:
##   Deacon spawns = loyal followers rushing the crew
##   Light projectiles = "God's wrath" blasts
##   Flashbang = "divine blinding light" escape

signal fled

const MAX_HP := 200
const FLEE_THRESHOLD := 80   # 40% — triggers Phase 3
const SPEED_FIGHT := 50.0
const SPEED_FLEE  := 130.0

const DEACON_SPAWN_INTERVAL := 8.0
const DEACON_CAP := 2          # max live deacons at once — keeps it manageable
const PROJECTILE_INTERVAL := 2.5
const PROJECTILE_SPEED := 180.0
const PROJECTILE_DAMAGE := 12

const FLASHBANG_DURATION := 1.8  # seconds the screen stays white

const ENEMY_SCRIPT    := preload("res://scenes/Enemy.gd")
const PROJECTILE_SCRIPT := preload("res://scenes/BossProjectile.gd")

enum Phase { SURPRISED, FIGHT, FLEE, DONE }

var hp := MAX_HP
var _phase := Phase.SURPRISED
var _player: CharacterBody2D = null
var _surprised_timer := 2.0
var _deacon_timer := 0.0
var _projectile_timer := 1.0  # slight delay before first shot
var _live_deacons: Array = []
var _flee_target: Vector2 = Vector2.ZERO
var _flashbang_node: ColorRect = null   # set by RooftopScene after _ready


func _ready() -> void:
	add_to_group("boss")
	call_deferred("_find_player")


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")


func set_flee_target(pos: Vector2) -> void:
	_flee_target = pos


func set_flashbang_node(node: ColorRect) -> void:
	_flashbang_node = node


func _physics_process(delta: float) -> void:
	match _phase:
		Phase.SURPRISED:
			_tick_surprised(delta)
		Phase.FIGHT:
			_tick_fight(delta)
		Phase.FLEE:
			_tick_flee(delta)


func _tick_surprised(delta: float) -> void:
	_surprised_timer -= delta
	if _surprised_timer <= 0.0:
		_phase = Phase.FIGHT
		_deacon_timer = DEACON_SPAWN_INTERVAL * 0.5  # first deacon wave comes faster


func _tick_fight(delta: float) -> void:
	if _player == null:
		return

	# Keep a mid-range distance — close enough to feel threatening,
	# far enough that players can hit him without running into him.
	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	if dist < 120.0:
		velocity = -to_player.normalized() * SPEED_FIGHT  # back away
	elif dist > 200.0:
		velocity = to_player.normalized() * SPEED_FIGHT   # close in
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	# Prune freed deacons
	_live_deacons = _live_deacons.filter(func(e): return is_instance_valid(e))

	_deacon_timer -= delta
	if _deacon_timer <= 0.0:
		_deacon_timer = DEACON_SPAWN_INTERVAL
		if _live_deacons.size() < DEACON_CAP:
			_spawn_deacon()

	_projectile_timer -= delta
	if _projectile_timer <= 0.0:
		_projectile_timer = PROJECTILE_INTERVAL
		_fire_projectile(to_player.normalized())


func _tick_flee(delta: float) -> void:
	if _flee_target == Vector2.ZERO:
		return
	var to_exit := _flee_target - global_position
	if to_exit.length() < 10.0:
		_phase = Phase.DONE
		emit_signal("fled")
		queue_free()
		return
	velocity = to_exit.normalized() * SPEED_FLEE
	move_and_slide()


func take_damage(amount: int, _killer: String = "") -> void:
	if _phase == Phase.FLEE or _phase == Phase.DONE:
		return
	hp = maxi(0, hp - amount)
	if hp <= FLEE_THRESHOLD and _phase == Phase.FIGHT:
		_trigger_flee()


func _trigger_flee() -> void:
	_phase = Phase.FLEE
	# Kill remaining deacons so they don't linger after the boss runs
	for d in _live_deacons:
		if is_instance_valid(d):
			d.queue_free()
	_live_deacons.clear()
	_fire_flashbang()


func _fire_flashbang() -> void:
	if _flashbang_node == null:
		return
	_flashbang_node.visible = true
	# Fade out over FLASHBANG_DURATION using a Tween
	var tween := get_tree().create_tween()
	tween.tween_property(_flashbang_node, "modulate:a", 0.0, FLASHBANG_DURATION)
	tween.tween_callback(func(): _flashbang_node.visible = false)
	tween.tween_callback(func(): _flashbang_node.modulate.a = 1.0)


func _spawn_deacon() -> void:
	var enemy := CharacterBody2D.new()
	enemy.set_script(ENEMY_SCRIPT)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	col.shape = rect
	enemy.add_child(col)
	# Spawn near Blackwood, not on top of the player
	var offset := Vector2(randf_range(-40, 40), randf_range(-40, 40))
	enemy.global_position = global_position + offset
	get_parent().add_child(enemy)
	_live_deacons.append(enemy)


func _fire_projectile(direction: Vector2) -> void:
	var proj := Area2D.new()
	proj.set_script(PROJECTILE_SCRIPT)
	proj.direction = direction
	proj.speed = PROJECTILE_SPEED
	proj.damage = PROJECTILE_DAMAGE
	get_parent().add_child(proj)
	proj.global_position = global_position + direction * 20.0


func _draw() -> void:
	# Placeholder: white robe silhouette with a gold cross.
	# Replaced with real Blackwood sprite when art lands.
	draw_rect(Rect2(-12, -20, 24, 40), Color(0.95, 0.95, 0.9))   # robe
	draw_rect(Rect2(-2, -28, 4, 14), Color(0.9, 0.75, 0.1))       # cross vertical
	draw_rect(Rect2(-6, -24, 12, 3), Color(0.9, 0.75, 0.1))       # cross horizontal
	# HP bar above sprite
	var bar_w := 40.0
	var fill := bar_w * (float(hp) / float(MAX_HP))
	draw_rect(Rect2(-bar_w / 2, -36, bar_w, 4), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, -36, fill, 4), Color(0.9, 0.75, 0.1))
