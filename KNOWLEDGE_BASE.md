# CRXCIBL3 — Knowledge Base

Consolidated reference. Source-of-truth files live elsewhere on disk (paths noted below) —
this doc summarizes them so a session doesn't need to re-read everything each time.

## Premise (full detail: `Downloads/crxcibl3-lore.md`)
Cooperative heist-and-survival game, classic top-down arcade dungeon-crawler formula
(4 heroes, waves of enemies, an exit) reskinned as 90s West Coast gangster cinema
(*Menace II Society*, *Boyz n the Hood*, *Training Day*) filtered through *GTA: San Andreas*
satire. 8-bit/16-bit retro pixel art. Setting: Beach Boulevard, a decayed coastal strip
fought over by three crews for **The Rune** (encrypted currency). Story spine: the crew's
"Seven Sorrows" (seven botched heists engineered by the Emperor's traitorous advisors, the
Corrupted Six) → scattering → reunion → revenge against each of the Six → the Emperor's death
→ epilogue where the crew walks away instead of taking over.

## Classic-formula reskin mapping
| Classic mechanic | CRXCIBL3 equivalent |
|---|---|
| Health | **Heat** — hunted meter, 0–100, rises from exposure, lowered by lying low/bribes/small jobs |
| Food | **Resources** — Cash, Ammo, Intel |
| Monster generators | **Crack Houses / Chop Shops** — enemy spawn strongholds, clear block by block |
| The Exit | **The Getaway** — car chase / rooftop sprint / boat run |

## Hero classes (4 archetypes × 3 variants = 12 playable heroes)
| Class | Role | Playstyle | Variants |
|---|---|---|---|
| Enforcer | Tank | high HP, high melee | Big Body (Marcus Williams), Ghost (Victor Reyes), Mama's Boy (DeShawn Johnson) |
| Wheelman | Tanky support | high armor, best driving | Slick (Elena Rodriguez), Grinder (Eddie Kowalski), Bonnie (Bonnie Greene) |
| Hacker | Glass cannon | high ranged "digital magic" damage | Byte (Kevin Chen), Hacktivist (Maya Park), Skeez (Archibald Whitmore III) |
| Street Rat | Speed | fastest movement, best stealth/looting | Slink (José Reyes), Vex (Vanessa Martinez), Mouse (Terrence Johnson) |

Every hero has a full backstory tied to the Seven Sorrows and a specific Corrupted Six member's
crime — see the lore doc's relationship web table for who's connected to whom (useful later for
the relationship/synergy system).

## The Corrupted Six (bosses) + finale
1. **The Fixer — Councilman Victor Cross** (Cross Tower Penthouse) — bodyguards/turrets/political attacks, panic room retreat.
2. **The Broker — Damian Voss** (Voss Compound Vault) — drones/turrets/data scrambles, personal energy shield.
3. **The Pusher — Dr. Celeste Moreau** (Moreau Pharmaceuticals Lab) — chemical weapons, self-injects into a "Super Rager" phase.
4. **The Warden — Leonard "Iron" Hayes** (Beach Boulevard Correctional Facility) — guards/turrets/gas, riot shield + baton.
5. **The Trader — Marcus Webb** (Webb Industries Data Center) — digital defenses, reveals a mech suit.
6. **The Priest — Reverend Isaiah Blackwood** (Blackwood Megachurch) — deacons/traps/fake "divine" illusions.
7. **The Emperor** (final, non-combat reckoning) — dies confessing he traded the Seven Sorrows to save the crew's lives.

Each boss fight already has scripted confrontation/defeat dialogue in the lore doc — useful
directly for cutscene/dialogue implementation later.

## Config values (implemented, `configs/game_config.json`)
fps 60, view 320×180, heat_max 100, heat_generation_rate 0.5, heat_reduction_rate 2.0,
resources_starting 100, enemy_wave_interval 30, per-hero health/damage for the 4 base archetypes
(Enforcer 120hp/15dmg, Wheelman 100hp/10dmg, Hacker 60hp/20dmg, Street Rat 70hp/12dmg).

## GameState implementations
- **The real one, live in this project:** `godot/autoload/GameState.gd` — full model: heat,
  squad, pairwise relationships (-10..+10), secrets/quests/bosses tracking, boss
  executed/finisher tracking, morale, reputation (ruthlessness vs. solidarity), resources,
  ghost_count (permanently lost crew), alliance formed/broken/betrayed counters, blame ledger,
  act/scene checkpoint. Not yet registered as an Autoload in the actual Godot project settings
  — that's Slice 2.3.
- **Retired:** Phaser 3 web prototype — Godot 4.7.1 is the shipping client.

