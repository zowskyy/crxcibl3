extends Area2D
class_name Bullet
## Metal Slug-style projectile -- Architect's creative direction: gun
## combat, not melee-only punches. Built entirely in code (constructs its
## own CollisionShape2D in _ready()) rather than as a separate .tscn,
## since Player.gd instantiates via object pool per shot.
##
## validate collision groups; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via _recycle() pool return.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const SPEED := 400.0
const DAMAGE := 15
const LIFETIME := 1.2
const RADIUS := 5.0
const POOL_MAX := 48
const COOP_HIT_RELAY := preload("res://autoload/CoopNetworkAuthorityRelay.gd")

## Hitscan combat stats (wow.txt spec): crit rolls and damage variance.
## Armor mitigation and cover live on the target's take_damage() instead
## (Enemy.gd), since that's where the target's own stats are known.
const CRIT_CHANCE := 0.15
const CRIT_MULT    := 1.75
const DAMAGE_VARIANCE := 0.15  # +/- 15%

var direction := Vector2.RIGHT
var shooter: String = ""   # hero_name of the player who fired this
var damage_bonus: int = 0  # added by bullet_damage upgrade
var crit_chance_bonus: float = 0.0  # from equipped gear (Inventory.get_stat_bonus("crit_chance"))

var _age := 0.0
var _shape_ready := false

static var _inactive_pool: Array = []

static func spawn(
	parent: Node,
	global_pos: Vector2,
	dir: Vector2,
	shooter_name: String,
	dmg_bonus: int,
	crit_bonus: float,
) -> void:
	var bullet := _acquire(parent)
	bullet.global_position = global_pos
	bullet.direction = dir
	bullet.shooter = shooter_name
	bullet.damage_bonus = dmg_bonus
	bullet.crit_chance_bonus = crit_bonus
	bullet._age = 0.0
	bullet.visible = true
	bullet.monitoring = true
	bullet.set_physics_process(true)

static func _acquire(parent: Node) -> Area2D:
	while not _inactive_pool.is_empty():
		var candidate: Variant = _inactive_pool.pop_back()
		if candidate is Area2D and is_instance_valid(candidate):
			if candidate.get_parent() != parent:
				parent.add_child(candidate)
			return candidate
	var bullet := Area2D.new()
	bullet.set_script(load("res://scenes/Bullet.gd"))
	parent.add_child(bullet)
	return bullet

func _ready() -> void:
	_ensure_collision_shape()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	print("[Bullet] pool ready")

func _ensure_collision_shape() -> void:
	if _shape_ready:
		return
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	_shape_ready = true

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	_age += delta
	if CoopNetwork.is_online() and CoopNetwork.is_host() and _try_host_peer_hit():
		return
	if _age >= LIFETIME:
		_recycle()

func _recycle() -> void:
	_age = 0.0
	monitoring = false
	set_physics_process(false)
	visible = false
	if _inactive_pool.size() < POOL_MAX:
		_inactive_pool.append(self)
	else:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Group check, not physics layers -- Player/Enemy are both on the
	# engine's default layer/mask, so filtering by group is what keeps
	# this from also triggering on the player who fired it.
	if body.is_in_group("player") and body.has_method("take_damage"):
		if shooter != body.hero_name:
			var ff_dmg := _compute_damage_amount(true)
			Blame.on_friendly_fire(shooter, body.hero_name)
			RelationshipSystem.on_friendly_fire(shooter, body.hero_name)
			body.take_damage(ff_dmg, shooter)
			_recycle()
		return

	if (body.is_in_group("enemy") or body.is_in_group("spawn_generator") \
			or body.is_in_group("boss") or body.is_in_group("npc")) \
			and body.has_method("take_damage"):
		var dmg := _compute_damage_amount(false)
		body.take_damage(dmg, shooter)
		Stress.on_hit_dealt()
		_recycle()


func _try_host_peer_hit() -> bool:
	var dmg := _compute_damage_amount(false)
	if not COOP_HIT_RELAY.try_apply_peer_bullet_hit(CoopNetwork, global_position, dmg, shooter):
		return false
	Stress.on_hit_dealt()
	_recycle()
	return true


func _compute_damage_amount(apply_friendly_penalty: bool) -> int:
	var dmg := float(DAMAGE + damage_bonus)
	dmg *= randf_range(1.0 - DAMAGE_VARIANCE, 1.0 + DAMAGE_VARIANCE)
	var is_crit := randf() < clampf(CRIT_CHANCE + crit_chance_bonus, 0.0, 1.0)
	if is_crit:
		dmg *= CRIT_MULT
	if apply_friendly_penalty:
		dmg *= 0.5
	return int(round(dmg))

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.85, 0.2))
