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
  arrow-key fallback. Confirmed working on-device (Pixel 8a emulator + real Galaxy A37).
- [x] **2.7** — First real APK export. Fixed a missing `icon.svg` reference and added
  `export_presets.cfg` (portable debug keystore config, works identically locally and in CI).
  New CI job builds and uploads the APK on every push. First attempt failed on a missing
  project setting (ETC2/ASTC texture compression); fixed, second attempt succeeded — 28.2 MB,
  confirmed installing and running correctly on-device.
- [x] **2.8** — Cross-device scaling. `canvas_items`/`expand` stretch on a 384×216 base
  viewport. Real bug found: the joystick's 150×150 footprint was 69% of the design canvas
  height, so it looked oversized on every device identically — not an orientation issue (a
  wrong first guess). Fixed by properly sizing it to ~26% of canvas height instead. See
  `PROJECT_STATE.md` for the full diagnostic writeup.
- [ ] **2.9** — Recreate the boardwalk room: ground/building/fence/palm-tree tiles, collision,
  camera follow with room bounds — parity with the Phaser prototype (`js/BoardwalkScene.js`
  is the reference for layout/behavior, not code to port directly). Real art assets already
  exist and are already Godot-imported in `assets/` — use those instead of placeholders.
- [ ] **2.10** — Heat HUD wired to real `GameState.heat` (still a static demo value even in the
  Phaser build — first slice where Heat becomes real anywhere in any engine).
- [ ] **2.11** — One playable hero class (start with Enforcer — simplest kit: melee, tank
  stats) using the balance numbers already in `configs/game_config.json`.
- [ ] **2.12** — Enemy base + one enemy type (rival crew grunt) with basic chase/attack AI.
- [ ] **2.13** — Wire `Stress.gd`'s combat hooks (`on_hit_taken`, `on_hit_dealt`,
  `on_crew_member_downed`) into actual combat once it exists.
- [ ] **2.14** — Crack House / Chop Shop spawn generator (replaces "monster generator" from
  the classic formula) — clearing conditions TBD, see Open Design Threads.
- [ ] **2.15** — Getaway/exit sequence for one level (car chase, rooftop sprint, or boat run).

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
