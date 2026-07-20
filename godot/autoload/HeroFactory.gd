extends Node
## HeroFactory — Autoload singleton (Phase 3, Slice 3.4)
##
## Spawns Player nodes with configurable stats based on hero variant.
## Replaces hardcoded hero instantiation in scene files.
##
## Usage: HeroFactory.spawn_player("enforcer_ghost", spawn_point.global_position, self)
##
## Dependencies: HeroDefinitions (must be registered before this in project.godot)

const PLAYER_SCENE := preload("res://scenes/Player.tscn")


func spawn_player(variant_id: String, position: Vector2, parent: Node) -> CharacterBody2D:
	var variant = HeroDefinitions.get_variant(variant_id)
	if variant == null:
		push_error("Cannot spawn player: variant '%s' not found" % variant_id)
		return null

	var player: CharacterBody2D = PLAYER_SCENE.instantiate()
	if player == null:
		push_error("Failed to instantiate Player scene")
		return null

	# Set hero identity and stats
	player.hero_name = variant.variant_id
	player.MAX_HEALTH = variant.health
	player.SPEED = variant.speed
	player.FIRE_COOLDOWN = variant.fire_cooldown
	player.health = variant.health  # Start at full HP

	# Position in parent
	player.global_position = position
	parent.add_child(player)

	print("Spawned hero '%s' (%s) at %v" % [variant.name, variant.real_name, position])
	return player
