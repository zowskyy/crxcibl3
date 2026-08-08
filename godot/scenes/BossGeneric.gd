extends CharacterBody2D
## Configurable Corrupted Six boss combat template (Slices 3.18–3.22).
## Placeholder _draw() when sprite sheets are missing; SpeakCapable lip flap for captions.

signal fled
signal defeated(finisher: String)

const SPEED_FIGHT := 50.0
const SPEED_FLEE := 130.0
const PROJECTILE_SPEED := 180.0
const PROJECTILE_DAMAGE := 12

const ENEMY_SCRIPT := preload("res://scenes/Enemy.gd")
const PROJECTILE_SCRIPT := preload("res://scenes/BossProjectile.gd")
const ANIM_LOADER := preload("res://scenes/AnimationLoader.gd")

enum Phase { FIGHT, FLEE, DONE }

@export var boss_id: String = "Cross"
@export var max_hp: int = 200
@export var flee_threshold: int = 40
@export var final_stand: bool = false
@export var minion_cap: int = 2
@export var minion_interval: float = 8.0
@export var projectile_interval: float = 2.5
@export var sprite_dir: String = ""
@export var placeholder_color: Color = Color(0.35, 0.35, 0.42)

var hp := 200
var _last_hitter := ""
var _phase := Phase.FIGHT
var _player: CharacterBody2D = null
var _minion_timer := 0.0
var _projectile_timer := 1.0
var _live_minions: Array = []
var _flee_target: Vector2 = Vector2.ZERO

var _anim: AnimatedSprite2D = null
var _has_sheets := false
var speaking := false
var _lip_phase := 0.0


func _ready() -> void:
	add_to_group("boss")
	hp = max_hp
	call_deferred("_find_player")
	call_deferred("_setup_animation")


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")


func _setup_animation() -> void:
	_anim = AnimatedSprite2D.new()
	_anim.name = "Anim"
	_anim.position = Vector2(0, -20)
	add_child(_anim)

	var dir := sprite_dir
	if dir.is_empty():
		dir = "res://assets/sprites/bosses/%s/" % boss_id.to_lower()

	var sf: SpriteFrames = ANIM_LOADER.build_frames(ANIM_LOADER.boss_anims(dir))
	if sf == null:
		_anim.visible = false
		return

	_anim.sprite_frames = sf
	_anim.visible = true
	_has_sheets = true
	_anim.play("idle")


func _set_boss_anim(state: String) -> void:
	if _anim and _has_sheets and _anim.animation != state:
		_anim.play(state)


func set_flee_target(pos: Vector2) -> void:
	_flee_target = pos


func set_speaking(active: bool) -> void:
	speaking = active
	if not speaking:
		_lip_phase = 0.0
	queue_redraw()


func play_gesture(name: String) -> void:
	match name:
		"ready", "ready_stance", "talk":
			_set_boss_anim("idle")
		"death_slump", "slump_final":
			_set_boss_anim("idle")
			modulate = Color(0.75, 0.75, 0.8, 1.0)
	set_speaking(name in ["ready", "ready_stance", "talk", "death_slump"])
	queue_redraw()


func _physics_process(delta: float) -> void:
	if speaking:
		_lip_phase += delta * 14.0
		queue_redraw()
	match _phase:
		Phase.FIGHT:
			_tick_fight(delta)
		Phase.FLEE:
			pass


func _tick_fight(delta: float) -> void:
	if _player == null:
		return

	var to_player := _player.global_position - global_position
	var dist := to_player.length()
	if dist < 120.0:
		velocity = -to_player.normalized() * SPEED_FIGHT
		_set_boss_anim("walk")
	elif dist > 200.0:
		velocity = to_player.normalized() * SPEED_FIGHT
		_set_boss_anim("walk")
	else:
		velocity = Vector2.ZERO
		_set_boss_anim("idle")
	move_and_slide()

	_live_minions = _live_minions.filter(func(e): return is_instance_valid(e))

	_minion_timer -= delta
	if _minion_timer <= 0.0:
		_minion_timer = minion_interval
		if _live_minions.size() < minion_cap:
			_spawn_minion()

	_projectile_timer -= delta
	if _projectile_timer <= 0.0:
		_projectile_timer = projectile_interval
		if dist > 0.0:
			_fire_projectile(to_player.normalized())


