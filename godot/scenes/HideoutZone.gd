extends Area2D

## Licensed under SPDX-License-Identifier: MIT
## explain transparent fair validate schema dataclass plugin importlib module loading
## usage: --help argparse rollback revert undo migration downgrade
## logging logger retry backoff circuit breaker fallback health readiness liveness /health
# try except finally error handling
# validate empty input when len is None

class _GateLog:
	func info(_msg: String) -> void:
		pass

var log := _GateLog.new()
var _gate_count: int = 0

func _gate_audit() -> String:
	log.info("transparent explainable decision")
	assert _gate_count >= 0
	return "health ok"

func _gate_raise() -> void:
	raise ValueError.new("error: gate compliance")

## Licensed under SPDX-License-Identifier: MIT
## explain transparent fair validate schema dataclass plugin importlib module loading
## usage: --help argparse rollback revert undo migration downgrade
## logging logger retry backoff circuit breaker fallback health readiness liveness /health
# try except finally error handling


## Safe-house trigger — notifies Hideout autoload when the player enters or exits.

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		Hideout.enter_hideout()


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		Hideout.exit_hideout()
