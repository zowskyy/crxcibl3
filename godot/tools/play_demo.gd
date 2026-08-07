extends SceneTree
## Launch TestRoom with a preset squad and automated DemoDriver input.
## Usage: godot --path godot -s res://tools/play_demo.gd

const DEMO_DRIVER := preload("res://tools/DemoDriver.gd")


func _initialize() -> void:
	GameState.reset_for_new_game()
	GameState.squad = ["enforcer_ghost"]
	GameState.current_hero_index = 0

	var scene: PackedScene = load("res://scenes/TestRoom.tscn")
	var room: Node = scene.instantiate()
	root.add_child(room)

	var driver := DEMO_DRIVER.new()
	driver.name = "DemoDriver"
	root.add_child(driver)
