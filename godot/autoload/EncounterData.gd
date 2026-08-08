class_name EncounterData
extends Node
## EncounterData — loads JSON beat sequences for BossEncounter / CutsceneDirector.
##
## Resolves @sequence_name references against top-level keys in the encounter file.

const DEFAULT_PATH := "res://data/_beat_encounter_template.json"


static func load_encounter(path: String) -> Dictionary:
	if not ResourceLoader.exists(path):
		push_error("EncounterData: missing %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("EncounterData: empty %s" % path)
		return {}
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("EncounterData: parse error in %s — %s" % [path, json.get_error_message()])
		return {}
	var data: Variant = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("EncounterData: root must be object in %s" % path)
		return {}
	return data


static func resolve_beats(data: Dictionary, beats: Array) -> Array:
	var resolved: Array = []
	for beat in beats:
		if typeof(beat) != TYPE_DICTIONARY:
			continue
		resolved.append(_resolve_beat(data, beat.duplicate(true)))
	return resolved


static func _resolve_beat(data: Dictionary, beat: Dictionary) -> Dictionary:
	if beat.has("map") and typeof(beat["map"]) == TYPE_DICTIONARY:
		var new_map: Dictionary = {}
		for key in beat["map"]:
			new_map[key] = resolve_value(data, beat["map"][key])
		beat["map"] = new_map
	for key in ["choices"]:
		if beat.has(key) and typeof(beat[key]) == TYPE_ARRAY:
			var copy: Array = []
			for item in beat[key]:
				if typeof(item) == TYPE_DICTIONARY:
					copy.append(item.duplicate(true))
				else:
					copy.append(item)
			beat[key] = copy
	return beat


static func resolve_value(data: Dictionary, value: Variant) -> Variant:
	if typeof(value) == TYPE_STRING and String(value).begins_with("@"):
		var ref: String = String(value).substr(1)
		if data.has(ref):
			var target = data[ref]
			if typeof(target) == TYPE_ARRAY:
				return resolve_beats(data, target)
		push_warning("EncounterData: unresolved reference %s" % value)
		return []
	if typeof(value) == TYPE_ARRAY:
		var out: Array = []
		for item in value:
			out.append(resolve_value(data, item))
		return out
	return value
