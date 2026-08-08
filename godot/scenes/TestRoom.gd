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

# Corrupted Six entry points — triggers spawned in code at these world anchors.
const BOSS_TRIGGER_SPECS := [
	{"boss_id": "Cross", "anchor": "Building1", "offset": Vector2(0, 50)},
	{"boss_id": "Voss", "anchor": "Building2", "offset": Vector2(0, 50)},
	{"boss_id": "Moreau", "anchor": "Building3", "offset": Vector2(0, 50)},
	{"boss_id": "Hayes", "anchor": "CrackHouse1", "offset": Vector2(0, -20)},
	{"boss_id": "Webb", "anchor": "Fence1", "offset": Vector2(0, -30)},
]

var _boss_triggers: Dictionary = {}  # boss_id -> Area2D
var _boss_hint_label: Label = null
var _active_boss_hint_id := ""


func _ready() -> void:
	_setup_environment()
	fire_button.pressed.connect(_on_fire_pressed)
	rooftop_trigger.body_entered.connect(_on_rooftop_trigger_entered)

	_apply_qa_cmdline_flags()
	ActProgression.unlock_act_for_boss_progress()
	_setup_boss_triggers()
	_setup_boss_hint_label()
	if not Bosses.boss_defeated.is_connected(_on_boss_progress_changed):
		Bosses.boss_defeated.connect(_on_boss_progress_changed)

	if "--demo" in OS.get_cmdline_args():
		GameState.reset_for_new_game()
		GameState.squad = ["enforcer_ghost"]
		GameState.current_hero_index = 0

	QuestManager.register_quest(SAMPLE_QUEST)
	QuestManager.start_quest(SAMPLE_QUEST["id"])

	# Spawn active hero via HeroFactory (Slice 3.5)
	var hero_id = GameState.get_active_hero()
	if hero_id.is_empty() and not GameState.squad.is_empty():
		hero_id = GameState.squad[0]

	if not hero_id.is_empty():
		player = HeroFactory.spawn_player(hero_id, Vector2(550, 300), self, _world_bounds)
	else:
		# Fallback: no squad selected (shouldn't happen in normal flow, but debug fallback)
		player = HeroFactory.spawn_player("enforcer_ghost", Vector2(550, 300), self, _world_bounds)

	_setup_hideout_zone()
	_setup_quest_hud()
	_setup_squad_label()
	_setup_synergy_hud()
	_connect_player_signals()

	if "--demo" in OS.get_cmdline_args():
		var driver := preload("res://tools/DemoDriver.gd").new()
		driver.name = "DemoDriver"
		add_child(driver)

	if "--boss-cross" in OS.get_cmdline_args():
		call_deferred("_load_boss_scene", "res://scenes/BossCrossScene.tscn")


func _apply_qa_cmdline_flags() -> void:
	var args := OS.get_cmdline_args()
	if "--boss-all" in args:
		for boss_id in ActProgression.CORRUPTED_SIX_IDS:
			if not GameState.bosses_fought.has(boss_id):
				GameState.mark_boss_defeated(boss_id, false, "qa")
		ActProgression.unlock_act_for_boss_progress()


func _setup_boss_triggers() -> void:
	for spec in BOSS_TRIGGER_SPECS:
		var boss_id: String = spec["boss_id"]
		var anchor_name: String = spec["anchor"]
		var anchor := get_node_or_null(anchor_name) as Node2D
		if anchor == null:
			push_warning("TestRoom: missing boss trigger anchor %s" % anchor_name)
			continue

		var zone := Area2D.new()
		zone.name = "%sBossTrigger" % boss_id
		zone.position = anchor.position + spec["offset"]
		zone.monitorable = false
		zone.monitoring = true

		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(80, 80)
		col.shape = shape
		zone.add_child(col)

		zone.body_entered.connect(_on_boss_trigger_entered.bind(boss_id))
		add_child(zone)
		_boss_triggers[boss_id] = zone


