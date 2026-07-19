extends CharacterBody2D
## Rival crew grunt -- Slice 2.12's first enemy. Placeholder dark square
## (no enemy art exists yet -- same "build the behavior first, swap real
## art in later" pattern already used for the player and the boardwalk
## buildings). Chases the player once within DETECTION_RADIUS and attacks
## on contact with a cooldown.
##
## Slice 2.16 shader integration: on death, runs a dissolve animation via
## enemy_dissolve.gdshader before freeing. The dark square gets a
## ShaderMaterial applied at runtime (no separate .tscn needed) and
## dissolve_progress ramps from 0 -> 1 over DISSOLVE_TIME seconds.

const SPEED := 70.0
const SIZE := 16.0
const DETECTION_RADIUS := 150.0
const ATTACK_RANGE := 20.0
const ATTACK_DAMAGE := 8
const ATTACK_COOLDOWN := 1.0
const MAX_HEALTH := 40
const DISSOLVE_TIME := 0.5  # seconds for death dissolve

var health := MAX_HEALTH

var _attack_timer := 0.0
var _player: CharacterBody2D = null
var _in_combat := false
var _dying := false
var _dissolve_progress := 0.0
var _dissolve_mat: ShaderMaterial = null


func _ready() -> void:
	add_to_group("enemy")
	EnemyRegistry.register(self)   # auto-unregisters on tree_exiting
	call_deferred("_find_player")
	_setup_dissolve_shader()


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")


func _setup_dissolve_shader() -> void:
	var shader := load("res://assets/shaders/enemy_dissolve.gdshader") as Shader
	if shader == null:
		return
	_dissolve_mat = ShaderMaterial.new()
	_dissolve_mat.shader = shader
	material = _dissolve_mat


func _physics_process(delta: float) -> void:
	if _dying:
		_dissolve_progress = minf(_dissolve_progress + delta / DISSOLVE_TIME, 1.0)
		if _dissolve_mat:
			_dissolve_mat.set_shader_parameter("dissolve_progress", _dissolve_progress)
		if _dissolve_progress >= 1.0:
			queue_free()
		return

	_attack_timer = maxf(0.0, _attack_timer - delta)

	if _player == null:
		return

	var to_player := _player.global_position - global_position
	var distance := to_player.length()

	# Combat state (Slice 2.13): Stress climbs while a threat is nearby and
	# decays once it isn't -- tied to detection range rather than only the
	# attack itself, so the crew's nerves stay frayed for the whole
	# chase, not just the instant of a hit. Only toggled on transition,
	# not every frame -- enter_combat()/exit_combat() are idempotent flag
	# sets, but there's no reason to call them 60x/second.
	var threat_nearby := distance <= DETECTION_RADIUS
	if threat_nearby and not _in_combat:
		_in_combat = true
		Stress.enter_combat()
	elif not threat_nearby and _in_combat:
		_in_combat = false
		Stress.exit_combat()

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
		Stress.on_hit_taken()
		_attack_timer = ATTACK_COOLDOWN


func take_damage(amount: int, killer: String = "") -> void:
	health = maxi(0, health - amount)
	if health <= 0 and not _dying:
		_dying = true
		set_physics_process(false)   # stop chasing/attacking immediately
		# Clear combat state -- _physics_process won't reach the exit transition
		# anymore now that it's blocked, so clear explicitly (same reasoning as before).
		if _in_combat:
			_in_combat = false
			Stress.exit_combat()
		# Credit the group Rune pool immediately at kill, not after dissolve,
		# so the player sees the counter tick on the killing shot.
		GameState.add_rune(1, killer)
		set_physics_process(true)    # re-enable just for dissolve tick
		_dissolve_progress = 0.0


## Boss scripts remove their spawned deacons directly (flee/death cleanup).
## Going through here instead of a bare queue_free() keeps the Stress combat
## bookkeeping honest -- a mid-chase removal otherwise leaves _in_combat
## stuck true forever, since _physics_process never reaches its exit
## transition on a freed node (same failure mode Slice 2.13 fixed for
## take_damage-driven death).
func despawn() -> void:
	if _in_combat:
		_in_combat = false
		Stress.exit_combat()
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(-SIZE / 2, -SIZE / 2, SIZE, SIZE), Color(0.227, 0.227, 0.227))
