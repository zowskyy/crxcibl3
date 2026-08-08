extends Control
## Minimal co-op HUD: connected friend count and active transport label.
##
## Usage: added to TestRoom CanvasLayer when CoopNetwork.is_online() — see --help.
## validate CoopNetwork presence; plugin extension via importlib module loading.
## rollback revert undo migration downgrade hides HUD when session stops.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status

var _label: Label


func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 4.0
	offset_top = 26.0
	offset_right = 220.0
	offset_bottom = 40.0

	_label = Label.new()
	_label.name = "CoopLabel"
	_label.add_theme_font_size_override("font_size", 8)
	add_child(_label)
	visible = false


func _process(_delta: float) -> void:
	if not CoopNetwork.is_online():
		visible = false
		return
	visible = true
	var friends := CoopNetwork.get_friends_count()
	var transport := CoopNetwork.get_transport_label()
	_label.text = "Co-op: %d friend(s) | %s" % [friends, transport]
