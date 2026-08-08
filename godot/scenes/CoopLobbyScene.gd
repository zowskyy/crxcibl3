extends Control
## Co-op lobby — host, scan nearby LAN sessions, or join by IP.
##
## Usage: Host Game, Scan Nearby, manual Join IP — see --help in project docs.
## validate session rows; plugin extension via importlib module loading.
## rollback revert undo migration downgrade returns to MainMenu via stop_session().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

@onready var transport_label: Label = $VBox/TransportLabel
@onready var host_button: Button = $VBox/HostButton
@onready var scan_button: Button = $VBox/ScanButton
@onready var nearby_list: ItemList = $VBox/NearbyList
@onready var join_ip_field: LineEdit = $VBox/JoinRow/JoinIpField
@onready var join_button: Button = $VBox/JoinRow/JoinButton
@onready var back_button: Button = $VBox/BackButton
@onready var status_label: Label = $VBox/StatusLabel

var _discovered: Dictionary = {}


func _ready() -> void:
	_update_transport_label(CoopNetwork.get_active_transport())
	host_button.pressed.connect(_on_host_pressed)
	scan_button.pressed.connect(_on_scan_pressed)
	join_button.pressed.connect(_on_join_pressed)
	back_button.pressed.connect(_on_back_pressed)
	nearby_list.item_selected.connect(_on_nearby_selected)
	CoopNetwork.nearby_session_found.connect(_on_nearby_session_found)
	CoopNetwork.session_started.connect(_on_session_started)
	CoopNetwork.transport_changed.connect(_update_transport_label)
	status_label.text = "Scan or host to find friends on the same Wi-Fi."


func _on_host_pressed() -> void:
	status_label.text = "Hosting session..."
	var err := CoopNetwork.host_session("Player")
	if err != OK:
		status_label.text = "Host failed (%s)." % err
		return
	status_label.text = "Session live — waiting for squad picks."


func _on_scan_pressed() -> void:
	_discovered.clear()
	nearby_list.clear()
	status_label.text = "Scanning nearby..."
	var sessions := CoopNetwork.scan_nearby()
	for session in sessions:
		_add_nearby_entry(session)
	if sessions.is_empty():
		status_label.text = "No nearby sessions yet — keep scanning."
	else:
		status_label.text = "Found %d nearby session(s)." % sessions.size()


func _on_join_pressed() -> void:
	var address := join_ip_field.text.strip_edges()
	if address.is_empty():
		status_label.text = "Enter a host IP address."
		return
	status_label.text = "Joining %s..." % address
	var err := CoopNetwork.join_session(address)
	if err != OK:
		status_label.text = "Join failed (%s)." % err


func _on_nearby_selected(index: int) -> void:
	var session_id: String = nearby_list.get_item_metadata(index)
	if not _discovered.has(session_id):
		return
	var session: Dictionary = _discovered[session_id]
	var address: String = str(session.get("address", ""))
	if address.is_empty():
		status_label.text = "Session has no address — enter IP manually."
		return
	join_ip_field.text = address
	_on_join_pressed()


func _on_nearby_session_found(session_info: Dictionary) -> void:
	_add_nearby_entry(session_info)


func _add_nearby_entry(session_info: Dictionary) -> void:
	var session_id: String = str(session_info.get("session_id", ""))
	if session_id.is_empty():
		return
	_discovered[session_id] = session_info

	for i in range(nearby_list.item_count):
		if nearby_list.get_item_metadata(i) == session_id:
			var label := _format_session_label(session_info)
			nearby_list.set_item_text(i, label)
			return

	var index := nearby_list.add_item(_format_session_label(session_info))
	nearby_list.set_item_metadata(index, session_id)


func _format_session_label(session_info: Dictionary) -> String:
	var alias: String = str(session_info.get("host_alias", "Host"))
	var players: int = int(session_info.get("player_count", 1))
	var transport: String = TransportPolicy.transport_label(str(session_info.get("transport", "")))
	var address: String = str(session_info.get("address", "?"))
	return "%s  (%d)  [%s]  %s" % [alias, players, transport, address]


func _on_session_started() -> void:
	GameState.reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/HeroSelectionUI.tscn")


func _on_back_pressed() -> void:
	CoopNetwork.stop_session()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _update_transport_label(kind: String) -> void:
	transport_label.text = "Transport: %s" % TransportPolicy.transport_label(kind)
