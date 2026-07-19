extends Control
## Slice 3.1 — player health bar, same self-drawing idiom as HeatMeter/StressMeter.
## Finds the player via group lookup (deferred, same race-condition fix as
## VirtualJoystick) so it works in any scene that has a "player" group member.
## Polls every frame — reflects damage from any source with no manual refresh.

const BAR_COLOR     := Color(0.2, 0.85, 0.3)    # green — distinct from Heat orange / Stress purple
const DOWNED_COLOR  := Color(0.85, 0.1, 0.1)    # red when at 0 HP
const BG_COLOR      := Color(0.1, 0.1, 0.1, 0.85)
const BORDER_COLOR  := Color(0.0, 0.0, 0.0, 1.0)
const TEXT_COLOR    := Color(1.0, 1.0, 1.0, 1.0)

var _player = null


func _ready() -> void:
	call_deferred("_find_player")


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)

	if _player == null or not is_instance_valid(_player):
		return

	var fill := clampf(float(_player.health) / float(_player.MAX_HEALTH), 0.0, 1.0)
	var bar_col := DOWNED_COLOR if _player.is_dead() else BAR_COLOR
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * fill, size.y)), bar_col)
	draw_rect(Rect2(Vector2.ZERO, size), BORDER_COLOR, false, 2.0)

	var label := "DOWNED..." if _player.is_dead() \
		else "HP  %d" % _player.health
	draw_string(ThemeDB.fallback_font, Vector2(4, size.y - 4), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_COLOR)
