extends Node
## Scarcity — Autoload singleton (Phase 3, Slice 3.6)
##
## Resource scarcity meter. Tracks crew's supply pressure.
## Follows Stress.gd template: constants, state in GameState, threshold signals.
##
## Dependencies: GameState

const SCARCITY_MAX: float = 100.0
const DECAY_PER_SECOND: float = 0.5  # Slow decay when crew finds resources
const THRESHOLD_ELEVATED: float = 40.0
const THRESHOLD_CRITICAL: float = 75.0

signal scarcity_changed(value: float)
signal scarcity_threshold_changed(level: String)  # "calm" | "elevated" | "critical"

var _last_level: String = "calm"


func _ready() -> void:
	if not GameState.has_meta("scarcity"):
		GameState.set_meta("scarcity", 0.0)


func tick(delta: float) -> void:
	var current = GameState.get_meta("scarcity", 0.0)
	current = clampf(current - DECAY_PER_SECOND * delta, 0.0, SCARCITY_MAX)
	GameState.set_meta("scarcity", current)
	_check_threshold()


func add_scarcity(amount: float) -> void:
	var current = GameState.get_meta("scarcity", 0.0)
	current = clampf(current + amount, 0.0, SCARCITY_MAX)
	GameState.set_meta("scarcity", current)
	scarcity_changed.emit(current)
	_check_threshold()


func _check_threshold() -> void:
	var current = GameState.get_meta("scarcity", 0.0)
	var level := "calm"
	if current >= THRESHOLD_CRITICAL:
		level = "critical"
	elif current >= THRESHOLD_ELEVATED:
		level = "elevated"

	if level != _last_level:
		_last_level = level
		scarcity_threshold_changed.emit(level)


func reset() -> void:
	GameState.set_meta("scarcity", 0.0)
	_last_level = "calm"
