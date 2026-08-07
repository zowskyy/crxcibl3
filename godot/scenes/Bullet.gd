extends Area2D
## Metal Slug-style projectile -- Architect's creative direction: gun
## combat, not melee-only punches. Built entirely in code (constructs its
## own CollisionShape2D in _ready()) rather than as a separate .tscn,
## since Player.gd instantiates a fresh one per shot.

const SPEED := 400.0
const DAMAGE := 15
const LIFETIME := 1.2
const RADIUS := 5.0

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
	if body.is_in_group("player") and body.has_method("take_damage"):
		if shooter != body.hero_name:
			var ff_dmg := float(DAMAGE + damage_bonus)
			ff_dmg *= randf_range(1.0 - DAMAGE_VARIANCE, 1.0 + DAMAGE_VARIANCE)
			var is_ff_crit := randf() < clampf(CRIT_CHANCE + crit_chance_bonus, 0.0, 1.0)
			if is_ff_crit:
				ff_dmg *= CRIT_MULT
			ff_dmg *= 0.5
			Blame.on_friendly_fire(shooter, body.hero_name)
			body.take_damage(int(round(ff_dmg)), shooter)
			queue_free()
		return

	if (body.is_in_group("enemy") or body.is_in_group("spawn_generator") \
			or body.is_in_group("boss") or body.is_in_group("npc")) \
			and body.has_method("take_damage"):
		var dmg := float(DAMAGE + damage_bonus)
		dmg *= randf_range(1.0 - DAMAGE_VARIANCE, 1.0 + DAMAGE_VARIANCE)
		var is_crit := randf() < clampf(CRIT_CHANCE + crit_chance_bonus, 0.0, 1.0)
		if is_crit:
			dmg *= CRIT_MULT
		body.take_damage(int(round(dmg)), shooter)
		Stress.on_hit_dealt()
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.85, 0.2))
