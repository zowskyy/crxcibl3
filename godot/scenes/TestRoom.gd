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


func _ready() -> void:
	fire_button.pressed.connect(_on_fire_pressed)
	rooftop_trigger.body_entered.connect(_on_rooftop_trigger_entered)

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
	_connect_player_signals()

	if "--demo" in OS.get_cmdline_args():
		var driver := preload("res://tools/DemoDriver.gd").new()
		driver.name = "DemoDriver"
		add_child(driver)


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


func _on_rooftop_trigger_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if "--demo" in OS.get_cmdline_args():
		return
	# Only trigger once per run — if the rooftop encounter is already done
	# (boss fled and GameState recorded it) skip the scene transition.
	if GameState.bosses_fought.has("Blackwood_rooftop"):
		return
	get_tree().change_scene_to_file("res://scenes/RooftopScene.tscn")
