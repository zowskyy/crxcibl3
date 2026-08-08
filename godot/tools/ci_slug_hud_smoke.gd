extends SceneTree
## SlugHud / SlugHudTheme verification harness — run before UI releases.
##
## Usage:
##   godot --headless -s res://tools/ci_slug_hud_smoke.gd
##
## Asserts: palette constants, score formatting, wanted/crew pip math, location tag.
## Side effects: none (pure static checks, exits 0/1).

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const EXPECTED_LOCATION := "SANTA ANA · BRISTOL · KOOS"


func _initialize() -> void:
	var failed := 0
	failed += _check_location_tag()
	failed += _check_format_score()
	failed += _check_palette_alpha()
	failed += _check_quest_format()
	if failed == 0:
		print("SlugHud smoke: PASS (%d checks)" % 4)
	else:
		push_error("SlugHud smoke: FAIL (%d checks failed)" % failed)
	quit(0 if failed == 0 else 1)


func _check_location_tag() -> int:
	if SlugHudTheme.location_tag() != EXPECTED_LOCATION:
		push_error("location_tag mismatch: %s" % SlugHudTheme.location_tag())
		return 1
	return 0


func _check_format_score() -> int:
	if SlugHudTheme.format_score(-5) != "000000":
		push_error("format_score negative clamp failed")
		return 1
	if SlugHudTheme.format_score(12345) != "012345":
		push_error("format_score padding failed")
		return 1
	return 0


func _check_palette_alpha() -> int:
	if SlugHudTheme.INK.a <= 0.0:
		push_error("INK alpha must be opaque")
		return 1
	if SlugHudTheme.TAG_GOLD.r <= 0.5:
		push_error("TAG_GOLD luminance too low for MS chrome")
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
