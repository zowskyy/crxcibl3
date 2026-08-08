extends Node
## QuestManager — Autoload singleton.
## Data-driven quest system (wow.txt spec): full lifecycle NEW -> IN_PROGRESS
## -> COMPLETED/CANCELED, with objectives and item/rune rewards. Quests are
## plain Dictionaries (registered via register_quest), matching the rest of
## the project's state style (GameState's own fields are plain Dictionaries/
## Arrays, not custom Resource classes) rather than a Resource hierarchy.
##
## Definition shape (registered once, e.g. from a level's _ready()):
##   {
##     "id": "clear_crack_house",
##     "title": "Clear the Crack House",
##     "objectives": [
##       {"id": "kill_grunts", "type": "kill", "target": "enemy", "count": 5},
##       ...
##     ],
##     "rewards": {"runes": 20, "items": ["9mm_extended_mag"]},
##   }
##
## Progress is driven by notify_event() -- gameplay systems report what just
## happened (a kill, an item pickup, a dialogue beat) without needing to
## know which quests care about it.

enum State { NEW, IN_PROGRESS, COMPLETED, CANCELED }

signal quest_started(quest_id: String)
signal quest_objective_progress(quest_id: String, objective_id: String, progress: int, count: int)
signal quest_completed(quest_id: String)
signal quest_canceled(quest_id: String)

var _definitions: Dictionary = {}  # id -> definition dict
var _states: Dictionary = {}       # id -> {"state": State, "objectives": [deep-copied, with progress/complete]}


func register_quest(definition: Dictionary) -> void:
	var id: String = definition["id"]
	if _definitions.has(id):
		return
	_definitions[id] = definition
	_states[id] = {
		"state": State.NEW,
		"objectives": [],
	}


func start_quest(id: String) -> bool:
	if not _states.has(id):
		return false
	var s: Dictionary = _states[id]
	if s["state"] != State.NEW:
		return false

	var objectives: Array = []
	for obj in _definitions[id]["objectives"]:
		var copy: Dictionary = obj.duplicate()
		copy["progress"] = 0
		copy["complete"] = false
		objectives.append(copy)

	s["state"] = State.IN_PROGRESS
	s["objectives"] = objectives
	_states[id] = s
	quest_started.emit(id)
	return true


func cancel_quest(id: String) -> void:
	if not _states.has(id):
		return
	var s: Dictionary = _states[id]
	if s["state"] != State.IN_PROGRESS:
		return
	s["state"] = State.CANCELED
	_states[id] = s
	quest_canceled.emit(id)


## Called by gameplay systems when something quest-relevant happens (a
## kill, a pickup, a delivered line) -- fans out to every IN_PROGRESS
## quest's matching objectives so callers don't need to know which quests
## care. target == "" matches any target for that event type.
func notify_event(event_type: String, target: String = "", amount: int = 1) -> void:
	for id in _states.keys():
		var s: Dictionary = _states[id]
		if s["state"] != State.IN_PROGRESS:
			continue
		var changed := false
		for obj in s["objectives"]:
			if obj["complete"]:
				continue
			if obj["type"] != event_type:
				continue
			if obj.get("target", "") != "" and obj.get("target", "") != target:
				continue
			obj["progress"] = mini(obj["progress"] + amount, obj["count"])
			changed = true
			if obj["progress"] >= obj["count"]:
				obj["complete"] = true
			quest_objective_progress.emit(id, obj["id"], obj["progress"], obj["count"])
		if changed:
			_states[id] = s
			_check_complete(id)


func _check_complete(id: String) -> void:
	var s: Dictionary = _states[id]
	for obj in s["objectives"]:
		if not obj["complete"]:
			return
	s["state"] = State.COMPLETED
	_states[id] = s
	_grant_rewards(id)
	if not GameState.quests_completed.has(id):
		GameState.quests_completed.append(id)
	RelationshipSystem.on_quest_completed()
	quest_completed.emit(id)


func _grant_rewards(id: String) -> void:
	var rewards: Dictionary = _definitions[id].get("rewards", {})
	var runes: int = rewards.get("runes", 0)
	if runes > 0:
		GameState.add_rune(runes)
	for item_id in rewards.get("items", []):
		if not Inventory.add_item(item_id):
			push_warning("QuestManager: reward item '%s' from quest '%s' lost -- inventory full" % [item_id, id])


func get_state(id: String) -> State:
	if not _states.has(id):
		return State.NEW
	return _states[id]["state"]


func get_objectives(id: String) -> Array:
	if not _states.has(id):
		return []
	return _states[id]["objectives"]


func active_quests() -> Array:
	var result: Array = []
	for id in _states.keys():
		if _states[id]["state"] == State.IN_PROGRESS:
			result.append(id)
	return result


func reset() -> void:
	_definitions.clear()
	_states.clear()
