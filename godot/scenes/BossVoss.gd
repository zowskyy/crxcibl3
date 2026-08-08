extends BossGeneric
## Damian Voss — The Broker (Slice 3.19).


func _ready() -> void:
	boss_id = "Voss"
	max_hp = 200
	flee_threshold = 35
	final_stand = false
	minion_cap = 2
	minion_interval = 7.5
	projectile_interval = 2.2
	sprite_dir = "res://assets/sprites/bosses/voss/"
	silhouette_color = Color(0.22, 0.22, 0.28)
	super._ready()
