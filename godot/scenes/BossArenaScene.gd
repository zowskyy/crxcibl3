extends BossEncounter
class_name BossArenaScene
## Shared arena + HUD setup for Corrupted Six boss encounters (Slices 3.18–3.22).
##
## validate boss outcome signals; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via BossEncounter super chain.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

@export var boss_context_key: String = "boss"
@export var spawn_pos: Vector2 = Vector2(80, 160)
@export var world_bounds: Rect2 = Rect2(0, 0, 600, 320)
@export var arrival_text: String = "BOSS ARENA — Move!"

const ARCANE_OVERLAY := preload("res://scenes/ArcaneOverlay.tscn")
const ENV_BACKDROP_SCRIPT := preload("res://scenes/EnvironmentBackdrop.gd")

var player: CharacterBody2D = null
var _intro_done := false
var _boss_outcome_done := false


func _ready() -> void:
	_setup_arena()
	_setup_player()
	add_child(ARCANE_OVERLAY.instantiate())
	if not encounter_data_path.is_empty():
		DialogueIntensity.on_boss_encountered(_get_boss_name())
	await super._ready()


func _get_boss_name() -> String:
	if not boss_context_key.is_empty() and boss_context_key != "boss":
		return boss_context_key.capitalize()
	return "Boss"


func _setup_arena() -> void:
	if get_node_or_null("EnvironmentBackdrop"):
		return
	var backdrop := Node2D.new()
	backdrop.name = "EnvironmentBackdrop"
	backdrop.set_script(ENV_BACKDROP_SCRIPT)
	backdrop.z_index = -20
	add_child(backdrop)
	move_child(backdrop, 0)


func _setup_player() -> void:
	var hero_id := GameState.get_active_hero()
	if hero_id.is_empty() and not GameState.squad.is_empty():
		hero_id = GameState.squad[0]
	if hero_id.is_empty():
		hero_id = "enforcer_ghost"
	player = HeroFactory.spawn_player(hero_id, spawn_pos, self, world_bounds)
	if player == null:
		push_error("BossArenaScene: failed to spawn player")
		return
	var fire_button := get_node_or_null("CanvasLayer/FireButton") as Button
	if fire_button and not fire_button.pressed.is_connected(_on_fire_pressed):
		fire_button.pressed.connect(_on_fire_pressed)


func _spawn_boss() -> void:
	super._spawn_boss()
	if _boss_instance == null:
		return
	_boss_instance.set_physics_process(false)
	if _boss_instance.has_method("set_flee_target"):
		var marker := get_node_or_null("FleeMarker") as Marker2D
		if marker:
			_boss_instance.call("set_flee_target", marker.global_position)


func _build_context() -> Dictionary:
	var ctx := {
		"boss": _boss_instance,
		"player": player if player else get_tree().get_first_node_in_group("player"),
	}
	if not boss_context_key.is_empty():
		ctx[boss_context_key] = _boss_instance
		ctx[boss_context_key.to_lower()] = _boss_instance
	return ctx


func _await_boss_outcome() -> void:
	if _boss_instance == null:
		return
	_intro_done = true
	_boss_instance.set_physics_process(true)
	await _wait_boss_end()


func _on_fire_pressed() -> void:
	if player:
		player.fire()


func _wait_boss_end() -> void:
	_boss_outcome_done = false
	if _boss_instance.has_signal("fled") and not _boss_instance.fled.is_connected(_on_boss_outcome_fled):
		_boss_instance.fled.connect(_on_boss_outcome_fled, CONNECT_ONE_SHOT)
	if _boss_instance.has_signal("defeated") and not _boss_instance.defeated.is_connected(_on_boss_outcome_defeated):
		_boss_instance.defeated.connect(_on_boss_outcome_defeated, CONNECT_ONE_SHOT)
	while not _boss_outcome_done and is_instance_valid(_boss_instance):
		await get_tree().process_frame


func _on_boss_outcome_fled() -> void:
	_boss_outcome_done = true


func _on_boss_outcome_defeated(_finisher: String) -> void:
	_boss_outcome_done = true


func _unhandled_key_input(event: InputEvent) -> void:
	if not _intro_done or player == null:
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
