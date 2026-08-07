extends Area2D
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
