extends Node
## Injury — Autoload singleton (Phase 3, Slice 3.7)
##
## Tracks crew injuries. Increments when heroes are downed, decrements with healing.
## Follows Stress.gd template.
##
## Dependencies: GameState

const INJURY_MAX: int = 100
const HEAL_PER_SECOND: float = 0.2  # Slow natural healing over time
const THRESHOLD_ELEVATED: int = 40
const THRESHOLD_CRITICAL: int = 75

signal injury_changed(value: int)
signal injury_threshold_changed(level: String)  # "calm" | "elevated" | "critical"

var _last_level: String = "calm"


func _ready() -> void:
	if not GameState.has_meta("injury_count"):
		GameState.set_meta("injury_count", 0)


func tick(delta: float) -> void:
	var current = GameState.get_meta("injury_count", 0)
	current = maxi(current - int(HEAL_PER_SECOND * delta), 0)
	GameState.set_meta("injury_count", current)
	_check_threshold()


func on_hero_downed() -> void:
	var current = GameState.get_meta("injury_count", 0)
	current = mini(current + 20, INJURY_MAX)
	GameState.set_meta("injury_count", current)
	injury_changed.emit(current)
	_check_threshold()


func on_hero_healed(amount: int = 10) -> void:
	var current = GameState.get_meta("injury_count", 0)
	current = maxi(current - amount, 0)
	GameState.set_meta("injury_count", current)
	injury_changed.emit(current)
	_check_threshold()


func _check_threshold() -> void:
	var current = GameState.get_meta("injury_count", 0)
	var level := "calm"
	if current >= THRESHOLD_CRITICAL:
		level = "critical"
	elif current >= THRESHOLD_ELEVATED:
		level = "elevated"

	if level != _last_level:
		_last_level = level
		injury_threshold_changed.emit(level)


func reset() -> void:
	GameState.set_meta("injury_count", 0)
	_last_level = "calm"
