extends Node2D
class_name GetawayScene
## Shared getaway mechanic (Slice 2.19+) — survive timed pursuit, then transition.
## Car chase, boat run, and future escapes all use this base.

signal getaway_started
signal getaway_survived

@export var chase_duration: float = 45.0
@export var scroll_speed: float = 160.0
@export var spawn_start_interval: float = 5.0
@export var spawn_min_interval: float = 1.8
@export var road_left: float = 78.0
@export var road_right: float = 306.0
@export var heat_on_complete: float = 25.0
@export var interstitial_text: String = "HE'S HEADED FOR THE HILLS..."
@export var exit_scene_path: String = "res://scenes/EmperorScene.tscn"
@export var getaway_label_prefix: String = "EVADE"

const PURSUIT_SCRIPT := preload("res://scenes/PursuitCar.gd")
const ARCANE_OVERLAY := preload("res://scenes/ArcaneOverlay.tscn")

var player_vehicle: CharacterBody2D
var road_renderer: Node2D
var target_marker: Node2D
var chase_label: Label
var hp_label: Label
var fire_button: Button

var _elapsed := 0.0
var _spawn_timer := 3.0
var _scroll := 0.0
var _done := false


func _ready() -> void:
	_resolve_nodes()
	if fire_button and player_vehicle and player_vehicle.has_method("fire"):
		fire_button.pressed.connect(func(): player_vehicle.fire())
	if player_vehicle and "owner_hero_id" in player_vehicle:
		player_vehicle.owner_hero_id = GameState.get_active_hero()
	_apply_carryover_upgrades()
	add_child(ARCANE_OVERLAY.instantiate())
	getaway_started.emit()


func _resolve_nodes() -> void:
	player_vehicle = get_node_or_null("PlayerCar") as CharacterBody2D
	road_renderer = get_node_or_null("RoadRenderer")
	target_marker = get_node_or_null("BlackwoodCar")
	chase_label = get_node_or_null("CanvasLayer/ChaseLabel") as Label
	hp_label = get_node_or_null("CanvasLayer/HpLabel") as Label
	fire_button = get_node_or_null("CanvasLayer/FireButton") as Button


func _apply_carryover_upgrades() -> void:
	if player_vehicle == null:
		return
	if GameState.has_upgrade("bullet_damage") and "bullet_damage_bonus" in player_vehicle:
		player_vehicle.bullet_damage_bonus += 10
	if GameState.has_upgrade("fire_rate") and "fire_cooldown_override" in player_vehicle:
		player_vehicle.fire_cooldown_override = 0.12


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if player_vehicle and player_vehicle.has_method("fire"):
			player_vehicle.fire()


func _process(delta: float) -> void:
	if _done:
		return

	_elapsed += delta
	_tick_mechanics(delta)
	_update_road(delta)
	_update_target_marker(delta)
	_update_spawns(delta)
	_update_hud()

	if _elapsed >= chase_duration:
		_finish_getaway()


func _tick_mechanics(delta: float) -> void:
	Stress.tick(delta)
	Morale.tick(delta)
	Injury.tick(delta)
	DialogueIntensity.tick(delta)
	Hideout.tick(delta)
	Scarcity.tick(delta)


func _update_road(delta: float) -> void:
	if road_renderer == null:
		return
	_scroll += scroll_speed * delta
	if "scroll_offset" in road_renderer:
		road_renderer.scroll_offset = _scroll
	if road_renderer.has_method("queue_redraw"):
		road_renderer.queue_redraw()


func _update_target_marker(delta: float) -> void:
	if target_marker == null:
		return
	target_marker.position.y -= 12.0 * delta
	if target_marker.position.y < -50.0:
		target_marker.position.y = -50.0
	if target_marker.has_method("queue_redraw"):
		target_marker.queue_redraw()


func _update_spawns(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	var t := clampf(_elapsed / chase_duration, 0.0, 1.0)
	_spawn_timer = lerpf(spawn_start_interval, spawn_min_interval, t)
	_spawn_pursuit()


func _spawn_pursuit() -> void:
	var car := CharacterBody2D.new()
	car.set_script(PURSUIT_SCRIPT)
	car.global_position = Vector2(
		randf_range(road_left + 15.0, road_right - 15.0),
		-45.0
	)
	add_child(car)


func _update_hud() -> void:
	if chase_label:
		var remaining := chase_duration - _elapsed
		chase_label.text = "%s  %.0fs" % [getaway_label_prefix, maxf(0.0, remaining)]
	if hp_label and player_vehicle and "hp" in player_vehicle:
		hp_label.text = "VEHICLE HP  %d" % int(player_vehicle.hp)


func _finish_getaway() -> void:
	_done = true
	getaway_survived.emit()
	if chase_label:
		chase_label.text = interstitial_text
	GameState.modify_heat(heat_on_complete)
	await get_tree().create_timer(2.5).timeout
	if exit_scene_path != "":
		get_tree().change_scene_to_file(exit_scene_path)
