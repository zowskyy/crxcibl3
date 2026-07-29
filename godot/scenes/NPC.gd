extends CharacterBody2D
## Civilian NPC — full personality FSM, distinct from the rival-crew
## chase AI in Enemy.gd. Wow.txt spec: IDLE/WANDER/FLEE/CONVERSE/CONFRONT/
## ENGAGE/SCRIPTED states, one of four personalities assigned at spawn,
## each with its own dialogue pool, escalation speed, and combat behavior.
## NPCs remember past interactions with the player across state changes.

const SPEED          := 40.0
const SIZE           := 14.0
const WANDER_RADIUS  := 60.0
const TALK_RADIUS    := 28.0
const FLEE_RADIUS    := 70.0
const MAX_HEALTH     := 20

enum Personality { FRIENDLY, NEUTRAL, RUDE, VIOLENT }
enum State { IDLE, WANDER, FLEE, CONVERSE, CONFRONT, ENGAGE, SCRIPTED }

## Per-personality tuning: how fast hostility escalates (lower = twitchier)
## and whether they fight back at all when attacked.
const PERSONALITY_DATA := {
	Personality.FRIENDLY: {"escalation": 0.5, "fights_back": false, "flee_first": true},
	Personality.NEUTRAL:  {"escalation": 1.0, "fights_back": false, "flee_first": true},
	Personality.RUDE:     {"escalation": 1.6, "fights_back": true,  "flee_first": false},
	Personality.VIOLENT:  {"escalation": 2.5, "fights_back": true,  "flee_first": false},
}

const DIALOGUE_POOLS := {
	Personality.FRIENDLY: ["Hey, watch yourself out there.", "Nice day, huh?", "You need something?"],
	Personality.NEUTRAL:  ["...", "Don't have time for this.", "What do you want."],
	Personality.RUDE:     ["Get outta my way.", "You lookin' at me?", "Beat it."],
	Personality.VIOLENT:  ["You picked the wrong street.", "Come on then.", "I'll gut you."],
}

var personality: Personality = Personality.NEUTRAL
var state: State = State.IDLE
var health := MAX_HEALTH

## Memory of interactions with the player. Persists across state changes
## for this NPC's lifetime (not saved across sessions — a per-encounter
## record, not a save-file record).
var hostility: float = 0.0        # 0..100, raised by hostile player actions
var times_confronted: int = 0
var times_attacked: int = 0
var last_dialogue: String = ""

var _home_position: Vector2
var _wander_target: Vector2
var _state_timer := 0.0
var _player: CharacterBody2D = null
var _dying := false
var _scripted_line: Array = []  # optional forced dialogue for SCRIPTED state

## Group conversation (NPCManager-coordinated). group_id == -1 means not
## currently in a group. NPCs don't talk to each other directly -- the
## manager assigns a meeting point and calls set_group_line() on whoever's
## turn it is.
var group_id: int = -1
var _group_meeting_point: Vector2


func _ready() -> void:
	add_to_group("npc")
	NPCManager.register(self)
	_home_position = global_position
	personality = PERSONALITY_DATA.keys().pick_random()
	call_deferred("_find_player")
	_enter_state(State.IDLE)


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")


## Force this NPC into a pre-written scripted beat (cutscene use) --
## it will hold SCRIPTED until release_script() is called.
func run_script(lines: Array) -> void:
	_scripted_line = lines
	_enter_state(State.SCRIPTED)


func release_script() -> void:
	if state == State.SCRIPTED:
		_enter_state(State.IDLE)


func _physics_process(delta: float) -> void:
	if _dying:
		return
	if _player == null:
		_find_player()
		return

	_state_timer += delta
	var to_player := _player.global_position - global_position
	var distance := to_player.length()

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if _state_timer > randf_range(1.5, 3.5):
				_enter_state(State.WANDER)
		State.WANDER:
			if group_id != -1:
				_tick_group_walk(delta)
			else:
				_tick_wander(delta)
				if _state_timer > randf_range(2.0, 4.0):
					_enter_state(State.IDLE)
		State.FLEE:
			_tick_flee(delta, to_player, distance)
		State.CONVERSE:
			velocity = Vector2.ZERO
			if group_id == -1 and distance > TALK_RADIUS * 1.5:
				_enter_state(State.IDLE)
		State.CONFRONT:
			velocity = Vector2.ZERO
			_face(to_player)
		State.ENGAGE:
			_tick_engage(delta, to_player, distance)
		State.SCRIPTED:
			velocity = Vector2.ZERO

	# Passive proximity checks: a violent/rude NPC left alone can still
	# notice the player and escalate on its own if hostility is already high.
	if state in [State.IDLE, State.WANDER] and distance <= FLEE_RADIUS and hostility > 60.0:
		_react_to_player(distance)

	move_and_slide()


func _tick_wander(delta: float) -> void:
	if _wander_target == Vector2.ZERO or global_position.distance_to(_wander_target) < 4.0:
		_wander_target = _home_position + Vector2(
			randf_range(-WANDER_RADIUS, WANDER_RADIUS),
			randf_range(-WANDER_RADIUS, WANDER_RADIUS)
		)
	var dir := (_wander_target - global_position).normalized()
	velocity = dir * SPEED * 0.5


