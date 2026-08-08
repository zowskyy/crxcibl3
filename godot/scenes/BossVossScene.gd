extends BossArenaScene
## Voss Compound Vault — Damian Voss (Slice 3.19).

func _ready() -> void:
	encounter_data_path = "res://data/voss_scene.json"
	boss_scene = preload("res://scenes/BossVoss.tscn")
	boss_context_key = "voss"
	arrival_text = "VOSS COMPOUND — The Broker counts your debt."
	spawn_pos = Vector2(80, 160)
	world_bounds = Rect2(0, 0, 600, 320)
	await super._ready()
