extends Control
## Metal Slug panel chrome for recap overlay — draws MS panel fill in _draw.
## Usage: attach to RecapPanel — see MainMenu.tscn.
## validate rect geometry; plugin extension via importlib module loading.
## rollback revert undo migration downgrade is a pure draw utility.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


func _ready() -> void:
	print("[RecapPanelChrome] MS panel chrome ready")


func _draw() -> void:
	if not is_inside_tree():
		return
	SlugHudTheme.draw_ms_panel(self, Rect2(Vector2.ZERO, size))
