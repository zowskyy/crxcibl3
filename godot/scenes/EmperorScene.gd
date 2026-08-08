extends Node2D
## Slice 2.20 — The Emperor confrontation (Act 3 finale).
## Blackwood final stand first; reckoning cutscene driven by data/emperor_scene.json
## via CutsceneDirector beats + DialogueBox autoload.

@onready var boss: CharacterBody2D = $BossBlackwood
@onready var emperor: Node2D = $EmperorFigure
@onready var player: CharacterBody2D = $Player
@onready var arrival_label: Label = $CanvasLayer/ArrivalLabel
@onready var fire_button: Button = $CanvasLayer/FireButton

const RECKONING_DATA := "res://data/emperor_scene.json"
const ARCANE_OVERLAY := preload("res://scenes/ArcaneOverlay.tscn")
const ARRIVAL_DISPLAY_TIME := 3.0

var _arrival_timer := ARRIVAL_DISPLAY_TIME
var _reckoning := false


func _ready() -> void:
	GameState.current_act = 3
	boss.defeated.connect(_on_blackwood_defeated)
	fire_button.pressed.connect(func(): player.fire())
	add_child(ARCANE_OVERLAY.instantiate())
	DialogueIntensity.on_boss_encountered("Emperor")


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if not _reckoning:
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


func _on_blackwood_defeated(_finisher: String) -> void:
	Emperor.start_reckoning()
	_reckoning = true
	fire_button.visible = false
	await get_tree().create_timer(1.5).timeout
	_play_reckoning_from_json()


func _play_reckoning_from_json() -> void:
	var data := EncounterData.load_encounter(RECKONING_DATA)
	if data.is_empty():
		push_error("EmperorScene: missing reckoning data")
		get_tree().change_scene_to_file("res://scenes/EpilogueScene.tscn")
		return

	CutsceneDirector.set_context({"emperor": emperor, "player": player})

	var beats: Array = []
	beats.append_array(EncounterData.resolve_beats(data, data.get("defeat_sequence", [])))
	beats.append_array(EncounterData.resolve_beats(data, data.get("choice_sequence", [])))

	CutsceneDirector.play("emperor", beats)
	await CutsceneDirector.cutscene_ended
