extends Node2D
class_name BossEncounter
## BossEncounter — reusable JSON-driven boss cutscene template (Slices 3.18–3.23).
##
## Subclasses set encounter_data_path + boss_scene, then call super._ready().
## For combat-heavy scenes (Rooftop, Emperor estate) override _await_boss_outcome().

@export var encounter_data_path: String = ""
@export var boss_scene: PackedScene

var _data: Dictionary = {}
var _boss_instance: Node = null


func _ready() -> void:
	if encounter_data_path == "":
		return
	_data = EncounterData.load_encounter(encounter_data_path)
	if _data.is_empty():
		return
	_spawn_boss()
	_apply_background()
	await _play_sequence("enter_sequence")
	await _await_boss_outcome()
	await _play_sequence("defeat_sequence")
	await _play_sequence("choice_sequence")
	_transition_next()


func _spawn_boss() -> void:
	var anchor := get_node_or_null("BossAnchor")
	if anchor == null:
		anchor = self
	if boss_scene == null:
		return
	_boss_instance = boss_scene.instantiate()
	anchor.add_child(_boss_instance)
	if _boss_instance is Node2D:
		(_boss_instance as Node2D).position = Vector2.ZERO
	if anchor != self and _boss_instance is Node:
		_boss_instance.name = "BossFigure"
	CutsceneDirector.set_context(_build_context())


func _build_context() -> Dictionary:
	var ctx := {"boss": _boss_instance, "player": get_tree().get_first_node_in_group("player")}
	if _boss_instance:
		ctx["emperor"] = _boss_instance
		ctx["blackwood"] = _boss_instance
	return ctx


func _apply_background() -> void:
	var bg_path: String = str(_data.get("background", ""))
	if bg_path == "" or not ResourceLoader.exists(bg_path):
		return
	var tex: Texture2D = load(bg_path)
	if tex == null:
		return
	var sprite := get_node_or_null("Background") as Sprite2D
	if sprite:
		sprite.texture = tex


func _play_sequence(key: String) -> void:
	if not _data.has(key):
		return
	var beats: Array = EncounterData.resolve_beats(_data, _data[key])
	if beats.is_empty():
		return
	CutsceneDirector.play(str(_data.get("id", key)), beats)
	await CutsceneDirector.cutscene_ended


func _await_boss_outcome() -> void:
	if _boss_instance == null:
		return
	if _boss_instance.has_signal("defeated"):
		await _boss_instance.defeated
	elif _boss_instance.has_signal("fled"):
		await _boss_instance.fled


func _on_boss_defeated(_finisher: String = "") -> void:
	# Subclasses can call this to skip waiting on the defeated signal.
	pass


func _transition_next() -> void:
	var next: String = str(_data.get("next_scene", ""))
	if next != "":
		get_tree().change_scene_to_file(next)


func _on_heat_changed(_new_heat: float) -> void:
	# Hook for heat_wave overlay — subclasses wire GameState.heat if desired.
	pass