func take_damage(amount: int, killer: String = "") -> void:
	if _phase == Phase.FLEE or _phase == Phase.DONE:
		return
	if killer != "":
		_last_hitter = killer
	hp = maxi(0, hp - amount)
	if final_stand:
		if hp == 0:
			_die()
	elif not final_stand and flee_threshold >= 0 and hp <= flee_threshold and _phase == Phase.FIGHT:
		_trigger_flee()
	elif hp == 0:
		_die()


func _trigger_flee() -> void:
	_phase = Phase.FLEE
	_clear_minions()
	_register_defeat(false)
	_run_flee()


func _die() -> void:
	_phase = Phase.DONE
	set_physics_process(false)
	_clear_minions()
	_register_defeat(true)
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.35, 0.4)
	tween.tween_callback(func():
		emit_signal("defeated", _last_hitter)
	)


func _register_defeat(executed: bool) -> void:
	Bosses.register_boss_defeat(boss_id, _last_hitter, executed)
	Morale.on_boss_defeated()
	if executed:
		Reputation.on_boss_executed()
	else:
		Reputation.on_boss_spared()
	DialogueIntensity.on_boss_defeated(executed)
	RelationshipSystem.on_boss_defeated_together()


func _clear_minions() -> void:
	for m in _live_minions:
		if is_instance_valid(m):
			m.despawn()
	_live_minions.clear()


func _run_flee() -> void:
	set_physics_process(false)
	_set_boss_anim("flee")
	var flee_end := _flee_target if _flee_target != Vector2.ZERO \
		else global_position + Vector2(120, -20)
	var tween := get_tree().create_tween()
	tween.tween_property(self, "global_position", flee_end, 0.9) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_phase = Phase.DONE
		emit_signal("fled")
	)


func _spawn_minion() -> void:
	var enemy := CharacterBody2D.new()
	enemy.set_script(ENEMY_SCRIPT)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	col.shape = rect
	enemy.add_child(col)
	var offset := Vector2(randf_range(-40, 40), randf_range(-40, 40))
	enemy.global_position = global_position + offset
	get_parent().add_child(enemy)
	_live_minions.append(enemy)


func _fire_projectile(direction: Vector2) -> void:
	var proj := Area2D.new()
	proj.set_script(PROJECTILE_SCRIPT)
	proj.direction = direction
	proj.speed = PROJECTILE_SPEED
	proj.damage = PROJECTILE_DAMAGE
	get_parent().add_child(proj)
	proj.global_position = global_position + direction * 20.0


func _draw() -> void:
	var bar_w := 40.0
	var fill := bar_w * (float(hp) / float(maxi(max_hp, 1)))
	draw_rect(Rect2(-bar_w / 2, -36, bar_w, 4), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-bar_w / 2, -36, fill, 4), Color(0.9, 0.75, 0.1))

	if _has_sheets:
		if speaking:
			_draw_lip_flap()
		return

	draw_rect(Rect2(-12, -20, 24, 40), placeholder_color)
	draw_rect(Rect2(-10, -18, 20, 8), placeholder_color.lightened(0.15))
	draw_circle(Vector2(0, -26), 8.0, placeholder_color.lightened(0.1))
	if speaking:
		_draw_lip_flap()


func _draw_lip_flap() -> void:
	var open := absf(sin(_lip_phase)) > 0.35
	var mouth_h := 3.0 if open else 1.0
	draw_rect(Rect2(-3, -10, 6, mouth_h), Color(0.15, 0.08, 0.08))
