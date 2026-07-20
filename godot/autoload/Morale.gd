extends Node
## Morale — Autoload singleton (Phase 3, Slice 3.9)
##
## Crew cohesion meter. Affected by relationship changes, quest completion, losses.
## GameState.morale field already exists; this module wires gameplay triggers.
## Follows Stress.gd template.
##
## Dependencies: GameState

const MORALE_MAX: int = 100
const MORALE_MIN: int = -100
const DECAY_PER_SECOND: float = 0.1  # Slow natural morale drift (negative without wins)
const THRESHOLD_ELEVATED: int = 40
const THRESHOLD_CRITICAL: int = -40

signal morale_changed(value: int)
signal morale_threshold_changed(level: String)  # "high" | "steady" | "low" | "broken"

var _last_level: String = "steady"


func _ready() -> void:
	if GameState.morale == 0:
		_last_level = "steady"


func tick(delta: float) -> void:
	# Slow morale drift when no events happening
	GameState.morale = clampi(
		GameState.morale - int(DECAY_PER_SECOND * delta),
		MORALE_MIN,
		MORALE_MAX
	)
	_check_threshold()


func on_quest_completed(amount: int = 10) -> void:
	GameState.morale = clampi(GameState.morale + amount, MORALE_MIN, MORALE_MAX)
	morale_changed.emit(GameState.morale)
	_check_threshold()


func on_boss_defeated(amount: int = 15) -> void:
	GameState.morale = clampi(GameState.morale + amount, MORALE_MIN, MORALE_MAX)
	morale_changed.emit(GameState.morale)
	_check_threshold()


func on_crew_ghosted(amount: int = -30) -> void:
	GameState.morale = clampi(GameState.morale + amount, MORALE_MIN, MORALE_MAX)
	morale_changed.emit(GameState.morale)
	_check_threshold()


func on_relationship_changed(delta: int) -> void:
	# Relationships improve → morale boost (solidarity), degrade → morale hit
	var morale_delta = delta * 2  # Relationships -10..+10 → morale ±20
	GameState.morale = clampi(GameState.morale + morale_delta, MORALE_MIN, MORALE_MAX)
	morale_changed.emit(GameState.morale)
	_check_threshold()


func _check_threshold() -> void:
	var level := "steady"
	if GameState.morale >= THRESHOLD_ELEVATED:
		level = "high"
	elif GameState.morale <= THRESHOLD_CRITICAL:
		level = "broken"
	elif GameState.morale < 0:
		level = "low"

	if level != _last_level:
		_last_level = level
		morale_threshold_changed.emit(level)


func reset() -> void:
	GameState.morale = 0
	_last_level = "steady"
