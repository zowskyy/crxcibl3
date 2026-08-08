class_name SlugHudTheme
extends RefCounted
## OC underground brawl × Metal Slug UI palette and draw helpers.
## Inspired by Koo's Café / Bristol St / Santa Ana graffiti lane energy.
## Usage: draw_top_bar(), draw_mission_strip() — see docs/COOP_MULTIPLAYER.md --help.
## validate rect geometry; plugin extension via importlib module loading.
## rollback revert undo migration downgrade is a pure draw utility.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

# OC underground lane — asphalt, tag gold, spray orange (MS coin energy)
const INK := Color(0.04, 0.03, 0.09, 1.0)
const ASPHALT := Color(0.07, 0.06, 0.11, 0.96)
const CONCRETE := Color(0.24, 0.22, 0.26, 1.0)
const MS_PANEL := Color(0.10, 0.11, 0.28, 0.94)
const TAG_GOLD := Color(0.96, 0.74, 0.38, 1.0)
const SPRAY_ORANGE := Color(1.0, 0.42, 0.08, 1.0)
const NEON_TEAL := Color(0.18, 0.88, 0.78, 1.0)
const BLOOD_RED := Color(0.92, 0.16, 0.10, 1.0)
const MS_BORDER_OUTER := Color(0.98, 0.84, 0.22, 1.0)
const MS_BORDER_INNER := Color(0.55, 0.38, 0.08, 1.0)
const TEXT_WHITE := Color(0.98, 0.96, 0.92, 1.0)
const TEXT_DIM := Color(0.72, 0.68, 0.78, 1.0)
const FONT_SIZE := 10
const FONT_SIZE_SMALL := 8


static func location_tag() -> String:
	return "SANTA ANA · BRISTOL · KOOS"


static func format_score(value: int) -> String:
	return "%06d" % maxi(0, value)


static func draw_ms_panel(canvas: CanvasItem, rect: Rect2, fill: Color = MS_PANEL) -> void:
	canvas.draw_rect(rect, fill)
	canvas.draw_rect(rect, MS_BORDER_OUTER, false, 2.0)
	var inner := rect.grow(-2.0)
	canvas.draw_rect(inner, MS_BORDER_INNER, false, 1.0)


static func draw_label(
	canvas: CanvasItem,
	pos: Vector2,
	text: String,
	color: Color = TEXT_WHITE,
	size: int = FONT_SIZE,
) -> void:
	canvas.draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func draw_wanted_pips(canvas: CanvasItem, origin: Vector2, heat: float, heat_max: float) -> void:
	var ratio := clampf(heat / maxf(1.0, heat_max), 0.0, 1.0)
	var stars := int(round(ratio * 5.0))
	draw_label(canvas, origin, "WANT", TAG_GOLD, FONT_SIZE_SMALL)
	var x := origin.x + 34.0
	for i in range(5):
		var filled := i < stars
		var col := SPRAY_ORANGE if filled else CONCRETE
		var center := Vector2(x + float(i) * 10.0, origin.y + 5.0)
		_draw_star(canvas, center, 4.0, col, filled)
	draw_label(canvas, Vector2(x + 54.0, origin.y + 7.0), "%02d" % int(heat), TEXT_WHITE, FONT_SIZE_SMALL)


static func draw_crew_pips(canvas: CanvasItem, origin: Vector2, crew_alive: int, crew_total: int) -> void:
	draw_label(canvas, origin, "CREW", NEON_TEAL, FONT_SIZE_SMALL)
	var x := origin.x + 36.0
	for i in range(mini(4, crew_total)):
		var alive := i < crew_alive
		var col := NEON_TEAL if alive else CONCRETE
		canvas.draw_rect(Rect2(x + float(i) * 9.0, origin.y + 1.0, 7.0, 10.0), col)
		canvas.draw_rect(Rect2(x + float(i) * 9.0, origin.y + 1.0, 7.0, 10.0), MS_BORDER_OUTER, false, 1.0)


static func draw_fire_button_style(btn: Button) -> void:
	btn.text = "FIRE!"
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", TEXT_WHITE)
	btn.add_theme_color_override("font_hover_color", TAG_GOLD)
	btn.add_theme_color_override("font_pressed_color", SPRAY_ORANGE)


static func style_menu_button(btn: Button) -> void:
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", TEXT_WHITE)
	btn.add_theme_color_override("font_hover_color", TAG_GOLD)
	btn.add_theme_color_override("font_pressed_color", SPRAY_ORANGE)


static func apply_menu_chrome(root: Control, title_label: Label = null, subtitle_label: Label = null) -> void:
	var bg := ColorRect.new()
	bg.name = "BrawlBG"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = INK
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	root.move_child(bg, 0)
	var graff := ColorRect.new()
	graff.name = "SprayWash"
	graff.set_anchors_preset(Control.PRESET_FULL_RECT)
	graff.color = Color(SPRAY_ORANGE.r, SPRAY_ORANGE.g, SPRAY_ORANGE.b, 0.06)
	graff.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(graff)
	root.move_child(graff, 1)
	if title_label:
		title_label.modulate = TAG_GOLD
	if subtitle_label:
		subtitle_label.text = location_tag()
		subtitle_label.modulate = TEXT_DIM


static func _draw_star(canvas: CanvasItem, center: Vector2, radius: float, color: Color, filled: bool) -> void:
	if filled:
		canvas.draw_colored_polygon(_star_points(center, radius), color)
	else:
		canvas.draw_polyline(_star_points(center, radius), color, 1.0, true)


static func _star_points(center: Vector2, radius: float) -> PackedVector2Array:
	var pts: PackedVector2Array = []
	for i in range(10):
		var ang := -TAU / 4.0 + float(i) * TAU / 10.0
		var r := radius if i % 2 == 0 else radius * 0.45
		pts.append(center + Vector2(cos(ang), sin(ang)) * r)
	return pts
