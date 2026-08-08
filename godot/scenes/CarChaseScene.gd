extends "res://scenes/GetawayScene.gd"
## Car chase getaway — shared GetawayScene mechanic on Beach Boulevard.

func _ready() -> void:
	chase_duration = 45.0
	scroll_speed = 160.0
	heat_on_complete = 25.0
	interstitial_text = "HE'S HEADED FOR THE HILLS..."
	exit_scene_path = "res://scenes/EmperorScene.tscn"
	getaway_label_prefix = "EVADE"
	super._ready()
