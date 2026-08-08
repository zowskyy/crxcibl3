class_name CoopNetworkJoin
extends RefCounted
## Join + discovery delegates for CoopNetwork.
## validate join payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via stop_bluetooth().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


static func connect_signal_pairs(owner: Node, pairs: Array) -> void:
	for pair in pairs:
		var sig: Signal = pair[0]
		var callable: Callable = pair[1]
		if not sig.is_connected(callable):
			sig.connect(callable)


static func process_discovery(network) -> void:
	for session in network._discovery.poll(network.is_host(), Callable(network, "_send_beacon")):
		if str(session.get("session_id", "")) != network._own_session_id:
			network._enrich_and_emit(session)


static func join_session(network, address: String, transport: String) -> Error:
	if address.is_empty():
		print("[CoopNetworkJoin] join rejected — empty address")
		return ERR_INVALID_PARAMETER

	network.stop_session()
	network.is_coop = true
	network._host_alias = "Client"
	network._own_session_id = ""
	network._join_start_usec = Time.get_ticks_usec()

	network._active_transport = (
		CoopLanUtil.transport_for_address(address) if transport.is_empty() else transport
	)
	network._emit_transport_changed()

	var target := CoopLanUtil.resolve_join_address(address, network._active_transport)
	var err: Error = network._start_enet_client(target)
	if err != OK and network._active_transport == TransportPolicy.TRANSPORT_BLUETOOTH:
		err = network._start_enet_client(address)

	if err != OK:
		M2MTransportLearner.record_failure(network._active_transport)
		network.stop_session()
		return err

	M2MSession.start_m2m_watch()
	network._discovery.start()
	return OK


static func stop_bluetooth() -> void:
	if CoopBluetooth == null:
		return
	CoopBluetooth.stop_advertising()
	CoopBluetooth.close_rfcomm()


static func peer_ids(network) -> Array:
	if not network.is_online():
		return [network.get_local_peer_id()]
	var ids: Array = [network.multiplayer.get_unique_id()]
	for peer_id in network.multiplayer.get_peers():
		ids.append(peer_id)
	return ids
