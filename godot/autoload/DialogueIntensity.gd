extends Node
## DialogueIntensity — Autoload singleton (Phase 3, Slice 3.12)
##
## Story tension meter. Escalates as bosses are defeated, choices made, lore unfolds.
## Decays between major story beats. Wires narrative pacing into mechanics.
##
## Dependencies: GameState

const INTENSITY_MAX: float = 100.0
const DECAY_PER_SECOND: float = 0.3  # Slow decay between story events
const THRESHOLD_ELEVATED: float = 40.0
const THRESHOLD_CRITICAL: float = 75.0

signal intensity_changed(value: float)
signal intensity_threshold_changed(level: String)  # "calm" | "tense" | "climactic"

var _last_level: String = "calm"


func _ready() -> void:
	if not GameState.has_meta("dialogue_intensity"):
		GameState.set_meta("dialogue_intensity", 0.0)


func tick(delta: float) -> void:
	var current = GameState.get_meta("dialogue_intensity", 0.0)
	current = clampf(current - DECAY_PER_SECOND * delta, 0.0, INTENSITY_MAX)
	GameState.set_meta("dialogue_intensity", current)
	_check_threshold()


func on_boss_encountered(boss_name: String = "") -> void:
	var current = GameState.get_meta("dialogue_intensity", 0.0)
	current = clampf(current + 30.0, 0.0, INTENSITY_MAX)
	GameState.set_meta("dialogue_intensity", current)
	intensity_changed.emit(current)
	_check_threshold()


func on_dialogue_choice_made(choice_value: int = 5) -> void:
	# Player makes a moral choice → story escalates
	var current = GameState.get_meta("dialogue_intensity", 0.0)
	current = clampf(current + float(choice_value), 0.0, INTENSITY_MAX)
	GameState.set_meta("dialogue_intensity", current)
	intensity_changed.emit(current)
	_check_threshold()


func on_boss_defeated(is_executed: bool = false) -> void:
	# Boss defeated, especially if executed → major tension release then climax
	var current = GameState.get_meta("dialogue_intensity", 0.0)
	var amount = 20.0 if is_executed else 10.0
	current = clampf(current + amount, 0.0, INTENSITY_MAX)
	GameState.set_meta("dialogue_intensity", current)
	intensity_changed.emit(current)
	_check_threshold()


func _check_threshold() -> void:
	var current = GameState.get_meta("dialogue_intensity", 0.0)
	var level := "calm"
	if current >= THRESHOLD_CRITICAL:
		level = "climactic"
	elif current >= THRESHOLD_ELEVATED:
		level = "tense"

	if level != _last_level:
		_last_level = level
		intensity_threshold_changed.emit(level)


func reset() -> void:
	GameState.set_meta("dialogue_intensity", 0.0)
	_last_level = "calm"
