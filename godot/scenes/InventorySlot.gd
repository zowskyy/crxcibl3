extends Panel
## One inventory grid cell or equipment slot (Quest & Inventory system,
## wow.txt spec). Supports Godot's native Control drag-and-drop
## (get_drag_data/can_drop_data/drop_data) so items can be reordered or
## equipped by dragging, with both mouse and touch.

@export var slot_index: int = -1        # >=0 for a normal inventory grid slot
@export var equip_category: String = "" # non-empty for an equipment slot

var _label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(32, 32)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_label)
	refresh()


func refresh() -> void:
	var item_id := _current_item_id()
	_label.text = "" if item_id == "" else Inventory.item_name(item_id).left(3)
	tooltip_text = "" if item_id == "" else Inventory.item_name(item_id)


func _current_item_id() -> String:
	if equip_category != "":
		var id = Inventory.equipped.get(equip_category)
		return "" if id == null else id
	if slot_index >= 0 and Inventory.slots[slot_index] != null:
		return Inventory.slots[slot_index]["item_id"]
	return ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	var item_id := _current_item_id()
	if item_id == "":
		return null
	var preview := Label.new()
	preview.text = Inventory.item_name(item_id)
	set_drag_preview(preview)
	return {"from_slot_index": slot_index, "from_equip_category": equip_category}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("from_slot_index")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var from_index: int = data["from_slot_index"]
	var from_category: String = data["from_equip_category"]

	if from_category != "":
		# Dragging an equipped item back into the grid -- unequip it.
		if equip_category == "":
			Inventory.unequip(from_category)
		return

	if equip_category != "":
		# Dragging a grid item onto an equip slot -- equip it if it matches.
		var item_id: String = ""
		if Inventory.slots[from_index] != null:
			item_id = Inventory.slots[from_index]["item_id"]
		if item_id != "" and Inventory.ITEM_DEFS.get(item_id, {}).get("category", "") == equip_category:
			Inventory.equip_from_slot(from_index)
		return

	Inventory.move_item(from_index, slot_index)
