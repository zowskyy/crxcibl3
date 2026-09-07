extends SceneTree
## Headless smoke test: a hero-card tap must register as a squad selection.
##
## Regression guard for the Button.toggled/.bind() argument-order bug class:
## Button.toggled fires as (button_pressed: bool), and .bind(x) appends x
## *after* the signal-supplied argument, so a bound callback's parameters
## must be ordered (bool, x) — not (x, bool), which type-mismatches silently
## on every tap and leaves the UI looking interactive while nothing updates.
##
## Usage: godot --headless --path godot -s res://tools/smoke_test_hero_selection.gd

const HERO_SELECTION_SCENE := "res://scenes/HeroSelectionUI.tscn"


func _initialize() -> void:
	var packed: PackedScene = load(HERO_SELECTION_SCENE)
	if packed == null:
		push_error("Could not load HeroSelectionUI.tscn")
		quit(1)
		return

	var ui := packed.instantiate()
	root.add_child(ui)
	await create_timer(0.1).timeout

	var grid: GridContainer = ui.get_node("VBoxContainer/ScrollContainer/GridContainer")
	if grid.get_child_count() == 0:
		push_error("Hero grid is empty — cannot smoke test selection")
		quit(1)
		return

	var first_button: Button = grid.get_child(0)
	# Setting button_pressed on a toggle_mode Button already emits `toggled`
	# natively (this is what a real tap does) — don't also emit manually, or
	# the callback fires twice and the test can't tell single-fire from
	# double-fire bugs apart.
	first_button.button_pressed = true
	await create_timer(0.1).timeout

	var squad_label: Label = ui.get_node("VBoxContainer/SquadLabel")
	var start_button: Button = ui.get_node("VBoxContainer/StartButton")

	var ok := true
	if ui._selected_variant_ids.size() != 1:
		push_error(
			"Tapping a hero card did not add it to _selected_variant_ids (size=%d, expected 1)"
			% ui._selected_variant_ids.size()
		)
		ok = false
	if squad_label.text.begins_with("Squad (0/"):
		push_error("squad_label still reads 0 selected after a tap: %s" % squad_label.text)
		ok = false
	if start_button.disabled:
		push_error("Start Mission button still disabled after selecting 1 hero (min is 1)")
		ok = false

	if ok:
		print("Hero selection smoke test: OK (tap -> squad=%d, start_button.disabled=false)" % ui._selected_variant_ids.size())
	else:
		print("Hero selection smoke test FAILED")

	quit(0 if ok else 1)
