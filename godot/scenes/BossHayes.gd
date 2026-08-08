extends BossGeneric
## Leonard "Iron" Hayes — The Warden (Slice 3.21).


func _ready() -> void:
	boss_id = "Hayes"
	max_hp = 260
	flee_threshold = 30
	final_stand = false
	minion_cap = 3
	minion_interval = 7.0
	projectile_interval = 2.8
	sprite_dir = "res://assets/sprites/bosses/hayes/"
	silhouette_color = Color(0.32, 0.34, 0.36)
	super._ready()
