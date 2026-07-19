# CRXCIBL3 — Project Blueprint (Roadmap)

Engine lineage: Godot (early, code-only) → Phaser 3 web prototype (playable reference) →
GameMaker LTS (started 2026-07-19, abandoned same day — Android export is a paid tier) →
**Godot 4.x, mobile/Android target (current)**.

Format: Salami Method — each slice is small, testable, and gets its own commit.

## Phase 1 — Web Prototype (DONE)
Playable Phaser 3 boardwalk level: movement, collision, camera follow, placeholder Heat HUD,
`assets/` folder structure matching art categories. See `README.md`. Status as a build:
kept as-is for now, not actively developed — open question whether it's retired later.

## Phase 2 — Godot Mobile Build (IN PROGRESS)
- [x] **2.1** *(GameMaker, abandoned)* — scaffolded GameMaker folders/config; deleted 2026-07-19.
- [x] **2.2** — Consolidated pre-existing Godot files (found scattered in `Downloads/`) into
  `crxcibl3/godot/`: `project.godot` (already configured for Godot 4.3 + "Mobile" feature)
  plus four autoload scripts (`GameState.gd`, `Stress.gd`, `SaveSystem.gd`, `Recap.gd`) moved
  into `godot/autoload/`. Godot 4.7.1 editor downloaded to Desktop (portable exe, no install).
- [x] **2.3** — Opened the project in the Godot editor; registered the 4 scripts as Autoloads
  in `project.godot` in dependency order (GameState → Stress → SaveSystem → Recap). Also set
  up GitHub Actions CI (`.github/workflows/godot-check.yml`) that boots the engine headless
  and verifies all four autoloads resolve on every push — confirmed green.
- [x] **2.4** — Android SDK (already present from an earlier machine setup) + JDK (Android
  Studio's bundled JBR) pointed to from Godot's Export → Android settings; debug keystore
  generated; official Godot 4.7.1 Android export templates (1.2 GB) downloaded and installed.
  NDK skipped — not needed unless Gradle Build gets turned on later. Target: sideload-only
  APK for friends, not a Play Store release — no Play Console/store-listing scope needed.
- [x] **2.5** — `TestRoom.tscn`: placeholder drawn-square player (arrow keys) + a Heat label
  and button wired to `GameState.modify_heat()`, set as the main scene. CI confirms it
  compiles/boots cleanly, and the Architect confirmed in the running editor that heat
  actually updates on click/H-press — reads/writes work end-to-end. An actual APK export
  still hasn't been attempted.
- [x] **2.6** — Touch controls: draggable virtual joystick (`VirtualJoystick.gd`), bottom-left
  of `TestRoom`, also mouse-draggable for desktop testing. `Player.gd` reads it with an
  arrow-key fallback. CI confirms the scene still boots; visual/feel confirmation pending.
- [ ] **2.7** — Screen-size/aspect-ratio scaling strategy (phones and tablets vary a lot more
  than the Phaser build's fixed 320×180 @ 3x zoom assumed).
- [ ] **2.8** — Recreate the boardwalk room: ground/building/fence/palm-tree tiles, collision,
  camera follow with room bounds — parity with the Phaser prototype (`js/BoardwalkScene.js`
  is the reference for layout/behavior, not code to port directly).
- [ ] **2.9** — Heat HUD wired to real `GameState.heat` (still a static demo value even in the
  Phaser build — first slice where Heat becomes real anywhere in any engine).
- [ ] **2.10** — One playable hero class (start with Enforcer — simplest kit: melee, tank
  stats) using the balance numbers already in `configs/game_config.json`.
- [ ] **2.11** — Enemy base + one enemy type (rival crew grunt) with basic chase/attack AI.
- [ ] **2.12** — Wire `Stress.gd`'s combat hooks (`on_hit_taken`, `on_hit_dealt`,
  `on_crew_member_downed`) into actual combat once it exists.
- [ ] **2.13** — Crack House / Chop Shop spawn generator (replaces "monster generator" from
  the classic formula) — clearing conditions TBD, see Open Design Threads.
- [ ] **2.14** — Getaway/exit sequence for one level (car chase, rooftop sprint, or boat run).

## Phase 3 — Full Roster & Story Content (NOT STARTED)
- 12 playable hero variants (3 per class × 4 classes) — see `KNOWLEDGE_BASE.md` for full roster.
- Relationship system — `GameState.gd` already has the full pairwise (-10..+10) model built;
  this phase is about wiring it into actual gameplay triggers, not building it from scratch.
- The 12 mechanics modules `Stress.gd` was written as a template for (Scarcity, Injury,
  Hideout, Morale, Reputation, Alliance, DialogueIntensity, PermanentDeath, Blame, Bosses,
  Emperor, Epilogue) — build one at a time, wire each into a scene before starting the next.
- The Corrupted Six boss fights (6 unique bosses + The Emperor finale) — each has a defined
  location, fight gimmick, and defeat scene already written in the lore bible.
- 3-act structure (The Fall / The Gathering / The Reckoning) mapped to actual mission order —
  `Recap.gd` already keys its summary text off `GameState.current_act` (1/2/3), so the act
  numbering convention is already decided.
- `SaveSystem.gd` already handles persistence for everything above via `user://` — no new
  save infrastructure needed as new state fields get added, just new lines in its
  save/load functions.

## Phase 4 — Art & Audio Integration (ONGOING, PARALLEL)
- AI-assisted pixel art pipeline already defined (Leonardo.ai/Bing → Pixel It → Piskel) — see
  `KNOWLEDGE_BASE.md` art section.
- One real art asset already referenced in code: `assets/heroes/hero_enforcer_ghost.png`
  (loaded in the Phaser build's `BoardwalkScene.js` preload, Phase 1).

## Open Design Threads (unresolved, need an Architect call before the relevant slice)
- Precise Heat thresholds/scaling per level (Recap.gd already has heat-tier text at 26/51/76
  — reuse those breakpoints for consistency unless there's a reason not to).
- Crack House / Chop Shop spawn logic and clearing conditions.
- Getaway sequence design — shared mechanic across levels, or unique per level?
- Relationship-based gameplay bonuses (co-op pair synergy buffs) — the data model exists,
  the bonus rules don't yet.
- 8-bit visual/audio direction: exact palette, sprite scale, resolution constraints for
  mobile (replaces the old 320×180 desktop-zoom assumption — needs a mobile-appropriate
  equivalent).
- "San Espada" vs. "Beach Boulevard" naming — lore doc flags these as needing reconciliation.
- Whether the Phaser web build gets fully retired now that Godot is the confirmed target, or
  kept as a lightweight reference/demo build.
- The other 11 mechanics modules `Stress.gd` templates for — build order/priority not yet
  decided.
