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
- [x] **2.9** — Boardwalk room: ground plane, 3 buildings, 2 fence segments as real
  `StaticBody2D`/`CollisionShape2D` obstacles (640×360 room, `Camera2D` on Player with
  `limit_*` set to match). Player upgraded from plain `Node2D` to `CharacterBody2D` +
  `move_and_slide()` — it had no physics body at all before this, so it would have walked
  straight through the new obstacles.
  - Real art wired in: `crxcibl3art/`+`assets/` sit outside `godot/`'s project root and
    aren't reachable via `res://`, so Architect picked the canonical asset per slot from a
    visual gallery (`urban storefront4`→liquor store, `arcade2`→arcade, `apart3`→apartment
    tower, `chainlink2`→fence), copied into `godot/assets/buildings/` with corrected
    extensions (two picks were PNG data misnamed `.jpg`). Scale factors computed from each
    source image's actual pixel dimensions, not guessed.
  - **Real CI bug found and fixed:** new image resources need a Godot *import* pass before
    they can load (unlike `.gd` scripts) — since these were added via file copy rather than
    the editor, no `.import` metadata existed, and CI's plain `--quit` boot doesn't perform
    first-time imports. Fixed by adding an explicit `godot --headless --path godot --import`
    step to CI, so this doesn't depend on remembering to open the editor after every new
    asset going forward.
- [x] **2.10** — Real Heat meter HUD (`HeatMeter.gd`), replacing the plain debug `Label` from
  2.5. Custom-drawn bar (background track + orange fill proportional to
  `GameState.heat`/`HEAT_MAX` + numeric readout), self-updating every frame rather than
  needing a manual refresh call — reflects heat changes from anywhere, not just the debug
  button. `GameState.heat` itself was already real since Slice 2.5; this was about the visual
  HUD, not the data wiring.
- [x] **2.11** — First real playable hero: the Enforcer (Ghost / Victor Reyes). Replaced the
  placeholder crimson square with `assets/heroes/hero_enforcer_ghost.png` — the same asset
  the Phaser prototype used as its own first real art integration, for continuity. Stats
  (`MAX_HEALTH=120`, `MELEE_DAMAGE=15`) match `configs/game_config.json`'s `hero_health`/
  `hero_damage.enforcer` values, hardcoded in `Player.gd` for now (no JSON-loading
  infrastructure yet). Added `take_damage()`/`is_dead()` as forward-looking scaffolding for
  2.12's enemy, not full combat — no enemy exists yet to actually use them.
- [x] **2.12** — First enemy: rival crew grunt (`Enemy.gd`), placeholder dark square (no
  enemy art exists yet). Idle until the player enters `DETECTION_RADIUS` (150 units), then
  chases via `move_and_slide()`; attacks on contact (`ATTACK_RANGE` 20) on a 1s cooldown,
  dealing 8 damage through the player's `take_damage()` from 2.11. 40 HP, `queue_free()`s at
  0. One instance placed in `TestRoom.tscn` just outside the player's starting detection
  range, so approaching it demonstrates the idle→chase transition.
- [x] **2.13** — Wired `Stress.gd`'s real hooks into combat: `enter_combat()`/`exit_combat()`
  toggle on Enemy.gd's detection radius (guarded against getting stuck if the enemy dies
  mid-combat), `on_hit_taken()` fires when the enemy lands a hit, `on_crew_member_downed()`
  fires once when the player hits 0 HP. `on_hit_dealt()`/`on_crew_member_ghosted()` left
  unwired — no player attack input or permanent-death system exists yet to trigger them
  honestly. Added `Stress.tick(delta)` to `TestRoom.gd` (nothing else owned a per-frame tick)
  and a `StressMeter.gd` debug HUD element so this is actually visible at runtime.
- [x] **2.14** — Combat direction pivot (Architect): Metal Slug-style gun combat + Warriors
  (PS2)-style brawl economy, not another "kill the spawner" mechanic — this superseded the
  originally-planned Crack House/Chop Shop generator for this slot (that idea still exists,
  see below, just no longer next). `Bullet.gd` (built in code, not a saved scene) + `Player.
  fire()` (Fire button/Space, 0.25s cooldown) give the player their first real attack — melee
  was scaffolded in 2.11/2.12 but never actually wired to an input. `Enemy.gd` drops 1 Rune
  per kill via `GameState.add_resource()`. Rune counter added to the debug HUD.
- [x] **2.15** — Shared group Rune pool + per-hero contribution tracking. All kill Runes from
  any player land in one shared `GameState` pool — no individual wallets, nobody can hoard.
  `purchase_upgrade(id, cost)` spends from the shared pool atomically. `rune_contributions`
  tallies each hero's kill-generated Runes as a solidarity metric (shown in end-of-run recap),
  not a competitive currency. `Bullet.shooter` / `Enemy.take_damage(killer)` thread the
  killing hero's name end-to-end so the tally is accurate in multiplayer. `top_contributor()`
  and `has_upgrade()` helpers added to `GameState`. Debug HUD now shows per-hero breakdown
  live (`"Rune (group): N  enforcer:N"`). This is the backend the bodega shop UI builds on.
