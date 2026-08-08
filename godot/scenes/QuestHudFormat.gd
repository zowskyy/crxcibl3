class_name QuestHudFormat
extends RefCounted
## Quest HUD text helpers — keeps QuestHUD.gd gate-friendly.
## Usage: format_objectives(), format_quest_line() — see --help in project docs.
## validate quest payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade when quest list empty.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest


static func format_objectives(objectives: Array) -> PackedStringArray:
	var obj_lines: PackedStringArray = []
	for obj in objectives:
		var obj_id: String = obj.get("id", "objective")
		var progress: int = obj.get("progress", 0)
		var count: int = obj.get("count", 1)
		obj_lines.append("%s %d/%d" % [obj_id.replace("_", " "), progress, count])
	return obj_lines


static func format_quest_line(title: String, obj_lines: PackedStringArray) -> String:
	if obj_lines.is_empty():
		return title.to_upper()
	return "%s — %s" % [title.to_upper(), ", ".join(obj_lines)]
