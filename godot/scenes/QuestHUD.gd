extends Control
## Quest HUD — bottom-center display for active quest title and objective progress.
## Polls QuestManager via refresh(); updates on quest lifecycle signals.

const BG_COLOR := Color(0.1, 0.1, 0.1, 0.85)
const TEXT_COLOR := Color(1.0, 1.0, 1.0, 1.0)

var _label: Label = null
var _title_overrides: Dictionary = {}


func set_quest_title(quest_id: String, title: String) -> void:
	_title_overrides[quest_id] = title
	refresh()


func _ready() -> void:
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -160.0
	offset_right = 160.0
	offset_top = -44.0
	offset_bottom = -8.0

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_color_override("font_color", TEXT_COLOR)
	_label.add_theme_font_size_override("font_size", 11)
	add_child(_label)

	_ensure_connected(QuestManager.quest_started, _on_quest_started)
	_ensure_connected(QuestManager.quest_objective_progress, _on_quest_objective_progress)
	_ensure_connected(QuestManager.quest_completed, _on_quest_completed)

	refresh()


func _ensure_connected(sig: Signal, callable: Callable) -> void:
	if not sig.is_connected(callable):
		sig.connect(callable)


func _on_quest_started(_id: String) -> void:
	refresh()


func _on_quest_objective_progress(
		_id: String, _obj: String, _prog: int, _count: int) -> void:
	refresh()


func _on_quest_completed(_id: String) -> void:
	refresh()


func refresh() -> void:
	var active: Array = QuestManager.active_quests()
	if active.is_empty():
		_label.text = ""
		queue_redraw()
		return

	var quest_id: String = active[0]
	var title: String = _title_overrides.get(quest_id, quest_id.replace("_", " ").capitalize())
	var objectives: Array = QuestManager.get_objectives(quest_id)
	var obj_lines: PackedStringArray = []
	for obj in objectives:
		var obj_id: String = obj.get("id", "objective")
		var progress: int = obj.get("progress", 0)
		var count: int = obj.get("count", 1)
		obj_lines.append("%s %d/%d" % [obj_id.replace("_", " "), progress, count])

	if obj_lines.is_empty():
		_label.text = title
	else:
		_label.text = "%s — %s" % [title, ", ".join(obj_lines)]
	queue_redraw()


func _draw() -> void:
	if _label.text.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)
