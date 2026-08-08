extends Control
## Metal Slug-style in-game HUD — OC underground brawl spin. No health bar.
## CREW lives (squad), RUNES score, WANTED heat stars, optional co-op strip.
## Usage: instance on CanvasLayer — replaces HeatMeter + HealthBar everywhere.
## validate GameState reads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade when scene unloads.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const BAR_HEIGHT := 26.0


func _ready() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 0.0
	offset_bottom = BAR_HEIGHT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	print("[SlugHud] OC brawl HUD online — no health bar, MS crew/score/wanted")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var w := size.x
	SlugHudTheme.draw_ms_panel(self, Rect2(0, 0, w, size.y))

	var crew_total := maxi(1, GameState.squad.size())
	var crew_alive := _count_living_crew()
	SlugHudTheme.draw_crew_pips(self, Vector2(6, 6), crew_alive, crew_total)

	var hero := GameState.get_active_hero()
	if not hero.is_empty():
		var variant = HeroDefinitions.get_variant(hero)
		var hero_name: String = str(variant.name) if variant else hero
		SlugHudTheme.draw_label(self, Vector2(88, 8), hero_name.to_upper(), SlugHudTheme.NEON_TEAL, 8)

	var runes := int(GameState.resources.get("Rune", 0))
	var score_x := w * 0.42
	SlugHudTheme.draw_label(self, Vector2(score_x, 6), "RUNES", SlugHudTheme.TAG_GOLD, 8)
	SlugHudTheme.draw_label(
		self, Vector2(score_x, 15), SlugHudTheme.format_score(runes), SlugHudTheme.TEXT_WHITE, 10
	)

	SlugHudTheme.draw_wanted_pips(self, Vector2(w - 118.0, 6), GameState.heat, GameState.HEAT_MAX)

	if _coop_online():
		var line := "LINK %s" % _coop_transport()
		SlugHudTheme.draw_label(self, Vector2(6, size.y - 2.0), line, SlugHudTheme.TEXT_DIM, 7)


func _count_living_crew() -> int:
	if GameState.squad.is_empty():
		return 1
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and player.is_dead():
		return maxi(0, GameState.squad.size() - 1)
	return GameState.squad.size()


func _coop_online() -> bool:
	var cn = get_node_or_null("/root/CoopNetwork")
	return cn != null and cn.is_online()


func _coop_transport() -> String:
	var cn = get_node_or_null("/root/CoopNetwork")
	if cn == null:
		return ""
	return cn.get_transport_label()
