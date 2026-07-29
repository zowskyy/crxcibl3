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

## Gang squad AI + cover system (wow.txt spec). Cover-seeking only kicks in
## where a level has placed CoverPoint nodes within COVER_SEARCH_RADIUS --
## grunts fall back to the original direct chase otherwise, so existing
## scenes without cover markers are unaffected.
const COVER_SEARCH_RADIUS := 180.0
const COVER_CLOSE_ENOUGH  := 10.0
const CROUCH_TIME         := 1.2   # time spent down behind cover
const POP_TIME            := 0.6   # time exposed, advancing toward the threat
const SUPPRESSION_BONUS   := 1.0   # extra crouch time added when hit while popped up

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
	_suppression_timer = maxf(0.0, _suppression_timer - delta)

	if _player == null:
		return

	var to_player := _player.global_position - global_position
	var distance  := to_player.length()

	var threat_nearby := distance <= DETECTION_RADIUS
	if threat_nearby and not _in_combat:
		_in_combat = true
		Stress.enter_combat()
		SquadController.alert_squad(self, faction_id, _player)
	elif not threat_nearby and _in_combat:
		_in_combat = false
		Stress.exit_combat()
		_release_cover()

	if distance <= ATTACK_RANGE:
		_release_cover()
		velocity = Vector2.ZERO
		_set_anim("attack")
		_try_attack()
	elif distance <= DETECTION_RADIUS:
		if not _tick_cover_seeking(delta, to_player, distance):
			var speed_mult := 0.5 if _suppression_timer > 0.0 else 1.0
			velocity = to_player.normalized() * SPEED * speed_mult
			_set_anim("walk")
	else:
		velocity = Vector2.ZERO
		_set_anim("idle")

	move_and_slide()


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
	return _cover_point


## Returns true if cover-seeking handled movement this frame (caller should
## skip the default direct-chase). Returns false (and touches nothing) when
## no cover point is in range, so behavior is unchanged in cover-less scenes.
func _tick_cover_seeking(delta: float, to_player: Vector2, distance: float) -> bool:
	if _cover_point != null and not is_instance_valid(_cover_point):
		_release_cover()  # cover point vanished from under us -- fall back to the search

	if _cover_point == null:
		_cover_point = _find_best_cover(distance)
		if _cover_point == null:
			return false
		_cover_point.claim(self)
		_in_cover = false
		_popped_up = false
		_cover_cycle_timer = 0.0

	var to_cover: Vector2 = _cover_point.global_position - global_position
	if to_cover.length() > COVER_CLOSE_ENOUGH:
		_in_cover = false  # still exposed in transit -- take_damage() must not mitigate yet
		velocity = to_cover.normalized() * SPEED
		_set_anim("walk")
		return true

	# At the cover point: crouch/pop-up cycle.
	_in_cover = true
	_cover_cycle_timer += delta
	if _popped_up:
		if _cover_cycle_timer >= POP_TIME:
			_popped_up = false
			_cover_cycle_timer = 0.0
			# Advance from this cover -- release it and find the next one
			# closer to the threat, leapfrogging toward the player.
			_release_cover()
			return true
		velocity = to_player.normalized() * SPEED * 0.5
		_set_anim("walk")
	else:
		velocity = Vector2.ZERO
		_set_anim("idle")
		if _cover_cycle_timer >= CROUCH_TIME:
			_popped_up = true
			_cover_cycle_timer = 0.0
	return true


func _find_best_cover(threat_distance: float) -> Node2D:
	if threat_distance <= ATTACK_RANGE * 2.0:
		return null  # close enough to just fight -- don't dive for cover mid-swing
	var candidates := get_tree().get_nodes_in_group("cover_point")
	var ally_angles := SquadController.ally_cover_angles(self, faction_id, _player.global_position)

	var best: Node2D = null
	var best_score := -INF
	for cp in candidates:
		if global_position.distance_to(cp.global_position) > COVER_SEARCH_RADIUS:
			continue
		if not (cp.is_free() or cp.occupied_by == self):
			continue
		var s: float = cp.score(global_position, _player.global_position, ally_angles)
		if s > best_score:
			best_score = s
			best = cp
	return best


func _release_cover() -> void:
	if _cover_point:
		_cover_point.release(self)
		_cover_point = null
	_in_cover = false
	_popped_up = false
	_cover_cycle_timer = 0.0


func _set_anim(state: String) -> void:
	if _anim and _has_sheets and _anim.animation != state:
		_anim.play(state)


func _try_attack() -> void:
	if _attack_timer <= 0.0 and _player.has_method("take_damage"):
		_player.take_damage(ATTACK_DAMAGE)
		Stress.on_hit_taken()
		_attack_timer = ATTACK_COOLDOWN


func take_damage(amount: int, killer: String = "") -> void:
	if _in_cover and is_instance_valid(_cover_point):
		if _popped_up:
			# Hit while exposed -- suppression forces them back down.
			_popped_up = false
			_cover_cycle_timer = -SUPPRESSION_BONUS
		elif _cover_point.high_cover:
			amount = 0  # fully blocked behind high cover while crouched
		else:
			amount = int(amount * 0.5)  # low cover softens the hit
	else:
		_suppression_timer = OPEN_SUPPRESSION_TIME  # no cover to duck behind -- just flinch

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
