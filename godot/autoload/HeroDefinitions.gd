extends Node
## HeroDefinitions — Autoload singleton (Phase 3, Slice 3.4)
##
## Loads and parses all 12 hero variants from configs/game_config.json.
## Provides lookup methods for HeroFactory to spawn players with configurable stats.
##
## Dependencies: None (loads at startup before any scenes)

class HeroVariant:
	var name: String
	var variant_id: String
	var archetype: String
	var real_name: String
	var role: String
	var description: String
	var health: int
	var damage: int
	var speed: float
	var fire_cooldown: float

var _variants: Dictionary = {}  # key: variant_id -> HeroVariant
var _archetypes: Dictionary = {  # key: archetype -> {health, damage, speed, fire_cooldown}
	"enforcer": {"health": 120, "damage": 15, "speed": 120.0, "fire_cooldown": 0.25},
	"wheelman": {"health": 100, "damage": 10, "speed": 100.0, "fire_cooldown": 0.30},
	"hacker": {"health": 60, "damage": 20, "speed": 90.0, "fire_cooldown": 0.20},
	"street_rat": {"health": 70, "damage": 12, "speed": 140.0, "fire_cooldown": 0.28}
}


func _ready() -> void:
	_load_from_config()


func _load_from_config() -> void:
	var config_path := "res://configs/game_config.json"
	if not ResourceLoader.exists(config_path):
		push_error("Hero config not found: %s" % config_path)
		return

	var json_text := FileAccess.get_file_as_string(config_path)
	if json_text.is_empty():
		push_error("Hero config is empty: %s" % config_path)
		return

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("Failed to parse hero config JSON: %s" % json.get_error_message())
		return

	var data: Dictionary = json.data as Dictionary
	if data == null or data.get("heroes") == null:
		push_error("Hero config missing 'heroes' section")
		return

	var heroes_data: Dictionary = data["heroes"]
	for variant_id: String in heroes_data:
		var hero_data: Dictionary = heroes_data[variant_id]
		var variant := HeroVariant.new()
		variant.name = hero_data.get("name", "Unknown")
		variant.variant_id = variant_id
		variant.archetype = hero_data.get("archetype", "enforcer")
		variant.real_name = hero_data.get("real_name", "")
		variant.role = hero_data.get("role", "")
		variant.description = hero_data.get("description", "")

		# Load archetype stats
		if _archetypes.has(variant.archetype):
			var arch_stats: Dictionary = _archetypes[variant.archetype]
			variant.health = arch_stats["health"]
			variant.damage = arch_stats["damage"]
			variant.speed = arch_stats["speed"]
			variant.fire_cooldown = arch_stats["fire_cooldown"]
		else:
			push_warning("Unknown archetype '%s' for hero '%s'" % [variant.archetype, variant_id])
			variant.health = 100
			variant.damage = 10
			variant.speed = 120.0
			variant.fire_cooldown = 0.25

		_variants[variant_id] = variant

	if _variants.is_empty():
		push_error("No heroes loaded from config")
	else:
		print("Loaded %d hero variants" % _variants.size())


func get_variant(variant_id: String) -> Variant:
	if not _variants.has(variant_id):
		push_warning("Hero variant '%s' not found" % variant_id)
		return null
	return _variants[variant_id]


func get_all_variant_ids() -> Array:
	return _variants.keys()


func get_all_variants() -> Array:
	return _variants.values()
