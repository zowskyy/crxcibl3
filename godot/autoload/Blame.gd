extends Node
## Blame — Autoload singleton (Phase 3, Slice 3.14)
##
## Tracks internal crew conflicts and blame ledger.
## GameState.blame_ledger already exists as Array[{blamed, victim, cause, time}].
##
## Dependencies: GameState

signal blame_recorded(blamed: String, victim: String, cause: String)
signal crew_conflict_high(total_blame: int)


func record_blame(blamed: String, victim: String, cause: String) -> void:
	var entry := {
		"blamed": blamed,
		"victim": victim,
		"cause": cause,
		"time": Time.get_ticks_msec()
	}
	GameState.blame_ledger.append(entry)
	blame_recorded.emit(blamed, victim, cause)

	if GameState.blame_ledger.size() >= 5:
		crew_conflict_high.emit(GameState.blame_ledger.size())


func on_friendly_fire(shooter: String, victim: String) -> void:
	record_blame(shooter, victim, "friendly_fire")


func on_resource_theft(thief: String, victim: String) -> void:
	record_blame(thief, victim, "resource_theft")


func on_poor_decision(leader: String, consequence: String) -> void:
	record_blame(leader, "crew", consequence)


func get_blame_count_for_hero(hero_name: String) -> int:
	var count := 0
	for entry in GameState.blame_ledger:
		if entry["blamed"] == hero_name:
			count += 1
	return count


func clear_blame_history() -> void:
	GameState.blame_ledger.clear()


func reset() -> void:
	GameState.blame_ledger.clear()
