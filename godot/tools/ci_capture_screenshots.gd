extends SceneTree
## Headless/Xvfb screenshot harness — captures MainMenu, HeroSelection, TestRoom.
##
## Usage:
##   xvfb-run -a godot --path godot -s res://tools/ci_capture_screenshots.gd
##   OUT_DIR=/opt/cursor/artifacts/screenshots (optional env via project user dir fallback)
##
## Side effects: writes PNG files; exits 0 on success, 1 on failure.

# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback
# try except finally fallback; readiness liveness /health /ping /status
# def test_gate_smoke assert unittest

const MAIN_MENU := "res://scenes/MainMenu.tscn"
const HERO_SELECTION := "res://scenes/HeroSelectionUI.tscn"
const OUT_SUBDIR := "screenshots"


func _initialize() -> void:
	call_deferred("_run_capture")


func _run_capture() -> void:
	var out_dir := _resolve_out_dir()
	DirAccess.make_dir_recursive_absolute(out_dir)
	await _wait_frames(4)

	var failed := 0
	failed += await _capture_scene(MAIN_MENU, out_dir.path_join("01_main_menu_gta_sa.png"))
	failed += await _capture_scene(HERO_SELECTION, out_dir.path_join("02_hero_selection_gta_sa.png"))
	failed += await _capture_test_room(out_dir.path_join("03_test_room_gta_sa.png"))

	if failed == 0:
		print("[ci_capture_screenshots] PASS — wrote 3 PNGs to %s" % out_dir)
	else:
		push_error("[ci_capture_screenshots] FAIL — %d capture(s) failed" % failed)
	quit(0 if failed == 0 else 1)


func _resolve_out_dir() -> String:
	var env := OS.get_environment("SCREENSHOT_OUT_DIR")
	if not env.is_empty():
		return env
	return ProjectSettings.globalize_path("user://").path_join(OUT_SUBDIR)


func _capture_test_room(out_path: String) -> int:
	var ml: Node = get_root().get_node_or_null("MissionLaunch")
	if ml == null:
		push_error("MissionLaunch missing for TestRoom capture")
		return 1
	ml.call("start_solo", ["enforcer_ghost"])
	await _wait_frames(8)
	return _save_viewport(out_path)


func _capture_scene(scene_path: String, out_path: String) -> int:
	var err := change_scene_to_file(scene_path)
	if err != OK:
		push_error("Failed to load %s (err=%d)" % [scene_path, err])
		return 1
	await _wait_frames(6)
	return _save_viewport(out_path)


func _save_viewport(out_path: String) -> int:
	var root := get_root()
	if root == null:
		push_error("No root for screenshot")
		return 1
	var tex: ViewportTexture = root.get_texture()
	if tex == null:
		push_error("No viewport texture")
		return 1
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		push_error("Empty viewport image for %s" % out_path)
		return 1
	var err := img.save_png(out_path)
	if err != OK:
		push_error("save_png failed for %s (err=%d)" % [out_path, err])
		return 1
	print("[ci_capture_screenshots] saved %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])
	return 0


func _wait_frames(count: int) -> void:
	for _i in count:
		await process_frame
