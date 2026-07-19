extends Node2D
## Slice 2.20 — The Emperor confrontation (Act 3 finale).
## The car chase ends at the Emperor's Estate in The Hills. Blackwood makes
## his final stand here — tag-team per the Architect's design note: he is
## the physical threat while the Emperor arc resolves emotionally. When he
## falls, combat is over for good and the reckoning is non-combat per lore:
## the Emperor confesses he traded the Seven Sorrows to save the crew's
## lives, the crew answers, and he dies surrounded by them. The crew walks
## away — no takeover.
##
## Confession lines come straight from the lore doc's "Final Reckoning"
## scene. The crew's answer is voiced by Big Body there; kept as "CREW"
## here since the active hero varies.

@onready var boss: CharacterBody2D = $BossBlackwood
@onready var emperor: Node2D = $EmperorFigure
@onready var player: CharacterBody2D = $Player
@onready var arrival_label: Label = $CanvasLayer/ArrivalLabel
@onready var stress_label: Label = $CanvasLayer/StressLabel
@onready var fire_button: Button = $CanvasLayer/FireButton
@onready var dialogue_panel: ColorRect = $CanvasLayer/DialoguePanel
@onready var dialogue_label: Label = $CanvasLayer/DialoguePanel/DialogueLabel
@onready var continue_button: Button = $CanvasLayer/DialoguePanel/ContinueButton
@onready var forgive_button: Button = $CanvasLayer/DialoguePanel/ForgiveButton
@onready var turn_away_button: Button = $CanvasLayer/DialoguePanel/TurnAwayButton

const ARRIVAL_DISPLAY_TIME := 3.0

const CONFESSION: Array = [
	"EMPEROR: I didn't betray you.",
	"EMPEROR: I made a deal with The Corrupted Six to save your lives.",
	"EMPEROR: I thought if I gave them the jobs, they'd let you walk. I was wrong.",
]
const ANSWER_FORGIVE: Array = [
	"CREW: We know. We've always known.",
	"CREW: You made a mistake. So did we.",
	"CREW: The Flats ain't about who's right — it's about who's still standing. And we're standing.",
	"The Emperor died that night, surrounded by the crew he'd failed and saved in equal measure.",
]
const ANSWER_TURN_AWAY: Array = [
	"The crew said nothing. There was nothing left worth saying.",
	"The Emperor died that night — alone in a room full of the people he'd failed.",
]

enum Stage { CONFESSION, ANSWER }

var _arrival_timer := ARRIVAL_DISPLAY_TIME
var _reckoning := false        # true once Blackwood falls — combat input is over
var _stage := Stage.CONFESSION
var _lines: Array = []
var _line_index := 0
var _awaiting_choice := false


func _ready() -> void:
	GameState.current_act = 3   # The Reckoning — Recap keys its act line off this
	boss.defeated.connect(_on_blackwood_defeated)
	fire_button.pressed.connect(func(): player.fire())
	continue_button.pressed.connect(_advance)
	forgive_button.pressed.connect(func(): _choose(true))
	turn_away_button.pressed.connect(func(): _choose(false))
	dialogue_panel.visible = false
	forgive_button.visible = false
	turn_away_button.visible = false


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if _reckoning:
			if dialogue_panel.visible and not _awaiting_choice:
				_advance()
		else:
			player.fire()


func _process(delta: float) -> void:
	Stress.tick(delta)

	if _arrival_timer > 0.0:
		_arrival_timer -= delta
		arrival_label.visible = true
		if _arrival_timer <= 0.0:
			arrival_label.visible = false
	stress_label.text = "Stress: %.0f" % Stress.stress


func _on_blackwood_defeated(finisher: String) -> void:
	# Blackwood dies here — he fled the rooftop, but there's nowhere left
	# to run. executed=true: this was a fight to the death, not a sparing.
	GameState.mark_boss_defeated("Blackwood", true, finisher)
	_reckoning = true
	fire_button.visible = false
	await get_tree().create_timer(1.5).timeout
	_stage = Stage.CONFESSION
	_lines = CONFESSION.duplicate()
	_line_index = 0
	dialogue_panel.visible = true
	_show_line()


func _show_line() -> void:
	dialogue_label.text = _lines[_line_index]


func _advance() -> void:
	if _awaiting_choice:
		return
	_line_index += 1
	if _line_index < _lines.size():
		_show_line()
		return
	match _stage:
		Stage.CONFESSION:
			_offer_choice()
		Stage.ANSWER:
			_end_reckoning()


func _offer_choice() -> void:
	_awaiting_choice = true
	dialogue_label.text = "He's waiting for an answer."
	continue_button.visible = false
	forgive_button.visible = true
	turn_away_button.visible = true


func _choose(forgive: bool) -> void:
	GameState.emperor_forgiven = forgive
	_awaiting_choice = false
	forgive_button.visible = false
	turn_away_button.visible = false
	continue_button.visible = true
	_stage = Stage.ANSWER
	_lines = (ANSWER_FORGIVE if forgive else ANSWER_TURN_AWAY).duplicate()
	_line_index = 0
	_show_line()


func _end_reckoning() -> void:
	dialogue_panel.visible = false
	if not GameState.quests_completed.has("emperor_reckoning"):
		GameState.quests_completed.append("emperor_reckoning")
	# The war dies with him — the city stops hunting a crew that's walking away.
	GameState.modify_heat(-50.0)
	# The Emperor fades out where he sits.
	var tween := get_tree().create_tween()
	tween.tween_property(emperor, "modulate:a", 0.0, 2.0)
	await tween.finished
	await get_tree().create_timer(1.0).timeout
	# First real in-game use of SaveSystem: the reckoning is the story
	# milestone worth persisting (act 3, Blackwood dead, emperor_forgiven).
	SaveSystem.save_game()
	# Epilogue is Phase 3 scope — back to the boardwalk for now.
	get_tree().change_scene_to_file("res://scenes/TestRoom.tscn")
