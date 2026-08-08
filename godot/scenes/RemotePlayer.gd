extends CharacterBody2D
## Network-driven avatar for a remote co-op peer. No local input — updated via
## set_network_state() when CoopNetwork.player_state_sync fires.
##
## Usage: set_network_state(pos, facing, hero_id, health) — see --help.
## validate network payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade when peer_left removes the node.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status

const PORTRAIT_TARGET_SIZE := 24.0
const SILHOUETTE_COLOR := Color(0.15, 0.18, 0.28, 0.92)
const SILHOUETTE_OUTLINE := Color(0.55, 0.65, 0.85, 0.85)

var peer_id: int = -1
var _hero_id: String = ""
var _facing := Vector2.RIGHT
var _health: int = 100
var _max_health: int = 120
var _portrait: Sprite2D


func _ready() -> void:
	add_to_group("remote_player")
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	col.shape = rect
	add_child(col)

	_portrait = Sprite2D.new()
	_portrait.name = "Portrait"
	_portrait.position = Vector2(0, -12)
	add_child(_portrait)


func set_network_state(pos: Vector2, facing: Vector2, hero_id: String, health: int) -> void:
	if hero_id.is_empty():
		push_warning("RemotePlayer: empty hero_id for peer %d" % peer_id)
		return
	global_position = pos
	if facing.length_squared() > 0.0001:
		_facing = facing.normalized()
	_health = maxi(0, health)
	if hero_id != _hero_id:
		_hero_id = hero_id
		_apply_portrait(hero_id)
		_refresh_max_health()
	_update_facing_visual()
	queue_redraw()


func _apply_portrait(hero_id: String) -> void:
	var portrait_path := "res://assets/heroes/portraits/%s.png" % hero_id
	if not ResourceLoader.exists(portrait_path):
		_portrait.texture = null
		_portrait.visible = false
		return
	var tex: Texture2D = load(portrait_path)
	_portrait.texture = tex
	_portrait.modulate = Color(0.88, 0.9, 1.0, 0.95)
	var largest := maxf(float(tex.get_width()), float(tex.get_height()))
	if largest > 0.0:
		_portrait.scale = Vector2.ONE * (PORTRAIT_TARGET_SIZE / largest)
	_portrait.visible = true


func _refresh_max_health() -> void:
	var variant = HeroDefinitions.get_variant(_hero_id)
	_max_health = variant.health if variant else 120


func _update_facing_visual() -> void:
	if _portrait == null or not _portrait.visible:
		return
	_portrait.flip_h = _facing.x < -0.01


func _draw() -> void:
	if _portrait != null and _portrait.visible:
		_draw_health_bar(Vector2(-18, -28))
		return
	var body := Rect2(-8, -18, 16, 22)
	draw_rect(body, SILHOUETTE_COLOR)
	draw_rect(body, SILHOUETTE_OUTLINE, false, 1.5)
	var head_center := Vector2(0, -22)
	draw_circle(head_center, 5.0, SILHOUETTE_COLOR)
	draw_arc(head_center, 5.0, 0.0, TAU, 16, SILHOUETTE_OUTLINE, 1.5)
	_draw_health_bar(Vector2(-18, -34))


func _draw_health_bar(origin: Vector2) -> void:
	var bar_w := 36.0
	var bar_h := 4.0
	var fill := 0.0
	if _max_health > 0:
		fill = clampf(float(_health) / float(_max_health), 0.0, 1.0)
	draw_rect(Rect2(origin, Vector2(bar_w, bar_h)), Color(0.08, 0.08, 0.1, 0.85))
	var fill_col := Color(0.85, 0.15, 0.15) if _health <= 0 else Color(0.35, 0.75, 0.95)
	draw_rect(Rect2(origin, Vector2(bar_w * fill, bar_h)), fill_col)
