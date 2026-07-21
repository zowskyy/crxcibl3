extends CharacterBody2D
## Rival crew grunt. Chase/attack AI with AnimatedSprite2D animation system.
##
## Animation states: idle, walk, attack, die
## Sheets loaded from res://assets/sprites/enemies/grunt/ at runtime.
## Falls back to _draw() dark square if sheets are missing.

const SPEED            := 70.0
const SIZE             := 16.0
const DETECTION_RADIUS := 150.0
const ATTACK_RANGE     := 20.0
const ATTACK_DAMAGE    := 8
const ATTACK_COOLDOWN  := 1.0
const MAX_HEALTH       := 40
const DISSOLVE_TIME    := 0.5

var health := MAX_HEALTH

var _attack_timer     := 0.0
var _player: CharacterBody2D = null
var _in_combat        := false
var _dying            := false
var _dissolve_progress := 0.0
var _dissolve_mat: ShaderMaterial = null
var _anim: AnimatedSprite2D = null
var _has_sheets       := false


func _ready() -> void:
	add_to_group("enemy")
	EnemyRegistry.register(self)
	call_deferred("_find_player")
	_setup_dissolve_shader()
	call_deferred("_setup_animation")


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")


func _setup_dissolve_shader() -> void:
	var shader := load("res://assets/shaders/enemy_dissolve.gdshader") as Shader
	if shader == null:
		return
	_dissolve_mat = ShaderMaterial.new()
	_dissolve_mat.shader = shader
	material = _dissolve_mat


const ANIM_LOADER := preload("res://scenes/AnimationLoader.gd")

func _setup_animation() -> void:
	_anim = AnimatedSprite2D.new()
	_anim.name = "Anim"
	_anim.position = Vector2(0, -8)
	add_child(_anim)

	var sprite_dir := "res://assets/sprites/enemies/grunt/"
	var sf: SpriteFrames = ANIM_LOADER.build_frames(ANIM_LOADER.enemy_anims(sprite_dir))
	if sf == null:
		_anim.visible = false
		return

	_anim.sprite_frames = sf
	_anim.visible       = true
	_has_sheets         = true
	_anim.play("idle")


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
	var distance  := to_player.length()

	var threat_nearby := distance <= DETECTION_RADIUS
	if threat_nearby and not _in_combat:
		_in_combat = true
		Stress.enter_combat()
	elif not threat_nearby and _in_combat:
		_in_combat = false
		Stress.exit_combat()

	if distance <= ATTACK_RANGE:
		velocity = Vector2.ZERO
		_set_anim("attack")
		_try_attack()
	elif distance <= DETECTION_RADIUS:
		velocity = to_player.normalized() * SPEED
		_set_anim("walk")
	else:
		velocity = Vector2.ZERO
		_set_anim("idle")

	move_and_slide()


func _set_anim(state: String) -> void:
	if _anim and _has_sheets and _anim.animation != state:
		_anim.play(state)


func _try_attack() -> void:
	if _attack_timer <= 0.0 and _player.has_method("take_damage"):
		_player.take_damage(ATTACK_DAMAGE)
		Stress.on_hit_taken()
		_attack_timer = ATTACK_COOLDOWN


func take_damage(amount: int, killer: String = "") -> void:
	health = maxi(0, health - amount)
	if health <= 0 and not _dying:
		_dying = true
		set_physics_process(false)
		if _in_combat:
			_in_combat = false
			Stress.exit_combat()
		GameState.add_rune(1, killer)
		if killer != "":
			RelationshipSystem.on_kill_together(killer)
		# Play die animation then let dissolve take over
		if _anim and _has_sheets:
			_anim.play("die")
		set_physics_process(true)
		_dissolve_progress = 0.0


func despawn() -> void:
	if _in_combat:
		_in_combat = false
		Stress.exit_combat()
	queue_free()


func _draw() -> void:
	if _has_sheets:
		return  # real art loaded — don't overdraw
	draw_rect(Rect2(-SIZE / 2, -SIZE / 2, SIZE, SIZE), Color(0.227, 0.227, 0.227))
