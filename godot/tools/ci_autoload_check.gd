extends SceneTree
# CI entry point: `--check-only --script` compiles a script in isolation and
# never boots the autoload registry, so it always flags cross-autoload
# references (e.g. Stress.gd's use of GameState) as undefined, regardless of
# whether autoloads are actually registered. Running as the real main loop
# via `-s` boots autoloads first, so this is the correct way to verify they
# resolve.

func _initialize() -> void:
	var ok := true

	if not root.has_node("GameState"):
		push_error("Autoload missing: GameState")
		ok = false
	if not root.has_node("Stress"):
		push_error("Autoload missing: Stress")
		ok = false
	if not root.has_node("SaveSystem"):
		push_error("Autoload missing: SaveSystem")
		ok = false
	if not root.has_node("Recap"):
		push_error("Autoload missing: Recap")
		ok = false
	if not root.has_node("CutsceneDirector"):
		push_error("Autoload missing: CutsceneDirector")
		ok = false
	if not root.has_node("EnemyRegistry"):
		push_error("Autoload missing: EnemyRegistry")
		ok = false

	if ok:
		print("All autoloads registered and resolved: GameState, Stress, SaveSystem, Recap, CutsceneDirector, EnemyRegistry")
	else:
		print("Autoload check FAILED")

	quit(0 if ok else 1)
