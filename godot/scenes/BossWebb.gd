extends BossGeneric
## Marcus Webb — The Trader (Slice 3.22).


func _ready() -> void:
	boss_id = "Webb"
	max_hp = 210
	flee_threshold = 25
	final_stand = false
	minion_cap = 2
	minion_interval = 6.0
	projectile_interval = 1.8
	sprite_dir = "res://assets/sprites/bosses/webb/"
	silhouette_color = Color(0.12, 0.38, 0.55)
	super._ready()
