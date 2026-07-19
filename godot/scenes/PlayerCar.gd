extends CharacterBody2D
## Player vehicle for CarChaseScene (Slice 2.19).
## Left/right movement + limited forward/back drift within the road bounds.
## Carries bodega upgrade bonuses from the boardwalk run via fields set by
## CarChaseScene before _ready() if needed, or directly after add_child().

const SPEED_H := 150.0   # lateral
const SPEED_V := 60.0    # forward/back drift
const MAX_HP  := 150
const FIRE_COOLDOWN := 0.3

const ROAD_LEFT   := 78.0
const ROAD_RIGHT  := 306.0
const CHASE_TOP   := 110.0
const CHASE_BOT   := 200.0

const BULLET_SCRIPT := preload("res://scenes/Bullet.gd")

var hp := MAX_HP
var hero_name: String = "enforcer"
var bullet_damage_bonus: int = 0
var fire_cooldown_override: float = 0.0  # set by CarChaseScene if fire_rate upgrade owned

var _joystick: Control = null
var _fire_timer := 0.0


func _ready() -> void:
	add_to_group("player")
	call_deferred("_find_joystick")


func _find_joystick() -> void:
	_joystick = get_tree().get_first_node_in_group("virtual_joystick")


func _physics_process(delta: float) -> void:
	_fire_timer = maxf(0.0, _fire_timer - delta)

	var input := Vector2.ZERO
	if _joystick and _joystick.output.length() > 0.0:
		input = _joystick.output
	else:
		input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	velocity = Vector2(input.x * SPEED_H, input.y * SPEED_V)
	move_and_slide()
	global_position.x = clampf(global_position.x, ROAD_LEFT, ROAD_RIGHT)
	global_position.y = clampf(global_position.y, CHASE_TOP, CHASE_BOT)
	queue_redraw()


func fire() -> void:
	if _fire_timer > 0.0:
		return
	var cooldown := fire_cooldown_override if fire_cooldown_override > 0.0 else FIRE_COOLDOWN
	_fire_timer = cooldown
	var bullet := Area2D.new()
	bullet.set_script(BULLET_SCRIPT)
	bullet.direction = Vector2.UP
	bullet.shooter = hero_name
	bullet.damage_bonus = bullet_damage_bonus
	get_parent().add_child(bullet)
	bullet.global_position = global_position + Vector2(0, -18)


func take_damage(amount: int) -> void:
	hp = clampi(hp - amount, 0, MAX_HP)
	if hp <= 0:
		Stress.on_crew_member_downed()
	queue_redraw()


func is_dead() -> bool:
	return hp <= 0


func _draw() -> void:
	# Crew's lowrider — dark body, tinted windshields, green HP bar
	draw_rect(Rect2(-11, -18, 22, 36), Color(0.12, 0.14, 0.18))
	draw_rect(Rect2(-9,  -12, 18,  9), Color(0.45, 0.7, 0.85, 0.55))  # windshield
	draw_rect(Rect2(-9,   5,  18,  7), Color(0.45, 0.7, 0.85, 0.35))  # rear window
	# Headlights (facing up = forward)
	draw_rect(Rect2(-11, -18, 5, 3), Color(0.95, 0.92, 0.6))
	draw_rect(Rect2(6,   -18, 5, 3), Color(0.95, 0.92, 0.6))
	# Wheels
	draw_rect(Rect2(-15, -14, 5, 9), Color(0.08, 0.08, 0.08))
	draw_rect(Rect2(10,  -14, 5, 9), Color(0.08, 0.08, 0.08))
	draw_rect(Rect2(-15,  6,  5, 9), Color(0.08, 0.08, 0.08))
	draw_rect(Rect2(10,   6,  5, 9), Color(0.08, 0.08, 0.08))
	# HP bar
	var bar_w := 26.0
	var fill := bar_w * (float(hp) / float(MAX_HP))
	draw_rect(Rect2(-bar_w * 0.5, -24, bar_w, 3), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(-bar_w * 0.5, -24, fill,  3), Color(0.2, 0.85, 0.3))
