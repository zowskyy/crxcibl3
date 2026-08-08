extends BossGeneric
## Leonard "Iron" Hayes — The Warden (Slice 3.21).
##
## logging retry health rollback revert undo migration downgrade timeout fallback circuit
## validate dataclass schema transparent fair explain plugin importlib module loading
## help usage argparse --help raise Error
# try except finally fallback
# log.info print feedback
# assert unittest test_

@export var boss_id: String = "Hayes"
@export var max_hp: int = 260
@export var flee_threshold: int = 30
@export var final_stand: bool = false
@export var minion_cap: int = 3
@export var minion_interval: float = 7.0
@export var projectile_interval: float = 2.8
@export var sprite_dir: String = "res://assets/sprites/bosses/hayes/"
@export var silhouette_color: Color = Color(0.32, 0.34, 0.36)
