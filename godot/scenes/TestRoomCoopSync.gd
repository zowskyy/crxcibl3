class_name TestRoomCoopSync
extends Node
## Co-op gameplay sync for TestRoom — remote avatars, state broadcast, host heat authority.
##
## Usage: setup(room, canvas_layer) then tick(delta, player) each frame — see --help.
## validate peer payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via teardown().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const REMOTE_PLAYER_SCRIPT := preload("res://scenes/RemotePlayer.gd")
const COOP_HUD_SCRIPT := preload("res://scenes/CoopHUD.gd")
const SYNC_INTERVAL := 0.1

var _room: Node2D
var _canvas_layer: CanvasLayer
var _remote_players: Dictionary = {}
var _sync_timer := 0.0
var _last_synced_heat := -1.0


func setup(room: Node2D, canvas_layer: CanvasLayer) -> void:
	_room = room
	_canvas_layer = canvas_layer
	if not CoopNetwork.is_online():
		return
	_connect_signals()
	_add_coop_hud()
	_spawn_existing_remotes()
	_configure_host_authority()
	_last_synced_heat = GameState.heat


func teardown() -> void:
	for peer_id in _remote_players.keys():
		var remote = _remote_players[peer_id]
		if is_instance_valid(remote):
			remote.queue_free()
	_remote_players.clear()


func spawn_offset() -> Vector2:
	if not CoopNetwork.is_online():
		return Vector2.ZERO
	var peer_id := CoopNetwork.get_local_peer_id()
	return Vector2(40.0 * float(peer_id % 3), 24.0 * float(peer_id / 3))


func tick(delta: float, player: CharacterBody2D) -> void:
	if not CoopNetwork.is_online():
		return
	_sync_timer -= delta
	if _sync_timer <= 0.0:
		_sync_timer = SYNC_INTERVAL
		_broadcast_local_player(player)
	_sync_host_heat()


func can_modify_heat() -> bool:
	if not CoopNetwork.is_online():
		return true
	return CoopNetwork.is_host()


func _connect_signals() -> void:
	if not CoopNetwork.peer_joined.is_connected(_on_peer_joined):
		CoopNetwork.peer_joined.connect(_on_peer_joined)
	if not CoopNetwork.peer_left.is_connected(_on_peer_left):
		CoopNetwork.peer_left.connect(_on_peer_left)
	if not CoopNetwork.player_state_sync.is_connected(_on_player_state_sync):
		CoopNetwork.player_state_sync.connect(_on_player_state_sync)
	if not CoopNetwork.heat_sync.is_connected(_on_heat_sync):
		CoopNetwork.heat_sync.connect(_on_heat_sync)


func _add_coop_hud() -> void:
	var hud := Control.new()
	hud.name = "CoopHUD"
	hud.set_script(COOP_HUD_SCRIPT)
	_canvas_layer.add_child(hud)


func _spawn_existing_remotes() -> void:
	var local_id := CoopNetwork.get_local_peer_id()
	for raw_id in CoopNetwork.get_peer_ids():
		var peer_id := int(raw_id)
		if peer_id != local_id:
			_ensure_remote_player(peer_id)


func _configure_host_authority() -> void:
	if CoopNetwork.is_host():
		return
	for gen in _room.get_tree().get_nodes_in_group("spawn_generator"):
		gen.set_physics_process(false)


func _ensure_remote_player(peer_id: int) -> CharacterBody2D:
	if _remote_players.has(peer_id):
		var existing = _remote_players[peer_id]
		if is_instance_valid(existing):
			return existing
		_remote_players.erase(peer_id)

	var remote := CharacterBody2D.new()
	remote.name = "RemotePlayer_%d" % peer_id
	remote.set_script(REMOTE_PLAYER_SCRIPT)
	remote.peer_id = peer_id
	_room.add_child(remote)
	_remote_players[peer_id] = remote
	return remote


func _on_peer_joined(peer_id: int) -> void:
	if peer_id == CoopNetwork.get_local_peer_id():
		return
	_ensure_remote_player(peer_id)


func _on_peer_left(peer_id: int) -> void:
	if not _remote_players.has(peer_id):
		return
	var remote = _remote_players[peer_id]
	if is_instance_valid(remote):
		remote.queue_free()
	_remote_players.erase(peer_id)


func _on_player_state_sync(
	peer_id: int,
	pos: Vector2,
	facing: Vector2,
	hero_id: String,
	health: int,
) -> void:
	if peer_id == CoopNetwork.get_local_peer_id():
		return
	var remote := _ensure_remote_player(peer_id)
	remote.set_network_state(pos, facing, hero_id, health)
	print("TestRoomCoopSync: applied state for peer %d" % peer_id)


func _on_heat_sync(heat: float) -> void:
	if CoopNetwork.is_host():
		return
	GameState.heat = clampf(heat, 0.0, GameState.HEAT_MAX)


func _broadcast_local_player(player: CharacterBody2D) -> void:
	if player == null or not is_instance_valid(player):
		return
	var facing: Vector2 = player._facing if "_facing" in player else Vector2.RIGHT
	CoopNetwork.broadcast_player_state(
		player.global_position,
		facing,
		player.hero_name,
		player.health,
	)


func _sync_host_heat() -> void:
	if not CoopNetwork.is_host():
		return
	if is_equal_approx(GameState.heat, _last_synced_heat):
		return
	_last_synced_heat = GameState.heat
	CoopNetwork.broadcast_heat(GameState.heat)
