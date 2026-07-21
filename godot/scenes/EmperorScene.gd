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
	# Entering the estate is the final story beat — maximum tension.
	DialogueIntensity.on_boss_encountered("Emperor")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if _reckoning:
			if dialogue_panel.visible and not _awaiting_choice:
				_advance()
		else:
			player.fire()


func _process(delta: float) -> void:
	Stress.tick(delta)
	Morale.tick(delta)
	Injury.tick(delta)
	DialogueIntensity.tick(delta)
	Hideout.tick(delta)
	Scarcity.tick(delta)

	if _arrival_timer > 0.0:
		_arrival_timer -= delta
		arrival_label.visible = true
		if _arrival_timer <= 0.0:
			arrival_label.visible = false


func _on_blackwood_defeated(finisher: String) -> void:
	# Blackwood dies here — he fled the rooftop, but there's nowhere left
	# to run. executed=true: this was a fight to the death, not a sparing.
	# Bosses.register_boss_defeat already called by BossBlackwood._die() in
	# the final_stand path — GameState.mark_boss_defeated is called there.
	Emperor.start_reckoning()
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
	Emperor.on_emperor_choice(forgive)          # heat adjustment + signal
	DialogueIntensity.on_dialogue_choice_made(15)  # moral reckoning spikes tension
	if forgive:
		Reputation.on_crew_saved()              # mercy = solidarity
	else:
		Reputation.on_boss_executed()           # vengeance = ruthlessness
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
	# Emperor.on_emperor_death() records the quest, drops heat -50, and emits arc_complete.
	# No need to touch quests_completed or heat here — it's all inside that call.
	Morale.on_quest_completed(20)    # major win — big morale boost
	Emperor.on_emperor_death()       # records quest, -50 heat, arc_complete signal
	Epilogue.start_epilogue()        # determines ending type from current state

	# CutsceneDirector sequences the closing beat:
	#   Emperor fades → 1s silence → save → Epilogue scene.
	var pb := PatternBuilder.new()
	pb.add_interpolate_value(emperor, "modulate:a", 1.0, 0.0, 2.0) \
	  .add_wait(1.0) \
	  .add_call_method(SaveSystem, "save_game", []) \
	  .add_call_method(get_tree(), "change_scene_to_file",
	                   ["res://scenes/EpilogueScene.tscn"]) \
	  .done()
	CutsceneDirector.start(pb.build())
