extends Node
## Emperor — Autoload singleton (Phase 3, Slice 3.16)
##
## Manages the Emperor arc (culmination of story). GameState.emperor_forgiven tracks the choice.
## Non-combat encounter with dialogue and choice mechanics.
##
## Dependencies: GameState

signal emperor_reckoning_started
signal emperor_choice_made(forgiven: bool)
signal emperor_defeated
signal emperor_arc_complete


var _reckoning_in_progress: bool = false


func start_reckoning() -> void:
	if _reckoning_in_progress:
		return
	_reckoning_in_progress = true
	emperor_reckoning_started.emit()


func on_emperor_choice(forgiven: bool) -> void:
	GameState.emperor_forgiven = forgiven
	emperor_choice_made.emit(forgiven)

	# Heat adjustment based on choice
	if forgiven:
		GameState.modify_heat(-5.0)  # Mercy: slight heat drop
	else:
		GameState.modify_heat(10.0)  # Cold: heat spike (world knows crew is merciless)


func on_emperor_death() -> void:
	emperor_defeated.emit()
	_reckoning_in_progress = false

	# Record completion
	if not GameState.quests_completed.has("emperor_reckoning"):
		GameState.quests_completed.append("emperor_reckoning")

	# Final heat drop (war ends)
	GameState.modify_heat(-50.0)

	emperor_arc_complete.emit()


func is_reckoning_active() -> bool:
	return _reckoning_in_progress


func was_emperor_forgiven() -> bool:
	return GameState.emperor_forgiven == true


func reset() -> void:
	GameState.emperor_forgiven = null
	_reckoning_in_progress = false
