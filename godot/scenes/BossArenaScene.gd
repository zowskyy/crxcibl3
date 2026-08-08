extends BossEncounter
class_name BossArenaScene
## Shared arena + HUD setup for Corrupted Six boss encounters (Slices 3.18–3.22).

@export var boss_context_key: String = "boss"
@export var spawn_pos: Vector2 = Vector2(80, 160)
@export var world_bounds: Rect2 = Rect2(0, 0, 600, 320)
@export var arrival_text: String = "BOSS ARENA — Move!"

const ARCANE_OVERLAY := preload("res://scenes/ArcaneOverlay.tscn")
const ENV_BACKDROP_SCRIPT := preload("res://scenes/EnvironmentBackdrop.gd")

var player: CharacterBody2D = null
var _intro_done := false


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
	if fire_button:
		fire_button.pressed.connect(func(): player.fire())


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


func _wait_boss_end() -> void:
	var ended := false
	if _boss_instance.has_signal("fled"):
		_boss_instance.fled.connect(func(): ended = true, CONNECT_ONE_SHOT)
	if _boss_instance.has_signal("defeated"):
		_boss_instance.defeated.connect(func(_f): ended = true, CONNECT_ONE_SHOT)
	while not ended and is_instance_valid(_boss_instance):
		await get_tree().process_frame


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
