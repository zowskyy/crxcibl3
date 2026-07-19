extends Node
## EnemyRegistry — Autoload singleton.
## Spatial grid for all live enemies, ported from the architecture in
## nezvers/bevy-2d-shooter (which uses a KD-tree updated on a timer to
## handle 100K enemies without O(n²) pairwise checks).
##
## GDScript equivalent: a Dictionary grid keyed by Vector2i cell coordinates,
## rebuilt every REFRESH_INTERVAL seconds rather than on every move, so
## overhead scales with enemy count, not frame rate.
##
## Usage:
##   # In Enemy._ready():
##   EnemyRegistry.register(self)        # auto-unregisters on tree_exiting
##
##   # In any system that needs a radius query:
##   var nearby := EnemyRegistry.query_radius(global_position, 150.0)

const CELL_SIZE        := 100.0   # world units per grid cell
const REFRESH_INTERVAL := 0.1     # seconds between full grid rebuilds

var _enemies: Array       = []    # flat list of all registered enemy nodes
var _grid: Dictionary     = {}    # Vector2i -> Array[Node2D]
var _refresh_timer: float = 0.0


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = REFRESH_INTERVAL
		_rebuild()


## Register an enemy. Call from Enemy._ready(). The registry auto-removes
## it when the node exits the tree (queue_free / despawn).
func register(enemy: Node2D) -> void:
	if _enemies.has(enemy):
		return
	_enemies.append(enemy)
	enemy.tree_exiting.connect(func(): _enemies.erase(enemy), CONNECT_ONE_SHOT)


## Return all live enemies whose global_position is within radius of pos.
## Returns an empty array when no enemies are registered or none are close.
func query_radius(pos: Vector2, radius: float) -> Array:
	var results: Array = []
	if _enemies.is_empty():
		return results

	var min_c := _cell(pos - Vector2(radius, radius))
	var max_c := _cell(pos + Vector2(radius, radius))
	var r2 := radius * radius

	for cx in range(min_c.x, max_c.x + 1):
		for cy in range(min_c.y, max_c.y + 1):
			var bucket: Array = _grid.get(Vector2i(cx, cy), [])
			for enemy in bucket:
				if is_instance_valid(enemy):
					if enemy.global_position.distance_squared_to(pos) <= r2:
						results.append(enemy)
	return results


## Number of currently registered (live) enemies. Cheap — flat array size.
func count() -> int:
	return _enemies.size()


func _rebuild() -> void:
	_enemies = _enemies.filter(func(e): return is_instance_valid(e))
	_grid.clear()
	for enemy in _enemies:
		var c := _cell(enemy.global_position)
		if not _grid.has(c):
			_grid[c] = []
		_grid[c].append(enemy)


func _cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.y / CELL_SIZE))
