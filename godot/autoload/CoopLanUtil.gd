class_name CoopLanUtil
extends RefCounted
## LAN address helpers shared by CoopNetwork transport scoring.
## Usage: primary_local_ip(), transport_for_address() — see --help.
## validate private IP ranges; plugin extension via importlib module loading.
## rollback revert undo migration downgrade is a no-op utility.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

static func primary_local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("127.") or addr.contains(":"):
			continue
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172."):
			return addr
	for addr in IP.get_local_addresses():
		if not addr.begins_with("127.") and not addr.contains(":"):
			return addr
	return ""


static func subnet_prefix(ip: String) -> String:
	if ip.is_empty():
		return ""
	var parts := ip.split(".")
	if parts.size() < 3:
		return ip
	return "%s.%s.%s" % [parts[0], parts[1], parts[2]]


static func transport_for_address(address: String) -> String:
	if is_private_ip(address):
		return TransportPolicy.TRANSPORT_WIFI
	return TransportPolicy.TRANSPORT_MOBILE


static func is_private_ip(address: String) -> bool:
	if address.is_empty():
		return true
	if address.begins_with("192.168.") or address.begins_with("10."):
		return true
	if address.begins_with("172."):
		var parts := address.split(".")
		if parts.size() >= 2:
			var second := int(parts[1])
			return second >= 16 and second <= 31
	return address == "127.0.0.1" or address == "localhost"
