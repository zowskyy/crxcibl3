extends CharacterBody2D
## The Enforcer (Ghost / Victor Reyes) -- Slice 2.11: first real playable
## hero, replacing the placeholder crimson square. Stats match
## configs/game_config.json's balance.hero_health/hero_damage for
## "enforcer" (120 HP, 15 dmg) -- hardcoded here rather than loaded from
## JSON at runtime, since there's no JSON-loading infrastructure yet and
## this is the only consumer so far.
##
## Reads from the virtual joystick (touch or mouse drag) when present,
## falling back to arrow keys so desktop testing in the editor still
## works without dragging it. CharacterBody2D so it actually collides
## with the boardwalk room's building/fence StaticBody2D obstacles.

const SPEED := 120.0
const MAX_HEALTH := 120
const MELEE_DAMAGE := 15  # kept for reference/lore continuity; no longer the attack path
const RESPAWN_TIME := 3.0  # seconds downed before returning to full HP

const BULLET_SCRIPT := preload("res://scenes/Bullet.gd")
const FIRE_COOLDOWN := 0.25  # ~4 shots/sec, Metal Slug-ish rapid but not instant

signal downed    # fires once when health first reaches 0
signal respawned # fires when the respawn timer completes

var health := MAX_HEALTH
var hero_name: String = "enforcer"  # set by whoever spawns the player

# --- Bodega upgrade fields (written by BodegaShop._apply_upgrade) ---
var bullet_damage_bonus: int = 0
var fire_cooldown_override: float = 0.0   # 0 = use FIRE_COOLDOWN default
var infinite_clip: bool = false           # no_reload upgrade

var _joystick: Control = null
var _facing := Vector2.RIGHT
var _fire_timer := 0.0


func _ready() -> void:
	add_to_group("player")
	# Deferred: Player is declared before CanvasLayer/VirtualJoystick in the
	# scene tree, so at _ready() time the joystick hasn't added itself to
	# the group yet (sibling _ready() order follows scene declaration
	# order). Deferring to the end of the frame runs this after the whole
	# tree has finished its _ready() pass.
	call_deferred("_find_joystick")


func _find_joystick() -> void:
	_joystick = get_tree().get_first_node_in_group("virtual_joystick")


func _physics_process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	if _joystick and _joystick.output.length() > 0.0:
		input_vector = _joystick.output
	else:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * SPEED * _stress_speed_mult()
	move_and_slide()

	if input_vector.length() > 0.0:
		_facing = input_vector.normalized()

	_fire_timer = maxf(0.0, _fire_timer - delta)


## Public so TestRoom.gd can wire a Fire button/key to it (same pattern as
## the existing Add Heat button) -- Metal Slug-style gun combat per the
## Architect's direction, replacing the melee-contact assumption from
## Slice 2.11/2.12 (MELEE_DAMAGE was never actually used by any attack).
func _stress_speed_mult() -> float:
	if Stress.stress >= Stress.THRESHOLD_CRITICAL:
		return 0.70
	if Stress.stress >= Stress.THRESHOLD_ELEVATED:
		return 0.85
	return 1.0


func fire() -> void:
	if _fire_timer > 0.0:
		return
	var base := fire_cooldown_override if fire_cooldown_override > 0.0 else FIRE_COOLDOWN
	var stress_mult := 2.0 if Stress.stress >= Stress.THRESHOLD_CRITICAL else 1.0
	var cooldown := base * stress_mult
	_fire_timer = cooldown
	# infinite_clip is a forward-looking flag: when an ammo system exists,
	# this skips the "out of ammo" block. No effect yet.

	var bullet := Area2D.new()
	bullet.set_script(BULLET_SCRIPT)
	bullet.direction = _facing
	bullet.shooter = hero_name
	bullet.damage_bonus = bullet_damage_bonus
	get_parent().add_child(bullet)
	bullet.global_position = global_position + _facing * 12.0


func take_damage(amount: int) -> void:
	var was_dead := is_dead()
	health = clampi(health - amount, 0, MAX_HEALTH)
	if is_dead() and not was_dead:
		Stress.on_crew_member_downed()
		set_physics_process(false)   # freeze movement and firing input
		downed.emit()
		_start_respawn()


func _start_respawn() -> void:
	await get_tree().create_timer(RESPAWN_TIME).timeout
	health = MAX_HEALTH
	set_physics_process(true)
	respawned.emit()


func is_dead() -> bool:
	return health <= 0
