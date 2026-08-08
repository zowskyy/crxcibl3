extends Control
## M2M-first co-op lobby — mobile IP catch + multi-transport friend discovery.

@onready var transport_label: Label = $VBox/TransportLabel
@onready var m2m_label: Label = $VBox/M2mLabel
@onready var host_button: Button = $VBox/HostButton
@onready var find_button: Button = $VBox/FindButton
@onready var scan_button: Button = $VBox/ScanButton
@onready var nearby_list: ItemList = $VBox/NearbyList
@onready var join_ip_field: LineEdit = $VBox/JoinRow/JoinIpField
@onready var join_button: Button = $VBox/JoinRow/JoinButton
@onready var back_button: Button = $VBox/BackButton
@onready var status_label: Label = $VBox/StatusLabel

var _discovered: Dictionary = {}


func _ready() -> void:
	M2MResilienceCore.start()
	host_button.pressed.connect(_on_host_pressed)
	find_button.pressed.connect(_on_find_friends_pressed)
	scan_button.pressed.connect(_on_scan_pressed)
	join_button.pressed.connect(_on_join_pressed)
	back_button.pressed.connect(_on_back_pressed)
	nearby_list.item_selected.connect(_on_nearby_selected)
	CoopNetwork.nearby_session_found.connect(_on_nearby_session_found)
	CoopNetwork.session_started.connect(_on_session_started)
	CoopNetwork.transport_changed.connect(_update_transport_label)
	CoopNetwork.m2m_mobile_ip_ready.connect(_on_mobile_ip_ready)
	M2MSession.mobile_ip_caught.connect(_on_mobile_ip_ready)
	M2MSession.m2m_sessions_updated.connect(_on_m2m_updated)
	M2MResilienceCore.self_recognized.connect(_on_self_recognized)
	M2MResilienceCore.recognition_confidence_changed.connect(_on_recognition_confidence_changed)
	status_label.text = "M2M catches your mobile IP and finds friends on Wi-Fi, Bluetooth, or cellular."
	_refresh_ip_banner()
	_refresh_machine_identity()


func _on_host_pressed() -> void:
	status_label.text = "Hosting — catching mobile IP for M2M mesh..."
	var err := CoopNetwork.host_session("Player")
	if err != OK:
		status_label.text = "Host failed (%s)." % err
		return
	status_label.text = "Session live. Share M2M codes or wait for friends to Find You."


func _on_find_friends_pressed() -> void:
	status_label.text = "M2M scan — Wi-Fi, Bluetooth, mobile IP mesh..."
	M2MSession.catch_mobile_ip()
	M2MSession.start_m2m_watch()
	var sessions := await CoopNetwork.scan_nearby()
	_refresh_list_from(sessions)
	if sessions.is_empty():
		status_label.text = "No friends yet — host on another device or enter IP below."
	else:
		status_label.text = "M2M found %d crew session(s). Tap to join." % sessions.size()


func _on_scan_pressed() -> void:
	_on_find_friends_pressed()


func _on_join_pressed() -> void:
	var address := join_ip_field.text.strip_edges()
	if address.is_empty():
		status_label.text = "Enter host LAN or mobile IP."
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
	status_label.text = "Joining via M2M %s..." % TransportPolicy.transport_label(
		str(session.get("recommended_transport", session.get("transport", "")))
	)
	var err := CoopNetwork.join_session_info(session)
	if err != OK:
		status_label.text = "Join failed (%s)." % err


func _on_nearby_session_found(session_info: Dictionary) -> void:
	_add_nearby_entry(session_info)


func _on_m2m_updated(sessions: Array) -> void:
	_refresh_list_from(sessions)


func _refresh_list_from(sessions: Array) -> void:
	for s in sessions:
		if s is Dictionary:
			_add_nearby_entry(s)


func _add_nearby_entry(session_info: Dictionary) -> void:
	var session_id: String = str(session_info.get("session_id", ""))
	if session_id.is_empty():
		return
	_discovered[session_id] = session_info
	for i in range(nearby_list.item_count):
		if nearby_list.get_item_metadata(i) == session_id:
			nearby_list.set_item_text(i, _format_session_label(session_info))
			return
	var index := nearby_list.add_item(_format_session_label(session_info))
	nearby_list.set_item_metadata(index, session_id)


func _format_session_label(session_info: Dictionary) -> String:
	var alias: String = str(session_info.get("host_alias", "Host"))
	var players: int = int(session_info.get("player_count", 1))
	var transport: String = TransportPolicy.transport_label(
		str(session_info.get("recommended_transport", session_info.get("transport", "")))
	)
	var prox: float = float(session_info.get("proximity_score", 0.0)) * 100.0
	var lan: String = str(session_info.get("lan_address", ""))
	var mobile: String = str(session_info.get("mobile_address", ""))
	var ip_hint := lan if not lan.is_empty() else mobile
	return "%s (%d)  M2M %.0f%%  [%s]  %s" % [alias, players, prox, transport, ip_hint]


func _on_session_started() -> void:
	GameState.reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/HeroSelectionUI.tscn")


func _on_back_pressed() -> void:
	CoopNetwork.stop_session()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _update_transport_label(kind: String) -> void:
	transport_label.text = "Active transport: %s" % TransportPolicy.transport_label(kind)


func _on_mobile_ip_ready(_ip: String) -> void:
	_refresh_ip_banner()


func _refresh_ip_banner() -> void:
	var ips := M2MSession.get_caught_addresses()
	var parts: PackedStringArray = []
	if not str(ips.get("lan", "")).is_empty():
		parts.append("LAN %s" % ips["lan"])
	if not str(ips.get("mobile", "")).is_empty():
		parts.append("Mobile %s" % ips["mobile"])
	if not str(ips.get("bluetooth", "")).is_empty():
		parts.append("BT %s" % ips["bluetooth"])
	var machine_line := _machine_identity_line()
	if not machine_line.is_empty():
		parts.append(machine_line)
	m2m_label.text = "M2M caught: " + (", ".join(parts) if parts.size() > 0 else "scanning...")


func _machine_identity_line() -> String:
	var machine_id := str(M2MMachineIdentity.machine_id)
	if machine_id.is_empty():
		return ""
	var short_id := machine_id.substr(0, mini(8, machine_id.length()))
	var confidence := int(round(M2MResilienceCore.get_confidence() * 100.0))
	return "ID %s %d%%" % [short_id, confidence]


func _refresh_machine_identity() -> void:
	_refresh_ip_banner()


func _on_self_recognized(_recognized: bool) -> void:
	_refresh_machine_identity()


func _on_recognition_confidence_changed(_confidence: float) -> void:
	_refresh_machine_identity()
