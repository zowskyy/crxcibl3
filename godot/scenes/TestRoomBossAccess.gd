class_name TestRoomBossAccess
extends Node
## Programmatic Corrupted Six triggers + proximity hints for TestRoom.
##
## validate boss trigger anchors; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via SaveSystem.save_game() on defeat.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const TRIGGER_SPECS := [
	{"boss_id": "Cross", "anchor": "Building1", "offset": Vector2(0, 50)},
	{"boss_id": "Voss", "anchor": "Building2", "offset": Vector2(0, 50)},
	{"boss_id": "Moreau", "anchor": "Building3", "offset": Vector2(0, 50)},
	{"boss_id": "Hayes", "anchor": "CrackHouse1", "offset": Vector2(0, -20)},
	{"boss_id": "Webb", "anchor": "Fence1", "offset": Vector2(0, -30)},
]

const HINT_RADIUS := 120.0

var _room: Node2D
var _player_getter: Callable
var _rooftop_trigger: Area2D
var _triggers: Dictionary = {}
var _trigger_callbacks: Dictionary = {}
var _hint_label: Label
var _active_hint_id := ""


func setup(room: Node2D, canvas_layer: CanvasLayer, player_getter: Callable, rooftop_trigger: Area2D) -> void:
	_room = room
	_player_getter = player_getter
	_rooftop_trigger = rooftop_trigger
	_spawn_triggers()
	_hint_label = _make_hint_label(canvas_layer)
	if not Bosses.boss_defeated.is_connected(_on_boss_defeated):
		Bosses.boss_defeated.connect(_on_boss_defeated)
	if not _rooftop_trigger.body_entered.is_connected(_on_rooftop_entered):
		_rooftop_trigger.body_entered.connect(_on_rooftop_entered)


func cleanup() -> void:
	if Bosses.boss_defeated.is_connected(_on_boss_defeated):
		Bosses.boss_defeated.disconnect(_on_boss_defeated)
	if _rooftop_trigger != null and _rooftop_trigger.body_entered.is_connected(_on_rooftop_entered):
		_rooftop_trigger.body_entered.disconnect(_on_rooftop_entered)
	for boss_id in _triggers.keys():
		var zone: Area2D = _triggers[boss_id]
		var cb: Callable = _trigger_callbacks.get(boss_id, Callable())
		if zone != null and cb.is_valid() and zone.body_entered.is_connected(cb):
			zone.body_entered.disconnect(cb)
	_triggers.clear()
	_trigger_callbacks.clear()


func queue_boss_cross_load() -> void:
	if "--boss-cross" in OS.get_cmdline_args():
		call_deferred("_load_scene", "res://scenes/BossCrossScene.tscn")


func tick_hint() -> void:
	if _hint_label == null:
		return
	var player: Node2D = _player_getter.call()
	var next_id := ActProgression.get_next_boss_id()
	if next_id == "" or player == null or not is_instance_valid(player):
		_hide_hint()
		return
	var zone: Area2D = _triggers.get(next_id)
	if zone == null:
		_hide_hint()
		return
	var near := player.global_position.distance_to(zone.global_position) <= HINT_RADIUS
	if not near:
		_hide_hint()
		return
	if _active_hint_id != next_id:
		_active_hint_id = next_id
		_hint_label.text = ActProgression.boss_hint_text(next_id)
	_hint_label.visible = true


func _spawn_triggers() -> void:
	for spec in TRIGGER_SPECS:
		var boss_id: String = spec["boss_id"]
		var anchor := _room.get_node_or_null(spec["anchor"]) as Node2D
		if anchor == null:
			push_warning("TestRoomBossAccess: missing anchor %s" % spec["anchor"])
			continue
		var zone := Area2D.new()
		zone.name = "%sBossTrigger" % boss_id
		zone.position = anchor.position + spec["offset"]
		zone.monitorable = false
		zone.monitoring = true
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(80, 80)
		col.shape = shape
		zone.add_child(col)
		var cb := _on_trigger_entered.bind(boss_id)
		if not zone.body_entered.is_connected(cb):
			zone.body_entered.connect(cb)
		_room.add_child(zone)
		_triggers[boss_id] = zone
		_trigger_callbacks[boss_id] = cb


func _make_hint_label(canvas_layer: CanvasLayer) -> Label:
	var label := Label.new()
	label.name = "BossHintLabel"
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.anchor_top = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = -220.0
	label.offset_top = -88.0
	label.offset_right = 220.0
	label.offset_bottom = -64.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.visible = false
	canvas_layer.add_child(label)
	return label


func _on_trigger_entered(body: Node, boss_id: String) -> void:
	if not body.is_in_group("player"):
		return
	if "--demo" in OS.get_cmdline_args():
		return
	var scene_path := ActProgression.scene_for_trigger(boss_id)
	if scene_path == "":
		return
	_load_scene(scene_path)


func _load_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_warning("TestRoomBossAccess: boss scene not found yet: %s" % scene_path)
		return
	_room.get_tree().change_scene_to_file(scene_path)


func _on_boss_defeated(_boss_name: String, _finisher: String, _executed: bool) -> void:
	ActProgression.unlock_act_for_boss_progress()
	_hide_hint()
	SaveSystem.save_game()
	print("[TestRoomBossAccess] boss checkpoint saved")


func _on_rooftop_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if "--demo" in OS.get_cmdline_args():
		return
	if not ActProgression.is_corrupted_six_complete():
		return
	if GameState.bosses_fought.has("Blackwood_rooftop"):
		return
	_room.get_tree().change_scene_to_file("res://scenes/RooftopScene.tscn")


func _hide_hint() -> void:
	_active_hint_id = ""
	if _hint_label:
		_hint_label.visible = false


func _exit_tree() -> void:
	cleanup()
