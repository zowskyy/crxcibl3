extends Node
## Recap — Autoload singleton (Project Settings > Autoload, name it "Recap")
## Depends on: GameState (must be listed above this one in Autoload order)
##
## Builds a short "Previously on..." summary from current GameState when the player
## hits Continue, so returning after a break doesn't require re-reading a wall of text.
## Picks from small fragment banks per category and joins whatever applies — nothing
## forced, so an early save just gets a short recap and a late save gets a fuller one.

func generate() -> String:
	var lines: Array = []

	lines.append(_act_line())

	var boss_line := _bosses_line()
	if boss_line != "":
		lines.append(boss_line)

	var heat_line := _heat_line()
	if heat_line != "":
		lines.append(heat_line)

	var relationship_line := _relationship_line()
	if relationship_line != "":
		lines.append(relationship_line)

	if GameState.ghost_count > 0:
		lines.append(_ghost_line())

	return "\n".join(lines)


func _act_line() -> String:
	match GameState.current_act:
		1:
			return "The crew is still picking up the pieces after the Seven Sorrows."
		2:
			return "The crew has regrouped and started hunting The Corrupted Six."
		3:
			return "The Reckoning is underway — The Emperor's betrayal is close to being answered."
		_:
			return "Beach Boulevard remembers everything you've done so far."


func _bosses_line() -> String:
	if GameState.bosses_fought.is_empty():
		return ""

	var count := GameState.bosses_fought.size()
	var last_boss: String = GameState.bosses_fought[count - 1]
	var executed = GameState.boss_executed.get(last_boss, false)
	var outcome := "didn't survive" if executed else "was left alive, broken"

	if count == 1:
		return "%s %s the confrontation." % [last_boss, outcome]
	return "%d of the Corrupted Six are down. %s %s the last one." % [count, last_boss, outcome]


func _heat_line() -> String:
	if GameState.heat >= 76:
		return "The heat is at its worst — the whole Boulevard is watching for the crew."
	elif GameState.heat >= 51:
		return "Heat is climbing. It won't take much to bring the wrong kind of attention."
	elif GameState.heat >= 26:
		return "There's a little heat on the crew, but nothing unmanageable yet."
	return ""


func _relationship_line() -> String:
	var worst_key := ""
	var worst_value := 11  # above the +10 max, so any real value replaces it

	for key in GameState.relationships.keys():
		var value: int = GameState.relationships[key]
		if value < worst_value:
			worst_value = value
			worst_key = key

	if worst_key == "" or worst_value > -5:
		return ""

	var names := worst_key.split("_")
	if names.size() < 2:
		return ""

	return "Things are still tense between %s and %s." % [names[0].capitalize(), names[1].capitalize()]


func _ghost_line() -> String:
	if GameState.ghost_count == 1:
		return "%s didn't make it. The crew hasn't stopped feeling that." % GameState.last_ghosted.capitalize()
	return "The crew has lost %d of their own along the way." % GameState.ghost_count
