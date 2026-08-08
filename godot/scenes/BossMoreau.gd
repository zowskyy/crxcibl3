extends BossGeneric
## Dr. Celeste Moreau — The Pusher (Slice 3.20). Final stand — no flee.


func _ready() -> void:
	boss_id = "Moreau"
	max_hp = 240
	flee_threshold = -1
	final_stand = true
	minion_cap = 3
	minion_interval = 6.5
	projectile_interval = 2.0
	sprite_dir = "res://assets/sprites/bosses/moreau/"
	silhouette_color = Color(0.55, 0.18, 0.42)
	super._ready()
