extends CharacterBody2D
## Cop / rival crew pursuit car (Slice 2.19).
## Spawned dynamically by CarChaseScene. Chases the player car, rams on
## close contact, and fires black/red bolts (same BossProjectile pattern).
## One bullet kill — numerous but fragile, rewarding the player for shooting.

const SPEED          := 95.0
const RAM_DAMAGE     := 20
const RAM_COOLDOWN   := 1.2   # seconds between ram hits (same enemy can't spam)
const FIRE_INTERVAL  := 3.5
const PROJ_SPEED     := 130.0
const PROJ_DAMAGE    := 10
const DESPAWN_Y      := 270.0  # past bottom of canvas — safe to free

const PROJECTILE_SCRIPT := preload("res://scenes/BossProjectile.gd")
const SIREN_SCRIPT       := preload("res://scenes/VehicleSiren.gd")

var _player: CharacterBody2D = null
var _fire_timer  := randf_range(1.0, 3.0)  # stagger first shot per car
var _ram_timer   := 0.0


func _ready() -> void:
	add_to_group("enemy")
	var col  := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 32)
	col.shape = rect
	add_child(col)

	var siren := Node2D.new()
	siren.name = "Siren"
	siren.set_script(SIREN_SCRIPT)
	siren.position = Vector2(0, -17.5)
	add_child(siren)

	call_deferred("_find_player")


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if _player == null:
		return

	var to_player := _player.global_position - global_position
	velocity = to_player.normalized() * SPEED
	move_and_slide()

	# Ram damage with cooldown
	_ram_timer = maxf(0.0, _ram_timer - delta)
	if to_player.length() < 22.0 and _ram_timer <= 0.0:
		if _player.has_method("take_damage"):
			_player.take_damage(RAM_DAMAGE)
		_ram_timer = RAM_COOLDOWN

	# Fire projectile at player
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = FIRE_INTERVAL
		_fire_shot(to_player.normalized())

	# Despawn when fully off-screen below
	if global_position.y > DESPAWN_Y:
		queue_free()


func _fire_shot(direction: Vector2) -> void:
	var proj := Area2D.new()
	proj.set_script(PROJECTILE_SCRIPT)
	proj.direction = direction
	proj.speed     = PROJ_SPEED
	proj.damage    = PROJ_DAMAGE
	get_parent().add_child(proj)
	proj.global_position = global_position + direction * 18.0


func take_damage(amount: int, killer: String = "") -> void:
	GameState.add_rune(1, killer)
	queue_free()


func _draw() -> void:
	# Cop/rival pursuit car — dark red body, blinking siren roof bar
	draw_rect(Rect2(-10, -16, 20, 32), Color(0.18, 0.08, 0.08))
	# Windshield (rear — facing player since car comes from top)
	draw_rect(Rect2(-8, -4, 16, 9), Color(0.4, 0.6, 0.8, 0.45))
	# Siren drawn by the optional Siren child node (VehicleSiren.gd)
	# Wheels
	draw_rect(Rect2(-14, -12, 5, 9), Color(0.08, 0.08, 0.08))
	draw_rect(Rect2(9,   -12, 5, 9), Color(0.08, 0.08, 0.08))
	draw_rect(Rect2(-14,  5,  5, 9), Color(0.08, 0.08, 0.08))
	draw_rect(Rect2(9,    5,  5, 9), Color(0.08, 0.08, 0.08))
