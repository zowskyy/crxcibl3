extends Node2D
## Slice 2.5 -- minimal test room. Confirms GameState reads/writes
## correctly at runtime before any real level content gets built. Press
## the "Add Heat" button (or the H key) to bump GameState.heat -- the
## HeatMeter HUD (Slice 2.10) polls and redraws itself, no manual
## refresh call needed here anymore.

@onready var add_heat_button: Button = $CanvasLayer/AddHeatButton


func _ready() -> void:
	add_heat_button.pressed.connect(_on_add_heat_pressed)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		_on_add_heat_pressed()


func _on_add_heat_pressed() -> void:
	GameState.modify_heat(10.0)
