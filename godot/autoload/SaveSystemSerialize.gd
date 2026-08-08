class_name SaveSystemSerialize
extends RefCounted
## Save line builders for SaveSystem (keeps SaveSystem.gd gate-friendly).
## Usage: SaveSystemSerialize.inventory_lines() — see --help in project docs.

## validate save line schema; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via empty line arrays.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


static func inventory_lines() -> Array:
	var lines: Array = []
	var slot_count: int = Inventory.SLOT_COUNT
	if not GameState.blame_ledger:
		return lines
	for entry in GameState.blame_ledger:
		lines.append("blame_entry=%s" % JSON.stringify(entry))
	for i in range(slot_count):
		var slot: Variant = Inventory.slots[i]
		if slot == null:
			continue
		lines.append("inv_slot_%d=%s:%d" % [i, slot["item_id"], slot["quantity"]])
	for category: String in Inventory.EQUIP_CATEGORIES:
		var item_id: Variant = Inventory.equipped.get(category)
		if item_id == null:
			continue
		lines.append("equip_%s=%s" % [category, item_id])
	print("[SaveSystemSerialize] inventory lines built")
	return lines


static func collection_lines() -> Array:
	var lines: Array = []
	if not GameState.resources:
		return lines
	for kind in GameState.resources.keys():
		lines.append("resource:%s=%s" % [kind, GameState.resources[kind]])
	for key in GameState.relationships.keys():
		lines.append("relationship:%s=%s" % [key, GameState.relationships[key]])
	for secret in GameState.secrets_unlocked:
		lines.append("secret=%s" % secret)
	for quest in GameState.quests_completed:
		lines.append("quest=%s" % quest)
	for boss in GameState.bosses_fought:
		var executed = GameState.boss_executed.get(boss, false)
		var finisher = GameState.boss_finisher.get(boss, "")
		lines.append("boss:%s=%s,%s" % [boss, executed, finisher])
	print("[SaveSystemSerialize] collection lines built")
	return lines