func _setup_boss_hint_label() -> void:
	_boss_hint_label = Label.new()
	_boss_hint_label.name = "BossHintLabel"
	_boss_hint_label.anchor_left = 0.5
	_boss_hint_label.anchor_right = 0.5
	_boss_hint_label.anchor_top = 1.0
	_boss_hint_label.anchor_bottom = 1.0
	_boss_hint_label.offset_left = -220.0
	_boss_hint_label.offset_top = -88.0
	_boss_hint_label.offset_right = 220.0
	_boss_hint_label.offset_bottom = -64.0
	_boss_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_hint_label.visible = false
	canvas_layer.add_child(_boss_hint_label)


func _on_boss_progress_changed(_boss_name: String, _finisher: String, _executed: bool) -> void:
	ActProgression.unlock_act_for_boss_progress()
	_refresh_boss_hint()


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
	_update_boss_hint_proximity()

	# Slice 2.13: nothing else in the scene owns a per-frame tick, and
	# Stress.tick() is what applies its out-of-combat decay -- without
	# this it would climb from Enemy.gd's hooks but never come back down.
	Stress.tick(delta)
	Morale.tick(delta)
	Injury.tick(delta)
	DialogueIntensity.tick(delta)
	Hideout.tick(delta)
	Scarcity.tick(delta)

	# Wave intensity: 0 below heat 51, ramps to 1.0 at heat 100.
	var heat_t := clampf((GameState.heat - 51.0) / 49.0, 0.0, 1.0)
	var mat := wave_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("intensity", heat_t)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_H:
			_on_add_heat_pressed()
		elif event.keycode == KEY_SPACE:
			_on_fire_pressed()
		elif event.keycode == KEY_I:
			_toggle_inventory()
		elif event.keycode == KEY_TAB:
			_cycle_squad_hero()


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
	GameState.modify_heat(10.0)


func _on_fire_pressed() -> void:
	if player and is_instance_valid(player):
		player.fire()


func _toggle_inventory() -> void:
	if _inventory_ui and is_instance_valid(_inventory_ui):
		_inventory_ui.queue_free()
		_inventory_ui = null
		return
	_inventory_ui = CanvasLayer.new()
	_inventory_ui.set_script(INVENTORY_UI_SCRIPT)
	add_child(_inventory_ui)


func _on_boss_trigger_entered(body: Node, boss_id: String) -> void:
	if not body.is_in_group("player"):
		return
	if "--demo" in OS.get_cmdline_args():
		return
	if GameState.bosses_fought.has(boss_id):
		return
	var next_id := ActProgression.get_next_boss_id()
	if next_id != boss_id:
		return
	var scene_path := ActProgression.get_next_boss_scene()
	if scene_path == "":
		return
	_load_boss_scene(scene_path)


func _load_boss_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_warning("TestRoom: boss scene not found yet: %s" % scene_path)
		return
	get_tree().change_scene_to_file(scene_path)


func _update_boss_hint_proximity() -> void:
	if _boss_hint_label == null:
		return
	var next_id := ActProgression.get_next_boss_id()
	if next_id == "" or player == null or not is_instance_valid(player):
		_boss_hint_label.visible = false
		_active_boss_hint_id = ""
		return

	var zone: Area2D = _boss_triggers.get(next_id)
	if zone == null:
		_boss_hint_label.visible = false
		return

	var hint_radius := 120.0
	var near := player.global_position.distance_to(zone.global_position) <= hint_radius
	if near:
		if _active_boss_hint_id != next_id:
			_active_boss_hint_id = next_id
			_boss_hint_label.text = ActProgression.boss_hint_text(next_id)
		_boss_hint_label.visible = true
	else:
		_boss_hint_label.visible = false
		_active_boss_hint_id = ""


func _refresh_boss_hint() -> void:
	_active_boss_hint_id = ""
	if _boss_hint_label:
		_boss_hint_label.visible = false


func _on_rooftop_trigger_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if "--demo" in OS.get_cmdline_args():
		return
	# Blackwood rooftop unlocks after the Corrupted Six are down.
	if not ActProgression.is_corrupted_six_complete():
		return
	# Only trigger once per run — if the rooftop encounter is already done
	# (boss fled and GameState recorded it) skip the scene transition.
	if GameState.bosses_fought.has("Blackwood_rooftop"):
		return
	get_tree().change_scene_to_file("res://scenes/RooftopScene.tscn")
