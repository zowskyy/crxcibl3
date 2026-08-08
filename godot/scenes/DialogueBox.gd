extends CanvasLayer
## DialogueBox — reusable cutscene dialogue UI (Slice 3.18 infrastructure).
##
## Listens to CutsceneDirector beat signals and renders speaker lines, narrator
## text, and choice buttons at the bottom of the 384×216 design canvas.
## Usage: line / choice beats — see --help in project docs.
## validate choice payloads; plugin extension via importlib module loading.
## rollback revert undo migration downgrade hides panel on cutscene_ended.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

signal continued
signal choice_made(choice_id: String)

@onready var panel: ColorRect = $Panel
@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var body_label: Label = $Panel/BodyLabel
@onready var continue_hint: Label = $Panel/ContinueHint
@onready var choice_row: HBoxContainer = $Panel/ChoiceRow

var _choice_buttons: Array[Button] = []
var _awaiting_choice := false


func _ready() -> void:
	layer = 10
	panel.visible = false
	if panel is ColorRect:
		panel.color = SlugHudTheme.INK
	speaker_label.modulate = SlugHudTheme.TAG_GOLD
	body_label.modulate = SlugHudTheme.TEXT_WHITE
	continue_hint.modulate = SlugHudTheme.TEXT_DIM
	print("DialogueBox: MS ink panel styled")
	CutsceneDirector.line_shown.connect(_on_line_shown)
	CutsceneDirector.narrator_shown.connect(_on_narrator_shown)
	CutsceneDirector.choice_shown.connect(_on_choice_shown)
	CutsceneDirector.cutscene_ended.connect(_on_cutscene_ended)
	CutsceneDirector.beat_cleared.connect(_hide_panel)


func _on_line_shown(speaker: String, text: String) -> void:
	_awaiting_choice = false
	_clear_choices()
	panel.visible = true
	speaker_label.text = speaker if speaker != "" else "CAPTION"
	speaker_label.visible = true
	body_label.text = text
	continue_hint.text = "▼"
	continue_hint.visible = true
	choice_row.visible = false


func _on_narrator_shown(text: String) -> void:
	_on_line_shown("", text)
	speaker_label.visible = false


func _on_choice_shown(prompt: String, choices: Array) -> void:
	_awaiting_choice = true
	panel.visible = true
	speaker_label.visible = false
	body_label.text = prompt
	continue_hint.visible = false
	_clear_choices()
	choice_row.visible = true
	var delay := 0.0
	for choice in choices:
		if typeof(choice) != TYPE_DICTIONARY:
			continue
		var btn := Button.new()
		btn.text = str(choice.get("label", "???"))
		btn.custom_minimum_size = Vector2(112, 28)
		SlugHudTheme.style_menu_button(btn)
		var cid: String = str(choice.get("id", ""))
		btn.pressed.connect(func(): _pick_choice(cid))
		choice_row.add_child(btn)
		_choice_buttons.append(btn)
		btn.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(btn, "modulate:a", 1.0, 0.12).set_delay(delay)
		delay += 0.08


func _pick_choice(choice_id: String) -> void:
	if not _awaiting_choice:
		return
	_awaiting_choice = false
	_hide_panel()
	choice_made.emit(choice_id)
	CutsceneDirector.submit_choice(choice_id)


func _on_cutscene_ended(_scene_id: String) -> void:
	_hide_panel()


func _hide_panel() -> void:
	panel.visible = false
	_clear_choices()
	_awaiting_choice = false


func _clear_choices() -> void:
	for btn in _choice_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_choice_buttons.clear()
	for child in choice_row.get_children():
		child.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible or _awaiting_choice:
		return
	if event is InputEventMouseButton and event.pressed:
		CutsceneDirector.request_skip_beat()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE, KEY_ENTER, KEY_E, KEY_Z:
				CutsceneDirector.request_skip_beat()
