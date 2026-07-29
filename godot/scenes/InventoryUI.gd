extends CanvasLayer
## Minimal drag-and-drop inventory panel (Quest & Inventory system,
## wow.txt spec: "30-slot drag-and-drop inventory with equipment slots and
## gear stat bonuses"). Built entirely in code, same construction pattern
## as the rest of this project's dynamic content (SpawnGenerator, Enemy).
## Toggle visibility from a level script (e.g. TestRoom's "I" key) --
## there's no HUD real estate for a permanent inventory grid at this
## project's mobile viewport size.

const SLOT_SCRIPT := preload("res://scenes/InventorySlot.gd")

var _slots: Array = []
var _equip_slots: Array = []


func _ready() -> void:
	layer = 10

	var panel := Panel.new()
	panel.position = Vector2(20, 10)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(6, 6)
	panel.add_child(vbox)

	var equip_row := HBoxContainer.new()
	vbox.add_child(equip_row)
	for category in Inventory.EQUIP_CATEGORIES:
		var slot := Panel.new()
		slot.set_script(SLOT_SCRIPT)
		slot.equip_category = category
		equip_row.add_child(slot)
		_equip_slots.append(slot)

	# The 384x216 base viewport can't fit all 30 slots without scrolling --
	# same problem HeroSelectionUI.tscn solves with a ScrollContainer around
	# its hero grid, so this follows that same established pattern rather
	# than letting the panel overflow off the bottom of the screen.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(210, 130)
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 6
	scroll.add_child(grid)
	for i in range(Inventory.SLOT_COUNT):
		var slot := Panel.new()
		slot.set_script(SLOT_SCRIPT)
		slot.slot_index = i
		grid.add_child(slot)
		_slots.append(slot)

	panel.custom_minimum_size = Vector2(222, 190)

	Inventory.inventory_changed.connect(_refresh_all)
	Inventory.item_equipped.connect(func(_c, _i): _refresh_all())
	Inventory.item_unequipped.connect(func(_c, _i): _refresh_all())


func _refresh_all() -> void:
	for s in _slots:
		s.refresh()
	for s in _equip_slots:
		s.refresh()
