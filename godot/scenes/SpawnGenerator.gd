extends StaticBody2D
## Crack House / Chop Shop spawn generator (Slice 2.17).
## Periodically spawns enemy grunts up to SPAWN_CAP. Once all spawned enemies
## from this generator are dead AND the generator itself has taken enough
## damage (player must "hit the stash") the generator is cleared permanently
## and stops spawning. Cleared state is stored in GameState so it persists
## across scene reloads.
##
## Placed in TestRoom at a fixed position near the fence line. In future
## levels each Crack House / Chop Shop gets its own instance with a unique
## generator_id so GameState can track clearing state per location.

const ENEMY_SCRIPT := preload("res://scenes/Enemy.gd")
const SPAWN_RADIUS := 30.0     # enemies spawn within this radius of the node
const SPAWN_INTERVAL := 6.0    # seconds between spawn attempts
const SPAWN_CAP := 3           # max live enemies from this generator at once
const GENERATOR_HP := 60       # "stash" hit points -- player must shoot it

@export var generator_id: String = "crack_house_1"

var _spawn_timer := 0.0
var _live_enemies: Array = []
var _hp := GENERATOR_HP
var _cleared := false


func _ready() -> void:
	add_to_group("spawn_generator")
	if GameState.group_upgrades.get("cleared_" + generator_id, false):
		_cleared = true
		queue_free()
		return
	_spawn_timer = 1.0  # short delay before first spawn so player isn't immediately rushed


func _physics_process(delta: float) -> void:
	if _cleared:
		return

	# Prune freed enemy refs
	_live_enemies = _live_enemies.filter(func(e): return is_instance_valid(e))

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = SPAWN_INTERVAL
		if _live_enemies.size() < SPAWN_CAP:
			_spawn_enemy()


func _spawn_enemy() -> void:
	var enemy := CharacterBody2D.new()
	enemy.set_script(ENEMY_SCRIPT)

	# Random offset within SPAWN_RADIUS
	var angle := randf() * TAU
	var dist  := randf_range(8.0, SPAWN_RADIUS)
	enemy.global_position = global_position + Vector2(cos(angle), sin(angle)) * dist

	# Collision shape (same 16x16 as the scene-placed enemy)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	col.shape = rect
	enemy.add_child(col)

	get_parent().add_child(enemy)
	_live_enemies.append(enemy)


## Called by Bullet when it hits the generator node directly.
func take_damage(amount: int, _killer: String = "") -> void:
	if _cleared:
		return
	_hp = maxi(0, _hp - amount)
	if _hp <= 0:
		_try_clear()


func _try_clear() -> void:
	# Prune first so the count is accurate
	_live_enemies = _live_enemies.filter(func(e): return is_instance_valid(e))
	# Must kill the stash AND have no living spawns to clear the location
	if _live_enemies.size() > 0:
		_hp = 1   # keep it at 1 so it stays hittable until spawns are gone
		return
	_cleared = true
	# Persist cleared state in group_upgrades so it survives scene reloads
	GameState.group_upgrades["cleared_" + generator_id] = true
	GameState.modify_heat(-20.0)   # clearing a generator cools heat -- reward
	queue_free()


func _draw() -> void:
	# Placeholder visual: dark red square with an X, sized to feel like a
	# small structure. Replaced with real art when the Chop Shop sprite lands.
	var s := 20.0
	draw_rect(Rect2(-s, -s, s * 2, s * 2), Color(0.5, 0.1, 0.1))
	draw_line(Vector2(-s, -s), Vector2(s, s), Color(0.9, 0.2, 0.2), 2.0)
	draw_line(Vector2(s, -s), Vector2(-s, s), Color(0.9, 0.2, 0.2), 2.0)
