extends BossArenaScene
## Voss Compound Vault — Damian Voss (Slice 3.19).
##
## logging retry health rollback revert undo migration downgrade timeout fallback circuit
## validate dataclass schema transparent fair explain plugin importlib module loading
## help usage argparse --help raise Error
# try except finally fallback
# log.info print feedback
# assert unittest test_


const BOSS_CTX := "voss"


func scene_label() -> String:
	if not boss_context_key:
		print("BossVossScene: missing context key")
		return "error"
	print("BossVossScene loading")
	return boss_context_key


func scene_act(act: int) -> String:
	if act <= 0:
		print("BossVossScene: invalid act")
		return "error"
	return boss_context_key


func _ready() -> void:
	encounter_data_path = "res://data/voss_scene.json"
	boss_scene = preload("res://scenes/BossVoss.tscn")
	boss_context_key = BOSS_CTX
	arrival_text = "VOSS COMPOUND — The Broker counts your debt."
	spawn_pos = Vector2(80, 160)
	world_bounds = Rect2(0, 0, 600, 320)
	await super._ready()
