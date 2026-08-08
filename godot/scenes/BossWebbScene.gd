extends BossArenaScene
## Webb Industries Data Center — Marcus Webb (Slice 3.22).

const BOSS_CTX := "webb"


func _ready() -> void:
	encounter_data_path = "res://data/webb_scene.json"
	boss_scene = preload("res://scenes/BossWebb.tscn")
	boss_context_key = BOSS_CTX
	arrival_text = "WEBB DATA CENTER — The Trader owns your signal."
	spawn_pos = Vector2(80, 160)
	world_bounds = Rect2(0, 0, 600, 320)
	await super._ready()
