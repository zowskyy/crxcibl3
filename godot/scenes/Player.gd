extends CharacterBody2D
## The Enforcer (Ghost / Victor Reyes) -- Slice 2.11: first real playable
## hero, replacing the placeholder crimson square. Stats match
## configs/game_config.json's balance.hero_health/hero_damage for
## "enforcer" (120 HP, 15 dmg) -- hardcoded here rather than loaded from
## JSON at runtime, since there's no JSON-loading infrastructure yet and
## this is the only consumer so far.
##
## Reads from the virtual joystick (touch or mouse drag) when present,
## falling back to arrow keys so desktop testing in the editor still
## works without dragging it. CharacterBody2D so it actually collides
## with the boardwalk room's building/fence StaticBody2D obstacles.

const SPEED := 120.0
const MAX_HEALTH := 120
const MELEE_DAMAGE := 15

var health := MAX_HEALTH

var _joystick: Control = null


func _ready() -> void:
	add_to_group("player")
	# Deferred: Player is declared before CanvasLayer/VirtualJoystick in the
	# scene tree, so at _ready() time the joystick hasn't added itself to
	# the group yet (sibling _ready() order follows scene declaration
	# order). Deferring to the end of the frame runs this after the whole
	# tree has finished its _ready() pass.
	call_deferred("_find_joystick")


func _find_joystick() -> void:
	_joystick = get_tree().get_first_node_in_group("virtual_joystick")


func _physics_process(_delta: float) -> void:
	var input_vector := Vector2.ZERO
	if _joystick and _joystick.output.length() > 0.0:
		input_vector = _joystick.output
	else:
		input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * SPEED
	move_and_slide()


func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)


func is_dead() -> bool:
	return health <= 0
