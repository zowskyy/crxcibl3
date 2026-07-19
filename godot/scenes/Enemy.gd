extends CharacterBody2D
## Rival crew grunt -- Slice 2.12's first enemy. Placeholder dark square
## (no enemy art exists yet -- same "build the behavior first, swap real
## art in later" pattern already used for the player and the boardwalk
## buildings). Chases the player once within DETECTION_RADIUS and attacks
## on contact with a cooldown.

const SPEED := 70.0
const SIZE := 16.0
const DETECTION_RADIUS := 150.0
const ATTACK_RANGE := 20.0
const ATTACK_DAMAGE := 8
const ATTACK_COOLDOWN := 1.0
const MAX_HEALTH := 40

var health := MAX_HEALTH

var _attack_timer := 0.0
var _player: CharacterBody2D = null


func _ready() -> void:
	# Deferred for the same reason Player's joystick lookup is: whichever
	# node calls add_to_group("player") might not have run its _ready()
	# yet at this point, depending on scene tree declaration order.
	call_deferred("_find_player")


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	_attack_timer = maxf(0.0, _attack_timer - delta)

	if _player == null:
		return

	var to_player := _player.global_position - global_position
	var distance := to_player.length()

	if distance <= ATTACK_RANGE:
		velocity = Vector2.ZERO
		_try_attack()
	elif distance <= DETECTION_RADIUS:
		velocity = to_player.normalized() * SPEED
	else:
		velocity = Vector2.ZERO

	move_and_slide()


func _try_attack() -> void:
	if _attack_timer <= 0.0 and _player.has_method("take_damage"):
		_player.take_damage(ATTACK_DAMAGE)
		_attack_timer = ATTACK_COOLDOWN


func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
	if health <= 0:
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-SIZE / 2, -SIZE / 2, SIZE, SIZE), Color(0.227, 0.227, 0.227))