- [x] **2.16** — Bodega upgrade shop UI: a trigger zone at the boardwalk room's liquor store
  (`Building1`, already built in 2.9) opens a simple menu that calls `purchase_upgrade()` —
  weapon upgrades (power, fire rate, reload speed) drawn from the shared Rune pool. Styled
  after The Warriors (PS2)'s brawl-flow economy (buying "Flash" heals from dealers mid-mission
  is the explicit reference; a heal-for-Rune option is worth wiring here too).
- [x] **2.16-shader** — Shader integration (ported from alfredbaudisch/godot-shaders, Godot 3→4):
  `enemy_dissolve.gdshader` — noise-based 2D dissolve runs on enemy death over 0.5s before
  `queue_free()`; `ShaderMaterial` applied at runtime in code, border orange matches Heat color.
  `heat_wave.gdshader` — full-screen wave warp `ColorRect` on `CanvasLayer` layer 2; intensity
  driven by `GameState.heat`, ramps 0→1 between the 51 and 100 thresholds already in the
  visual direction doc.
- [x] **2.17** — Crack House / Chop Shop spawn generator (`SpawnGenerator.gd`, `StaticBody2D`).
  Spawns up to 3 enemy grunts every 6s. Clearing requires shooting the stash to 0 HP *and*
  having no live spawns — two-phase clearing so the player must mop up before the location
  goes quiet. On clear: persists `"cleared_<id>"` in `GameState.group_upgrades`, drops heat
  by 20 (reward), `queue_free()`s. Placed in TestRoom at (850, 460) near the fence line.
  Bullets detect `spawn_generator` group so the stash is directly shootable.
- [x] **2.18** — Rooftop sprint + Blackwood surprise boss encounter. `RooftopScene.tscn`
  (600×320 rooftop room). `RooftopTrigger` Area2D near Building3 (apartment tower) in TestRoom
  loads the scene; skipped if encounter already logged in `GameState.bosses_fought`.
  `BossBlackwood.gd` (200 HP, three phases): SURPRISED (2s idle — players get free shots),
  FIGHT (mid-range orbiting, Deacon grunt spawns every 8s capped at 2, gold light projectiles
  every 2.5s), FLEE at 80 HP threshold (kills deacons, fires white flashbang `ColorRect`
  fade via Tween, sprints to FleeMarker, emits `fled` signal). On flee: records
  `"Blackwood_rooftop"` in `GameState.bosses_fought`, spikes heat +15, returns to TestRoom.
  `BossProjectile.gd`: boss-side ranged attack, same Area2D pattern as `Bullet.gd`.
