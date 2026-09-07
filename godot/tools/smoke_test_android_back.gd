extends SceneTree
## Headless smoke test: Android hardware back-press must route to
## AndroidPlatform's predictive-back handler instead of auto-quitting.
##
## Regression guard: Godot 4.x defaults application/config/quit_on_go_back
## to true, which makes the engine quit on NOTIFICATION_WM_GO_BACK_REQUEST
## before any node (including AndroidPlatform's own, correctly-written
## handler) ever sees it. project.godot must override this to false, or the
## back button "crashes" (quits) the app regardless of in-scene handling.
##
## Usage: godot --headless --path godot -s res://tools/smoke_test_android_back.gd

const HERO_SELECTION_SCENE := "res://scenes/HeroSelectionUI.tscn"
const MAIN_MENU_PATH := "res://scenes/MainMenu.tscn"


func _initialize() -> void:
	var ok := true

	var quit_on_go_back = ProjectSettings.get_setting("application/config/quit_on_go_back", true)
	if quit_on_go_back != false:
		push_error(
			("application/config/quit_on_go_back is %s, expected false — the engine will "
			+ "auto-quit on Android back-press before AndroidPlatform's handler ever runs")
			% quit_on_go_back
		)
		ok = false

	if not root.has_node("AndroidPlatform"):
		push_error("AndroidPlatform autoload missing — cannot smoke test back handling")
		quit(1)
		return
	var android_platform: Node = root.get_node("AndroidPlatform")
	if not android_platform.has_method("_handle_predictive_back"):
		push_error("AndroidPlatform lost its _handle_predictive_back() method")
		ok = false

	var packed: PackedScene = load(HERO_SELECTION_SCENE)
	var ui := packed.instantiate()
	root.add_child(ui)
	current_scene = ui
	await create_timer(0.1).timeout

	if not ui.has_method("handle_android_back"):
		push_error("HeroSelectionUI lost its handle_android_back() method")
		ok = false
	else:
		android_platform._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		await create_timer(0.2).timeout
		var scene_after := current_scene
		if scene_after == null or scene_after.scene_file_path != MAIN_MENU_PATH:
			push_error(
				"Back-press did not navigate to MainMenu (current scene: %s)"
				% (scene_after.scene_file_path if scene_after else "<null>")
			)
			ok = false

	if ok:
		print("Android back-button smoke test: OK (quit_on_go_back=false, back-press -> MainMenu)")
	else:
		print("Android back-button smoke test FAILED")

	quit(0 if ok else 1)
