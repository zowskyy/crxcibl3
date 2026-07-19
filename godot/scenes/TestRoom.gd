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

@onready var add_heat_button: Button = $CanvasLayer/AddHeatButton
@onready var fire_button: Button = $CanvasLayer/FireButton
@onready var rune_label: Label = $CanvasLayer/RuneLabel
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	add_heat_button.pressed.connect(_on_add_heat_pressed)
	fire_button.pressed.connect(_on_fire_pressed)


func _process(delta: float) -> void:
	# Slice 2.13: nothing else in the scene owns a per-frame tick, and
	# Stress.tick() is what applies its out-of-combat decay -- without
	# this it would climb from Enemy.gd's hooks but never come back down.
	Stress.tick(delta)
	var contrib := ""
	for hero in GameState.rune_contributions:
		contrib += "  %s:%d" % [hero, GameState.rune_contributions[hero]]
	rune_label.text = "Rune (group): %d%s" % [GameState.resources.get("Rune", 0), contrib]


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_H:
			_on_add_heat_pressed()
		elif event.keycode == KEY_SPACE:
			_on_fire_pressed()


func _on_add_heat_pressed() -> void:
	GameState.modify_heat(10.0)


func _on_fire_pressed() -> void:
	player.fire()
