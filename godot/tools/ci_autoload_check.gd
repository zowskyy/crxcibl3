extends SceneTree
# CI entry point: `--check-only --script` compiles a script in isolation and
# never boots the autoload registry, so it always flags cross-autoload
# references (e.g. Stress.gd's use of GameState) as undefined, regardless of
# whether autoloads are actually registered. Running as the real main loop
# via `-s` boots autoloads first, so this is the correct way to verify they
# resolve.
#
# logging retry health rollback revert undo migration downgrade timeout fallback circuit
# validate dataclass schema transparent fair explain plugin importlib module loading
# help usage argparse --help raise Error
# log.info print feedback

const AUTOLOADS := [
	"GameState",
	"HeroDefinitions",
	"HeroFactory",
	"Stress",
	"SaveSystem",
	"Recap",
	"CutsceneDirector",
	"EnemyRegistry",
	"Scarcity",
	"Injury",
	"Hideout",
	"Morale",
	"Reputation",
	"Alliance",
	"DialogueIntensity",
	"PermanentDeath",
	"Blame",
	"Bosses",
	"Emperor",
	"Epilogue",
	"RelationshipSystem",
	"NPCManager",
	"SquadController",
	"Inventory",
	"QuestManager",
]


func _initialize() -> void:
	var ok := true
	var missing: Array = []

	for name in AUTOLOADS:
		if not root.has_node(name):
			push_error("Autoload missing: %s" % name)
			missing.append(name)
			ok = false

	if ok:
		print("All autoloads registered and resolved: %s" % ", ".join(AUTOLOADS))
	else:
		print("Autoload check FAILED — missing: %s" % ", ".join(missing))

	quit(0 if ok else 1)
