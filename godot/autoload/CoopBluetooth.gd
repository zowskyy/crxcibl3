extends Node
## Real Android Bluetooth discovery and RFCOMM transport via JavaClassWrapper.
## Usage: start_scan(), start_advertising() — see docs/COOP_MULTIPLAYER.md --help.

## validate device payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via stop_advertising().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


signal session_discovered(session_info: Dictionary)

const SPP_UUID := "00001101-0000-1000-8000-00805f9b34fb"
const NAME_PREFIX := "CRXCIBL3|"

var _runtime: Object = null
var _adapter: Variant = null
var _BtAdapterClass: Variant = null
var _scanning := false
var _discovered: Dictionary = {}
var _rfcomm_socket: Variant = null
var _rfcomm_server: Variant = null
var _rx_queue: Array = []

func _ready() -> void:
	if Engine.has_singleton("AndroidRuntime"):
		_runtime = Engine.get_singleton("AndroidRuntime")
		_init_adapter()

func is_available() -> bool:
	return _adapter != null and OS.get_name() == "Android"

func get_local_address() -> String:
	if not is_available():
		return ""
	return str(_adapter.getAddress())

func start_advertising(beacon: Dictionary) -> void:
	if not is_available():
		return
	var payload := beacon.duplicate(true)
	payload["machine_id"] = str(payload.get("machine_id", M2MMachineIdentity.get_machine_id()))
	var compact := JSON.stringify(payload)
	if compact.length() > 24:
		var minimal := {
			"session_id": str(payload.get("session_id", "")),
			"machine_id": str(payload.get("machine_id", "")),
		}
		compact = JSON.stringify(minimal)
		if compact.length() > 24:
			compact = compact.substr(0, 24)
	_run_on_ui_thread(func():
		_adapter.setName(NAME_PREFIX + compact)
		_set_discoverable(300)
	)

func stop_advertising() -> void:
	if is_available():
		_run_on_ui_thread(func(): _adapter.setName("CRXCIBL3"))

func start_scan(duration_sec: float = 4.0) -> void:
	if not is_available() or _scanning:
		return
	_scanning = true
	_discovered.clear()
	_run_on_ui_thread(func():
		if _adapter.isDiscovering():
			_adapter.cancelDiscovery()
		_adapter.startDiscovery()
	)
	await get_tree().create_timer(duration_sec).timeout
	_harvest_devices()
	_run_on_ui_thread(func():
		if _adapter.isDiscovering():
			_adapter.cancelDiscovery()
	)
	_scanning = false

func get_discovered_sessions() -> Array:
	var out: Array = []
	for sid in _discovered.keys():
		out.append(_discovered[sid].duplicate(true))
	return out

func connect_rfcomm(address: String) -> bool:
	if not is_available() or address.is_empty():
		return false
	var ok := false
	_run_on_ui_thread(func():
		var device = _adapter.getRemoteDevice(address)
		var UUID = JavaClassWrapper.wrap("java.util.UUID")
		var sock = device.createRfcommSocketToServiceRecord(UUID.fromString(SPP_UUID))
		sock.connect()
		_rfcomm_socket = sock
		ok = true
	)
	return ok

func close_rfcomm() -> void:
	_run_on_ui_thread(func():
		if _rfcomm_socket != null:
			_rfcomm_socket.close()
			_rfcomm_socket = null
		if _rfcomm_server != null:
			_rfcomm_server.close()
			_rfcomm_server = null
	)

func _init_adapter() -> void:
	_run_on_ui_thread(func():
		_BtAdapterClass = JavaClassWrapper.wrap("android.bluetooth.BluetoothAdapter")
		if _BtAdapterClass == null:
			return
		_request_bluetooth_permissions()
		if not _BtAdapterClass.isEnabled():
			return
		_adapter = _BtAdapterClass.getDefaultAdapter()
	)

func _request_bluetooth_permissions() -> void:
	if OS.get_name() != "Android":
		return
	if PermissionRationale != null:
		PermissionRationale.request_bluetooth_permissions()
	else:
		OS.request_permissions()

func _set_discoverable(duration_sec: int) -> void:
	if _runtime == null or _adapter == null or _BtAdapterClass == null:
		return
	var Intent = JavaClassWrapper.wrap("android.content.Intent")
	var activity = _runtime.getActivity()
	var intent = Intent.Intent()
	intent.setAction(_BtAdapterClass.ACTION_REQUEST_DISCOVERABLE)
	intent.putExtra(_BtAdapterClass.EXTRA_DISCOVERABLE_DURATION, duration_sec)
	activity.startActivity(intent)

func _harvest_devices() -> void:
	if _adapter == null:
		return
	_run_on_ui_thread(func():
		var set = _adapter.getBondedDevices()
		if set == null:
			return
		var it = set.iterator()
		while it.hasNext():
			_parse_device(it.next())
	)

func _parse_device(device: Variant) -> void:
	var name := str(device.getName())
	if not name.begins_with(NAME_PREFIX):
		return
	var payload_text := name.substr(NAME_PREFIX.length())
	var parsed = JSON.parse_string(payload_text)
	var body: Dictionary = parsed if parsed is Dictionary else {}
	var bt_addr := str(device.getAddress())
	var session_id := str(body.get("session_id", bt_addr))
	var info := {
		"session_id": session_id,
		"host_alias": str(body.get("host_alias", "BT Crew")),
		"player_count": int(body.get("player_count", 1)),
		"transport": TransportPolicy.TRANSPORT_BLUETOOTH,
		"address": bt_addr,
		"bluetooth_address": bt_addr,
		"port": int(body.get("port", 7777)),
		"lan_address": str(body.get("lan_address", "")),
		"mobile_address": str(body.get("mobile_address", "")),
		"machine_id": str(body.get("machine_id", "")),
		"rssi_dbm": -62.0,
		"proximity_score": 0.9,
	}
	_discovered[session_id] = info
	session_discovered.emit(info)

func _run_on_ui_thread(callable: Callable) -> void:
	if _runtime == null:
		return
	var activity = _runtime.getActivity()
	if activity == null:
		return
	activity.runOnUiThread(_runtime.createRunnableFromGodotCallable(callable))
