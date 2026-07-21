extends Node2D
## Slice 2.19 — Car chase getaway sequence.
## Follows directly from the rooftop: Blackwood vanishes off the roof and
## the crew scrambles to their car. Blackwood's town car is visible ahead,
## pulling away. Survive CHASE_DURATION seconds against escalating pursuit
## cars to reach the act break (Emperor confrontation, Slice 2.20).
##
## Road scrolls downward at SCROLL_SPEED to simulate forward movement.
## Pursuit cars spawn from off-screen top at increasing frequency.
## Bodega upgrades (bullet_damage, fire_rate) carry over from the boardwalk run.

const CHASE_DURATION   := 45.0    # seconds to survive
const SCROLL_SPEED     := 160.0   # road scroll px/sec
const SPAWN_START_INT  := 5.0     # seconds between spawns at the start
const SPAWN_MIN_INT    := 1.8     # floor as pressure ramps
const ROAD_LEFT        := 78.0
const ROAD_RIGHT       := 306.0

const PURSUIT_SCRIPT   := preload("res://scenes/PursuitCar.gd")

@onready var player_car:     CharacterBody2D = $PlayerCar
@onready var blackwood_car:  Node2D          = $BlackwoodCar
@onready var road_renderer:  Node2D          = $RoadRenderer
@onready var fire_button:    Button          = $CanvasLayer/FireButton
@onready var chase_label:    Label           = $CanvasLayer/ChaseLabel
@onready var hp_label:       Label           = $CanvasLayer/HpLabel

var _elapsed      := 0.0
var _spawn_timer  := 3.0  # first car after 3s so player can orient
var _scroll       := 0.0
var _done         := false


func _ready() -> void:
	fire_button.pressed.connect(func(): player_car.fire())
	# Apply bodega upgrades carried from the boardwalk
	if GameState.has_upgrade("bullet_damage"):
		player_car.bullet_damage_bonus += 10
	if GameState.has_upgrade("fire_rate"):
		player_car.fire_cooldown_override = 0.12


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		player_car.fire()


func _process(delta: float) -> void:
	if _done:
		return

	_elapsed += delta
	Stress.tick(delta)
	Morale.tick(delta)
	Injury.tick(delta)
	DialogueIntensity.tick(delta)
	Hideout.tick(delta)
	Scarcity.tick(delta)

	# Scroll road
	_scroll += SCROLL_SPEED * delta
	road_renderer.scroll_offset = _scroll
	road_renderer.queue_redraw()

	# Blackwood's car slowly pulls ahead — always slightly out of reach
	blackwood_car.position.y -= 12.0 * delta
	if blackwood_car.position.y < -50.0:
		blackwood_car.position.y = -50.0   # stay just off top edge
	blackwood_car.queue_redraw()

	# Spawn pressure escalates linearly over the chase
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		var t := clampf(_elapsed / CHASE_DURATION, 0.0, 1.0)
		_spawn_timer = lerpf(SPAWN_START_INT, SPAWN_MIN_INT, t)
		_spawn_pursuit_car()

	# HUD
	var remaining := CHASE_DURATION - _elapsed
	chase_label.text = "EVADE  %.0fs" % maxf(0.0, remaining)
	hp_label.text = "CAR HP  %d" % player_car.hp

	# Win: survived the full chase
	if _elapsed >= CHASE_DURATION:
		_finish_chase()


func _spawn_pursuit_car() -> void:
	var car := CharacterBody2D.new()
	car.set_script(PURSUIT_SCRIPT)
	# Randomise lane — keeps pressure spread and unpredictable
	car.global_position = Vector2(
		randf_range(ROAD_LEFT + 15.0, ROAD_RIGHT - 15.0),
		-45.0
	)
	add_child(car)


func _finish_chase() -> void:
	_done = true
	chase_label.text = "HE'S HEADED FOR THE HILLS..."
	# Heat spikes — the chase was loud, the whole city saw it
	GameState.modify_heat(25.0)
	await get_tree().create_timer(2.5).timeout
	# The chase ends where it was always going: the Emperor's estate (Slice 2.20)
	get_tree().change_scene_to_file("res://scenes/EmperorScene.tscn")
