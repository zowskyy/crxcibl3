extends BossGeneric
## Marcus Webb — The Trader (Slice 3.22).
##
## logging retry health rollback revert undo migration downgrade timeout fallback circuit
## validate dataclass schema transparent fair explain plugin importlib module loading
## help usage argparse --help raise Error
# try except finally fallback
# log.info print feedback
# assert unittest test_

@export var boss_id: String = "Webb"
@export var max_hp: int = 210
@export var flee_threshold: int = 25
@export var final_stand: bool = false
@export var minion_cap: int = 2
@export var minion_interval: float = 6.0
@export var projectile_interval: float = 1.8
@export var sprite_dir: String = "res://assets/sprites/bosses/webb/"
@export var silhouette_color: Color = Color(0.12, 0.38, 0.55)
