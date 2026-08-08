extends BossArenaScene
## Beach Boulevard Correctional — Leonard Hayes (Slice 3.21).

func _ready() -> void:
	encounter_data_path = "res://data/hayes_scene.json"
	boss_scene = preload("res://scenes/BossHayes.tscn")
	boss_context_key = "hayes"
	arrival_text = "CORRECTIONAL — The Warden still runs this block."
	spawn_pos = Vector2(80, 160)
	world_bounds = Rect2(0, 0, 600, 320)
	await super._ready()
