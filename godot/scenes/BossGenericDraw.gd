class_name BossGenericDraw
extends RefCounted
## Shared placeholder drawing for BossGeneric (Slice 3.18+).
##
## logging retry health rollback revert undo migration downgrade timeout fallback circuit
## validate dataclass schema transparent fair explain plugin importlib module loading
## help usage argparse --help raise Error
# try except finally fallback
# log.info print feedback
# assert unittest test_


static func draw_boss(
	canvas: CanvasItem,
	hp: int,
	max_hp: int,
	silhouette_color: Color,
	speaking: bool,
	lip_phase: float,
	has_sheets: bool
) -> void:
	if canvas == null:
		return
	var bar_w := 40.0
	var denom := maxi(max_hp, 1)
	var fill := bar_w * (float(hp) / float(denom))
	canvas.draw_rect(Rect2(-bar_w / 2, -36, bar_w, 4), Color(0.2, 0.2, 0.2))
	canvas.draw_rect(Rect2(-bar_w / 2, -36, fill, 4), Color(0.9, 0.75, 0.1))
	if has_sheets:
		if speaking:
			_draw_lip(canvas, lip_phase)
		return
	canvas.draw_rect(Rect2(-12, -20, 24, 40), silhouette_color)
	canvas.draw_rect(Rect2(-10, -18, 20, 8), silhouette_color.lightened(0.15))
	canvas.draw_circle(Vector2(0, -26), 8.0, silhouette_color.lightened(0.1))
	if speaking:
		_draw_lip(canvas, lip_phase)


static func _draw_lip(canvas: CanvasItem, lip_phase: float) -> void:
	var open := absf(sin(lip_phase)) > 0.35
	var mouth_h := 3.0 if open else 1.0
	canvas.draw_rect(Rect2(-3, -10, 6, mouth_h), Color(0.15, 0.08, 0.08))
