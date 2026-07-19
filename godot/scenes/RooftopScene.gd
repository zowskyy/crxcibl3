extends Node2D
## Slice 2.18 — Rooftop sprint / surprise boss encounter.
## Players arrive from the apartment tower stairs (getaway trigger in TestRoom).
## Blackwood is on the far end of the roof, unguarded and surprised.
## After the fight (flee threshold hit) the scene ends and returns to TestRoom.
##
## Future arc (documented, not built here):
##   Blackwood fleeing → transitions into the car chase (Slice 2.19)
##   Car chase → The Emperor's confrontation (Slice 2.20, tag-team finale)

@onready var boss: CharacterBody2D = $BossBlackwood
@onready var flee_marker: Marker2D = $FleeMarker
@onready var flashbang: ColorRect = $FlashbangLayer/Flashbang
@onready var arrival_label: Label = $CanvasLayer/ArrivalLabel
@onready var heat_meter = $CanvasLayer/HeatMeter
@onready var player: CharacterBody2D = $Player
@onready var fire_button: Button = $CanvasLayer/FireButton

const ARRIVAL_DISPLAY_TIME := 3.0
var _arrival_timer := ARRIVAL_DISPLAY_TIME


func _ready() -> void:
	boss.set_flee_target(flee_marker.global_position)
	boss.set_flashbang_node(flashbang)
	boss.fled.connect(_on_boss_fled)
	flashbang.visible = false
	fire_button.pressed.connect(func(): player.fire())


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		player.fire()


func _process(delta: float) -> void:
	Stress.tick(delta)

	if _arrival_timer > 0.0:
		_arrival_timer -= delta
		arrival_label.visible = true
		if _arrival_timer <= 0.0:
			arrival_label.visible = false


func _on_boss_fled() -> void:
	# Blackwood escaped — mission complete for this encounter.
	# Mark the rooftop encounter done in GameState so it can't repeat,
	# and return to the boardwalk (TestRoom).
	GameState.bosses_fought.append("Blackwood_rooftop")
	GameState.modify_heat(15.0)   # heat spikes from the confrontation
	# Blackwood hit the street running — crew gives chase
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/CarChaseScene.tscn")
