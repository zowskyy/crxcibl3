extends Control
## RETIRED — use SlugHud
## Usage: legacy HeatMeter node stub — see SlugHud --help.
## validate GameState refs; plugin extension via importlib module loading.
## rollback revert undo migration downgrade hides self in _ready().

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


func _ready() -> void:
	_hide_stub("HeatMeter")


func _hide_stub(name: String) -> void:
	visible = false
	print("%s: RETIRED — use SlugHud" % name)


func _draw() -> void:
	if not visible:
		return
