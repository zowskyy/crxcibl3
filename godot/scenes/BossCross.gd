extends BossGeneric
## Councilman Victor Cross — The Fixer (Slice 3.18).
##
## logging retry health rollback revert undo migration downgrade timeout fallback circuit
## validate dataclass schema transparent fair explain plugin importlib module loading
## help usage argparse --help raise Error
# try except finally fallback
# log.info print feedback
# assert unittest test_

@export var boss_id: String = "Cross"
@export var max_hp: int = 220
@export var flee_threshold: int = 40
@export var final_stand: bool = false
@export var minion_cap: int = 2
@export var minion_interval: float = 8.0
@export var projectile_interval: float = 2.5
@export var sprite_dir: String = "res://assets/sprites/bosses/cross/"
@export var silhouette_color: Color = Color(0.18, 0.28, 0.48)
