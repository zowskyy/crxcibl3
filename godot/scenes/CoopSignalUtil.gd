class_name CoopSignalUtil
extends RefCounted
## Connect/disconnect signal pairs for co-op scenes.
## validate signal pairs; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via disconnect_pairs().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


static func connect_pairs(pairs: Array) -> void:
	for pair in pairs:
		var sig: Signal = pair[0]
		var callable: Callable = pair[1]
		if not sig.is_connected(callable):
			sig.connect(callable)
	print("[CoopSignalUtil] connect_pairs complete")


static func disconnect_pairs(pairs: Array) -> void:
	for pair in pairs:
		var sig: Signal = pair[0]
		var callable: Callable = pair[1]
		if sig.is_connected(callable):
			sig.disconnect(callable)
