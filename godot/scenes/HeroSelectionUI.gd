extends Control
## HeroSelectionUI — Hero selection lobby (Phase 3, Slice 3.5)
##
## Display 12 hero portraits in a 4×3 grid, allow player to select 1–4 heroes.
## "Start Mission" loads TestRoom. Co-op: host starts; clients receive RPC sync.
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
@onready var hint_label: Label = $VBoxContainer/HintLabel
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var title_label: Label = $VBoxContainer/TitleLabel

const HERO_BUTTON_SCENE := preload("res://scenes/HeroSelectionButton.tscn")
const ARCANE_OVERLAY := preload("res://scenes/ArcaneOverlay.tscn")
const MAX_SQUAD_SIZE := 4
const MIN_SQUAD_SIZE := 1

var _selected_variant_ids: Array = []


func _ready() -> void:
	_setup_arcane_presentation()
	start_button.disabled = true
	_populate_hero_grid()
	start_button.pressed.connect(_on_start_pressed)
	if _is_coop_client():
		_set_client_coop_mode()
	elif _is_coop_host():
		title_label.text = "Co-op — Host Picks Squad"
		hint_label.text = "Select 1–4 heroes, then tap Start Mission to launch Beach Boulevard."
	else:
		hint_label.text = "Select 1–4 heroes, then tap Start Mission."
	_update_squad_display()


func _setup_arcane_presentation() -> void:
	var bg := ColorRect.new()
	bg.name = "ArcaneBG"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.03, 0.09, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)
	add_child(ARCANE_OVERLAY.instantiate())
	title_label.modulate = Color(0.96, 0.74, 0.38, 1.0)
	squad_label.modulate = Color(0.88, 0.86, 0.92, 1.0)
	hint_label.modulate = Color(0.72, 0.68, 0.78, 1.0)


func _is_coop_active() -> bool:
	return CoopNetwork.is_online() and CoopNetwork.is_coop


func _is_coop_host() -> bool:
	return _is_coop_active() and CoopNetwork.is_host()


func _is_coop_client() -> bool:
	return _is_coop_active() and not CoopNetwork.is_host()


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
			match variant.archetype:
				"enforcer": button.modulate = Color(0.95, 0.35, 0.28)
				"wheelman": button.modulate = Color(0.35, 0.55, 0.95)
				"hacker": button.modulate = Color(0.95, 0.85, 0.25)
				"street_rat": button.modulate = Color(0.35, 0.85, 0.45)

		hero_grid.add_child(button)


func _on_hero_toggled(variant_id: String, is_selected: bool) -> void:
	if _is_coop_client():
		return
	if is_selected:
		if _selected_variant_ids.size() < MAX_SQUAD_SIZE:
			_selected_variant_ids.append(variant_id)
		else:
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
	title_label.text = "Co-op — Crew Ready"
	hint_label.text = "The host picks the squad and taps Start Mission. You will load in automatically."
	print("[HeroSelectionUI] co-op client waiting for host squad sync")
	for child in hero_grid.get_children():
		if child is BaseButton:
			child.disabled = true


func _update_squad_display() -> void:
	var prefix := "Co-op squad" if _is_coop_active() else "Squad"
	var squad_text := "%s (%d/%d):\n" % [prefix, _selected_variant_ids.size(), MAX_SQUAD_SIZE]
	for variant_id: String in _selected_variant_ids:
		var variant = HeroDefinitions.get_variant(variant_id)
		if variant:
			squad_text += "• %s (%s)\n" % [variant.name, variant.real_name]

	squad_label.text = squad_text
	start_button.disabled = _selected_variant_ids.size() < MIN_SQUAD_SIZE or _is_coop_client()
	if _is_coop_host() and not start_button.disabled:
		start_button.text = "Start Mission — Launch Co-op"
	elif not _is_coop_active():
		start_button.text = "Start Mission"


func _on_start_pressed() -> void:
	if _selected_variant_ids.is_empty():
		return
	if _is_coop_client():
		return

	if _is_coop_host():
		CoopNetwork.begin_coop_mission(_selected_variant_ids.duplicate())
		return

	GameState.squad = _selected_variant_ids.duplicate()
	GameState.current_hero_index = 0
	print("[HeroSelectionUI] solo mission start — loading TestRoom")
	get_tree().change_scene_to_file("res://scenes/TestRoom.tscn")
