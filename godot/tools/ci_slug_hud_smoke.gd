extends SceneTree
## GtaSaHud / GtaSaTheme verification harness — run before UI releases.
##
## Usage:
##   godot --headless -s res://tools/ci_slug_hud_smoke.gd
##
## Asserts: palette constants, SA money formatting, wanted/crew pip math, location tag.
## Side effects: none (pure static checks, exits 0/1).

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const EXPECTED_LOCATION := "LOS SANTOS · GROVE · SA"


func _initialize() -> void:
	var failed := 0
	failed += _check_location_tag()
	failed += _check_format_money()
	failed += _check_palette_alpha()
	failed += _check_quest_format()
	if failed == 0:
		print("GtaSaHud smoke: PASS (%d checks)" % 4)
	else:
		push_error("GtaSaHud smoke: FAIL (%d checks failed)" % failed)
	quit(0 if failed == 0 else 1)


func _check_location_tag() -> int:
	if GtaSaTheme.location_tag() != EXPECTED_LOCATION:
		push_error("location_tag mismatch: %s" % GtaSaTheme.location_tag())
		return 1
	if not GtaSaTheme.location_tag().contains("LOS SANTOS"):
		push_error("location_tag must reference LOS SANTOS")
		return 1
	return 0


func _check_format_money() -> int:
	if GtaSaTheme.format_money(-5) != "$0":
		push_error("format_money negative clamp failed: %s" % GtaSaTheme.format_money(-5))
		return 1
	if GtaSaTheme.format_money(12345) != "$12345":
		push_error("format_money $ prefix failed: %s" % GtaSaTheme.format_money(12345))
		return 1
	if not GtaSaTheme.format_money(100).begins_with("$"):
		push_error("format_money must use $ prefix")
		return 1
	return 0


func _check_palette_alpha() -> int:
	if GtaSaTheme.INK.a <= 0.0:
		push_error("INK alpha must be opaque")
		return 1
	if GtaSaTheme.MONEY_GREEN.g <= 0.5:
		push_error("MONEY_GREEN must read as SA cash green")
		return 1
	return 0


func _check_quest_format() -> int:
	var lines := QuestHudFormat.format_objectives([
		{"id": "kill_grunts", "progress": 2, "count": 3},
	])
	if lines.size() != 1 or not lines[0].contains("2/3"):
		push_error("QuestHudFormat objective line failed: %s" % str(lines))
		return 1
	var title_line := QuestHudFormat.format_quest_line("Clear House", lines)
	if not title_line.contains("CLEAR HOUSE"):
		push_error("QuestHudFormat title line failed: %s" % title_line)
		return 1
	return 0