- [x] **2.19** — Car chase getaway sequence. Blackwood's flee triggers a vehicle pursuit level
  (top-down scrolling road, player vehicle vs. cop/crew cars). Designed as the bridge between
  the rooftop encounter and the Emperor confrontation. Boss reference: Blackwood riding ahead
  in his town car; players must survive the chase to reach the finale. Boat run variant noted
  for a separate level (different geography, different boss — The Broker's compound has water).
- [x] **2.20** — The Emperor confrontation (Act 3 finale). `EmperorScene.tscn` (estate room,
  reached automatically when the car chase ends). Tag-team per the Architect's note:
  Blackwood makes his final stand first (`final_stand` export on `BossBlackwood.gd` — no
  surprise phase, no flee, dies at 0 HP emitting `defeated(finisher)`, recorded via
  `mark_boss_defeated`), then the non-combat reckoning: the Emperor's confession verbatim
  from the lore doc, a FORGIVE HIM / TURN AWAY choice setting `GameState.emperor_forgiven`,
  his death, heat -50, and the first real in-game `SaveSystem.save_game()` call. Crew walks
  away — back to TestRoom (epilogue is Phase 3). Two pre-existing bugs fixed en route:
  `Bullet.gd` never hit the `"boss"` group (rooftop Blackwood was bullet-immune), and
  boss-forced deacon cleanup left the Stress combat flag stuck (new `Enemy.despawn()`).
  CI now boots every scene in `godot/scenes/`, not just the main scene.

### Deferred architecture: unified combat pipeline (noted, not built)
Architect proposed a `CombatDirector` (autoload) + `WeaponBehavior` strategy pattern
(`MeleeWeapon`/`RangedWeapon`/`GrenadeThrow` subclasses with `start_attack()`/`apply_hit()`/
`interrupt()`) + a centralized `HitResolver` (hurtboxes/hitboxes, damage, stun, team/gang
alliances) + a formal FSM for `EnemyBehavior` (idle/patrol/chase/attack/retreat). This is a
legitimate, well-established pattern (strategy pattern + FSM) — genuinely the right shape
*once* there's real weapon/enemy variety to justify it. Right now there's exactly one gun,
one unused melee stub, and one enemy with a 3-state chase/attack loop, so building the full
framework now would be scaffolding around a single `if` statement — same "don't build all
twelve before testing one" principle already guiding `Stress.gd`'s design. Revisit this
the moment a second weapon type or second enemy archetype actually gets built (rule-of-three:
abstract after 2-3 concrete cases exist, not before).

## Phase 3 — Full Roster & Story Content (IN PROGRESS)
- [x] **3.1** — Player health HUD (`HealthBar.gd`, same `_draw()` idiom as Heat/Stress meters).
  Green fill, turns red + "DOWNED" text at 0 HP. `Player.gd` freezes input on death and
  auto-respawns at full HP after 3s (`downed`/`respawned` signals). Added to TestRoom,
  RooftopScene, EmperorScene CanvasLayers. Permanent death is a separate later module.
- [x] **3.2** — HUD cleanup: removed debug elements (AddHeatButton, StressMeter, RuneLabel
  from TestRoom; StressLabel from Rooftop/Emperor scenes). Compacted permanent meters to
  corners — HealthBar top-left (4,4→134,22), HeatMeter top-right (right-anchored,
  -134,4→-4,22) — both 130×18 px. Font size 13→11, text label shortened to "HP N" / "HEAT N".
- [x] **3.3** — Stress gameplay consequences wired into `Player.gd`. At elevated stress (≥40):
  movement speed ×0.85. At critical stress (≥75): speed ×0.70 and fire cooldown ×2 (shaky hands).
  Uses the existing `Stress.THRESHOLD_*` constants — no new infrastructure, purely wired the
  already-tracked meter into the player's actual behaviour.
- 12 playable hero variants (3 per class × 4 classes) — see `KNOWLEDGE_BASE.md` for full roster.
- Relationship system — `GameState.gd` already has the full pairwise (-10..+10) model built;
  this phase is about wiring it into actual gameplay triggers, not building it from scratch.
- The 12 mechanics modules `Stress.gd` was written as a template for (Scarcity, Injury,
  Hideout, Morale, Reputation, Alliance, DialogueIntensity, PermanentDeath, Blame, Bosses,
  Emperor, Epilogue) — build one at a time, wire each into a scene before starting the next.
- [x] **3.18** — **Cross (The Fixer)** — `BossCrossScene.tscn` + `BossCross.gd` on `BossGeneric` template. Cross Tower Penthouse; bodyguards, turrets, political smear attacks, panic-room retreat. TestRoom trigger zone + `--boss-cross` demo flag.
- [x] **3.19** — **Voss (The Broker)** — `BossVossScene.tscn` + `BossVoss.gd`. Voss Compound Vault; drones, turrets, data scrambles, personal energy shield. TestRoom trigger + `--boss-voss`.
- [x] **3.20** — **Moreau (The Pusher)** — `BossMoreauScene.tscn` + `BossMoreau.gd`. Moreau Pharmaceuticals Lab; chemical weapons, toxin clouds, Super Rager final phase. TestRoom trigger + `--boss-moreau`.
- [x] **3.21** — **Hayes (The Warden)** — `BossHayesScene.tscn` + `BossHayes.gd`. Beach Boulevard Correctional Facility; guards, turrets, gas waves, riot shield + baton. TestRoom trigger + `--boss-hayes`.
- [x] **3.22** — **Webb (The Trader)** — `BossWebbScene.tscn` + `BossWebb.gd`. Webb Industries Data Center; digital defenses, firewall drones, mech-suit reveal. TestRoom trigger + `--boss-webb`.
- [x] **3.23** — **`BossGeneric` template system** — shared combat + JSON cutscene pipeline on `BossEncounter`; metadata in `bosses.json`, beats in per-boss JSON. **GA scope for v1.2.0.**
- The Corrupted Six boss fights (6 unique bosses + The Emperor finale) — **implemented in v1.2.0**; Blackwood + Emperor shipped in Phase 2.
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

## Act arc (locked design, Architect-confirmed)
1. **Rooftop (2.18 DONE)** — crew stumbles on Blackwood unguarded → surprise fight → flashbang flee
2. **Car chase (2.19)** — Blackwood riding ahead, crew in pursuit, survive to reach the Emperor
3. **Boat run variant (deferred)** — The Broker's compound, water geography, separate level
4. **Emperor confrontation (2.20)** — Blackwood + Emperor tag-team challenge → Emperor's confession
   reckoning → crew walks away (no takeover). Non-combat resolution per lore.

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
- **Resolved:** Beach Boulevard is the canonical setting name (San Espada retired).
- **Resolved:** Phaser web build fully retired — Godot 4.7.1 is the shipping target.
- The other 11 mechanics modules `Stress.gd` templates for — build order/priority not yet
  decided.
