extends CharacterBody2D
## Player — driven by joystick/arrow keys, Metal Slug gun combat.
##
## Animation system (Slice 3.8-anim):
##   An AnimatedSprite2D child named "Anim" is expected. If the sprite sheets
##   exist under res://assets/sprites/heroes/<variant_id>/ they are loaded at
##   _ready() via AnimationLoader. If the folder / PNGs are missing the node
##   stays invisible and the _draw() placeholder (hero_enforcer_ghost.png
##   Sprite2D child "PlayerSprite") remains visible — zero breaking change.
##
## Animation states driven here:
##   idle, walk_right, walk_left, walk_up, walk_down, shoot, downed
##
## Stress consequences (Slice 3.3): elevated/critical stress reduces speed and
## fire rate. RelationshipSystem synergy bonuses stack on top (Slice 3.6).

const SPEED         := 120.0
const MAX_HEALTH    := 120
const MELEE_DAMAGE  := 15   # lore ref, not an active attack path
const RESPAWN_TIME  := 3.0

const BULLET_SCRIPT  := preload("res://scenes/Bullet.gd")
const ANIM_LOADER    := preload("res://scenes/AnimationLoader.gd")
const FIRE_COOLDOWN  := 0.25

signal downed
signal respawned

var health    := MAX_HEALTH
var hero_name : String = "enforcer"

# Bodega upgrade fields
var bullet_damage_bonus   : int   = 0
var fire_cooldown_override: float = 0.0
var infinite_clip         : bool  = false

var _joystick : Control = null
var _facing   := Vector2.RIGHT
var _fire_timer := 0.0
var _shooting   := false   # true for one frame after fire() — drives shoot anim
var _shoot_timer := 0.0
const SHOOT_ANIM_DURATION := 0.12   # seconds to hold "shoot" before returning to walk/idle

var _anim: AnimatedSprite2D = null  # set in _ready(); null = no sheets loaded yet


func _ready() -> void:
	add_to_group("player")
	call_deferred("_find_joystick")
	call_deferred("_setup_animation")


func _find_joystick() -> void:
	_joystick = get_tree().get_first_node_in_group("virtual_joystick")


func _setup_animation() -> void:
	_anim = get_node_or_null("Anim") as AnimatedSprite2D
	if _anim == null:
		_anim = AnimatedSprite2D.new()
		_anim.name = "Anim"
		_anim.position = Vector2(0, -12)
		add_child(_anim)

	var sprite_dir := "res://assets/sprites/heroes/%s/" % hero_name
	var sf: SpriteFrames = ANIM_LOADER.build_frames(ANIM_LOADER.player_anims(sprite_dir))
	if sf == null:
		# No sheets — keep static Sprite2D visible, hide AnimatedSprite2D.
		_anim.visible = false
		return

	_anim.sprite_frames = sf
	_anim.visible = true

	# Hide the static Sprite2D placeholder now that we have real animation.
	var static_sprite := get_node_or_null("PlayerSprite")
	if static_sprite:
		static_sprite.visible = false

	_anim.play("idle")


func _physics_process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	if _joystick and _joystick.output.length() > 0.0:
		input_vector = _joystick.output
	else:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	var speed_mult := _stress_speed_mult() \
		* (1.0 + RelationshipSystem.get_speed_bonus(hero_name))
	velocity = input_vector * SPEED * speed_mult
	move_and_slide()

	if input_vector.length() > 0.0:
		_facing = input_vector.normalized()

	_fire_timer  = maxf(0.0, _fire_timer  - delta)
	_shoot_timer = maxf(0.0, _shoot_timer - delta)

	_update_animation(input_vector)


func _update_animation(input_vector: Vector2) -> void:
	if _anim == null or not _anim.visible:
		return

	if is_dead():
		_play_once("downed")
		return

	if _shoot_timer > 0.0:
		_play_once("shoot")
		return

	if input_vector.length() < 0.1:
		_play("idle")
		return

	# 8-direction → 4 walk animations.  Left/right take priority over up/down
	# so diagonal movement looks horizontal (most natural for top-down 3/4 view).
	if absf(input_vector.x) >= absf(input_vector.y):
		_play("walk_right" if input_vector.x >= 0.0 else "walk_left")
	else:
		_play("walk_down" if input_vector.y >= 0.0 else "walk_up")


func _play(anim_name: String) -> void:
	if _anim and _anim.visible and _anim.sprite_frames \
			and _anim.sprite_frames.has_animation(anim_name) \
			and _anim.animation != anim_name:
		_anim.play(anim_name)


func _play_once(anim_name: String) -> void:
	if _anim and _anim.visible and _anim.sprite_frames \
			and _anim.sprite_frames.has_animation(anim_name) \
			and _anim.animation != anim_name:
		_anim.play(anim_name)


func _stress_speed_mult() -> float:
	if Stress.stress >= Stress.THRESHOLD_CRITICAL:
		return 0.70
	if Stress.stress >= Stress.THRESHOLD_ELEVATED:
		return 0.85
	return 1.0


func fire() -> void:
	if _fire_timer > 0.0:
		return
	var base      := fire_cooldown_override if fire_cooldown_override > 0.0 else FIRE_COOLDOWN
	var s_mult    := 2.0 if Stress.stress >= Stress.THRESHOLD_CRITICAL else 1.0
	_fire_timer   = base * s_mult
	_shoot_timer  = SHOOT_ANIM_DURATION

	var bullet := Area2D.new()
	bullet.set_script(BULLET_SCRIPT)
	bullet.direction     = _facing
	bullet.shooter       = hero_name
	bullet.damage_bonus  = bullet_damage_bonus \
		+ RelationshipSystem.get_damage_bonus(hero_name)
	get_parent().add_child(bullet)
	bullet.global_position = global_position + _facing * 12.0


func take_damage(amount: int) -> void:
	var was_dead := is_dead()
	health = clampi(health - amount, 0, MAX_HEALTH)
	if is_dead() and not was_dead:
		Stress.on_crew_member_downed()
		Injury.on_hero_downed()
		RelationshipSystem.on_hero_downed(hero_name)
		set_physics_process(false)
		_play_once("downed")
		downed.emit()
		_start_respawn()


func _start_respawn() -> void:
	await get_tree().create_timer(RESPAWN_TIME).timeout
	health = MAX_HEALTH
	set_physics_process(true)
	_play("idle")
	respawned.emit()


func is_dead() -> bool:
	return health <= 0
