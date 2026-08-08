extends BossArenaScene
## Moreau Pharmaceuticals Lab — Dr. Celeste Moreau (Slice 3.20).

const BOSS_CTX := "moreau"


func _ready() -> void:
	encounter_data_path = "res://data/moreau_scene.json"
	boss_scene = preload("res://scenes/BossMoreau.tscn")
	boss_context_key = BOSS_CTX
	arrival_text = "MOREAU LAB — The Pusher guards her samples."
	spawn_pos = Vector2(80, 160)
	world_bounds = Rect2(0, 0, 600, 320)
	await super._ready()
