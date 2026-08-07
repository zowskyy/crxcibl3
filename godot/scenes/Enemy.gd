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

## Hitscan combat stats (wow.txt spec) applied to incoming damage: armor
## mitigation uses a WoW-style diminishing-returns curve (each point of
## armor is worth less than the last, never reaches 100%), and any hit
## taken in the open briefly suppresses movement even without cover.
const ARMOR_K            := 50.0   # higher = armor needs more points per % mitigated
const OPEN_SUPPRESSION_TIME := 0.8

@export var faction_id: String = "rival_crew"
@export var armor: int = 0

var health := MAX_HEALTH

var _attack_timer     := 0.0
var _player: CharacterBody2D = null
var _in_combat        := false
var _dying            := false
var _dissolve_progress := 0.0
var _dissolve_mat: ShaderMaterial = null
var _anim: AnimatedSprite2D = null
var _has_sheets       := false

var _cover_point: Node2D = null
var _in_cover          := false  # true only once actually AT the cover point, not merely claimed
var _popped_up        := false
var _cover_cycle_timer := 0.0
var _suppression_timer := 0.0


func _ready() -> void:
	add_to_group("enemy")
	EnemyRegistry.register(self)
	SquadController.join_squad(self, faction_id)
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
	_dissolve_mat.set_shader_parameter("noise_texture", DissolveTextures.make_noise_texture())
	_dissolve_mat.set_shader_parameter("overlay_texture", DissolveTextures.make_overlay_texture())
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
	EnemyMovement.physics_tick(self, delta)


## Alerted by a squad mate that spotted or was hurt by the player (see
## SquadController.alert_squad). Engages immediately instead of waiting on
## its own DETECTION_RADIUS check.
func on_squad_alert(threat: Node) -> void:
	if _in_combat or _dying:
		return
	if threat is CharacterBody2D:
		_player = threat
	_in_combat = true
	Stress.enter_combat()


func get_cover_point() -> Node2D:
	return EnemyCoverAI.get_cover_point(self)


func _set_anim(state: String) -> void:
	if _anim and _has_sheets and _anim.animation != state:
		_anim.play(state)


func _try_attack() -> void:
	if _attack_timer <= 0.0 and _player.has_method("take_damage"):
		_player.take_damage(ATTACK_DAMAGE)
		Stress.on_hit_taken()
		_attack_timer = ATTACK_COOLDOWN


func take_damage(amount: int, killer: String = "") -> void:
	amount = EnemyCoverAI.apply_cover_damage(self, amount)

	if armor > 0:
		var mitigation := float(armor) / (float(armor) + ARMOR_K)  # diminishing returns, never hits 100%
		amount = int(round(amount * (1.0 - mitigation)))

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
		QuestManager.notify_event("kill", "enemy")
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