## Godot autoload modules (all in `godot/autoload/`, none wired into a scene yet)
- **`GameState.gd`** — see above. Load first; everything else depends on it.
- **`Stress.gd`** — a second meter, crew-wide combat/death stress, separate from Heat (Heat =
  "hunted by the world," Stress = "the crew's own fraying nerves"). Constants: max 100, decays
  1.5/sec out of combat, +4 per hit taken, +1 per hit dealt, +20 crew member downed, +40 crew
  member ghosted (permanent loss, also increments `GameState.ghost_count`). Thresholds at 40
  ("elevated") and 75 ("critical") emit a `stress_threshold_changed` signal the UI can listen
  for. **Explicitly written as the template shape** for 12 more planned modules that don't
  exist yet: Scarcity, Injury, Hideout, Morale, Reputation, Alliance, DialogueIntensity,
  PermanentDeath, Blame, Bosses, Emperor, Epilogue — build them one at a time, wire each into
  a scene before starting the next, don't build all twelve speculatively.
- **`SaveSystem.gd`** — writes/reads `GameState` to a human-readable text file at
  `user://crxcibl3_save.txt`. Uses Godot's `user://` virtual path, which auto-resolves to
  sandboxed per-platform app storage — **on Android this needs zero manual permission
  handling**, a real advantage over hand-rolling file I/O. Save format is simple `key=value`
  lines plus prefixed lines for dict/array data (`resource:`, `relationship:`, `boss:`,
  `secret=`, `quest=`) — adding a new GameState field just means adding one line to
  `save_game()` and one `match` case to `load_game()`.
- **`Recap.gd`** — builds a "previously on..." summary from current `GameState` for a
  returning player (act progress, bosses fought/spared, heat tier text at 26/51/76
  thresholds, worst relationship if ≤ -5, ghost count). Fragment-based, so it scales with
  however much/little progress exists — no forced wall of text on an early save.

## Godot project config
`godot/project.godot` — name "CRXCIBL3", already configured for Godot **4.3** with the
**"Mobile" feature preset** already set (confirms mobile was already the plan in an earlier
pass, before this session rediscovered it). The installed editor is 4.7.1 — opening the
project will likely auto-upgrade the version tag once, expected and safe for a project this
small (no scenes to break yet, only scripts).

## Mobile/Android build requirements (not yet done)
Target is a **sideload APK for friends**, not a Play Store release — no Play Console, store
listing, or compliance scope needed. Still required regardless:
- Android SDK + NDK + JDK, referenced from Godot's Editor Settings → Export → Android.
- Godot's Android export templates (free, downloadable in-editor or via CLI).
- A signing keystore (`keytool`, standard/free, fully scriptable).
- Touch controls — VirtualJoystick in TestRoom; keyboard fallback for desktop.

## Art pipeline (full detail: `Downloads/CRXCIBL3-art-prompt-sheet.md`)
Leonardo.ai (Pixel Art model, primary) or Bing Image Creator (backup) → Pixel It (snap to
16px/32px grid, quantize to ~12–16 colors) → Piskel/LibreSprite (hand-cleanup + walk-cycle
frames, AI output used only as a single reference pose, never a finished animation) → export
PNG, `Nearest` filter on import.

Style anchor string (append to every generation prompt):
> `16-bit pixel art, top-down 3/4 angle game asset, flat color fills, hard black outlines, no gradients, no anti-aliasing, limited retro color palette, muted gritty urban tones, transparent background`

Full prompt sheet already written for: sidewalk tile, liquor store/arcade facade, project
tower facade, chop shop, chain-link fence, dead palm tree, orange/pink neon signs, police
checkpoint, burned arcade sign, all 4 hero idle poses, rival grunt, Corrupted Six enforcer,
police officer, lowrider getaway car, dumpster, Heat meter icon, Rune currency icon.

One real asset already integrated in code: `assets/heroes/hero_enforcer_ghost.png`.

## Technical standards (from `Desktop/AEF_GLOBAL_FRAMEWORK.md` — engine-agnostic parts still apply)
- Verify any engine API against current docs via web search before using it — don't rely on
  training-data memory for library/API specifics, especially for Godot 4.x which changed a lot
  from 3.x (the AEF doc was written with GameMaker in mind, but this rule is engine-agnostic
  and matters even more now given the project.godot version mismatch noted above).
- Build/test tooling, FOSS-only per the AEF communication contract: Godot's own CLI
  (`godot --headless --export-release ...`) + GitHub Actions (free tier) for CI; Godot's
  built-in debugger; ImageMagick/FFmpeg for asset pipeline where needed. This is actually a
  better fit for Godot than it was for GameMaker — no paid tier blocks any part of the
  Android pipeline.
- Communication contract from AEF: treat the Architect as a competent peer, drive automation
  and code, they supply art/creative calls; ask a single-sentence question when a creative
  decision is genuinely needed rather than guessing.
- GameMaker-specific standards (GML conventions, `ds_*` avoidance, etc. from
  `Desktop/GMKF_VOLUMES.md`) no longer apply — kept on disk for reference only, not relevant
  to the current Godot target.

## Tone & voice
Gutter and visceral, not glossy — grime, heat, concrete, desperation. A paranoid,
chain-smoking fixer barks radio updates, e.g. *"Enforcer needs ammo, bad!"*,
*"Street Rat's Heat is maxed — move, fool!"*
