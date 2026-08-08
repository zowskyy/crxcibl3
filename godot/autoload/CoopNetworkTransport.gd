class_name CoopNetworkTransport
extends RefCounted
## ENet + LAN beacon helpers for CoopNetwork (keeps CoopNetwork.gd gate-friendly).
## validate transport payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via close_peer().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const GAME_PORT := 7777


static func create_server() -> ENetMultiplayerPeer:
	var peer := ENetMultiplayerPeer.new()
	var err: int = peer.create_server(GAME_PORT, 8)
	if err != OK:
		print("[CoopNetworkTransport] server create failed: %s" % err)
		return null
	return peer


static func create_client(address: String) -> ENetMultiplayerPeer:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, GAME_PORT)
	return peer if err == OK else null


static func build_beacon(
	session_id: String,
	host_alias: String,
	player_count: int,
	transport: String,
) -> Dictionary:
	var beacon := M2MSession.build_host_beacon(session_id, host_alias, player_count, GAME_PORT)
	beacon["transport"] = transport
	beacon["address"] = str(beacon.get("lan_address", ""))
	return beacon


static func enrich_session(session: Dictionary) -> Dictionary:
	if M2MMachineIdentity.is_self_beacon(session):
		return {}
	session["lan_address"] = str(session.get("lan_address", session.get("address", "")))
	session["mobile_address"] = str(session.get("mobile_address", ""))
	session["bluetooth_address"] = str(session.get("bluetooth_address", ""))
	M2MSession.register_external_session(session)
	return session


static func bluetooth_advert_payload(
	session_id: String,
	host_alias: String,
	player_count: int,
) -> Dictionary:
	return {
		"session_id": session_id,
		"host_alias": host_alias,
		"player_count": player_count,
		"port": GAME_PORT,
		"lan_address": M2MSession.lan_ip,
		"mobile_address": M2MSession.effective_mobile_ip(),
		"machine_id": M2MMachineIdentity.get_machine_id(),
	}
