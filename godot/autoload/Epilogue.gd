extends Node
## Epilogue — Autoload singleton (Phase 3, Slice 3.17)
##
## Final game state: crew walks away. Tracks ending reached and outcomes.
## Wraps up all story arcs. GameState has epilogue_state field (Phase 3 addition).
##
## Dependencies: GameState

signal epilogue_started
signal epilogue_state_changed(state: String)
signal game_completed(ending_type: String)

enum ENDING {
	NONE = 0,
	CREW_WALKS_AWAY_MERCY = 1,     # Forgave Emperor
	CREW_WALKS_AWAY_VENGEANCE = 2,  # Executed Emperor
	CREW_DECIMATED = 3,             # Lost too many members
	VICTORY_BITTERSWEET = 4,        # Default ending
}

var _current_ending: int = ENDING.NONE


func start_epilogue() -> void:
	epilogue_started.emit()
	_determine_ending()


func _determine_ending() -> void:
	if GameState.ghost_count >= 3:
		_current_ending = ENDING.CREW_DECIMATED
	elif GameState.emperor_forgiven == true:
		_current_ending = ENDING.CREW_WALKS_AWAY_MERCY
	elif GameState.emperor_forgiven == false:
		_current_ending = ENDING.CREW_WALKS_AWAY_VENGEANCE
	else:
		_current_ending = ENDING.VICTORY_BITTERSWEET

	GameState.set_meta("epilogue_state", ENDING.keys()[_current_ending])
	epilogue_state_changed.emit(ENDING.keys()[_current_ending])


func get_ending_text() -> String:
	match _current_ending:
		ENDING.CREW_WALKS_AWAY_MERCY:
			return "The crew walked away from The Flats that night. The Emperor was gone, but his final confession gave them peace."
		ENDING.CREW_WALKS_AWAY_VENGEANCE:
			return "The crew walked away from The Flats that night. The Emperor paid for his sins. But victory tasted cold."
		ENDING.CREW_DECIMATED:
			return "The crew walked away from The Flats that night. Only a handful remained. The war cost them everything."
		ENDING.VICTORY_BITTERSWEET:
			return "The crew walked away from The Flats that night. They survived. That was enough."
		_:
			return "The End."


func get_summary() -> Dictionary:
	return {
		"ending": ENDING.keys()[_current_ending],
		"bosses_defeated": GameState.bosses_fought.size(),
		"bosses_total": Bosses.BOSS_LIST.size(),
		"crew_lost": GameState.ghost_count,
		"heat_final": GameState.heat,
		"morale_final": GameState.morale,
		"emperor_forgiven": GameState.emperor_forgiven,
		"top_contributor": GameState.top_contributor()
	}


func on_game_complete() -> void:
	game_completed.emit(ENDING.keys()[_current_ending])
	SaveSystem.save_game()  # Final save


func reset() -> void:
	_current_ending = ENDING.NONE
	GameState.set_meta("epilogue_state", "NONE")
