extends BossArenaScene
## Cross Tower Penthouse — Victor Cross (Slice 3.18).

const BOSS_CTX := "cross"


func _ready() -> void:
	encounter_data_path = "res://data/cross_scene.json"
	boss_scene = preload("res://scenes/BossCross.tscn")
	boss_context_key = BOSS_CTX
	arrival_text = "CROSS TOWER — The Fixer waits."
	spawn_pos = Vector2(80, 160)
	world_bounds = Rect2(0, 0, 600, 320)
	await super._ready()
