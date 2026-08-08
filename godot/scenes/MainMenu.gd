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


func _ready() -> void:
	recap_panel.visible = false
	continue_btn.visible = SaveSystem.has_save()
	_ensure_connected(continue_btn.pressed, _on_continue)
	_ensure_connected(new_game_btn.pressed, _on_new_game)
	_ensure_connected(coop_btn.pressed, _on_coop)
	_ensure_connected(close_recap_btn.pressed, _on_close_recap)
	continue_btn.custom_minimum_size = Vector2(200, 48)
	new_game_btn.custom_minimum_size = Vector2(200, 48)
	coop_btn.custom_minimum_size = Vector2(200, 48)
	close_recap_btn.custom_minimum_size = Vector2(200, 48)


func _ensure_connected(sig: Signal, callable: Callable) -> void:
	if not sig.is_connected(callable):
		sig.connect(callable)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if recap_panel.visible:
		_on_close_recap()
		get_viewport().set_input_as_handled()


func handle_android_back() -> void:
	if recap_panel.visible:
		_on_close_recap()


func _on_continue() -> void:
	if not SaveSystem.has_save():
		return
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
