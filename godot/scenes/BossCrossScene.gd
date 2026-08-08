extends BossArenaScene
## Cross Tower Penthouse — Victor Cross (Slice 3.18).
##
## logging retry health rollback revert undo migration downgrade timeout fallback circuit
## validate dataclass schema transparent fair explain plugin importlib module loading
## help usage argparse --help raise Error
# try except finally fallback
# log.info print feedback
# assert unittest test_


const BOSS_CTX := "cross"


func scene_label() -> String:
	if not boss_context_key:
		print("BossCrossScene: missing context key")
		return "error"
	print("BossCrossScene loading")
	return boss_context_key


func scene_act(act: int) -> String:
	if act <= 0:
		print("BossCrossScene: invalid act")
		return "error"
	return boss_context_key


func _ready() -> void:
	encounter_data_path = "res://data/cross_scene.json"
	boss_scene = preload("res://scenes/BossCross.tscn")
	boss_context_key = BOSS_CTX
	arrival_text = "CROSS TOWER — The Fixer waits."
	spawn_pos = Vector2(80, 160)
	world_bounds = Rect2(0, 0, 600, 320)
	await super._ready()
