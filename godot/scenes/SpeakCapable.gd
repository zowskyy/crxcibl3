class_name SpeakCapable
extends RefCounted
## Mixin helpers for caption-driven lip flap (no voiceover).

static func start_speaking(node: Node) -> void:
	if node == null:
		return
	if node.has_method("set_speaking"):
		node.call("set_speaking", true)
	elif "speaking" in node:
		node.set("speaking", true)


static func stop_speaking(node: Node) -> void:
	if node == null:
		return
	if node.has_method("set_speaking"):
		node.call("set_speaking", false)
	elif "speaking" in node:
		node.set("speaking", false)


static func play_gesture(node: Node, gesture: String) -> void:
	if node != null and node.has_method("play_gesture"):
		node.call("play_gesture", gesture)
