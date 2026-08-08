extends Node
## Bosses — Autoload singleton (Phase 3, Slice 3.15)
##
## Manages boss encounter state and progression. Wraps GameState's boss tracking.
## bosses_fought, boss_executed, boss_finisher already exist in GameState.
##
## BOSS_LIST ids must match defeat registration keys:
##   Blackwood_rooftop (RooftopScene flee) and Blackwood_final (Emperor estate).
## Cross–Webb are Corrupted Six encounters (slices 3.18–3.22, v1.2.0 GA).
##
## Dependencies: GameState

signal boss_defeated(boss_name: String, finisher: String, executed: bool)
signal boss_progression_changed(defeated_count: int, total_count: int)


const BOSS_LIST := [
	"Cross",              # 1. The Fixer (slice 3.18)
	"Voss",               # 2. The Broker (slice 3.19)
	"Moreau",             # 3. The Pusher (slice 3.20)
	"Hayes",              # 4. The Warden (slice 3.21)
	"Webb",               # 5. The Trader (slice 3.22)
	"Blackwood_rooftop",  # 6. The Priest — rooftop encounter
	"Blackwood_final",    # 6b. The Priest — final stand at Emperor estate
]


func register_boss_defeat(boss_name: String, finisher: String, executed: bool = false) -> void:
	if not boss_name:
		push_error("Bosses.register_boss_defeat: empty boss_name")
		return
	GameState.mark_boss_defeated(boss_name, executed, finisher)
	ActProgression.unlock_act_for_boss_progress()
	boss_defeated.emit(boss_name, finisher, executed)
	boss_progression_changed.emit(
		GameState.bosses_fought.size(),
		BOSS_LIST.size()
	)


func is_boss_defeated(boss_name: String) -> bool:
	if not boss_name:
		return false
	return GameState.bosses_fought.has(boss_name)


func get_boss_execution_choice(boss_name: String) -> bool:
	return GameState.boss_executed.get(boss_name, false)


func get_boss_finisher(boss_name: String) -> String:
	return GameState.boss_finisher.get(boss_name, "unknown")


func get_progression() -> Dictionary:
	return {
		"defeated": GameState.bosses_fought.size(),
		"total": BOSS_LIST.size(),
		"list": BOSS_LIST
	}


func is_final_boss_defeated() -> bool:
	# Blackwood final stand is the last boss encounter before the Emperor reckoning.
	return is_boss_defeated("Blackwood_final")


func reset() -> void:
	GameState.bosses_fought.clear()
	GameState.boss_executed.clear()
	GameState.boss_finisher.clear()
