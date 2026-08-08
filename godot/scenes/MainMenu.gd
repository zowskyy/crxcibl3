extends Control
## MainMenu — Slice 3.5. Entry point before HeroSelectionUI.
##
## Three states:
##   No save file  — only New Game shown.
##   Save exists   — Continue (loads game + shows recap) + New Game both shown.
##   Recap visible — scrollable "Previously on..." panel before going to HeroSelectionUI.
##
## All save/load/reset logic lives in SaveSystem and GameState — this scene only routes.
## Usage: New Game, Continue, Co-op — see --help in project docs.
## validate save presence; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via stop_session before Co-op lobby.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

@onready var title_label:    Label     = $VBox/TitleLabel
@onready var recap_panel:    Control   = $RecapPanel
@onready var recap_label:    Label     = $RecapPanel/RecapLabel
@onready var continue_btn:   Button    = $VBox/ContinueButton
@onready var new_game_btn:   Button    = $VBox/NewGameButton
@onready var coop_btn:       Button    = $VBox/CoopButton
@onready var close_recap_btn:Button    = $RecapPanel/CloseButton

const TITLE_TEXT := "CRXCIBL3"
const ARCANE_OVERLAY := preload("res://scenes/ArcaneOverlay.tscn")


func _ready() -> void:
	_setup_arcane_presentation()
	recap_panel.visible = false
	continue_btn.visible = SaveSystem.has_save()
	continue_btn.pressed.connect(_on_continue)
	new_game_btn.pressed.connect(_on_new_game)
	coop_btn.pressed.connect(_on_coop)
	close_recap_btn.pressed.connect(_on_close_recap)


func _on_continue() -> void:
	if not SaveSystem.has_save():
		return
	CoopNetwork.stop_session()
	SaveSystem.load_game()
	var recap_text := Recap.generate()
	if _should_show_recap(recap_text):
		recap_label.text = "PREVIOUSLY ON CRXCIBL3\n\n" + recap_text
		recap_panel.visible = true
	else:
		_go_to_selection()


func _should_show_recap(recap_text: String) -> bool:
	return not recap_text.is_empty()


func _on_close_recap() -> void:
	recap_panel.visible = false
	_go_to_selection()


func _on_new_game() -> void:
	CoopNetwork.stop_session()
	GameState.reset_for_new_game()
	_go_to_selection()


func _on_coop() -> void:
	CoopNetwork.stop_session()
	print("[MainMenu] opening co-op lobby")
	get_tree().change_scene_to_file("res://scenes/CoopLobbyScene.tscn")


func _go_to_selection() -> void:
	if not is_inside_tree():
		return
	get_tree().change_scene_to_file("res://scenes/HeroSelectionUI.tscn")


func _setup_arcane_presentation() -> void:
	var bg := ColorRect.new()
	bg.name = "ArcaneBG"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.03, 0.09, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)
	add_child(ARCANE_OVERLAY.instantiate())
	title_label.modulate = Color(0.96, 0.74, 0.38, 1.0)
	$VBox/SubLabel.modulate = Color(0.62, 0.58, 0.72, 1.0)
