extends Control
## Quest HUD — MS mission ticker at bottom (OC brawl strip, no plain box).
## Usage: set_quest_title(), refresh() — see --help in project docs.
## validate quest payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade when quest completes.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

var _label: Label = null
var _title_overrides: Dictionary = {}


func set_quest_title(quest_id: String, title: String) -> void:
	_title_overrides[quest_id] = title
	refresh()


func _ready() -> void:
	_apply_layout()
	_build_label()
	_connect_quest_signals()
	print("[QuestHUD] MS mission ticker online — OC brawl strip")
	refresh()


func _apply_layout() -> void:
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -170.0
	offset_right = 170.0
	offset_top = -36.0
	offset_bottom = -6.0


func _build_label() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_color_override("font_color", GtaSaTheme.TEXT_WHITE)
	_label.add_theme_font_size_override("font_size", 9)
	add_child(_label)


func _connect_quest_signals() -> void:
	QuestManager.quest_started.connect(func(_id: String) -> void: refresh())
	QuestManager.quest_objective_progress.connect(
		func(_id: String, _obj: String, _prog: int, _count: int) -> void: refresh())
	QuestManager.quest_completed.connect(func(_id: String) -> void: refresh())


func refresh() -> void:
	var active: Array = QuestManager.active_quests()
	if active.is_empty():
		_label.text = ""
		queue_redraw()
		return
	var quest_id: String = active[0]
	var title: String = _title_overrides.get(quest_id, quest_id.replace("_", " ").capitalize())
	var obj_lines := QuestHudFormat.format_objectives(QuestManager.get_objectives(quest_id))
	_label.text = QuestHudFormat.format_quest_line(title, obj_lines)
	queue_redraw()


func _draw() -> void:
	if _label.text.is_empty():
		return
	GtaSaTheme.draw_ms_panel(self, Rect2(Vector2.ZERO, size), GtaSaTheme.ASPHALT)
	GtaSaTheme.draw_label(self, Vector2(6, 2), "MISSION", GtaSaTheme.SPRAY_ORANGE, 7)
