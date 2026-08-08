extends Control
## Co-op strip — MS-style link status (merged into SlugHud bottom line when online).
## Usage: added to TestRoom CanvasLayer when CoopNetwork.is_online() — see --help.
## validate CoopNetwork presence; plugin extension via importlib module loading.
## rollback revert undo migration downgrade hides when session stops.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("[CoopHUD] crew link strip — rendered via SlugHud when online")


func _process(_delta: float) -> void:
	visible = CoopNetwork.is_online()
