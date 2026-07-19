extends Control
## Slice 2.10 -- real Heat meter HUD, replacing the plain debug Label from
## Slice 2.5. Polls GameState.heat every frame rather than requiring a
## manual refresh call, so it reflects changes from anywhere, not just the
## debug "Add Heat" button.

const BAR_COLOR := Color(1.0, 0.4, 0.0)        # matches the established
const BG_COLOR := Color(0.1, 0.1, 0.1, 0.85)   # heat/signOrange palette
const BORDER_COLOR := Color(0, 0, 0, 1)
const TEXT_COLOR := Color(1, 1, 1, 1)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)

	var fill_ratio: float = clampf(GameState.heat / GameState.HEAT_MAX, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * fill_ratio, size.y)), BAR_COLOR)

	draw_rect(Rect2(Vector2.ZERO, size), BORDER_COLOR, false, 2.0)

	var label := "HEAT  %d" % int(GameState.heat)
	draw_string(ThemeDB.fallback_font, Vector2(4, size.y - 4), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_COLOR)
