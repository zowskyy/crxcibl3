extends Node
## Stress — Autoload singleton (Project Settings > Autoload, name it "Stress")
## Depends on: GameState (must be listed above this one in Autoload order)
##
## Tracks a crew-wide combat/death stress meter, separate from Heat (which is the
## "hunted by the world" meter). Stress represents the crew's own fraying nerves —
## it climbs from combat and losses, decays when things are calm, and past certain
## thresholds triggers screen-effect signals the UI layer can listen for.
##
## This is the template module: config constants at the top, public functions that
## read/write GameState directly, and a tick(delta) for per-frame decay. The rest of
## the mechanics suite (Scarcity, Injury, Hideout, Morale, Reputation, Alliance,
## DialogueIntensity, PermanentDeath, Blame, Bosses, Emperor, Epilogue) follow this
## same shape as separate autoloads — ask for the next one whenever you're ready to
## wire it into a scene, rather than building all twelve before testing any of them.

# --- Config ---
const STRESS_MAX: float = 100.0
const DECAY_PER_SECOND: float = 1.5          # stress bleeds off when not in combat
const COMBAT_HIT_TAKEN: float = 4.0
const COMBAT_HIT_DEALT: float = 1.0
const CREW_MEMBER_DOWNED: float = 20.0
const CREW_MEMBER_GHOSTED: float = 40.0
const THRESHOLD_ELEVATED: float = 40.0
const THRESHOLD_CRITICAL: float = 75.0

signal stress_threshold_changed(new_level: String)  # "calm" | "elevated" | "critical"

var stress: float = 0.0
var _in_combat: bool = false
var _last_level: String = "calm"


func enter_combat() -> void:
	_in_combat = true


func exit_combat() -> void:
	_in_combat = false


func on_hit_taken() -> void:
	_add_stress(COMBAT_HIT_TAKEN)


func on_hit_dealt() -> void:
	_add_stress(COMBAT_HIT_DEALT)


func on_crew_member_downed() -> void:
	_add_stress(CREW_MEMBER_DOWNED)


func on_crew_member_ghosted(hero_name: String) -> void:
	_add_stress(CREW_MEMBER_GHOSTED)
	GameState.ghost_count += 1
	GameState.last_ghosted = hero_name


func tick(delta: float) -> void:
	if not _in_combat and stress > 0.0:
		stress = maxf(0.0, stress - DECAY_PER_SECOND * delta)
		_check_threshold()


func _add_stress(amount: float) -> void:
	stress = clampf(stress + amount, 0.0, STRESS_MAX)
	_check_threshold()


func _check_threshold() -> void:
	var level := "calm"
	if stress >= THRESHOLD_CRITICAL:
		level = "critical"
	elif stress >= THRESHOLD_ELEVATED:
		level = "elevated"

	if level != _last_level:
		_last_level = level
		stress_threshold_changed.emit(level)


func reset() -> void:
	stress = 0.0
	_in_combat = false
	_last_level = "calm"
