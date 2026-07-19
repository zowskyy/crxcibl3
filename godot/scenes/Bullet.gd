extends Area2D
## Metal Slug-style projectile -- Architect's creative direction: gun
## combat, not melee-only punches. Built entirely in code (constructs its
## own CollisionShape2D in _ready()) rather than as a separate .tscn,
## since Player.gd instantiates a fresh one per shot.

const SPEED := 400.0
const DAMAGE := 15
const LIFETIME := 1.2
const RADIUS := 5.0

var direction := Vector2.RIGHT
var shooter: String = ""   # hero_name of the player who fired this
var damage_bonus: int = 0  # added by bullet_damage upgrade

var _age := 0.0


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	_age += delta
	if _age >= LIFETIME:
		queue_free()


func _on_body_entered(body: Node) -> void:
	# Group check, not physics layers -- Player/Enemy are both on the
	# engine's default layer/mask, so filtering by group is what keeps
	# this from also triggering on the player who fired it.
	if (body.is_in_group("enemy") or body.is_in_group("spawn_generator") \
			or body.is_in_group("boss")) \
			and body.has_method("take_damage"):
		body.take_damage(DAMAGE + damage_bonus, shooter)
		Stress.on_hit_dealt()
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.85, 0.2))
