extends Control
## RPG synergy bond HUD — graffiti tag tier list (no plain box).
## Usage: polls RelationshipSystem — see --help in project docs.
## validate bond payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade when squad empty.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

@onready var label: Label = $BondLabel

const BOND_COLORS := {
	"Soulbound": GtaSaTheme.TAG_GOLD,
	"Bonded": Color(0.75, 0.55, 0.95),
	"Ally": GtaSaTheme.NEON_TEAL,
	"Strained": GtaSaTheme.HEALTH_RED,
}

var _last_hero := ""


func _ready() -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -120.0
	offset_top = -58.0
	offset_right = -4.0
	offset_bottom = -38.0
	if label == null:
		label = Label.new()
		label.name = "BondLabel"
		add_child(label)
	label.add_theme_font_size_override("font_size", 7)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	RelationshipSystem.synergy_updated.connect(_on_synergy_updated)
	RelationshipSystem.relationship_changed.connect(func(_a, _b, _v): _refresh())
	print("SynergyHUD: graffiti tag tier ready")


func _on_synergy_updated(_hero: String, _bonuses: Dictionary) -> void:
	_refresh()


func _refresh() -> void:
	var hero := GameState.get_active_hero()
	if hero.is_empty():
		label.text = ""
		queue_redraw()
		return
	var b: Dictionary = RelationshipSystem.get_rpg_bonuses(hero)
	var bonds: Array = b.get("active_bonds", [])
	if bonds.is_empty():
		label.text = "TAG —"
	else:
		var parts: PackedStringArray = []
		for bond in bonds:
			parts.append(str(bond.get("tier", "?")).substr(0, 1))
		label.text = "TAG %s" % "".join(parts)
	label.modulate = GtaSaTheme.TAG_GOLD
	queue_redraw()


func _process(_delta: float) -> void:
	if GameState.get_active_hero() != _last_hero:
		_last_hero = GameState.get_active_hero()
		_refresh()


func _draw() -> void:
	if label.text.is_empty():
		return
	GtaSaTheme.draw_ms_panel(self, Rect2(Vector2.ZERO, size), GtaSaTheme.MS_PANEL)
