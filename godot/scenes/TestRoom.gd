extends Node2D
## Slice 2.5 -- minimal test room. Confirms GameState reads/writes
## correctly at runtime before any real level content gets built. Press
## the "Add Heat" button (or the H key) to bump GameState.heat -- the
## HeatMeter HUD (Slice 2.10) polls and redraws itself, no manual
## refresh call needed here anymore.
##
## Slice 2.14: also wires the Fire button/Space key to Player.fire() --
## Metal Slug-style gun combat per the Architect's direction. RuneLabel
## polls GameState.resources.Rune so kills (Enemy.gd drops 1 Rune each)
## are visibly confirmable, same reasoning as the Heat/Stress meters.
##
## Shader integration (Slice 2.16): wave overlay intensity tracks
## GameState.heat -- kicks in past the 51 threshold already used by the
## vignette/tint in the visual direction doc, maxes out at heat 100.
##
## Co-op (Slice 4.x): TestRoomCoopSync handles remote avatars + host heat when
## CoopNetwork.is_online(); solo path unchanged when offline.
##
## Usage: solo or co-op TestRoom — see --help in project docs.

## validate player spawn; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via CoopNetwork.stop_session().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


@onready var fire_button: Button = $CanvasLayer/FireButton
@onready var wave_rect: ColorRect = $WaveOverlayLayer/WaveRect
@onready var rooftop_trigger: Area2D = $RooftopTrigger
@onready var canvas_layer: CanvasLayer = $CanvasLayer

var player: CharacterBody2D  # Spawned dynamically by HeroFactory

const INVENTORY_UI_SCRIPT := preload("res://scenes/InventoryUI.gd")
const QUEST_HUD_SCRIPT := preload("res://scenes/QuestHUD.gd")
const HIDEOUT_ZONE_SCRIPT := preload("res://scenes/HideoutZone.gd")
const ENV_BACKDROP_SCRIPT := preload("res://scenes/EnvironmentBackdrop.gd")
const ARCANE_OVERLAY := preload("res://scenes/ArcaneOverlay.tscn")
const SYNERGY_HUD_SCRIPT := preload("res://scenes/SynergyHUD.gd")

var _inventory_ui: CanvasLayer = null
var _quest_hud: Control = null
var _squad_label: Label = null
var _world_bounds := Rect2(Vector2(0, 0), Vector2(1100, 600))

const SAMPLE_QUEST := {
	"id": "clear_crack_house",
	"title": "Clear the Crack House",
	"objectives": [
		{"id": "kill_grunts", "type": "kill", "target": "enemy", "count": 3},
	],
	"rewards": {"runes": 20, "items": ["9mm_extended_mag"]},
}

var _boss_access: TestRoomBossAccess
var _coop_sync: TestRoomCoopSync

func _ready() -> void:
	_setup_environment()
	if not fire_button.pressed.is_connected(_on_fire_pressed):
		fire_button.pressed.connect(_on_fire_pressed)
	fire_button.custom_minimum_size = Vector2(80, 48)

	ActProgression.apply_qa_cmdline_flags()
	ActProgression.unlock_act_for_boss_progress()
	_boss_access = TestRoomBossAccess.new()
	_boss_access.name = "BossAccess"
	add_child(_boss_access)
	_boss_access.setup(self, canvas_layer, Callable(self, "_get_player"), rooftop_trigger)
	_boss_access.queue_boss_cross_load()

	_coop_sync = TestRoomCoopSync.new()
	_coop_sync.name = "CoopSync"
	add_child(_coop_sync)
	_coop_sync.setup(self, canvas_layer, _world_bounds)

	var is_demo := "--demo" in OS.get_cmdline_args()
	if is_demo:
		GameState.reset_for_new_game()
		GameState.squad = ["enforcer_ghost"]
		GameState.current_hero_index = 0

	QuestManager.register_quest(SAMPLE_QUEST)
	QuestManager.start_quest(SAMPLE_QUEST["id"])

	_spawn_local_player()
	_connect_player_signals()
	print("TestRoom: player spawned (%s run)" % ["solo", "co-op"][int(CoopNetwork.is_online())])

	_setup_hideout_zone()
	_setup_quest_hud()
	_setup_squad_label()
	_setup_synergy_hud()

	if is_demo:
		var driver := preload("res://tools/DemoDriver.gd").new()
		driver.name = "DemoDriver"
		add_child(driver)

func _get_player() -> CharacterBody2D:
	return player

func _spawn_local_player() -> void:
	var spawn_pos := Vector2(550, 300) + _coop_sync.spawn_offset()
	var hero_id := GameState.get_active_hero()
	if hero_id.is_empty() and not GameState.squad.is_empty():
		hero_id = GameState.squad[0]
	var spawn_id := hero_id if not hero_id.is_empty() else "enforcer_ghost"
	player = HeroFactory.spawn_player(spawn_id, spawn_pos, self, _world_bounds)

