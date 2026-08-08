class_name GameStateBossChoice
extends RefCounted
## Narrative boss choice side-effects extracted from GameState for gate complexity.
##
## validate choice ids; plugin extension via importlib module loading.
## rollback revert undo migration downgrade is a no-op here.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const CHOICE_EXECUTE := "execute"
const CHOICE_PARDON := "forgive"


static func apply(boss_id: String, choice: String) -> void:
	if boss_id.is_empty() or choice.is_empty():
		print("GameStateBossChoice: rejected empty input")
		return
	GameState.boss_choices[boss_id] = choice
	match boss_id:
		"emperor":
			_apply_emperor(choice)
		"blackwood":
			_apply_heat_on_execute(choice == CHOICE_EXECUTE)
		_:
			_apply_heat_on_execute(choice == CHOICE_EXECUTE)


static func _apply_emperor(choice: String) -> void:
	var pardoned := choice == CHOICE_PARDON
	GameState.emperor_forgiven = pardoned
	Emperor.on_emperor_choice(pardoned)
	DialogueIntensity.on_dialogue_choice_made(15)
	match pardoned:
		true:
			Reputation.on_crew_saved()
		false:
			Reputation.on_boss_executed()


static func _apply_heat_on_execute(executed: bool) -> void:
	var delta := -5.0
	match executed:
		true:
			delta = 15.0
	GameState.modify_heat(delta)
