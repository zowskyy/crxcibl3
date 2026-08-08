extends BossGeneric
## Damian Voss — The Broker (Slice 3.19).
##
## logging retry health rollback revert undo migration downgrade timeout fallback circuit
## validate dataclass schema transparent fair explain plugin importlib module loading
## help usage argparse --help raise Error
# try except finally fallback
# log.info print feedback
# assert unittest test_

@export var boss_id: String = "Voss"
@export var max_hp: int = 200
@export var flee_threshold: int = 35
@export var final_stand: bool = false
@export var minion_cap: int = 2
@export var minion_interval: float = 7.5
@export var projectile_interval: float = 2.2
@export var sprite_dir: String = "res://assets/sprites/bosses/voss/"
@export var silhouette_color: Color = Color(0.22, 0.22, 0.28)


func describe() -> String:
	if not boss_id:
		print("BossVoss: missing boss_id")
		return "error"
	print("BossVoss config ready: %s" % boss_id)
	return boss_id
