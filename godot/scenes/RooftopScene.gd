extends Node2D
## Slice 2.18 — Rooftop sprint / surprise boss encounter.
## Players arrive from the apartment tower stairs (getaway trigger in TestRoom).
## Blackwood is on the far end of the roof, unguarded and surprised.
## After the fight (flee threshold hit) the scene ends and transitions to car chase.
##
## Caption intro driven by godot/data/blackwood_scene.json enter_sequence.

@onready var boss: CharacterBody2D = $BossBlackwood
@onready var flee_marker: Marker2D = $FleeMarker
@onready var flashbang: ColorRect = $FlashbangLayer/Flashbang
@onready var arrival_label: Label = $CanvasLayer/ArrivalLabel
@onready var player: CharacterBody2D = $Player
@onready var fire_button: Button = $CanvasLayer/FireButton

const BLACKWOOD_DATA := "res://data/blackwood_scene.json"
const ARCANE_OVERLAY := preload("res://scenes/ArcaneOverlay.tscn")
const ARRIVAL_DISPLAY_TIME := 3.0

var _arrival_timer := ARRIVAL_DISPLAY_TIME
var _intro_done := false


func _ready() -> void:
	boss.set_flee_target(flee_marker.global_position)
	boss.set_flashbang_node(flashbang)
	boss.fled.connect(_on_boss_fled)
	flashbang.visible = false
	fire_button.pressed.connect(func(): player.fire())
	add_child(ARCANE_OVERLAY.instantiate())
	DialogueIntensity.on_boss_encountered("Blackwood")
	call_deferred("_play_intro_cutscene")


func _play_intro_cutscene() -> void:
	if "--demo" in OS.get_cmdline_args():
		_intro_done = true
		return

	var data := EncounterData.load_encounter(BLACKWOOD_DATA)
	var beats: Array = EncounterData.resolve_beats(data, data.get("enter_sequence", []))
	if beats.is_empty():
		_intro_done = true
		return

	boss.set_physics_process(false)
	CutsceneDirector.set_context({"blackwood": boss, "player": player})
	CutsceneDirector.play("blackwood_intro", beats)
	await CutsceneDirector.cutscene_ended
	boss.set_physics_process(true)
	_intro_done = true


func _unhandled_key_input(event: InputEvent) -> void:
	if not _intro_done:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
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
		arrival_label.visible = _intro_done
		if _arrival_timer <= 0.0:
			arrival_label.visible = false


func _on_boss_fled() -> void:
	GameState.modify_heat(15.0)
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/CarChaseScene.tscn")
