extends Node2D
## EpilogueScene — Slice 3.7. Ending screen reached after EmperorScene.
##
## Displays the ending type (determined by Epilogue.start_epilogue() called in EmperorScene),
## the run summary, and a "Play Again" button that resets and returns to the main menu.
## Epilogue.start_epilogue() must have already been called before this scene loads.

@onready var ending_label:  Label  = $CanvasLayer/EndingLabel
@onready var summary_label: Label  = $CanvasLayer/SummaryLabel
@onready var play_again:    Button = $CanvasLayer/PlayAgainButton

const TITLE_COLOR := Color(1.0, 0.4, 0.0)  # Heat orange — same as the rest of the HUD


func _ready() -> void:
	ending_label.text = Epilogue.get_ending_text()
	summary_label.text = _format_summary(Epilogue.get_summary())
	play_again.pressed.connect(_on_play_again)
	Epilogue.on_game_complete()


func _on_play_again() -> void:
	GameState.reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _format_summary(s: Dictionary) -> String:
	var lines: Array = []
	lines.append("- Run Summary -")
	lines.append("")
	lines.append("Bosses defeated:  %d / 7" % int(s.get("bosses_defeated", 0)))
	lines.append("Crew lost:        %d"     % int(s.get("crew_lost",       0)))
	lines.append("Final heat:       %.0f"  % float(s.get("heat_final",    0.0)))
	lines.append("Final morale:     %d"    % int(s.get("morale_final",    0)))

	var forgiven: Variant = s.get("emperor_forgiven", null)
	if forgiven == true:
		lines.append("Emperor:          Forgiven")
	elif forgiven == false:
		lines.append("Emperor:          Turned away")
	else:
		lines.append("Emperor:          -")

	var top: String = str(s.get("top_contributor", ""))
	if top != "":
		lines.append("Most Runes:       %s" % top)

	return "\n".join(lines)
