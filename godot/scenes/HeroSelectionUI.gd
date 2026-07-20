extends Control
## HeroSelectionUI — Hero selection lobby (Phase 3, Slice 3.5)
##
## Display 12 hero portraits in a 4×3 grid, allow player to select 1–4 heroes.
## "Start Mission" button loads TestRoom with selected squad.

@onready var hero_grid: GridContainer = $ScrollContainer/GridContainer
@onready var squad_label: Label = $VBoxContainer/SquadLabel
@onready var start_button: Button = $VBoxContainer/StartButton

const HERO_BUTTON_SCENE := preload("res://scenes/HeroSelectionButton.tscn")
const MAX_SQUAD_SIZE := 4
const MIN_SQUAD_SIZE := 1

var _selected_variant_ids: Array = []  # Hero variant IDs currently selected


func _ready() -> void:
	start_button.disabled = true
	_populate_hero_grid()
	start_button.pressed.connect(_on_start_pressed)


func _populate_hero_grid() -> void:
	var variant_ids = HeroDefinitions.get_all_variant_ids()
	for variant_id: String in variant_ids:
		var variant = HeroDefinitions.get_variant(variant_id)
		if variant == null:
			continue

		var button: Button = HERO_BUTTON_SCENE.instantiate()
		button.text = variant.name
		button.custom_minimum_size = Vector2(80, 80)
		button.toggled.connect(func(pressed: bool): _on_hero_toggled(variant_id, pressed))

		# Placeholder: color by archetype (will use portrait images later)
		match variant.archetype:
			"enforcer": button.modulate = Color.RED
			"wheelman": button.modulate = Color.BLUE
			"hacker": button.modulate = Color.YELLOW
			"street_rat": button.modulate = Color.GREEN

		hero_grid.add_child(button)


func _on_hero_toggled(variant_id: String, is_selected: bool) -> void:
	if is_selected:
		if _selected_variant_ids.size() < MAX_SQUAD_SIZE:
			_selected_variant_ids.append(variant_id)
		else:
			# Too many selected, uncheck this one
			var button: Button = _get_hero_button(variant_id)
			if button:
				button.button_pressed = false
			return
	else:
		_selected_variant_ids.erase(variant_id)

	_update_squad_display()


func _get_hero_button(variant_id: String) -> Button:
	for child in hero_grid.get_children():
		if child.is_in_group(variant_id):
			return child
	return null


func _update_squad_display() -> void:
	var squad_text := "Squad (%d/%d):\n" % [_selected_variant_ids.size(), MAX_SQUAD_SIZE]
	for variant_id: String in _selected_variant_ids:
		var variant = HeroDefinitions.get_variant(variant_id)
		if variant:
			squad_text += "• %s (%s)\n" % [variant.name, variant.real_name]

	squad_label.text = squad_text
	start_button.disabled = _selected_variant_ids.size() < MIN_SQUAD_SIZE


func _on_start_pressed() -> void:
	if _selected_variant_ids.is_empty():
		return

	GameState.squad = _selected_variant_ids
	GameState.current_hero_index = 0
	get_tree().change_scene_to_file("res://scenes/TestRoom.tscn")
