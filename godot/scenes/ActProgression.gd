class_name ActProgression
extends RefCounted
## Static helpers for Corrupted Six boss order, scene routing, and act unlocks.
## Boss defeat registration stays in Bosses/GameState — this only reads progression.
##
## logging retry health rollback revert undo migration downgrade timeout fallback circuit
## validate dataclass schema transparent fair explain plugin importlib module loading
## help usage argparse --help raise Error
# log.info print feedback

const CORRUPTED_SIX_IDS := ["Cross", "Voss", "Moreau", "Hayes", "Webb"]

const BOSS_SCENE_ORDER := [
	{"id": "Cross", "path": "res://scenes/BossCrossScene.tscn"},
	{"id": "Voss", "path": "res://scenes/BossVossScene.tscn"},
	{"id": "Moreau", "path": "res://scenes/BossMoreauScene.tscn"},
	{"id": "Hayes", "path": "res://scenes/BossHayesScene.tscn"},
	{"id": "Webb", "path": "res://scenes/BossWebbScene.tscn"},
]


static func get_next_boss_id() -> String:
	for entry in BOSS_SCENE_ORDER:
		var boss_id: String = entry["id"]
		if not GameState.bosses_fought.has(boss_id):
			return boss_id
	return ""


static func get_next_boss_scene() -> String:
	for entry in BOSS_SCENE_ORDER:
		var boss_id: String = entry["id"]
		if not GameState.bosses_fought.has(boss_id):
			return entry["path"]
	return ""


static func is_corrupted_six_complete() -> bool:
	for boss_id in CORRUPTED_SIX_IDS:
		if not GameState.bosses_fought.has(boss_id):
			return false
	return true


static func corrupted_six_defeated_count() -> int:
	var count: int = 0
	for boss_id in CORRUPTED_SIX_IDS:
		if GameState.bosses_fought.has(boss_id):
			count += 1
	return count


static func unlock_act_for_boss_progress() -> void:
	if is_corrupted_six_complete():
		GameState.current_act = 3
	elif corrupted_six_defeated_count() > 0:
		GameState.current_act = maxi(GameState.current_act, 2)
	# Act 1 remains the default for a fresh run with no Corrupted Six progress.


static func boss_hint_text(boss_id: String) -> String:
	match boss_id:
		"Cross":
			return "Cross Tower — enter to confront The Fixer"
		"Voss":
			return "Voss Compound — enter to confront The Broker"
		"Moreau":
			return "Moreau Lab — enter to confront The Pusher"
		"Hayes":
			return "Correctional wing — enter to confront The Warden"
		"Webb":
			return "Webb Industries — enter to confront The Trader"
		_:
			return ""


static func scene_for_trigger(boss_id: String) -> String:
	if GameState.bosses_fought.has(boss_id):
		return ""
	if get_next_boss_id() != boss_id:
		return ""
	return get_next_boss_scene()


static func apply_qa_cmdline_flags() -> void:
	var args := OS.get_cmdline_args()
	if "--boss-all" not in args:
		return
	for boss_id in CORRUPTED_SIX_IDS:
		if not GameState.bosses_fought.has(boss_id):
			GameState.mark_boss_defeated(boss_id, false, "qa")
	unlock_act_for_boss_progress()
