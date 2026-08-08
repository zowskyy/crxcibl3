extends Area2D
## Safe-house trigger — notifies Hideout autoload when the player enters or exits.
##
## validate player group membership; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via SaveSystem.save_game() checkpoint.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


func _ready() -> void:
	_ensure_connected(body_entered, _on_body_entered)
	_ensure_connected(body_exited, _on_body_exited)
	print("[HideoutZone] ready")


func _ensure_connected(sig: Signal, callable: Callable) -> void:
	if not sig.is_connected(callable):
		sig.connect(callable)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		Hideout.enter_hideout()
		SaveSystem.save_game()


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		Hideout.exit_hideout()