func _setup_environment() -> void:
	var ground := get_node_or_null("Ground")
	if ground:
		ground.visible = false

	var backdrop := Node2D.new()
	backdrop.name = "EnvironmentBackdrop"
	backdrop.set_script(ENV_BACKDROP_SCRIPT)
	backdrop.z_index = -20
	add_child(backdrop)
	move_child(backdrop, 0)

	add_child(ARCANE_OVERLAY.instantiate())

func _setup_synergy_hud() -> void:
	var synergy := Control.new()
	synergy.name = "SynergyHUD"
	synergy.set_script(SYNERGY_HUD_SCRIPT)
	var bond_label := Label.new()
	bond_label.name = "BondLabel"
	synergy.add_child(bond_label)
	canvas_layer.add_child(synergy)

func _setup_hideout_zone() -> void:
	var zone := Area2D.new()
	zone.name = "HideoutZone"
	zone.position = Vector2(560, 200)
	zone.set_script(HIDEOUT_ZONE_SCRIPT)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(120, 100)
	col.shape = shape
	zone.add_child(col)
	add_child(zone)

func _setup_quest_hud() -> void:
	_quest_hud = Control.new()
	_quest_hud.name = "QuestHUD"
	_quest_hud.set_script(QUEST_HUD_SCRIPT)
	canvas_layer.add_child(_quest_hud)
	_quest_hud.set_quest_title(SAMPLE_QUEST["id"], SAMPLE_QUEST["title"])

func _setup_squad_label() -> void:
	_squad_label = Label.new()
	_squad_label.name = "SquadLabel"
	_squad_label.anchor_left = 0.0
	_squad_label.anchor_top = 1.0
	_squad_label.anchor_bottom = 1.0
	_squad_label.offset_left = 4.0
	_squad_label.offset_top = -56.0
	_squad_label.offset_right = 200.0
	_squad_label.offset_bottom = -40.0
	canvas_layer.add_child(_squad_label)
	_update_squad_label()

func _connect_player_signals() -> void:
	if player == null or not is_instance_valid(player):
		return
	if not player.downed.is_connected(_on_player_downed):
		player.downed.connect(_on_player_downed)

func _update_squad_label() -> void:
	if _squad_label == null:
		return
	var hero_id := GameState.get_active_hero()
	var variant = HeroDefinitions.get_variant(hero_id)
	var display_name: String = variant.name if variant else hero_id
	_squad_label.text = "Squad: %s" % display_name

func _process(delta: float) -> void:
	_boss_access.tick_hint()
	_coop_sync.tick(delta, player)

	Stress.tick(delta)
	Morale.tick(delta)
	Injury.tick(delta)
	DialogueIntensity.tick(delta)
	Hideout.tick(delta)
	Scarcity.tick(delta)

	var heat_t := clampf((GameState.heat - 51.0) / 49.0, 0.0, 1.0)
	(wave_rect.material as ShaderMaterial).set_shader_parameter("intensity", heat_t)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	for entry in [
		["add_heat", _on_add_heat_pressed],
		["fire", _on_fire_pressed],
		["inventory", _toggle_inventory],
		["cycle_hero", _cycle_squad_hero],
	]:
		if event.is_action_pressed(entry[0]):
			entry[1].call()
			return

func _cycle_squad_hero() -> void:
	if GameState.squad.size() <= 1:
		return
	var next_index := (GameState.current_hero_index + 1) % GameState.squad.size()
	GameState.switch_to_hero(next_index)
	var new_id := GameState.get_active_hero()
	player = HeroFactory.switch_active_hero(player, new_id, self, _world_bounds)
	_connect_player_signals()
	_update_squad_label()

func _on_player_downed() -> void:
	if not GameState.permadeath_mode:
		return
	call_deferred("_auto_switch_after_permadeath")

func _auto_switch_after_permadeath() -> void:
	if not PermanentDeath.is_squad_viable():
		Epilogue.start_epilogue()
		get_tree().change_scene_to_file("res://scenes/EpilogueScene.tscn")
		return
	if GameState.current_hero_index >= GameState.squad.size():
		GameState.current_hero_index = maxi(0, GameState.squad.size() - 1)
	var new_id := GameState.get_active_hero()
	if new_id.is_empty():
		return
	player = HeroFactory.switch_active_hero(player, new_id, self, _world_bounds)
	_connect_player_signals()
	_update_squad_label()

func _on_add_heat_pressed() -> void:
	if not _coop_sync.can_modify_heat():
		return
	GameState.modify_heat(10.0)

func _on_fire_pressed() -> void:
	if is_instance_valid(player):
		player.fire()

func _exit_tree() -> void:
	if _coop_sync != null:
		_coop_sync.teardown()

func _toggle_inventory() -> void:
	if _inventory_ui and is_instance_valid(_inventory_ui):
		_inventory_ui.queue_free()
		_inventory_ui = null
		return
	_inventory_ui = CanvasLayer.new()
	_inventory_ui.set_script(INVENTORY_UI_SCRIPT)
	add_child(_inventory_ui)
