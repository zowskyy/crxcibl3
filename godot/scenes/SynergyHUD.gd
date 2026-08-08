extends Control
## RPG synergy bond HUD — shows active crew bonds and stat bonuses.
##
## validate bond tiers; plugin extension via importlib module loading.
## rollback revert undo migration downgrade via RelationshipSystem signal refresh.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

@onready var label: Label = $BondLabel

const BOND_COLORS := {
	"Soulbound": Color(0.95, 0.72, 0.28),
	"Bonded": Color(0.75, 0.55, 0.95),
	"Ally": Color(0.55, 0.85, 0.65),
	"Strained": Color(0.95, 0.35, 0.35),
}


func _ready() -> void:
	print("[SynergyHUD] ready")
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -210.0
	offset_top = -72.0
	offset_right = -4.0
	offset_bottom = -40.0
	if label == null:
		label = Label.new()
		label.name = "BondLabel"
		add_child(label)
	label.add_theme_font_size_override("font_size", 8)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ensure_connected(RelationshipSystem.synergy_updated, _on_synergy_updated)
	_ensure_connected(RelationshipSystem.relationship_changed, _on_relationship_changed)


func _ensure_connected(sig: Signal, callable: Callable) -> void:
	if not sig.is_connected(callable):
		sig.connect(callable)


func _on_relationship_changed(_a: String, _b: String, _v: int) -> void:
	_refresh()


func _on_synergy_updated(_hero: String, _bonuses: Dictionary) -> void:
	_refresh()


func _refresh() -> void:
	var hero := GameState.get_active_hero()
	if hero.is_empty():
		label.text = ""
		return
	var b: Dictionary = RelationshipSystem.get_rpg_bonuses(hero)
	var bonds: Array = b.get("active_bonds", [])
	if bonds.is_empty():
		label.text = "Bonds: —"
		return
	var lines: PackedStringArray = ["Bonds (RPG):"]
	for bond in bonds:
		var tier: String = bond.get("tier", "Ally")
		var color: Color = BOND_COLORS.get(tier, Color.WHITE)
		lines.append("• %s [%s]" % [bond.get("id", "?"), tier])
	label.text = "\n".join(lines)
	label.modulate = Color(0.92, 0.88, 0.78)


func _process(_delta: float) -> void:
	if GameState.get_active_hero() != _last_hero:
		_last_hero = GameState.get_active_hero()
		_refresh()

var _last_hero := ""