func _tick_group_walk(_delta: float) -> void:
	var to_point := _group_meeting_point - global_position
	if to_point.length() < 6.0:
		velocity = Vector2.ZERO
	else:
		velocity = to_point.normalized() * SPEED * 0.6


## Called by NPCManager when it forms a small group. This NPC will walk to
## meeting_point; NPCManager takes over turn assignment once everyone's
## arrived (see at_meeting_point()).
func join_group(id: int, meeting_point: Vector2) -> void:
	group_id = id
	_group_meeting_point = meeting_point
	_enter_state(State.WANDER)


## Called by NPCManager (group disbanded, or this member snapped out due
## to hostility) -- returns the NPC to ordinary idle behavior.
func leave_group() -> void:
	if group_id == -1:
		return
	group_id = -1
	if state in [State.WANDER, State.CONVERSE]:
		_enter_state(State.IDLE)


func at_meeting_point() -> bool:
	return group_id != -1 and global_position.distance_to(_group_meeting_point) < 6.0


## Called by NPCManager on this member's turn during a group conversation.
func set_group_line(line: String) -> void:
	last_dialogue = line
	if state != State.CONVERSE:
		_enter_state(State.CONVERSE)


func _tick_flee(_delta: float, to_player: Vector2, distance: float) -> void:
	if distance > FLEE_RADIUS * 2.0:
		_enter_state(State.IDLE)
		velocity = Vector2.ZERO
		return
	var away := (-to_player).normalized()
	velocity = away * SPEED


func _tick_engage(_delta: float, to_player: Vector2, distance: float) -> void:
	if distance > FLEE_RADIUS:
		_enter_state(State.IDLE)
		velocity = Vector2.ZERO
		return
	if distance <= TALK_RADIUS:
		velocity = Vector2.ZERO
		_try_attack()
	else:
		velocity = to_player.normalized() * SPEED


func _try_attack() -> void:
	if _player and _player.has_method("take_damage"):
		_player.take_damage(4)


func _face(to_player: Vector2) -> void:
	if to_player.length() > 0.01:
		rotation = to_player.angle()


## Called by the player interact action (e.g. TestRoom interact key) when
## in range -- starts a CONVERSE beat and returns the line said.
func interact() -> String:
	if state in [State.FLEE, State.ENGAGE, State.SCRIPTED]:
		return ""
	if group_id != -1:
		leave_group()  # a direct player conversation takes priority over the group beat
	_enter_state(State.CONVERSE)
	last_dialogue = DIALOGUE_POOLS[personality].pick_random()
	return last_dialogue


## Called when the player commits a hostile action against this NPC
## (shoves, draws a weapon nearby, or attacks). Escalates according to
## personality and remembered hostility.
func on_player_hostile_action(distance: float) -> void:
	var data: Dictionary = PERSONALITY_DATA[personality]
	hostility = clampf(hostility + 20.0 * float(data["escalation"]), 0.0, 100.0)
	times_confronted += 1
	_react_to_player(distance)


func _react_to_player(distance: float) -> void:
	var data: Dictionary = PERSONALITY_DATA[personality]
	if bool(data["flee_first"]) and hostility < 80.0:
		_enter_state(State.FLEE)
	elif hostility >= 70.0 and bool(data["fights_back"]):
		_enter_state(State.ENGAGE)
	else:
		_enter_state(State.CONFRONT)


func take_damage(amount: int, _killer: String = "") -> void:
	if _dying:
		return
	times_attacked += 1
	hostility = 100.0
	health = maxi(0, health - amount)
	if health <= 0:
		_dying = true
		set_physics_process(false)
		if state == State.ENGAGE:
			Stress.exit_combat()
		queue_free()
		return

	var data: Dictionary = PERSONALITY_DATA[personality]
	if bool(data["fights_back"]):
		_enter_state(State.ENGAGE)
	else:
		_enter_state(State.FLEE)


func _enter_state(new_state: State) -> void:
	# A hostile turn snaps this member out of any group conversation --
	# "hostile NPCs can snap mid-conversation and walk away" (wow.txt spec).
	# NPCManager notices via group_id going to -1 and prunes its roster.
	if group_id != -1 and new_state in [State.FLEE, State.CONFRONT, State.ENGAGE]:
		group_id = -1

	# Stress._in_combat is a single shared flag, not a ref-count (see
	# Stress.gd) -- enter/exit calls must be paired 1:1 per source, same
	# as Enemy.gd's own _in_combat toggle, or the meter gets stuck.
	var was_engaged := state == State.ENGAGE
	var now_engaged := new_state == State.ENGAGE
	if now_engaged and not was_engaged:
		Stress.enter_combat()
	elif was_engaged and not now_engaged:
		Stress.exit_combat()

	state = new_state
	_state_timer = 0.0


func _draw() -> void:
	var color := Color(0.3, 0.5, 0.3)
	match personality:
		Personality.FRIENDLY: color = Color(0.3, 0.55, 0.35)
		Personality.NEUTRAL:  color = Color(0.45, 0.45, 0.45)
		Personality.RUDE:     color = Color(0.55, 0.4, 0.2)
		Personality.VIOLENT:  color = Color(0.55, 0.2, 0.2)
	draw_rect(Rect2(-SIZE / 2, -SIZE / 2, SIZE, SIZE), color)
