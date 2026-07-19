extends Control
## Slice 2.13 -- debug meter for Stress, same idiom as HeatMeter.gd
## (Slice 2.10). Without some visible readout there'd be no way to
## actually confirm the Stress hooks wired into Enemy.gd/Player.gd/
## TestRoom.gd are doing anything at runtime.

const BAR_COLOR := Color(0.55, 0.25, 0.85)     # distinct from Heat's orange --
const BG_COLOR := Color(0.1, 0.1, 0.1, 0.85)   # purple reads as "nerves", not heat
const BORDER_COLOR := Color(0, 0, 0, 1)
const TEXT_COLOR := Color(1, 1, 1, 1)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)

	var fill_ratio: float = clampf(Stress.stress / Stress.STRESS_MAX, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * fill_ratio, size.y)), BAR_COLOR)

	draw_rect(Rect2(Vector2.ZERO, size), BORDER_COLOR, false, 2.0)

	var label := "STRESS  %d / %d" % [int(Stress.stress), int(Stress.STRESS_MAX)]
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(8, size.y - 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, TEXT_COLOR)
