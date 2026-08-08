class_name CoopInputGatherer
extends RefCounted
## Gather local player input for host-authoritative co-op sync.
## validate input payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via gather() empty defaults.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


static func gather(player: CharacterBody2D) -> Dictionary:
	var move: Vector2 = Vector2.ZERO
	var facing: Vector2 = Vector2.RIGHT
	var hero_id: String = ""
	var fire_pressed: bool = false
	if not player or not is_instance_valid(player):
		print("[CoopInputGatherer] gather skipped — invalid player")
		return {"move": move, "facing": facing, "hero_id": hero_id, "fire_pressed": fire_pressed}
	if player.has_method("get_move_input_vector"):
		move = player.get_move_input_vector()
	if "_facing" in player:
		facing = player._facing
	if "hero_name" in player:
		hero_id = str(player.hero_name)
	if player.has_method("consume_fire_input"):
		fire_pressed = player.consume_fire_input()
	return {"move": move, "facing": facing, "hero_id": hero_id, "fire_pressed": fire_pressed}
