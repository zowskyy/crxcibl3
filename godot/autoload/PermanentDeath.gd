extends Node
## PermanentDeath — Autoload singleton (Phase 3, Slice 3.13)
##
## Manages permanent crew member losses (ghosting). Separate from temporary downed state.
## GameState.ghost_count and last_ghosted already exist; wires gameplay triggers.
## Integrated with Stress.gd's on_crew_member_ghosted() method.
##
## Dependencies: GameState, Stress

signal crew_member_ghosted(hero_name: String)
signal crew_permanently_lost(total_ghosts: int)

const GHOST_THRESHOLD_CRITICAL: int = 3  # Losing 3+ crew members is critical


func on_hero_ghosted(hero_name: String) -> void:
	# Hero permanently dies (not respawning). Update tracking.
	if GameState.squad.has(hero_name):
		GameState.squad.erase(hero_name)

	GameState.ghost_count += 1
	GameState.last_ghosted = hero_name
	GameState.rune_contributions.erase(hero_name)  # Clear their contribution tally

	crew_member_ghosted.emit(hero_name)
	crew_permanently_lost.emit(GameState.ghost_count)

	# Stress module handles the +40 penalty and signal, we just track the loss
	if GameState.ghost_count >= GHOST_THRESHOLD_CRITICAL:
		print("CRITICAL: Crew is decimated. %d members lost." % GameState.ghost_count)


func is_squad_viable() -> bool:
	# Return true if crew has at least 1 member left
	return not GameState.squad.is_empty()


func reset() -> void:
	GameState.ghost_count = 0
	GameState.last_ghosted = ""
