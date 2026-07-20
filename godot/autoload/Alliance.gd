extends Node
## Alliance — Autoload singleton (Phase 3, Slice 3.11)
##
## Tracks alliance formation/breaking between crew and external factions.
## GameState already has alliances_formed, alliances_broken, alliances_betrayed counters.
## This module wires gameplay triggers.
##
## Dependencies: GameState

signal alliance_formed(faction: String)
signal alliance_broken(faction: String)
signal alliance_betrayed(faction: String)
signal alliance_status_changed(total: int, broken: int, betrayed: int)


func on_alliance_formed(faction: String = "") -> void:
	GameState.alliances_formed += 1
	alliance_formed.emit(faction)
	alliance_status_changed.emit(
		GameState.alliances_formed,
		GameState.alliances_broken,
		GameState.alliances_betrayed
	)


func on_alliance_broken(faction: String = "") -> void:
	GameState.alliances_broken += 1
	alliance_broken.emit(faction)
	alliance_status_changed.emit(
		GameState.alliances_formed,
		GameState.alliances_broken,
		GameState.alliances_betrayed
	)


func on_alliance_betrayed(faction: String = "") -> void:
	GameState.alliances_betrayed += 1
	alliance_betrayed.emit(faction)
	alliance_status_changed.emit(
		GameState.alliances_formed,
		GameState.alliances_broken,
		GameState.alliances_betrayed
	)


func get_alliance_health() -> float:
	# Return a 0-1 score: how many alliances are active vs. broken/betrayed
	var total_events = GameState.alliances_formed + GameState.alliances_broken + GameState.alliances_betrayed
	if total_events == 0:
		return 1.0
	var active = GameState.alliances_formed - GameState.alliances_broken - GameState.alliances_betrayed
	return maxf(0.0, float(active) / float(total_events))


func reset() -> void:
	GameState.alliances_formed = 0
	GameState.alliances_broken = 0
	GameState.alliances_betrayed = 0
