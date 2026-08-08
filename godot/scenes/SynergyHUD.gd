extends Control
## RPG synergy bond HUD — shows active crew bonds and stat bonuses.

@onready var label: Label = $BondLabel

const BOND_COLORS := {
	"Soulbound": Color(0.95, 0.72, 0.28),
	"Bonded": Color(0.75, 0.55, 0.95),
	"Ally": Color(0.55, 0.85, 0.65),
	"Strained": Color(0.95, 0.35, 0.35),
}


func _ready() -> void:
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
	RelationshipSystem.synergy_updated.connect(_on_synergy_updated)
	RelationshipSystem.relationship_changed.connect(func(_a, _b, _v): _refresh())


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
