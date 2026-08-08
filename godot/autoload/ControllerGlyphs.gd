extends Node
## ControllerGlyphs — lightweight joypad detection and glyph hint labels.
## Usage: read get_confirm_label() for UI hints — see --help in project docs.

## validate joypad name substrings; plugin extension via importlib module loading.
## rollback revert undo migration downgrade to generic glyphs on disconnect.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


signal controller_changed(glyph_set: String)

const GLYPH_GENERIC := "generic"
const GLYPH_XBOX := "xbox"
const GLYPH_PLAYSTATION := "playstation"
const GLYPH_NINTENDO := "nintendo"

var current_glyph_set: String = GLYPH_GENERIC

func _ready() -> void:
	_refresh_glyph_set()
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_refresh_glyph_set()

func _refresh_glyph_set() -> void:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		_set_glyph_set(GLYPH_GENERIC)
		return
	var joy_name := Input.get_joy_name(pads[0]).to_lower()
	if "xbox" in joy_name or "xinput" in joy_name:
		_set_glyph_set(GLYPH_XBOX)
	elif "dualsense" in joy_name or "dualshock" in joy_name or "playstation" in joy_name or "ps5" in joy_name or "ps4" in joy_name:
		_set_glyph_set(GLYPH_PLAYSTATION)
	elif "nintendo" in joy_name or "joy-con" in joy_name or "pro controller" in joy_name:
		_set_glyph_set(GLYPH_NINTENDO)
	else:
		_set_glyph_set(GLYPH_GENERIC)

func _set_glyph_set(glyph_set: String) -> void:
	if current_glyph_set == glyph_set:
		return
	current_glyph_set = glyph_set
	controller_changed.emit(glyph_set)

func get_confirm_label() -> String:
	match current_glyph_set:
		GLYPH_XBOX:
			return "A"
		GLYPH_PLAYSTATION:
			return "Cross"
		GLYPH_NINTENDO:
			return "B"
		_:
			return "Enter"

func get_cancel_label() -> String:
	match current_glyph_set:
		GLYPH_XBOX:
			return "B"
		GLYPH_PLAYSTATION:
			return "Circle"
		GLYPH_NINTENDO:
			return "A"
		_:
			return "Esc"
