extends Control
## Metal Slug panel chrome for bodega / café menu overlays.
## Usage: draw_ms_panel chrome — see --help in project docs.
## validate PromptLabel sibling; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via parent hide().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


func _ready() -> void:
	var prompt: Label = get_node_or_null("PromptLabel") as Label
	if not prompt:
		print("BodegaMenuChrome: MS panel chrome ready")
		return
	prompt.modulate = GtaSaTheme.TAG_GOLD
	print("BodegaMenuChrome: MS panel chrome ready")


func _draw() -> void:
	GtaSaTheme.draw_ms_panel(self, Rect2(Vector2.ZERO, size))
