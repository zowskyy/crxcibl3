extends Node2D
## Beach Boulevard environment using production art direction assets.
## Arcane palette: warm sand, ink-violet shadows, gold streetlight accents.

@export var world_size := Vector2(1100, 600)
@export var sand_texture_path := "res://assets/environment/tiles/tile_sand.jpg"
@export var water_texture_path := "res://assets/environment/tiles/tile_water.jpg"

var _sand: Texture2D
var _water: Texture2D
var _skyline: Array[Texture2D] = []


func _ready() -> void:
	_load_textures()
	_spawn_boulevard_props()
	queue_redraw()


func _spawn_boulevard_props() -> void:
	# Production art direction — clutter and distant vehicles along Beach Boulevard.
	var layout: Array = [
		["res://assets/environment/props/prop_clutter_bottles.jpg", Vector2(260, 470), 0.09],
		["res://assets/environment/props/prop_clutter_trashbags.jpg", Vector2(720, 500), 0.1],
		["res://assets/environment/vehicles/vehicle_police_cruiser.jpg", Vector2(140, 380), 0.07],
		["res://assets/environment/vehicles/vehicle_rival_crew.jpg", Vector2(980, 390), 0.075],
	]
	for entry in layout:
		var path: String = entry[0]
		if not ResourceLoader.exists(path):
			continue
		var spr := Sprite2D.new()
		spr.texture = load(path)
		spr.position = entry[1]
		var scale: float = entry[2]
		spr.scale = Vector2(scale, scale)
		spr.modulate = Color(0.82, 0.74, 0.62, 0.88)
		spr.z_index = -5
		add_child(spr)


func _load_textures() -> void:
	if ResourceLoader.exists(sand_texture_path):
		_sand = load(sand_texture_path)
	if ResourceLoader.exists(water_texture_path):
		_water = load(water_texture_path)
	for path in [
		"res://assets/environment/buildings/building_cross_tower.jpg",
		"res://assets/environment/buildings/building_voss_compound.jpg",
		"res://assets/environment/buildings/building_emperor_estate.jpg",
	]:
		if ResourceLoader.exists(path):
			_skyline.append(load(path))


func _draw() -> void:
	var w := world_size.x
	var h := world_size.y

	# Ocean strip — twilight Arcane gradient over water tile.
	draw_rect(Rect2(0, 0, w, h * 0.22), Color(0.06, 0.05, 0.14))
	if _water:
		var tw := _water.get_width()
		var th := _water.get_height()
		var y_end := h * 0.22
		var x := 0.0
		while x < w:
			draw_texture_rect(_water, Rect2(x, 0, tw, y_end), false, Color(0.55, 0.65, 0.85, 0.55))
			x += tw

	# Boardwalk sand — tiled production sand art.
	if _sand:
		var tw := _sand.get_width()
		var th := _sand.get_height()
		var y := h * 0.18
		while y < h:
			var x := 0.0
			while x < w:
				draw_texture_rect(_sand, Rect2(x, y, tw, th), false, Color(0.92, 0.82, 0.62, 0.95))
				x += tw
			y += th
	else:
		draw_rect(Rect2(0, h * 0.18, w, h * 0.82), Color(0.28, 0.22, 0.16))

	# Distant skyline silhouettes — Arcane ink-wash depth.
	var sx := 40.0
	for i in range(_skyline.size()):
		var tex := _skyline[i]
		if tex == null:
			continue
		var scale := 0.14 + float(i) * 0.02
		var bw := tex.get_width() * scale
		var bh := tex.get_height() * scale
		var by := h * 0.12 - bh * 0.15
		draw_texture_rect(tex, Rect2(sx, by, bw, bh), false, Color(0.12, 0.08, 0.18, 0.45))
		sx += bw * 0.85

	# Warm boulevard streetlight pools.
	for lx in [180.0, 520.0, 860.0]:
		draw_circle(Vector2(lx, h * 0.72), 38.0, Color(0.95, 0.62, 0.18, 0.07))
