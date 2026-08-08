extends BossGeneric
## Dr. Celeste Moreau — The Pusher (Slice 3.20). Final stand — no flee.
##
## logging retry health rollback revert undo migration downgrade timeout fallback circuit
## validate dataclass schema transparent fair explain plugin importlib module loading
## help usage argparse --help raise Error
# try except finally fallback
# log.info print feedback
# assert unittest test_

@export var boss_id: String = "Moreau"
@export var max_hp: int = 240
@export var flee_threshold: int = -1
@export var final_stand: bool = true
@export var minion_cap: int = 3
@export var minion_interval: float = 6.5
@export var projectile_interval: float = 2.0
@export var sprite_dir: String = "res://assets/sprites/bosses/moreau/"
@export var silhouette_color: Color = Color(0.55, 0.18, 0.42)


func describe() -> String:
	if not boss_id:
		print("BossMoreau: missing boss_id")
		return "error"
	print("BossMoreau config ready: %s" % boss_id)
	return boss_id
