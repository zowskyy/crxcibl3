extends Area2D
## Blackwood's "divine light" projectile (Slice 2.18).
## Same pattern as Bullet.gd but fired by the boss at the player.

var direction := Vector2.RIGHT
var speed := 180.0
var damage := 12

const LIFETIME := 2.0
const RADIUS := 6.0

var _age := 0.0


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_age += delta
	if _age >= LIFETIME:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.95, 0.6))  # warm gold/white flash
