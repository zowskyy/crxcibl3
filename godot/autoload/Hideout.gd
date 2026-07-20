extends Node
## Hideout — Autoload singleton (Phase 3, Slice 3.8)
##
## Tracks safe-house heat decay. When crew is in a safe zone, heat decays faster.
## When hideout is detected (enemies nearby), decay stops and heat rises.
## Follows Stress.gd template.
##
## Dependencies: GameState

const HIDEOUT_HEAT_DECAY_SAFE: float = 5.0  # Heat decay rate per second in hideout
const HIDEOUT_HEAT_DECAY_NORMAL: float = GameState.HEAT_MAX / 200.0  # Default decay
const THRESHOLD_ELEVATED: float = 40.0
const THRESHOLD_CRITICAL: float = 75.0

signal hideout_status_changed(is_safe: bool)
signal hideout_threshold_changed(level: String)  # "safe" | "at_risk" | "compromised"

var _in_hideout: bool = false
var _last_level: String = "safe"


func _ready() -> void:
	if not GameState.has_meta("hideout_heat_decay"):
		GameState.set_meta("hideout_heat_decay", 0.0)


func tick(delta: float) -> void:
	if _in_hideout:
		# In hideout: accelerate heat decay
		GameState.modify_heat(-HIDEOUT_HEAT_DECAY_SAFE * delta)
	_check_threshold()


func enter_hideout() -> void:
	_in_hideout = true
	hideout_status_changed.emit(true)


func exit_hideout() -> void:
	_in_hideout = false
	hideout_status_changed.emit(false)


func hideout_compromised() -> void:
	# Enemies detected in hideout location
	var current_heat = GameState.heat
	GameState.modify_heat(15.0)  # Heat spike when discovered
	exit_hideout()
	_check_threshold()


func _check_threshold() -> void:
	var level := "safe"
	if GameState.heat >= THRESHOLD_CRITICAL:
		level = "compromised"
	elif GameState.heat >= THRESHOLD_ELEVATED:
		level = "at_risk"

	if level != _last_level:
		_last_level = level
		hideout_threshold_changed.emit(level)


func reset() -> void:
	GameState.set_meta("hideout_heat_decay", 0.0)
	_in_hideout = false
	_last_level = "safe"
