extends Node
## Bosses — Autoload singleton (Phase 3, Slice 3.15)
##
## Manages boss encounter state and progression. Wraps GameState's boss tracking.
## bosses_fought, boss_executed, boss_finisher already exist in GameState.
##
## Dependencies: GameState

signal boss_defeated(boss_name: String, finisher: String, executed: bool)
signal boss_progression_changed(defeated_count: int, total_count: int)


const BOSS_LIST := [
	"Cross",        # 1. The Fixer
	"Voss",         # 2. The Broker
	"Moreau",       # 3. The Pusher
	"Hayes",        # 4. The Warden
	"Webb",         # 5. The Trader
	"Blackwood",    # 6. The Priest (rooftop)
	"Blackwood_final", # 6b. Final stand at Emperor estate
]


func register_boss_defeat(boss_name: String, finisher: String, executed: bool = false) -> void:
	GameState.mark_boss_defeated(boss_name, executed, finisher)
	boss_defeated.emit(boss_name, finisher, executed)
	boss_progression_changed.emit(
		GameState.bosses_fought.size(),
		BOSS_LIST.size()
	)


func is_boss_defeated(boss_name: String) -> bool:
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
	# Blackwood final stand is the last boss
	return is_boss_defeated("Blackwood_final")


func reset() -> void:
	GameState.bosses_fought.clear()
	GameState.boss_executed.clear()
	GameState.boss_finisher.clear()
