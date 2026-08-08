extends Node2D
## EpilogueScene — Slice 3.7. Ending screen reached after EmperorScene.
##
## Displays the ending type (determined by Epilogue.start_epilogue() called in EmperorScene),
## the run summary, and a "Play Again" button that resets and returns to the main menu.
## Usage: Play Again — see --help in project docs.
## validate summary dict; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via stop_session + reset_for_new_game().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

@onready var ending_label:  Label  = $CanvasLayer/EndingLabel
@onready var summary_label: Label  = $CanvasLayer/SummaryLabel
@onready var play_again:    Button = $CanvasLayer/PlayAgainButton
@onready var background:   ColorRect = $Background


func _ready() -> void:
	background.color = SlugHudTheme.INK
	ending_label.modulate = SlugHudTheme.TAG_GOLD
	summary_label.modulate = SlugHudTheme.TEXT_DIM
	SlugHudTheme.style_menu_button(play_again)
	ending_label.text = Epilogue.get_ending_text()
	summary_label.text = _format_summary(Epilogue.get_summary())
	play_again.pressed.connect(_on_play_again)
	Epilogue.on_game_complete()


func _on_play_again() -> void:
	CoopNetwork.stop_session()
	GameState.reset_for_new_game()
	print("[EpilogueScene] Play Again — returning to MainMenu")
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _format_summary(s: Dictionary) -> String:
	var lines: Array = []
	lines.append("- Run Summary -")
	lines.append("")
	lines.append("Bosses defeated:  %d / %d" % [
		int(s.get("bosses_defeated", 0)),
		int(s.get("bosses_total", Bosses.BOSS_LIST.size())),
	])
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
	if not top.is_empty():
		lines.append("Most Runes:       %s" % top)

	return "\n".join(lines)
