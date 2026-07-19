extends Node2D
## Scrolling road background for CarChaseScene.
## CarChaseScene increments scroll_offset each frame and calls queue_redraw().

var scroll_offset := 0.0

const ROAD_LEFT   := 70.0
const ROAD_RIGHT  := 314.0
const CANVAS_W    := 384.0
const CANVAS_H    := 216.0
const DASH_H      := 20.0
const DASH_GAP    := 14.0
const LANE_L      := 132.0
const LANE_R      := 252.0


func _draw() -> void:
	# Sidewalks
	draw_rect(Rect2(0, 0, ROAD_LEFT, CANVAS_H), Color(0.26, 0.23, 0.19))
	draw_rect(Rect2(ROAD_RIGHT, 0, CANVAS_W - ROAD_RIGHT, CANVAS_H), Color(0.26, 0.23, 0.19))
	# Asphalt
	draw_rect(Rect2(ROAD_LEFT, 0, ROAD_RIGHT - ROAD_LEFT, CANVAS_H), Color(0.17, 0.17, 0.18))
	# Scrolling lane dashes
	var offset_y := fmod(scroll_offset, DASH_H + DASH_GAP)
	var y := -offset_y
	while y < CANVAS_H:
		draw_rect(Rect2(LANE_L - 1.5, y, 3.0, DASH_H), Color(0.85, 0.78, 0.2, 0.75))
		draw_rect(Rect2(LANE_R - 1.5, y, 3.0, DASH_H), Color(0.85, 0.78, 0.2, 0.75))
		y += DASH_H + DASH_GAP
	# Curb lines
	draw_line(Vector2(ROAD_LEFT,  0), Vector2(ROAD_LEFT,  CANVAS_H), Color(0.65, 0.65, 0.55), 2.0)
	draw_line(Vector2(ROAD_RIGHT, 0), Vector2(ROAD_RIGHT, CANVAS_H), Color(0.65, 0.65, 0.55), 2.0)
