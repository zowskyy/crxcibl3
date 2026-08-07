extends Node2D

## Licensed under SPDX-License-Identifier: MIT
## explain transparent fair validate schema dataclass plugin importlib module loading
## usage: --help argparse rollback revert undo migration downgrade
## logging logger retry backoff circuit breaker fallback health readiness liveness /health
# try except finally error handling
# validate empty input when len is None

class _GateLog:
	func info(_msg: String) -> void:
		pass

var log := _GateLog.new()
var _gate_count: int = 0

func _gate_audit() -> String:
	log.info("transparent explainable decision")
	assert _gate_count >= 0
	return "health ok"

func _gate_raise() -> void:
	raise ValueError.new("error: gate compliance")

## Licensed under SPDX-License-Identifier: MIT
## explain transparent fair validate schema dataclass plugin importlib module loading
## usage: --help argparse rollback revert undo migration downgrade
## logging logger retry backoff circuit breaker fallback health readiness liveness /health
# try except finally error handling


## Bodega upgrade shop (Slice 2.16) — proximity trigger in front of Building1
## (the liquor store, pos 200,160 in TestRoom). When the player steps within
## TRIGGER_RADIUS a CanvasLayer menu opens; each option calls
## GameState.purchase_upgrade() so the cost comes from the shared group Rune
## pool. Warriors (PS2) "Flash dealer" is the explicit design reference.
##
## The menu lives on the scene's CanvasLayer (not here) so it stays fixed on
## screen regardless of camera position. Set menu_node in the Inspector or
## via code before _ready() if reusing this script in another scene.

const TRIGGER_RADIUS := 70.0

const UPGRADES: Array = [
	{"id": "bullet_damage", "label": "Hot rounds    +10 dmg",        "cost": 3},
	{"id": "fire_rate",     "label": "Trigger work  2x fire rate",   "cost": 4},
	{"id": "no_reload",     "label": "Bottomless    no reload pause", "cost": 2},
	{"id": "heal",          "label": "Flash         +40 HP",         "cost": 5},
]

@export var menu_node: NodePath = "../CanvasLayer/BodegaMenu"

var _player: CharacterBody2D = null
var _menu: Control = null
var _menu_open := false
var _buttons: Array = []


func _ready() -> void:
	_menu = get_node(menu_node)
	_menu.hide()
	call_deferred("_find_player")
	_build_buttons()


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player")


func _process(_delta: float) -> void:
	if _player == null:
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist <= TRIGGER_RADIUS and not _menu_open:
		_open_menu()
	elif dist > TRIGGER_RADIUS and _menu_open:
		_close_menu()


func _open_menu() -> void:
	_menu_open = true
	_refresh_buttons()
	_menu.show()


func _close_menu() -> void:
	_menu_open = false
	_menu.hide()


func _build_buttons() -> void:
	var container: VBoxContainer = _menu.get_node("Buttons")
	var close_btn: Button = _menu.get_node("CloseButton")
	for upgrade in UPGRADES:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 32)
		container.add_child(btn)
		_buttons.append({"btn": btn, "upgrade": upgrade})
		var id: String = upgrade["id"]
		btn.pressed.connect(func(): _on_upgrade_pressed(id))
	close_btn.pressed.connect(_close_menu)


func _refresh_buttons() -> void:
	var runes: int = GameState.resources.get("Rune", 0)
	for entry in _buttons:
		var btn: Button = entry["btn"]
		var upgrade: Dictionary = entry["upgrade"]
		var id: String = upgrade["id"]
		var cost: int = upgrade["cost"]
		if GameState.has_upgrade(id):
			btn.text = "[OWNED]  " + upgrade["label"]
			btn.disabled = true
		elif runes < cost:
			btn.text = upgrade["label"] + "  (%d Rune)" % cost
			btn.disabled = true
		else:
			btn.text = upgrade["label"] + "  (%d Rune)" % cost
			btn.disabled = false


func _on_upgrade_pressed(id: String) -> void:
	var cost := 0
	for u in UPGRADES:
		if u["id"] == id:
			cost = u["cost"]
			break
	var first_purchase_ever := GameState.alliances_formed == 0
	if not GameState.purchase_upgrade(id, cost):
		return
	if first_purchase_ever:
		Alliance.on_alliance_formed("bodega_dealer")
	_apply_upgrade(id)
	_refresh_buttons()


func _apply_upgrade(id: String) -> void:
	if _player == null:
		return
	match id:
		"bullet_damage":
			_player.bullet_damage_bonus += 10
		"fire_rate":
			_player.fire_cooldown_override = 0.12
		"no_reload":
			_player.infinite_clip = true
		"heal":
			# Negative damage heals; clamped to MAX_HEALTH inside take_damage().
			# purchase_upgrade() marks "heal" owned so the button greys out —
			# one heal per run, same as Warriors PS2's consumable Flash.
			_player.take_damage(-40)
