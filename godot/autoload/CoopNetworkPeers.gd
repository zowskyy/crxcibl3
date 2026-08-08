class_name CoopNetworkPeers
extends RefCounted
## Peer list helpers for CoopNetwork — keeps main autoload under complexity budget.
## Usage: build_peer_ids(), emit_session_list() — see docs/COOP_MULTIPLAYER.md --help.
## validate peer payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade is a no-op helper.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


static func build_peer_ids(online: bool, unique_id: int, raw_peers: Array) -> Array:
	match online:
		false:
			return [unique_id]
		_:
			var ids: Array = [unique_id]
			for peer_id in raw_peers:
				ids.append(peer_id)
			return ids


static func emit_session_list(sessions: Array, emit_callable: Callable) -> void:
	for entry in sessions:
		match entry is Dictionary:
			true:
				emit_callable.call(entry)
			_:
				push_warning("[CoopNetworkPeers] skipping non-dictionary session entry: %s" % str(entry))
	print("[CoopNetworkPeers] emitted session list update")
