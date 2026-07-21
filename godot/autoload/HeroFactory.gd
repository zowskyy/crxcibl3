extends Node
## HeroFactory — Autoload singleton (Phase 3, Slice 3.4)
##
## Spawns Player nodes with configurable stats based on hero variant.
## Builds the player entirely in code (same pattern as bullets/enemies/etc.) —
## there is no Player.tscn; the Player CharacterBody2D lives directly inside
## each scene file (.tscn) or is constructed here at runtime.
##
## Usage: HeroFactory.spawn_player("enforcer_ghost", spawn_point.global_position, self)
##
## Dependencies: HeroDefinitions (must be registered before this in project.godot)

const PLAYER_SCRIPT := preload("res://scenes/Player.gd")


func spawn_player(variant_id: String, spawn_pos: Vector2, parent: Node) -> CharacterBody2D:
	var variant = HeroDefinitions.get_variant(variant_id)
	if variant == null:
		push_error("Cannot spawn player: variant '%s' not found" % variant_id)
		return null

	# Build CharacterBody2D in code — same pattern as Bullet.gd / Enemy.gd spawned
	# at runtime. No .tscn needed since all visual/collision children are set up
	# in Player.gd's _ready() via call_deferred and _draw().
	var player := CharacterBody2D.new()
	player.set_script(PLAYER_SCRIPT)

	# Collision shape (16×16, matches the embedded Player nodes in the .tscn files)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	col.shape = rect
	player.add_child(col)

	# Set hero identity and stats before _ready() runs
	player.hero_name = variant.variant_id
	player.health = variant.health

	player.global_position = spawn_pos
	parent.add_child(player)

	print("Spawned hero '%s' (%s) at %v" % [variant.name, variant.real_name, spawn_pos])
	return player
