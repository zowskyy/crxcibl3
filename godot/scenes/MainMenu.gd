extends Control
## MainMenu — Slice 3.5. Entry point before HeroSelectionUI.
##
## Three states:
##   No save file  — only New Game shown.
##   Save exists   — Continue (loads game + shows recap) + New Game both shown.
##   Recap visible — scrollable "Previously on..." panel before going to HeroSelectionUI.
##
## All save/load/reset logic lives in SaveSystem and GameState — this scene only routes.

@onready var title_label:    Label     = $VBox/TitleLabel
@onready var recap_panel:    Control   = $RecapPanel
@onready var recap_label:    Label     = $RecapPanel/RecapLabel
@onready var continue_btn:   Button    = $VBox/ContinueButton
@onready var new_game_btn:   Button    = $VBox/NewGameButton
@onready var close_recap_btn:Button    = $RecapPanel/CloseButton

const TITLE_TEXT := "CRXCIBL3"


func _ready() -> void:
	recap_panel.visible = false
	continue_btn.visible = SaveSystem.has_save()
	continue_btn.pressed.connect(_on_continue)
	new_game_btn.pressed.connect(_on_new_game)
	close_recap_btn.pressed.connect(_on_close_recap)


func _on_continue() -> void:
	SaveSystem.load_game()
	var recap_text := Recap.generate()
	if recap_text != "":
		recap_label.text = "PREVIOUSLY ON CRXCIBL3\n\n" + recap_text
		recap_panel.visible = true
	else:
		_go_to_selection()


func _on_close_recap() -> void:
	recap_panel.visible = false
	_go_to_selection()


func _on_new_game() -> void:
	GameState.reset_for_new_game()
	_go_to_selection()


func _go_to_selection() -> void:
	get_tree().change_scene_to_file("res://scenes/HeroSelectionUI.tscn")
