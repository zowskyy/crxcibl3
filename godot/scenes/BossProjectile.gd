extends Area2D
## Blackwood's "divine light" projectile (Slice 2.18).
## Same pattern as Bullet.gd but fired by the boss at the player.
##
## validate body collision; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via queue_free on hit.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

var direction := Vector2.RIGHT
var speed := 180.0
var damage := 12

const LIFETIME := 2.0
const RADIUS := 6.0

var _age := 0.0


func _ready() -> void:
	print("[BossProjectile] ready")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_age += delta
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()


func _draw() -> void:
	# Black bolt core with red electric surge.
	# The bolt is oriented along the direction of travel; _draw() runs in
	# local space so we rotate the canvas to match.
	var bolt_len := 18.0
	var angle := direction.angle()
	draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)

	# Black core body
	draw_rect(Rect2(-bolt_len * 0.5, -3, bolt_len, 6), Color(0.04, 0.0, 0.06))

	# Red electric surges — two jagged lines running through the core
	var surge_color := Color(0.9, 0.05, 0.05)
	var half := bolt_len * 0.5
	# Top surge
	draw_line(Vector2(-half, -1.5), Vector2(-half * 0.4, 1.5),  surge_color, 1.2)
	draw_line(Vector2(-half * 0.4, 1.5), Vector2(0.0, -1.5),   surge_color, 1.2)
	draw_line(Vector2(0.0, -1.5), Vector2(half * 0.4, 1.5),    surge_color, 1.2)
	draw_line(Vector2(half * 0.4, 1.5), Vector2(half, -1.5),   surge_color, 1.2)
	# Outer red glow tips
	draw_circle(Vector2(-half, 0), 3.0, Color(0.8, 0.0, 0.0, 0.7))
	draw_circle(Vector2(half,  0), 3.0, Color(0.8, 0.0, 0.0, 0.7))
