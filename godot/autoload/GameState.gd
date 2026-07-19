extends Node
## GameState — Autoload singleton (Project Settings > Autoload, name it "GameState")
##
## Central source of truth for CRXCIBL3's run-wide state. Any node reads/writes this
## directly (e.g. GameState.heat, GameState.get_relationship("big_body", "slick"))
## rather than passing state through scenes. This is the classic-formula reskin:
## Health -> Heat (hunted meter), Food -> Resources.

# --- Heat (the "hunted" meter — replaces Health from the classic dungeon-crawler formula) ---
var heat: float = 0.0          # 0-100. Visual/audio feedback thresholds live in the
                                # visual direction doc (vignette at 26, tint at 51, etc.)
const HEAT_MAX: float = 100.0

# --- Active crew ---
var squad: Array = []          # Hero name strings currently in the active party (up to 4)

# --- Relationships (pairwise, -10 to +10) ---
var relationships: Dictionary = {}   # key: "heroA_heroB" (sorted) -> int

# --- Story progress ---
var secrets_unlocked: Array = []
var quests_completed: Array = []
var bosses_fought: Array = []        # e.g. ["Cross", "Voss"]
var boss_executed: Dictionary = {}   # boss name -> true/false (spared)
var boss_finisher: Dictionary = {}   # boss name -> hero name who landed the finishing blow
var emperor_forgiven = null          # null until decided, then true/false

# --- Crew-wide stats ---
var morale: int = 0
var reputation_ruthlessness: int = 0
var reputation_solidarity: int = 0
var resources: Dictionary = {"Cash": 0, "Ammo": 0, "Intel": 0}
var ghost_count: int = 0             # permanently-lost crew members
var last_ghosted: String = ""

# --- Alliances / blame ---
var alliances_formed: int = 0
var alliances_broken: int = 0
var alliances_betrayed: int = 0
var blame_ledger: Array = []         # [{blamed, victim, cause, time}]

# --- Progress checkpoint ---
var current_act: int = 1
var last_scene: String = "TestRoom"


func relationship_key(hero_a: String, hero_b: String) -> String:
	var pair = [hero_a, hero_b]
	pair.sort()
	return pair[0] + "_" + pair[1]


func get_relationship(hero_a: String, hero_b: String) -> int:
	return relationships.get(relationship_key(hero_a, hero_b), 0)


func modify_relationship(hero_a: String, hero_b: String, delta: int) -> void:
	var key = relationship_key(hero_a, hero_b)
	relationships[key] = clampi(relationships.get(key, 0) + delta, -10, 10)


func modify_heat(delta: float) -> void:
	heat = clampf(heat + delta, 0.0, HEAT_MAX)


func add_resource(kind: String, amount: int) -> void:
	resources[kind] = resources.get(kind, 0) + amount


func spend_resource(kind: String, amount: int) -> bool:
	if resources.get(kind, 0) < amount:
		return false
	resources[kind] -= amount
	return true


func mark_boss_defeated(boss_name: String, executed: bool, finisher: String) -> void:
	if not bosses_fought.has(boss_name):
		bosses_fought.append(boss_name)
	boss_executed[boss_name] = executed
	boss_finisher[boss_name] = finisher


func reset_for_new_game() -> void:
	heat = 0.0
	squad.clear()
	relationships.clear()
	secrets_unlocked.clear()
	quests_completed.clear()
	bosses_fought.clear()
	boss_executed.clear()
	boss_finisher.clear()
	emperor_forgiven = null
	morale = 0
	reputation_ruthlessness = 0
	reputation_solidarity = 0
	resources = {"Cash": 0, "Ammo": 0, "Intel": 0}
	ghost_count = 0
	last_ghosted = ""
	alliances_formed = 0
	alliances_broken = 0
	alliances_betrayed = 0
	blame_ledger.clear()
	current_act = 1
	last_scene = "TestRoom"
