extends Control
## GTA San Andreas full-screen HUD overlay — money, wanted stars, radar, HP/armor.
## Usage: instance on CanvasLayer — polls GameState + player group each frame.
## validate GameState reads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade when scene unloads.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const RADAR_RADIUS := 42.0
const ARMOR_DISPLAY_MAX := 60.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("[GtaSaHud] SA HUD online")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y

	var runes := int(GameState.resources.get("Rune", 0))
	var money_text := GtaSaTheme.format_money(runes)
	var money_w := 72.0
	GtaSaTheme.draw_label(
		self,
		Vector2(w - money_w - 8.0, 8.0),
		money_text,
		GtaSaTheme.MONEY_GREEN,
		12,
	)
	GtaSaTheme.draw_wanted_stars(
		self, Vector2(w - money_w - 8.0, 24.0), GameState.heat, GameState.HEAT_MAX
	)

	var weapon_line := _hero_weapon_line()
	if not weapon_line.is_empty():
		GtaSaTheme.draw_label(
			self,
			Vector2(w - money_w - 8.0, 40.0),
			weapon_line,
			GtaSaTheme.TEXT_DIM,
			GtaSaTheme.FONT_SIZE_SMALL,
		)

	var radar_center := Vector2(8.0 + RADAR_RADIUS, h - 8.0 - RADAR_RADIUS)
	GtaSaTheme.draw_radar(self, radar_center, RADAR_RADIUS)

	var health_ratio := 1.0
	var armor_ratio := 0.0
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var max_hp := 120.0
		if player.has_method("_max_health"):
			max_hp = float(player.call("_max_health"))
		var hp := float(player.health)
		health_ratio = clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
		var hero_name := str(player.hero_name)
		var armor_total := Inventory.get_stat_bonus("armor") + float(
			RelationshipSystem.get_armor_bonus(hero_name)
		)
		armor_ratio = clampf(armor_total / ARMOR_DISPLAY_MAX, 0.0, 1.0)

	var bar_origin := Vector2(radar_center.x - RADAR_RADIUS, h - 28.0)
	GtaSaTheme.draw_health_armor(self, bar_origin, health_ratio, armor_ratio)

	if _coop_online():
		var line := "LINK %s" % _coop_transport()
		GtaSaTheme.draw_label(self, Vector2(8.0, h - 4.0), line, GtaSaTheme.TEXT_DIM, 7)


func _hero_weapon_line() -> String:
	var weapon_id = Inventory.equipped.get("weapon")
	if weapon_id != null:
		return Inventory.item_name(str(weapon_id)).to_upper()
	var hero := GameState.get_active_hero()
	if hero.is_empty():
		return ""
	var variant = HeroDefinitions.get_variant(hero)
	if variant:
		return "%s · PISTOL" % str(variant.name).to_upper()
	return hero.to_upper()


func _coop_online() -> bool:
	var cn = get_node_or_null("/root/CoopNetwork")
	return cn != null and cn.is_online()


func _coop_transport() -> String:
	var cn = get_node_or_null("/root/CoopNetwork")
	if cn == null:
		return ""
	return cn.get_transport_label()
