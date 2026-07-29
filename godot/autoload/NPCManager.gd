extends Node
## NPCManager — Autoload singleton.
## Spatial registry for all live civilian NPCs (NPC.gd), mirroring
## EnemyRegistry's grid approach. Also the coordinator NPCs use to find
## group-conversation partners without knowing about each other directly
## (see NPC.gd CONVERSE state / Slice: NPC group conversations).

const NPC_SCRIPT := preload("res://scenes/NPC.gd")

const CELL_SIZE        := 100.0
const REFRESH_INTERVAL := 0.1

## Group conversation tuning (wow.txt "NPC Group Conversations" spec).
const GROUP_FORM_RADIUS   := 50.0
const GROUP_FORM_INTERVAL := 3.0
const GROUP_MAX_SIZE      := 3
const TURN_INTERVAL       := 2.5
const HOSTILITY_CAP_TO_JOIN := 30.0

const TOPICS := {
	"weather": ["Hot one today.", "Yeah, brutal out.", "Better than the rain, at least."],
	"heat":    ["Cops been rolling through more lately.", "Tell me about it.", "Just keep your head down."],
	"rumor":   ["Heard a crew lost territory up north.", "About time.", "Won't last, they never do."],
}

var _npcs: Array    = []   # flat list of all registered NPC nodes
var _grid: Dictionary = {} # Vector2i -> Array[Node2D]
var _refresh_timer: float = 0.0

var _groups: Dictionary = {}  # int group_id -> group state dict
var _next_group_id := 0
var _group_form_timer: float = 0.0


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = REFRESH_INTERVAL
		_rebuild()

	_group_form_timer -= delta
	if _group_form_timer <= 0.0:
		_group_form_timer = GROUP_FORM_INTERVAL
		_try_form_groups()

	_tick_groups(delta)


func register(npc: Node2D) -> void:
	if _npcs.has(npc):
		return
	_npcs.append(npc)
	npc.tree_exiting.connect(func(): _npcs.erase(npc), CONNECT_ONE_SHOT)


func query_radius(pos: Vector2, radius: float, exclude: Node2D = null) -> Array:
	var results: Array = []
	if _npcs.is_empty():
		return results

	var min_c := _cell(pos - Vector2(radius, radius))
	var max_c := _cell(pos + Vector2(radius, radius))
	var r2 := radius * radius

	for cx in range(min_c.x, max_c.x + 1):
		for cy in range(min_c.y, max_c.y + 1):
			var bucket: Array = _grid.get(Vector2i(cx, cy), [])
			for npc in bucket:
				if is_instance_valid(npc) and npc != exclude:
					if npc.global_position.distance_squared_to(pos) <= r2:
						results.append(npc)
	return results


func count() -> int:
	return _npcs.size()


func _rebuild() -> void:
	_npcs = _npcs.filter(func(n): return is_instance_valid(n))
	_grid.clear()
	for npc in _npcs:
		var c := _cell(npc.global_position)
		if not _grid.has(c):
			_grid[c] = []
		_grid[c].append(npc)


func _cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / CELL_SIZE), floori(pos.y / CELL_SIZE))


## Eligible for a fresh group: idle/wandering, calm, not already grouped,
## and not the volatile personality (a VIOLENT NPC doesn't "chat").
func _is_group_eligible(npc: Node) -> bool:
	if not is_instance_valid(npc):
		return false
	if npc.group_id != -1:
		return false
	if npc.hostility > HOSTILITY_CAP_TO_JOIN:
		return false
	if npc.personality == NPC_SCRIPT.Personality.VIOLENT:
		return false
	return npc.state in [NPC_SCRIPT.State.IDLE, NPC_SCRIPT.State.WANDER]


func _try_form_groups() -> void:
	var claimed: Array = []
	for npc in _npcs:
		if npc in claimed or not _is_group_eligible(npc):
			continue

		var nearby := query_radius(npc.global_position, GROUP_FORM_RADIUS, npc)
		var partners: Array = []
		for other in nearby:
			if other in claimed or partners.has(other):
				continue
			if _is_group_eligible(other):
				partners.append(other)
				if partners.size() >= GROUP_MAX_SIZE - 1:
					break

		if partners.is_empty():
			continue

		var members: Array = [npc] + partners
		var meeting_point := Vector2.ZERO
		for m in members:
			meeting_point += m.global_position
		meeting_point /= float(members.size())

		var topic: String = TOPICS.keys().pick_random()
		var gid := _next_group_id
		_next_group_id += 1
		_groups[gid] = {
			"members": members,
			"meeting_point": meeting_point,
			"topic": topic,
			"phase": "walking",
			"turn_index": 0,
			"turn_timer": 0.0,
		}
		for m in members:
			m.join_group(gid, meeting_point)
			claimed.append(m)


func _tick_groups(delta: float) -> void:
	var dead_groups: Array = []
	for gid in _groups.keys():
		var g: Dictionary = _groups[gid]
		g["members"] = g["members"].filter(func(m): return is_instance_valid(m) and m.group_id == gid)

		if g["members"].size() < 2:
			for m in g["members"]:
				m.leave_group()
			dead_groups.append(gid)
			continue

		if g["phase"] == "walking":
			var all_arrived := true
			for m in g["members"]:
				if not m.at_meeting_point():
					all_arrived = false
					break
			if all_arrived:
				g["phase"] = "conversing"
				g["turn_index"] = 0
				g["turn_timer"] = 0.0
				var lines: Array = TOPICS[g["topic"]]
				g["members"][0].set_group_line(lines[0])
		elif g["phase"] == "conversing":
			g["turn_timer"] += delta
			if g["turn_timer"] >= TURN_INTERVAL:
				g["turn_timer"] = 0.0
				g["turn_index"] += 1
				var lines: Array = TOPICS[g["topic"]]
				if g["turn_index"] >= lines.size() or g["turn_index"] >= g["members"].size():
					for m in g["members"]:
						m.leave_group()
					dead_groups.append(gid)
				else:
					g["members"][g["turn_index"]].set_group_line(lines[g["turn_index"]])

		_groups[gid] = g

	for gid in dead_groups:
		_groups.erase(gid)
