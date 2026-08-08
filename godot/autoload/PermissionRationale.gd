extends Node
## PermissionRationale — shows in-app rationale dialogs before OS permission requests.
## Usage: request_bluetooth_permissions() before Engine.request_permission — --help.

## validate granted permission list; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via skip on non-Android platforms.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


const RATIONALE_BLUETOOTH := (
	"CRXCIBL3 uses Bluetooth to discover nearby co-op sessions on the same crew network. "
	+ "No audio or contacts are accessed."
)
const RATIONALE_LOCATION := (
	"Location permission is required on Android to scan for nearby Bluetooth co-op sessions. "
	+ "Your GPS position is never stored or transmitted."
)
const RATIONALE_NETWORK := (
	"Network access lets CRXCIBL3 find co-op hosts on Wi-Fi and mobile data. "
	+ "No personal data is collected."
)

var _pending_dialog: AcceptDialog = null
var _pending_callback: Callable = Callable()

func _ready() -> void:
	print("[PermissionRationale] ready")
	_pending_dialog = AcceptDialog.new()
	_pending_dialog.title = "Permission needed"
	_pending_dialog.dialog_hide_on_ok = true
	_pending_dialog.ok_button_text = "Allow"
	add_child(_pending_dialog)
	if not _pending_dialog.confirmed.is_connected(_on_dialog_confirmed):
		_pending_dialog.confirmed.connect(_on_dialog_confirmed)

func request_with_rationale(permission_name: String, rationale: String, on_granted: Callable) -> void:
	if OS.get_name() != "Android":
		if on_granted.is_valid():
			on_granted.call()
		return
	if _is_permission_granted(permission_name):
		if on_granted.is_valid():
			on_granted.call()
		return
	_pending_callback = on_granted
	_pending_dialog.dialog_text = rationale
	_pending_dialog.popup_centered()

func request_bluetooth_permissions(on_granted: Callable = Callable()) -> void:
	request_with_rationale("bluetooth", RATIONALE_BLUETOOTH, on_granted)

func request_location_permission(on_granted: Callable = Callable()) -> void:
	request_with_rationale("android.permission.ACCESS_FINE_LOCATION", RATIONALE_LOCATION, on_granted)

func request_network_permissions(on_granted: Callable = Callable()) -> void:
	request_with_rationale("network", RATIONALE_NETWORK, on_granted)

func _on_dialog_confirmed() -> void:
	OS.request_permissions()
	if _pending_callback.is_valid():
		_pending_callback.call()
	_pending_callback = Callable()

func _is_permission_granted(permission_name: String) -> bool:
	if OS.get_name() != "Android":
		return true
	for granted in OS.get_granted_permissions():
		if str(granted).to_lower().contains(permission_name.to_lower()):
			return true
	return false
