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

var player: CharacterBody2D  # Spawned dynamically by HeroFactory

const INVENTORY_UI_SCRIPT := preload("res://scenes/InventoryUI.gd")
var _inventory_ui: CanvasLayer = null

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

	QuestManager.register_quest(SAMPLE_QUEST)
	QuestManager.start_quest(SAMPLE_QUEST["id"])

	# Spawn active hero via HeroFactory (Slice 3.5)
	var hero_id = GameState.get_active_hero()
	if hero_id.is_empty() and not GameState.squad.is_empty():
		hero_id = GameState.squad[0]

	var world_bounds := Rect2(Vector2(0, 0), Vector2(1100, 600))
	if not hero_id.is_empty():
		player = HeroFactory.spawn_player(hero_id, Vector2(550, 300), self, world_bounds)
	else:
		# Fallback: no squad selected (shouldn't happen in normal flow, but debug fallback)
		player = HeroFactory.spawn_player("enforcer_ghost", Vector2(550, 300), self, world_bounds)


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


func _on_add_heat_pressed() -> void:
	GameState.modify_heat(10.0)


func _on_fire_pressed() -> void:
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
	# Only trigger once per run — if the rooftop encounter is already done
	# (boss fled and GameState recorded it) skip the scene transition.
	if GameState.bosses_fought.has("Blackwood_rooftop"):
		return
	get_tree().change_scene_to_file("res://scenes/RooftopScene.tscn")
