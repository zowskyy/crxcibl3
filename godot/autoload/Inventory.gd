extends Node
## Inventory — Autoload singleton.
## 30-slot inventory with equipment slots and gear stat bonuses (wow.txt
## spec). Slot contents and item defs are plain Dictionaries, matching the
## rest of the project's state style. Drag-and-drop lives in InventoryUI.gd
## (a Control that calls move_item()/equip_from_slot() on drop) -- this
## autoload only owns the data.

const SLOT_COUNT := 30
const EQUIP_CATEGORIES := ["weapon", "armor", "accessory"]

## Sample item catalogue -- placeholder content until real gear design
## lands, same "wired but not yet content-authored" pattern as the other
## Phase 3 mechanics modules.
const ITEM_DEFS := {
	"9mm_extended_mag": {"name": "Extended Mag",  "category": "weapon",   "stat_bonuses": {"fire_rate": -0.05}},
	"kevlar_vest":      {"name": "Kevlar Vest",   "category": "armor",    "stat_bonuses": {"armor": 15}},
	"lucky_charm":      {"name": "Lucky Charm",   "category": "accessory","stat_bonuses": {"crit_chance": 0.05}},
	"steel_plating":    {"name": "Steel Plating", "category": "armor",    "stat_bonuses": {"armor": 30}},
}

signal inventory_changed
signal item_equipped(category: String, item_id: String)
signal item_unequipped(category: String, item_id: String)

var slots: Array = []          # SLOT_COUNT entries, each null or {"item_id": String, "quantity": int}
var equipped: Dictionary = {}  # category -> item_id or null


func _ready() -> void:
	slots.resize(SLOT_COUNT)
	for category in EQUIP_CATEGORIES:
		equipped[category] = null


## Adds an item, stacking onto an existing slot of the same id first, then
## falling back to the first empty slot. Returns false if there's no room.
func add_item(item_id: String, quantity: int = 1) -> bool:
	for i in range(SLOT_COUNT):
		var s = slots[i]
		if s != null and s["item_id"] == item_id:
			s["quantity"] += quantity
			slots[i] = s
			inventory_changed.emit()
			return true
	for i in range(SLOT_COUNT):
		if slots[i] == null:
			slots[i] = {"item_id": item_id, "quantity": quantity}
			inventory_changed.emit()
			return true
	return false


func remove_item_at(slot_index: int, quantity: int = 1) -> void:
	if slot_index < 0 or slot_index >= SLOT_COUNT or slots[slot_index] == null:
		return
	var s = slots[slot_index]
	s["quantity"] -= quantity
	if s["quantity"] <= 0:
		slots[slot_index] = null
	else:
		slots[slot_index] = s
	inventory_changed.emit()


## Moves/swaps the contents of two inventory slots (drag-and-drop target).
func move_item(from_index: int, to_index: int) -> void:
	if from_index == to_index:
		return
	if from_index < 0 or from_index >= SLOT_COUNT or to_index < 0 or to_index >= SLOT_COUNT:
		return
	var tmp = slots[to_index]
	slots[to_index] = slots[from_index]
	slots[from_index] = tmp
	inventory_changed.emit()


## Equips the item in slot_index into its gear category, swapping out
## whatever was equipped there before (returned to the same inventory slot).
func equip_from_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= SLOT_COUNT or slots[slot_index] == null:
		return false
	var item_id: String = slots[slot_index]["item_id"]
	if not ITEM_DEFS.has(item_id):
		return false
	var category: String = ITEM_DEFS[item_id]["category"]

	var previous = equipped.get(category)
	equipped[category] = item_id
	if previous != null:
		slots[slot_index] = {"item_id": previous, "quantity": 1}
	else:
		slots[slot_index] = null

	item_equipped.emit(category, item_id)
	inventory_changed.emit()
	return true


func unequip(category: String) -> bool:
	var item_id = equipped.get(category)
	if item_id == null:
		return false
	if not add_item(item_id):
		return false  # inventory full -- leave it equipped rather than lose it
	equipped[category] = null
	item_unequipped.emit(category, item_id)
	inventory_changed.emit()
	return true


## Sum of a given stat across all currently equipped gear (e.g. "armor",
## "fire_rate", "crit_chance") -- callers (Player.gd, Enemy.gd) add this to
## their base stat.
func get_stat_bonus(stat_name: String) -> float:
	var total := 0.0
	for category in EQUIP_CATEGORIES:
		var item_id = equipped.get(category)
		if item_id == null:
			continue
		var bonuses: Dictionary = ITEM_DEFS.get(item_id, {}).get("stat_bonuses", {})
		total += float(bonuses.get(stat_name, 0.0))
	return total


func item_name(item_id: String) -> String:
	return ITEM_DEFS.get(item_id, {}).get("name", item_id)


func reset() -> void:
	slots.resize(SLOT_COUNT)
	for i in range(SLOT_COUNT):
		slots[i] = null
	for category in EQUIP_CATEGORIES:
		equipped[category] = null
	inventory_changed.emit()
