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
##
## validate animation frames; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via HeroFactory.switch_active_hero().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const SPEED         := 120.0
const MAX_HEALTH    := 120
const MELEE_DAMAGE  := 15   # lore ref, not an active attack path
const RESPAWN_TIME  := 3.0

const ANIM_LOADER    := preload("res://scenes/AnimationLoader.gd")
const PLAYER_COOP_BRIDGE := preload("res://scenes/PlayerCoopBridge.gd")
const PLAYER_DAMAGE := preload("res://scenes/PlayerDamage.gd")
const PLAYER_ANIMATION := preload("res://scenes/PlayerAnimation.gd")
const FIRE_COOLDOWN  := 0.25
const RECOIL_SPREAD_DEG := 4.0
const ARMOR_K := 50.0

signal downed
signal respawned

var health    := MAX_HEALTH
var hero_name : String = "enforcer"
var speaking  := false
var _lip_phase := 0.0

# Bodega upgrade fields
var bullet_damage_bonus   : int   = 0
var fire_cooldown_override: float = 0.0
var infinite_clip         : bool  = false

var _joystick : Control = null
var _facing   := Vector2.RIGHT
var _fire_timer := 0.0
var _shooting   := false   # holds shoot anim one frame after fire()
var _shoot_timer := 0.0
const SHOOT_ANIM_DURATION := 0.12   # seconds to hold "shoot" before returning to walk/idle

var _anim: AnimatedSprite2D = null  # set in _ready(); null = no sheets loaded yet
var _fire_pressed_this_tick := false


func _ready() -> void:
	add_to_group("player")
	print("[Player] ready")
	call_deferred("_find_joystick")
	call_deferred("_setup_animation")
	call_deferred("_apply_rpg_bonuses")


func _apply_rpg_bonuses() -> void:
	var hp_bonus := RelationshipSystem.get_hp_bonus(hero_name)
	health = MAX_HEALTH + hp_bonus


func set_speaking(active: bool) -> void:
	speaking = active
	if not speaking:
		_lip_phase = 0.0


func play_gesture(_name: String) -> void:
	set_speaking(true)


func _draw() -> void:
	if not speaking:
		return
	_lip_phase += 0.0  # driven in _physics_process
	var open := absf(sin(_lip_phase)) > 0.35
	var mouth_h := 2.5 if open else 0.8
	draw_rect(Rect2(-2, -2, 4, mouth_h), Color(0.1, 0.05, 0.05))


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
	var input_vector := get_move_input_vector()

	var speed_mult := _stress_speed_mult() \
		* (1.0 + RelationshipSystem.get_speed_bonus(hero_name))
	velocity = input_vector * SPEED * speed_mult
	move_and_slide()

	_facing = input_vector.normalized() if input_vector.length() > 0.0 else _facing

	_fire_timer  = maxf(0.0, _fire_timer  - delta)
	_shoot_timer = maxf(0.0, _shoot_timer - delta)

	if speaking:
		_lip_phase += delta * 14.0
		queue_redraw()

	var regen := RelationshipSystem.get_regen_bonus(hero_name)
	if regen > 0.0 and health < _max_health():
		health = mini(_max_health(), health + int(regen * delta))

	PLAYER_ANIMATION.update_animation(self, _anim, input_vector, _shoot_timer)


func _play(anim_name: String) -> void:
	PLAYER_ANIMATION._play(_anim, anim_name)


func _play_once(anim_name: String) -> void:
	PLAYER_ANIMATION._play_once(_anim, anim_name)


func _stress_speed_mult() -> float:
	var tier := int(Stress.stress >= Stress.THRESHOLD_ELEVATED) \
		+ int(Stress.stress >= Stress.THRESHOLD_CRITICAL)
	return [1.0, 0.85, 0.70][mini(2, tier)]


func fire() -> void:
	if _fire_timer > 0.0:
		return
	var base      := fire_cooldown_override if fire_cooldown_override > 0.0 else FIRE_COOLDOWN
	var s_mult    := 2.0 if Stress.stress >= Stress.THRESHOLD_CRITICAL else 1.0
	base         *= (1.0 + Inventory.get_stat_bonus("fire_rate"))
	_fire_timer   = maxf(0.05, base * s_mult)
	_shoot_timer  = SHOOT_ANIM_DURATION

	var recoil_angle := deg_to_rad(randf_range(-RECOIL_SPREAD_DEG, RECOIL_SPREAD_DEG))
	var bullet_dir := _facing.rotated(recoil_angle)
	var dmg_bonus := bullet_damage_bonus + RelationshipSystem.get_damage_bonus(hero_name)
	var crit_bonus := Inventory.get_stat_bonus("crit_chance") \
		+ RelationshipSystem.get_crit_bonus(hero_name)
	Bullet.spawn(
		get_parent(),
		global_position + _facing * 12.0,
		bullet_dir,
		hero_name,
		dmg_bonus,
		crit_bonus,
	)

	if not infinite_clip:
		Scarcity.add_scarcity(2.0)
	_fire_pressed_this_tick = true


func consume_fire_input() -> bool:
	var pressed := _fire_pressed_this_tick
	_fire_pressed_this_tick = false
	return pressed


func get_move_input_vector() -> Vector2:
	if _joystick and _joystick.output.length() > 0.0:
		return _joystick.output
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")


func take_damage(amount: int, attacker: String = "") -> void:
	var armor_bonus := Inventory.get_stat_bonus("armor") + float(RelationshipSystem.get_armor_bonus(hero_name))
	if armor_bonus > 0.0:
		var mitigation := armor_bonus / (armor_bonus + ARMOR_K)
		amount = int(round(amount * (1.0 - mitigation)))

	if PLAYER_COOP_BRIDGE.route_damage(self, amount, attacker):
		return

	_apply_damage_local(amount, attacker)
	if CoopNetwork.is_online() and CoopNetwork.is_host():
		CoopNetwork.notify_host_player_state(self)


func apply_authoritative_state(pos: Vector2, facing: Vector2, new_health: int) -> void:
	var result := PLAYER_COOP_BRIDGE.apply_authoritative_state(self, pos, facing, new_health, _max_health())
	if not result.get("changed", false):
		return
	if result.get("became_dead", false):
		PLAYER_DAMAGE.on_player_downed(self, hero_name)
		_start_respawn()
	elif result.get("revived", false):
		set_physics_process(true)
		_play("idle")
		respawned.emit()


func _apply_damage_local(amount: int, _attacker: String = "") -> void:
	if PLAYER_DAMAGE.apply_local_damage(self, amount, _max_health()):
		PLAYER_DAMAGE.on_player_downed(self, hero_name)
		_start_respawn()


func _start_respawn() -> void:
	await PLAYER_DAMAGE.schedule_respawn(self, hero_name, RESPAWN_TIME)


func is_dead() -> bool:
	return health <= 0


func _max_health() -> int:
	return MAX_HEALTH + RelationshipSystem.get_hp_bonus(hero_name)
