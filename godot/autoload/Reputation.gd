extends Node
## Reputation — Autoload singleton (Phase 3, Slice 3.10)
##
## Tracks crew's reputation for ruthlessness vs. solidarity.
## GameState already has reputation_ruthlessness and reputation_solidarity fields.
## This module wires gameplay triggers.
##
## Dependencies: GameState

const REP_MAX: int = 100
const REP_MIN: int = -100

signal reputation_changed(ruthlessness: int, solidarity: int)
signal reputation_threshold_changed(axis: String, level: String)  # axis: "ruthlessness" | "solidarity"

var _last_ruthless_level: String = "balanced"
var _last_solidarity_level: String = "balanced"


func on_boss_executed() -> void:
	# Crew voted to execute a captured boss
	GameState.reputation_ruthlessness = clampi(
		GameState.reputation_ruthlessness + 15,
		REP_MIN,
		REP_MAX
	)
	reputation_changed.emit(GameState.reputation_ruthlessness, GameState.reputation_solidarity)
	_check_threshold()


func on_boss_spared() -> void:
	# Crew voted to spare a captured boss
	GameState.reputation_solidarity = clampi(
		GameState.reputation_solidarity + 15,
		REP_MIN,
		REP_MAX
	)
	reputation_changed.emit(GameState.reputation_ruthlessness, GameState.reputation_solidarity)
	_check_threshold()


func on_crew_sacrificed() -> void:
	# Crew sacrificed one of their own
	GameState.reputation_ruthlessness = clampi(
		GameState.reputation_ruthlessness + 10,
		REP_MIN,
		REP_MAX
	)
	reputation_changed.emit(GameState.reputation_ruthlessness, GameState.reputation_solidarity)
	_check_threshold()


func on_crew_saved() -> void:
	# Crew risked themselves to save someone
	GameState.reputation_solidarity = clampi(
		GameState.reputation_solidarity + 10,
		REP_MIN,
		REP_MAX
	)
	reputation_changed.emit(GameState.reputation_ruthlessness, GameState.reputation_solidarity)
	_check_threshold()


func _check_threshold() -> void:
	var ruthless_level := "balanced"
	if GameState.reputation_ruthlessness > 40:
		ruthless_level = "ruthless"
	elif GameState.reputation_ruthlessness < -40:
		ruthless_level = "merciful"

	if ruthless_level != _last_ruthless_level:
		_last_ruthless_level = ruthless_level
		reputation_threshold_changed.emit("ruthlessness", ruthless_level)

	var solidarity_level := "balanced"
	if GameState.reputation_solidarity > 40:
		solidarity_level = "unified"
	elif GameState.reputation_solidarity < -40:
		solidarity_level = "fractured"

	if solidarity_level != _last_solidarity_level:
		_last_solidarity_level = solidarity_level
		reputation_threshold_changed.emit("solidarity", solidarity_level)


func reset() -> void:
	GameState.reputation_ruthlessness = 0
	GameState.reputation_solidarity = 0
	_last_ruthless_level = "balanced"
	_last_solidarity_level = "balanced"
