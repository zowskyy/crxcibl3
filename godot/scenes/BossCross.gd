extends BossGeneric
## Councilman Victor Cross — The Fixer (Slice 3.18).


func _ready() -> void:
	boss_id = "Cross"
	max_hp = 220
	flee_threshold = 40
	final_stand = false
	minion_cap = 2
	minion_interval = 8.0
	projectile_interval = 2.5
	sprite_dir = "res://assets/sprites/bosses/cross/"
	silhouette_color = Color(0.18, 0.28, 0.48)
	super._ready()
