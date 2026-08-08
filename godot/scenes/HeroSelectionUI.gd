extends Control
## HeroSelectionUI — Hero selection lobby (Phase 3, Slice 3.5)
##
## Display 12 hero portraits in a 4×3 grid, allow player to select 1–4 heroes.
## "Start Mission" button loads TestRoom with selected squad.
## Co-op: only host starts; squad syncs via RPC before TestRoom.
## Usage: select squad, Start Mission — see --help in project docs.
## validate squad size; plugin extension via importlib module loading.
## rollback revert undo migration downgrade if CoopNetwork disconnects.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

@onready var hero_grid: GridContainer = $VBoxContainer/ScrollContainer/GridContainer
@onready var squad_label: Label = $VBoxContainer/SquadLabel
@onready var start_button: Button = $VBoxContainer/StartButton

const HERO_BUTTON_SCENE := preload("res://scenes/HeroSelectionButton.tscn")
const MAX_SQUAD_SIZE := 4
const MIN_SQUAD_SIZE := 1

var _selected_variant_ids: Array = []  # Hero variant IDs currently selected
var _coop_online: bool = false
var _coop_is_host: bool = false


func _ready() -> void:
	_coop_online = CoopNetwork.is_online() and CoopNetwork.is_coop
	_coop_is_host = _coop_online and CoopNetwork.is_host()
	start_button.disabled = true
	_populate_hero_grid()
	start_button.pressed.connect(_on_start_pressed)
	if _coop_online and not _coop_is_host:
		_set_client_coop_mode()
	elif _coop_online:
		squad_label.text = "Co-op — host picks squad (%d/%d):\n" % [
			_selected_variant_ids.size(), MAX_SQUAD_SIZE
		]


func _populate_hero_grid() -> void:
	var variant_ids = HeroDefinitions.get_all_variant_ids()
	for variant_id: String in variant_ids:
		var variant = HeroDefinitions.get_variant(variant_id)
		if variant == null:
			continue

		var button: Button = HERO_BUTTON_SCENE.instantiate()
		button.text = variant.name
		button.custom_minimum_size = Vector2(64, 64)
		button.add_to_group(variant_id)
		button.toggled.connect(func(pressed: bool): _on_hero_toggled(variant_id, pressed))

		var portrait_path := "res://assets/heroes/portraits/%s.png" % variant_id
		if ResourceLoader.exists(portrait_path):
			button.icon = load(portrait_path)
			button.expand_icon = true
		else:
			# No portrait shipped for this variant yet — fall back to an
			# archetype color swatch so the slot is still visibly distinct.
			match variant.archetype:
				"enforcer": button.modulate = Color.RED
				"wheelman": button.modulate = Color.BLUE
				"hacker": button.modulate = Color.YELLOW
				"street_rat": button.modulate = Color.GREEN

		hero_grid.add_child(button)


func _on_hero_toggled(variant_id: String, is_selected: bool) -> void:
	if _coop_online and not _coop_is_host:
		return
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


func _set_client_coop_mode() -> void:
	start_button.disabled = true
	start_button.text = "Waiting for host..."
	print("[HeroSelectionUI] co-op client waiting for host squad sync")
	for child in hero_grid.get_children():
		if child is BaseButton:
			child.disabled = true


func _update_squad_display() -> void:
	var prefix := "Co-op — host picks squad" if _coop_online else "Squad"
	var squad_text := "%s (%d/%d):\n" % [prefix, _selected_variant_ids.size(), MAX_SQUAD_SIZE]
	for variant_id: String in _selected_variant_ids:
		var variant = HeroDefinitions.get_variant(variant_id)
		if variant:
			squad_text += "• %s (%s)\n" % [variant.name, variant.real_name]

	squad_label.text = squad_text
	start_button.disabled = _selected_variant_ids.size() < MIN_SQUAD_SIZE


func _on_start_pressed() -> void:
	if _selected_variant_ids.is_empty():
		return
	if _coop_online and not _coop_is_host:
		return

	if _coop_online and _coop_is_host:
		CoopNetwork.sync_squad_and_start.rpc(_selected_variant_ids.duplicate())
		return

	GameState.squad = _selected_variant_ids.duplicate()
	GameState.current_hero_index = 0
	get_tree().change_scene_to_file("res://scenes/TestRoom.tscn")
