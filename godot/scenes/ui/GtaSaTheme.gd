class_name GtaSaTheme
extends RefCounted
## GTA San Andreas HUD / menu palette and draw helpers.
## Top-right money + wanted stars; bottom-left radar, health, armor bars.
## Usage: apply_menu_chrome(), draw_hud_panel() — see CONTEXT.md visual direction.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const INK := Color(0.02, 0.05, 0.02, 1.0)
const SA_OLIVE := Color(0.22, 0.28, 0.18, 0.92)
const HUD_BG := Color(0.0, 0.0, 0.0, 0.55)
const MONEY_GREEN := Color(0.39, 0.96, 0.39, 1.0)
const HEALTH_RED := Color(0.88, 0.18, 0.12, 1.0)
const ARMOR_BLUE := Color(0.35, 0.62, 0.95, 1.0)
const WANTED_GOLD := Color(1.0, 0.86, 0.22, 1.0)
const TEXT_WHITE := Color(0.95, 0.95, 0.92, 1.0)
const TEXT_DIM := Color(0.65, 0.68, 0.62, 1.0)
const RADAR_GREEN := Color(0.12, 0.42, 0.12, 0.85)
const BORDER := Color(0.15, 0.15, 0.15, 1.0)
const FONT_SIZE := 10
const FONT_SIZE_SMALL := 8

# Legacy aliases — SlugHudTheme callers map to SA palette during migration
const TAG_GOLD := WANTED_GOLD
const SPRAY_ORANGE := Color(1.0, 0.55, 0.12, 1.0)
const NEON_TEAL := MONEY_GREEN
const MS_PANEL := HUD_BG
const ASPHALT := SA_OLIVE
const MS_BORDER_OUTER := BORDER
const MS_BORDER_INNER := Color(0.3, 0.3, 0.3, 1.0)


static func location_tag() -> String:
	return "LOS SANTOS · GROVE · SA"


static func format_money(value: int) -> String:
	return "$%d" % maxi(0, value)


static func format_score(value: int) -> String:
	return format_money(value)


static func draw_sa_panel(canvas: CanvasItem, rect: Rect2, fill: Color = HUD_BG) -> void:
	canvas.draw_rect(rect, fill)
	canvas.draw_rect(rect, BORDER, false, 1.0)


static func draw_ms_panel(canvas: CanvasItem, rect: Rect2, fill: Color = HUD_BG) -> void:
	draw_sa_panel(canvas, rect, fill)


static func draw_label(
	canvas: CanvasItem,
	pos: Vector2,
	text: String,
	color: Color = TEXT_WHITE,
	size: int = FONT_SIZE,
) -> void:
	canvas.draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func draw_wanted_stars(canvas: CanvasItem, origin: Vector2, heat: float, heat_max: float) -> void:
	var ratio := clampf(heat / maxf(1.0, heat_max), 0.0, 1.0)
	var stars := int(round(ratio * 6.0))
	draw_label(canvas, origin, "WANTED", WANTED_GOLD, FONT_SIZE_SMALL)
	var x := origin.x + 38.0
	for i in range(6):
		var filled := i < stars
		var col := WANTED_GOLD if filled else TEXT_DIM
		_draw_star(canvas, Vector2(x + float(i) * 9.0, origin.y + 5.0), 3.5, col, filled)


static func draw_wanted_pips(canvas: CanvasItem, origin: Vector2, heat: float, heat_max: float) -> void:
	draw_wanted_stars(canvas, origin, heat, heat_max)


static func draw_health_armor(
	canvas: CanvasItem,
	origin: Vector2,
	health_ratio: float,
	armor_ratio: float,
	bar_w: float = 56.0,
) -> void:
	var h_fill := bar_w * clampf(health_ratio, 0.0, 1.0)
	var a_fill := bar_w * clampf(armor_ratio, 0.0, 1.0)
	draw_label(canvas, origin, "HP", HEALTH_RED, FONT_SIZE_SMALL)
	canvas.draw_rect(Rect2(origin.x + 16.0, origin.y + 1.0, bar_w, 5.0), Color(0.1, 0.1, 0.1, 0.9))
	canvas.draw_rect(Rect2(origin.x + 16.0, origin.y + 1.0, h_fill, 5.0), HEALTH_RED)
	draw_label(canvas, Vector2(origin.x, origin.y + 9.0), "AR", ARMOR_BLUE, FONT_SIZE_SMALL)
	canvas.draw_rect(Rect2(origin.x + 16.0, origin.y + 10.0, bar_w, 5.0), Color(0.1, 0.1, 0.1, 0.9))
	canvas.draw_rect(Rect2(origin.x + 16.0, origin.y + 10.0, a_fill, 5.0), ARMOR_BLUE)


static func draw_radar(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	canvas.draw_circle(center, radius, RADAR_GREEN)
	canvas.draw_arc(center, radius, 0.0, TAU, 32, BORDER, 1.5)
	canvas.draw_line(center + Vector2(-radius * 0.6, 0), center + Vector2(radius * 0.6, 0), Color(0.2, 0.55, 0.2, 0.6), 1.0)
	canvas.draw_line(center + Vector2(0, -radius * 0.6), center + Vector2(0, radius * 0.6), Color(0.2, 0.55, 0.2, 0.6), 1.0)
	canvas.draw_circle(center, 2.0, MONEY_GREEN)


static func draw_fire_button_style(btn: Button) -> void:
	btn.text = "FIRE"
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", TEXT_WHITE)
	btn.add_theme_color_override("font_hover_color", MONEY_GREEN)
	btn.add_theme_color_override("font_pressed_color", WANTED_GOLD)


static func style_menu_button(btn: Button) -> void:
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", MONEY_GREEN)
	btn.add_theme_color_override("font_hover_color", TEXT_WHITE)
	btn.add_theme_color_override("font_pressed_color", WANTED_GOLD)


static func apply_menu_chrome(root: Control, title_label: Label = null, subtitle_label: Label = null) -> void:
	var bg := ColorRect.new()
	bg.name = "SaBG"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = INK
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	root.move_child(bg, 0)
	var wash := ColorRect.new()
	wash.name = "SaOliveWash"
	wash.set_anchors_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(SA_OLIVE.r, SA_OLIVE.g, SA_OLIVE.b, 0.35)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wash)
	root.move_child(wash, 1)
	if title_label:
		title_label.modulate = MONEY_GREEN
	if subtitle_label:
		subtitle_label.text = location_tag()
		subtitle_label.modulate = TEXT_DIM


static func draw_crew_pips(canvas: CanvasItem, origin: Vector2, crew_alive: int, crew_total: int) -> void:
	draw_label(canvas, origin, "CREW", MONEY_GREEN, FONT_SIZE_SMALL)
	var x := origin.x + 36.0
	for i in range(mini(4, crew_total)):
		var alive := i < crew_alive
		var col := MONEY_GREEN if alive else TEXT_DIM
		canvas.draw_rect(Rect2(x + float(i) * 8.0, origin.y + 2.0, 6.0, 8.0), col)


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
