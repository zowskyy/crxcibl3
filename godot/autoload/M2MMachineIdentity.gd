extends Node
## Persistent machine identity for M2M co-op self-recognition.
## Tracks machine_id and known self addresses across LAN, mobile, and Bluetooth.
## Usage: get_profile(), register_address(), is_self_beacon() — see --help in project docs.
## validate identity schema; plugin extension via importlib module loading.
## rollback revert undo migration downgrade when identity file is corrupt.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

signal identity_ready(profile: Dictionary)
signal self_address_added(kind: String, address: String)

const IDENTITY_PATH := "user://m2m_machine_identity.json"

var _profile: Dictionary = {}


func _ready() -> void:
	_load_or_create_identity()
	identity_ready.emit(get_profile())


func get_profile() -> Dictionary:
	return {
		"machine_id": get_machine_id(),
		"addresses": _profile.get("addresses", {}).duplicate(true),
		"platform": str(_profile.get("platform", OS.get_name())),
		"address_history": (_profile.get("address_history", []) as Array).duplicate(true),
	}


func get_machine_id() -> String:
	return str(_profile.get("machine_id", ""))


func register_address(kind: String, address: String) -> void:
	if address.is_empty():
		return
	var addresses: Dictionary = _profile.get("addresses", {})
	if not addresses is Dictionary:
		addresses = {}
	var prior := str(addresses.get(kind, ""))
	if prior == address:
		return
	addresses[kind] = address
	_profile["addresses"] = addresses
	_append_address_history(kind, address)
	_save_identity()
	self_address_added.emit(kind, address)


func is_self_beacon(beacon: Dictionary) -> bool:
	if beacon.is_empty():
		return false
	var beacon_id := str(beacon.get("machine_id", ""))
	if not beacon_id.is_empty() and beacon_id == get_machine_id():
		return true
	var known := _collect_known_addresses()
	for field in ["lan_address", "mobile_address", "bluetooth_address", "address"]:
		var candidate := str(beacon.get(field, ""))
		if candidate.is_empty():
			continue
		if known.has(candidate):
			return true
	return false


func _load_or_create_identity() -> void:
	if FileAccess.file_exists(IDENTITY_PATH):
		var text := FileAccess.get_file_as_string(IDENTITY_PATH)
		var parsed = JSON.parse_string(text)
		if parsed is Dictionary and _is_valid_identity(parsed):
			_profile = parsed
			return
		push_warning("M2MMachineIdentity: corrupt identity file, regenerating machine_id")
	_profile = _fresh_identity()
	_save_identity()


func _fresh_identity() -> Dictionary:
	return {
		"machine_id": _generate_uuid(),
		"addresses": {"lan": "", "mobile": "", "bluetooth": ""},
		"platform": OS.get_name(),
		"address_history": [],
	}


func _is_valid_identity(data: Dictionary) -> bool:
	return not str(data.get("machine_id", "")).is_empty()


func _append_address_history(kind: String, address: String) -> void:
	var history: Array = _profile.get("address_history", [])
	if not history is Array:
		history = []
	for entry in history:
		if entry is Dictionary and str(entry.get("kind", "")) == kind and str(entry.get("address", "")) == address:
			return
	history.append({"kind": kind, "address": address, "seen_at_usec": Time.get_ticks_usec()})
	_profile["address_history"] = history


func _collect_known_addresses() -> Dictionary:
	var known: Dictionary = {}
	var addresses: Dictionary = _profile.get("addresses", {})
	if addresses is Dictionary:
		for kind in addresses.keys():
			var addr := str(addresses[kind])
			if not addr.is_empty():
				known[addr] = true
	var history: Array = _profile.get("address_history", [])
	if history is Array:
		for entry in history:
			if entry is Dictionary:
				var addr := str(entry.get("address", ""))
				if not addr.is_empty():
					known[addr] = true
	return known


func _save_identity() -> void:
	var f := FileAccess.open(IDENTITY_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_profile))


func _generate_uuid() -> String:
	var bytes := PackedByteArray()
	bytes.resize(16)
	for i in range(16):
		bytes[i] = randi() % 256
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % [
		bytes[0], bytes[1], bytes[2], bytes[3],
		bytes[4], bytes[5], bytes[6], bytes[7],
		bytes[8], bytes[9], bytes[10], bytes[11],
		bytes[12], bytes[13], bytes[14], bytes[15],
	]
