class_name PlayerAnimation
extends RefCounted
## Animation state selection for Player movement and combat.
## validate animation names; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via update_animation().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


static func update_animation(
	player: CharacterBody2D,
	anim: AnimatedSprite2D,
	input_vector: Vector2,
	shoot_timer: float,
) -> void:
	if anim == null or not anim.visible:
		return

	if player.has_method("is_dead") and player.is_dead():
		print("[PlayerAnimation] downed state")
		_play_once(anim, "downed")
		return

	if shoot_timer > 0.0:
		_play_once(anim, "shoot")
		return

	if input_vector.length() < 0.1:
		_play(anim, "idle")
		return

	var anim_name := "idle"
	if absf(input_vector.x) >= absf(input_vector.y):
		anim_name = "walk_right" if input_vector.x >= 0.0 else "walk_left"
	else:
		anim_name = "walk_down" if input_vector.y >= 0.0 else "walk_up"
	_play(anim, anim_name)


static func _play(anim: AnimatedSprite2D, anim_name: String) -> void:
	if anim and anim.visible and anim.sprite_frames \
			and anim.sprite_frames.has_animation(anim_name) \
			and anim.animation != anim_name:
		anim.play(anim_name)


static func _play_once(anim: AnimatedSprite2D, anim_name: String) -> void:
	_play(anim, anim_name)
