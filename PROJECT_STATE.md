# CRXCIBL3 — Project State

Last updated: 2026-07-19 (Slice 3.1 — player health HUD + downed/respawn state)

## Engine status — Godot is the target, confirmed
Lineage: Godot (early, code-only) → Phaser 3 web prototype (playable reference) →
GameMaker LTS (started, then abandoned) → **Godot 4.x, mobile-targeted (current)**.

**Why the GameMaker attempt got dropped:** Android export in GameMaker requires a paid
subscription tier; Godot's Android export is fully free. Since the goal is an APK to
sideload to friends (not necessarily a Play Store release), Godot removes the only real
blocker. The Architect confirmed this pivot on 2026-07-19.

**GameMaker cleanup done:** the `CRXCIBL3.yyp` project (which did have real progress — a
handful of objects created), the OS-level scaffold folders (`scripts/`, `objects/`,
`sprites/`, `sounds/`, `rooms/`, `data/`), and `crxcibl3_gamemaker_setup.ps1` have all been
deleted per Architect instruction. `configs/game_config.json` was kept — it's generic
balance data, not GameMaker-specific.

## What already existed before this slice (discovered, not built this session)
A more complete Godot codebase than initially known was sitting loose in `Downloads/`,
now consolidated into `crxcibl3/godot/`:
- `project.godot` — was configured for Godot 4.3 with the "Mobile" feature preset; upgraded
  to **4.7** automatically the first time the 4.7.1 editor opened it (expected, no data loss).
- `autoload/GameState.gd` — the full state singleton (heat, squad, relationships, quests,
  bosses, morale, reputation, resources, ghost tracking, alliances, blame ledger, act/scene
  checkpoint).
- `autoload/Stress.gd` — a second meter (crew nerves, distinct from Heat), with combat
  hooks and decay-over-time. **Explicitly written as a template** for 12 more planned
  mechanics modules that were never built: Scarcity, Injury, Hideout, Morale, Reputation,
  Alliance, DialogueIntensity, PermanentDeath, Blame, Bosses, Emperor, Epilogue.
- `autoload/SaveSystem.gd` — full save/load to a human-readable text file via Godot's
  `user://` path, which auto-resolves to sandboxed app storage per platform — **already
  Android-safe with no extra permissions needed**.
- `autoload/Recap.gd` — generates a "previously on..." summary from GameState for a
  returning player.

None of these have scenes/nodes/UI built around them yet — this is all logic, no rooms.

## Godot editor
Downloaded by the Architect to `Desktop\Godot_v4.7.1-stable_win64.exe` (portable, no
installer needed). **Do not run the local exe directly from a shell command** — even with
`--headless`, certain startup-error paths (e.g. "no main scene defined") still pop a native
Windows dialog on screen. Verification now happens exclusively through GitHub Actions CI,
which runs properly containerized/headless.

## Git / CI (set up this slice)
- Repo: `https://github.com/zowskyy/crxcibl3` — **private** (was public on creation, switched
  before the first push since the repo holds the full lore bible and art assets).
- Local repo is scoped to just this project folder. **Important:** the earlier `git status`
  run from inside this folder showed the *user's entire home directory* as a git repo
  (`C:\Users\mrscp`), with an `origin` pointing at an unrelated HuggingFace Space
  (`zowskyy/reconcile`) that had a live access token embedded in the remote URL in plaintext.
  That repo was left untouched — this project now has its own independent `.git`, nested
  inside it but operating separately.
- `.github/workflows/godot-check.yml` — runs on every push to `main`. Boots the Godot engine
  headless via `godot --headless --path godot -s res://tools/ci_autoload_check.gd`, which
  verifies all four autoloads resolve and surfaces any compile/parse error in any of them.
  Free tier only (`chickensoft-games/setup-godot` action, Godot 4.7.1).
  - **Known gotcha, don't reintroduce it:** `godot --check-only --script <file>` compiles a
    script in total isolation and never boots the autoload registry — it will *always*
    misreport `GameState` as undefined inside `Stress.gd`/`SaveSystem.gd`/`Recap.gd`
    regardless of whether autoloads are registered. The fix was to run the real engine main
    loop via `-s` instead (see `godot/tools/ci_autoload_check.gd`), which boots autoloads
    before the script runs.
  - **Standing instruction from the Architect:** always push after committing, so CI catches
    build/runtime errors automatically.
- `.gitignore` excludes `godot/.godot/` (editor cache/import artifacts, machine-regenerated).
  `.uid` sidecar files for the autoload scripts *are* committed — Godot treats those as
  stable resource references, not cache.

## Slice 2.3 — DONE
- Autoloads registered in `godot/project.godot`, in dependency order: GameState → Stress →
  SaveSystem → Recap (added via direct edit of `project.godot` while the editor was closed,
  per Godot's own guidance against editing it live).
- CI confirmed green on run `cf60080` (2026-07-19T09:47:00Z) — all four autoloads resolve
  correctly at boot.

## Mobile/Android target
Confirmed goal: build an installable `.apk` to share directly with friends (sideload),
**not** a Play Store release — this drops Play Console/store-listing/compliance scope
entirely.

## Slice 2.4 — DONE (Android build toolchain)
Turned out most of this was already half-done on the machine from an earlier, unrelated
Android Studio install — found via `editor_settings-4.7.tres`, not built from scratch:
- **Android SDK** — already present at `C:\Users\mrscp\AppData\Local\Android\Sdk`
  (`build-tools 36.0.0`, `platform android-36.1`); `export/android/android_sdk_path` was
  already set in Godot's editor settings from a prior session.
- **JDK** — no standalone JDK existed, but Android Studio's bundled JBR (OpenJDK 21) at
  `C:\Program Files\Android\Android Studio\jbr` works. Set
  `export/android/java_sdk_path` to that path directly in `editor_settings-4.7.tres`
  (plain-text Godot resource file, editable the same way as `project.godot`).
- **Debug keystore** — generated via `keytool` at
  `C:\Users\mrscp\AppData\Roaming\Godot\keystores\debug.keystore`, matching the path/alias/
  password (`androiddebugkey` / `android`) Godot's editor settings already expected. Good
  enough for sideloading to friends. A **release** keystore was deliberately *not* generated
  — only needed later if pushing updates to the same install without everyone reinstalling,
  and losing that password permanently breaks future updates, so it should be a deliberate
  choice with a password the Architect actually saves, not something auto-generated silently.
- **Export templates** — downloaded (official `Godot_v4.7.1-stable_export_templates.tpz`,
  1.2 GB, from github.com/godotengine/godot releases, Architect confirmed the download) and
  installed to `C:\Users\mrscp\AppData\Roaming\Godot\export_templates\4.7.1.stable\`.
  Confirmed `android_debug.apk`/`android_release.apk`/`android_source.zip` present.
- **NDK** — not installed, and not needed yet. Only required if the project later turns on
  Gradle Build (custom Android permissions, native plugins) — the default Godot Android
  export path doesn't need it.
## Slice 2.5 — DONE, visually confirmed
`godot/scenes/TestRoom.tscn` (+ `TestRoom.gd`, `Player.gd`) — minimal scene, set as the
project's `run/main_scene`:
- A placeholder player: a drawn crimson square (`Player.gd`, `_draw()`/`queue_redraw()`, no
  real art yet) that moves with arrow keys — a stopgap until touch controls (Slice 2.6).
- A `HeatLabel` + `AddHeatButton` wired directly to `GameState.modify_heat(10.0)`, so pressing
  the button (or the H key) visibly bumps the Heat value on screen.
- Room named `TestRoom` deliberately, to match the default value already hardcoded in
  `GameState.gd`'s `last_scene` field.
- CI extended with a second check that boots this scene headless
  (`godot --headless --path godot --quit`) and greps for script/load errors — confirmed
  green, so the scene compiles and boots cleanly with no errors.
- **Architect confirmed (2026-07-19) the heat system actually works in the running editor** —
  pressing the button/H visibly updates the Heat label. This was the real "does this behave
  correctly" checkpoint, not just CI's compile-time check. `GameState` reads/writes are
  confirmed working end-to-end at runtime.

**Still not attempted:** an actual `--export-debug` APK build. Toolchain is fully in place
(Slice 2.4) but no export has been tried yet, locally or via CI.

## PR workflow note
PR #1 (`.uid` sidecar files generated by the editor, plus a minor `project.godot` field-order
normalization) was opened, confirmed CI-green, and squash-merged into `main` on 2026-07-19.
First use of a feature branch + PR in this project — everything before that went straight to
`main`. No preference stated yet on whether that should be the norm going forward; ask if
unclear next time a PR-worthy change comes up, or just keep pushing to `main` directly for
solo-authored slices — either is fine until told otherwise.

## Slice 2.6 — DONE and confirmed
`godot/scenes/VirtualJoystick.gd` — draggable on-screen joystick, added to `TestRoom.tscn`
under `CanvasLayer`, anchored bottom-left (150×150, 20px margin). Exposes `output: Vector2`
(normalized, dead zone 0.15), handles both touch and mouse drag, `Player.gd` reads it with
an arrow-key fallback.
- **Bug found + fixed:** `Player._ready()` looked up the joystick via
  `get_tree().get_first_node_in_group("virtual_joystick")` before `VirtualJoystick._ready()`
  had run (Player is declared earlier in the scene tree, and sibling `_ready()` order follows
  scene declaration order) — the lookup always returned null, silently falling back to arrow
  keys forever. Fixed by deferring the lookup (`call_deferred`) to after the whole tree's
  `_ready()` pass completes.
- **Input latency tightened:** Architect noticed a slight but real drag lag after the fix.
  Added `[input_devices]` `buffering/agile_event_flushing=true` and
  `buffering/use_accumulated_input=false` to `project.godot` — Godot's own documented fix for
  exactly this (input events get flushed eagerly instead of batched once per frame).
- **Architect confirmed the joystick moves the player correctly**, both before and after the
  latency fix.

## Slice 2.7 — DONE: first real APK built and verified
This is the real milestone — proof the entire toolchain (Slice 2.4) actually produces a
working build, not just that it's installed:
- Found `config/icon="res://icon.svg"` in `project.godot` referenced a file that never
  actually existed (project was hand-assembled, not created via Godot's New Project wizard,
  which normally auto-generates one). Added a placeholder `godot/icon.svg` before it could
  cause an export failure.
- `godot/export_presets.cfg` — one Android preset (`com.zowskyy.crxcibl3`, debug-signed,
  non-Gradle build). Deliberately points `keystore/debug` at a project-relative
  `res://debug.keystore` rather than relying on per-machine global editor settings, so the
  exact same preset config works identically on this machine and in CI. A matching local
  keystore was generated at `godot/debug.keystore` (gitignored — not committed; not a real
  secret, it's the well-known debug alias/password, but binaries don't belong in the repo).
- New CI job `android-build` (`.github/workflows/godot-check.yml`, gated on `check` passing
  first): installs JDK (`actions/setup-java`) + Android SDK (`android-actions/setup-android`)
  + Godot's export templates (`chickensoft-games/setup-godot` with `include-templates: true`),
  generates the same debug keystore, points Godot's CI-local editor settings at the SDK
  (writes a minimal `editor_settings-4.7.tres` to `~/.config/godot/`, mirroring what was done
  locally), runs `--export-debug`, and uploads the APK as a build artifact.
- **First attempt failed** with a clean, specific error: `ETC2/ASTC texture compression is
  required for Android export`. Fixed with one project setting:
  `[rendering] textures/vram_compression/import_etc2_astc=true`.
- **Second attempt succeeded.** Downloaded and verified the artifact — 28.2 MB, a well-formed
  APK containing `AndroidManifest.xml`, `classes*.dex`, and `lib/arm64-v8a/libgodot_android.so`.
  Sent to the Architect for sideload testing on an actual phone.

**On-device confirmed:** Architect tested on a Pixel 8a emulator (via Android Studio's Device
Manager) and a real Samsung Galaxy A37 — installs and runs correctly on both, joystick moves
the player, matches editor behavior. Note for later: `godot-engine` was used as the `path`
override for `chickensoft-games/setup-godot` in both CI jobs (default is `godot`, which would
collide with this repo's own `godot/` project folder — worth remembering if adding more
Godot-related Actions later).

## Slice 2.8 — DONE: cross-device scaling
- Set a 384×216 base viewport with `canvas_items` stretch + `expand` aspect (`project.godot`),
  so the game scales to fill any screen instead of rendering at a fixed tiny size.
- Architect reported the UI still looked "way too big" on the real Galaxy A37 after that.
  **First diagnosis was wrong:** guessed it was a portrait/landscape orientation mismatch and
  added `window/handheld/orientation="landscape"` — but the "too big" screenshot before and
  after that fix were pixel-identical, meaning orientation was never the actual problem. Note
  for future slices: don't ship a plausible-sounding fix without confirming it actually
  changes the observed symptom.
- **Actual root cause, found by working the math instead of guessing again:** the virtual
  joystick's `150×150` pixel footprint was set against the `384×216` design canvas with no
  regard for what fraction of the screen that is — **69% of the design canvas height**.
  `canvas_items` stretch preserves that ratio when scaling to any real device resolution, so
  it was always going to look identically oversized everywhere, which is exactly why the
  emulator and the real phone looked the same both times.
- Fixed by shrinking the joystick control to `56×56` (radius 20, knob 9) — roughly 26% of
  design-canvas height, a normal proportion for a mobile joystick HUD element. Documented the
  design-space-vs-device-pixel math directly in `VirtualJoystick.gd` as a comment, so future
  HUD/UI sizing in this project doesn't repeat the same mistake.
- **Not re-confirmed on-device** — Architect explicitly asked to stop the test-and-report loop
  and move forward, trusting the corrected math instead. Verified by calculation only:
  player (16px / 216 ≈ 7%), joystick (56px / 216 ≈ 26%), debug label/button (40px / 216 ≈
  18.5% height each) are all in normal ranges for their role, unlike the joystick's original
  69%. If a real proportion issue somehow remains, treat it as a new bug report, not a
  reason to revisit this reasoning — the math checks out.

## Slice 2.9 — DONE: boardwalk room with real art
`TestRoom.tscn` now has actual level geometry, not just the debug UI:
- Ground plane (640×360 room), 3 buildings, 2 fence segments — all `StaticBody2D` +
  `CollisionShape2D`, real collision (not just visual placeholders).
- `Camera2D` added as a child of Player, `limit_left/top/right/bottom` set to the room
  bounds so it stops scrolling at the edges instead of showing empty space beyond them.
- **Player upgraded from `Node2D` to `CharacterBody2D`** (`velocity` + `move_and_slide()`).
  It previously had no physics body at all — before this change, it would have walked
  straight through the new obstacles regardless of their collision shapes.

**Real art wired in, not placeholders — this took an extra correction pass:**
- Discovered `crxcibl3art/` and `assets/` (the folders with all the curated/background-removed
  art) sit at the repo root, *outside* `godot/`'s project root — Godot's `res://` filesystem
  can't see them. Initially built the room with plain colored `Polygon2D` shapes instead
  (matching the Phaser prototype's own placeholder approach) to avoid derailing into an
  asset-pipeline tangent mid-slice.
- Architect asked to bring real art in. Built a visual gallery artifact of building/fence
  candidates (grouped by role: liquor/storefront, arcade, apartment tower, fence) so the
  Architect could pick the canonical asset per slot rather than me guessing aesthetically —
  I'd already done the mechanical background-removal matching in an earlier session, but
  hadn't made "this is THE liquor store" calls, and several files are near-duplicate variants
  (`arcade1-4`, `chainlink1-4`, etc.).
- Architect picked: `urban storefront4` (liquor store), `arcade2` (arcade), `apart3`
  (apartment tower), `chainlink2` (fence). Copied into `godot/assets/buildings/` — inside the
  project root this time, so `res://` can reach them — with corrected extensions (two of the
  picks were PNG data misnamed with a `.jpg` extension, confirmed via `Image.format`, not just
  guessed). Scale factors for each `Sprite2D` were computed from each source image's actual
  pixel dimensions (512–1024px sources → target ~64–90px world footprint), not eyeballed —
  a deliberate callback to the joystick sizing mistake from Slice 2.8.
- **New CI bug found and fixed:** first push failed with `No loader found for resource` —
  image resources need a Godot *import* pass before they're loadable (unlike `.gd` scripts,
  which don't need one). Since these were added via a plain file copy rather than through the
  editor, no `.import` metadata existed yet, and CI's `--quit` boot doesn't perform first-time
  imports. Fixed by adding `godot --headless --path godot --import` as an explicit CI step
  before any boot check — this makes CI self-sufficient going forward; new assets no longer
  depend on remembering to open the editor locally first.
- APK built successfully with the real art and sent to the Architect. Not yet confirmed
  on-device (Architect has been doing that verification themselves without reporting back
  every time per their standing "move forward" instruction from Slice 2.8 — treat silence as
  not-yet-checked, not as a failure).
- **Follow-up fix, same day:** Architect reported buildings read too close in size to the
  player. Checked actual non-transparent content bounds first (68–96% of each canvas is real
  artwork, ruling out alpha-padding as the cause) — the original scale factors were just too
  conservative. Recomputed from each image's real visible-content bbox, targeting ~120–150px
  displayed footprint (~7–9x the player's 16px, comfortably past the requested 30% minimum).
  Widened the room 640×360 → 960×540 so bigger buildings have room to be spaced out, updated
  `Camera2D` limits and collision box sizes (130×130 buildings, 100×90 fence — the fence art
  is a squarish isometric crop, not a thin horizontal strip) to match.

## Slice 2.10 — DONE: real Heat meter HUD
`godot/scenes/HeatMeter.gd` — replaces the plain "Heat: X / 100" debug `Label` from Slice 2.5
with a custom-drawn meter, same idiom as `VirtualJoystick.gd`'s own `_draw()` approach:
- Background track + a fill rectangle sized to `GameState.heat / GameState.HEAT_MAX`, colored
  with the same orange (`Color(1.0, 0.4, 0.0)`) already established as the heat/signOrange
  color across the Phaser reference palette and lore docs.
- Numeric readout drawn over the bar (`HEAT  N / 100`).
- Polls and redraws every `_process()` frame rather than needing an explicit refresh call —
  `TestRoom.gd` previously called `_refresh_label()` manually after every heat change; that's
  gone now, and the meter reflects heat changes from *any* source, not just the debug button.
- The debug "Add Heat" button / H key from Slice 2.5 stayed as-is — still useful for testing,
  the label it used to update was always the placeholder, not the button itself.
- `GameState.heat` was already real data since Slice 2.5 (confirmed working end-to-end back
  then) — this slice was purely about the HUD's visual presentation, not the data wiring.

## Follow-up, same day: building sizes matched and confirmed
Architect sent screenshots showing the arcade and apartment tower reading noticeably smaller
than the liquor store despite the earlier "7-9x player size" math targeting comparable
footprints. Rather than re-derive the math, matched world footprint directly to the
Architect-confirmed reference (liquor_store, 1024px canvas × 0.2 scale ≈ 205 world units):
arcade bumped to 0.4 scale, apartment tower to 0.41 — both now ≈205 units too. Room widened
960×540 → 1100×600, all positions/collision boxes (130→190) and `Camera2D` limits updated to
fit without overlap. **Architect confirmed this looks right ("great") — closed, no further
action needed here.**

## Slice 2.11 — DONE: first real playable hero
Replaced the placeholder crimson square with `assets/heroes/hero_enforcer_ghost.png` in
`godot/assets/heroes/` — the same asset the Phaser prototype used as its own first real art
integration, kept for continuity. This also resolved the mystery from the earlier art
restoration: the unmatched trenchcoat character sitting in `crxcibl3art/needs_review/`
(`alpha_crop_12`/`object_16`) is this exact character — Ghost (Victor Reyes).
`Player.gd` now has real stats: `MAX_HEALTH=120`, `MELEE_DAMAGE=15`, matching
`configs/game_config.json`'s `hero_health`/`hero_damage.enforcer` (hardcoded — no
JSON-loading infrastructure exists yet). Added `take_damage()`/`is_dead()` as forward-looking
scaffolding for 2.12's enemy, not full combat. Sprite scaled to ~40 world units tall (source
238×628, scale 0.064), offset so the character's feet align with the existing 16×16 collision
box instead of floating above it.

## Slice 2.12 — DONE: first enemy
`godot/scenes/Enemy.gd` — rival crew grunt, placeholder dark square (no enemy art exists yet,
same "behavior before art" pattern as the player and buildings had before their real art
landed):
- Idle until the player is within `DETECTION_RADIUS` (150 units), then chases via
  `move_and_slide()`.
- Attacks on contact (`ATTACK_RANGE` 20) with a 1s cooldown, dealing 8 damage through the
  player's `take_damage()` from Slice 2.11.
- 40 HP, `queue_free()`s at 0 — no death animation/effects yet, just despawns.
- `Player.gd` now calls `add_to_group("player")` in `_ready()` so the enemy can find it via
  `get_tree().get_first_node_in_group()` — same deferred-lookup pattern as the joystick
  (Slice 2.6), since sibling `_ready()` order depends on scene declaration order.
- One `Enemy1` instance placed in `TestRoom.tscn`, positioned just outside the player's
  starting detection range so approaching it demonstrates the idle→chase transition rather
  than starting mid-chase.

**Not yet built:** any player-side combat (no attack input exists — the player can be hit but
can't hit back yet), damage feedback/UI (health has no on-screen indicator), or death handling
for either side beyond the enemy's `queue_free()`. These are natural next steps but weren't
in this slice's stated scope ("chase/attack AI" describes the enemy, not player combat).

## Slice 2.13 — DONE: Stress hooks wired into real combat
- `Enemy.gd` calls `Stress.enter_combat()`/`exit_combat()` on the transition (not every frame)
  of the player entering/leaving `DETECTION_RADIUS` — Stress climbs for the whole chase, not
  just the moment of a hit. Guarded against the enemy dying mid-combat: `queue_free()` stops
  `_physics_process` forever, which would've left `Stress._in_combat` stuck `true` with no
  decay ever applying again, so `take_damage()` clears it explicitly before freeing.
- `Enemy._try_attack()` calls `Stress.on_hit_taken()` on a successful hit.
- `Player.take_damage()` calls `Stress.on_crew_member_downed()` once (guarded against firing
  again on repeat hits at 0 HP) when health first reaches 0.
- `Stress.on_hit_dealt()` and `on_crew_member_ghosted()` are **not wired** — no player attack
  input exists (player can be hit but can't hit back), and there's no permanent-death system.
  Left honestly unwired rather than faked with a placeholder trigger.
- `TestRoom.gd` now calls `Stress.tick(delta)` every frame — nothing else in the scene owned
  a per-frame tick, and `tick()` is what applies the out-of-combat decay; without it Stress
  would climb but never come back down.
- `StressMeter.gd` — new debug HUD element (same idiom as `HeatMeter.gd`, purple instead of
  orange), added below the Heat bar, so this wiring is actually visible/verifiable at runtime
  instead of wired blind.

## Slice 2.14 — DONE: Metal Slug-style gun combat + Rune drops
Architect direction pivot: gun combat (Metal Slug) + Warriors (PS2)-style brawl economy,
superseding the originally-planned Crack House/Chop Shop generator for this slot.
- `Bullet.gd` — projectile built entirely in code (no saved scene), `Area2D` + programmatically
  constructed `CircleShape2D`, 400-unit speed, 15 damage, 1.2s lifetime. `Player.fire()` spawns
  one per 0.25s (Fire button / Space key) aimed in `_facing` direction.
- `Enemy.gd` drops 1 Rune per kill via `GameState.add_resource("Rune", 1)` (first use of Rune
  key — `add_resource()` creates it on demand since the initial resources dict only had
  Cash/Ammo/Intel).
- `Stress.on_hit_dealt()` wired in `Bullet._on_body_entered()` — now fires honestly since the
  player has a real attack path.
- `RuneLabel` added to `TestRoom.tscn` debug HUD, polling `GameState.resources.Rune` each frame.

## Slice 2.15 — DONE: shared group Rune pool + per-hero contribution tracking
Design goal (Architect): every player's kills add to one shared group Rune count — nobody feels
the need to get greedy. Backend fully enforces this at the data layer, not just the UI.

- `GameState.resources` now initializes `"Rune": 0` explicitly (no more first-use workaround).
- `group_upgrades: Dictionary` — keyed by upgrade id string, `true` once the group has
  purchased it. Nobody owns upgrades individually.
- `rune_contributions: Dictionary` — keyed by hero name, counts kill-generated Runes per hero.
  This is a **solidarity metric** shown in end-of-run recap, not a per-player wallet.
- `add_rune(amount, hero)` — adds to shared pool and credits the hero's contribution tally.
  Replaces the `add_resource("Rune", N)` call in `Enemy.gd`.
- `purchase_upgrade(id, cost)` — atomic: checks already-owned, checks affordability, spends,
  marks owned. Returns false on either failure, true on success. Bodega shop UI calls this.
- `has_upgrade(id)` — simple boolean gate for any gameplay system that conditionally applies an
  upgrade's effect (e.g. higher bullet damage if "power_up" is owned).
- `top_contributor()` — returns the hero with the most kill-Runes this run. Intended for
  Recap.gd's end-of-run summary ("Enforcer led the crew with 14 Runes").
- `reset_for_new_game()` clears `group_upgrades` and `rune_contributions` alongside everything
  else.
- **Kill attribution chain:** `Player.hero_name = "enforcer"` (set by whoever spawns the
  player) → stamped onto `Bullet.shooter` at fire time → passed as `killer` arg to
  `Enemy.take_damage(amount, killer)` → forwarded to `add_rune(1, killer)`. In multiplayer
  each player's node sets its own `hero_name`, so contributions track correctly without any
  extra coordination.
- `TestRoom.gd` HUD now shows `"Rune (group): N  enforcer:N"` per-hero breakdown live so the
  attribution chain is visibly verifiable during playtesting.

## Slice 2.16 — DONE: Bodega upgrade shop UI
`BodegaShop.gd` (`Node2D` at pos 200,240, just in front of `Building1`). Proximity trigger
at `TRIGGER_RADIUS = 70` units opens a centered `CanvasLayer` menu (`BodegaMenu` under the
existing `CanvasLayer`). Four upgrades purchased from the shared Rune pool:
- **Hot rounds** (3 Rune) — `bullet_damage_bonus += 10` on Player, applied to every bullet
- **Trigger work** (4 Rune) — `fire_cooldown_override = 0.12` (2× fire rate)
- **Bottomless clip** (2 Rune) — `infinite_clip = true` flag (gates future ammo system)
- **Flash** (5 Rune) — `take_damage(-40)` heals 40 HP; one per run (Warriors PS2 ref)

Buttons refresh on menu open: greyed if already owned or can't afford. All spending goes
through `GameState.purchase_upgrade()` so the shared-pool invariant holds. `take_damage()`
updated to `clampi(..., 0, MAX_HEALTH)` so negative amount (heal) correctly caps at max HP.

## Slice 2.16-shader — DONE: dissolve + wave shaders (ported from alfredbaudisch/godot-shaders)
Two Godot 3 shaders ported to Godot 4 (`.gdshader` extension, `hint_color → source_color`):

**`enemy_dissolve.gdshader`** — noise-based 2D dissolve for enemy death:
- `ShaderMaterial` built in code in `Enemy._ready()`, applied to the enemy node's `material`.
- `dissolve_progress` uniform ramps 0→1 over `DISSOLVE_TIME = 0.5s` in `_physics_process`.
- `queue_free()` fires when progress reaches 1.0. Enemy stops chasing/attacking immediately
  on `take_damage()` hitting 0 HP (`set_physics_process(false)` then re-enabled for dissolve).
- Rune drop and combat exit happen at kill time (not after dissolve) so the HUD ticks on the
  killing shot and Stress clears immediately.
- `border_color` defaults to `(1.0, 0.4, 0.0)` — the existing Heat orange.
- No noise texture wired yet (shader gracefully handles null sampler); add a noise `.png` to
  `assets/shaders/` and set the `noise_texture` param when real art lands.

**`heat_wave.gdshader`** — full-screen wave distortion:
- `ColorRect` on `WaveOverlayLayer` (`CanvasLayer` layer 2, above HUD at layer 1).
- `mouse_filter = 2` so clicks pass through.
- `intensity` uniform: 0.0 below heat 51, ramps to 1.0 at heat 100.
  Uses the same 51 breakpoint as the visual direction doc's vignette/tint threshold —
  consistent sensory escalation. `TestRoom._process()` calls `set_shader_parameter` each frame.

## Slice 2.17 — DONE: Crack House spawn generator
`SpawnGenerator.gd` (`StaticBody2D` so bullets can collide with it):
- Spawns up to `SPAWN_CAP = 3` enemy grunts every `SPAWN_INTERVAL = 6s`.
- Each spawned enemy is built fully in code (same pattern as bullets): `CharacterBody2D` +
  `Enemy.gd` script + `CollisionShape2D`, added to the scene's parent.
- **Two-phase clearing:** shoot stash to `GENERATOR_HP = 0` *and* have zero live spawns.
  If the stash hits 0 with spawns still alive, HP clamps to 1 so it stays hittable until
  the last grunt is down — forces the player to mop up before getting the reward.
- On clear: `GameState.group_upgrades["cleared_<id>"] = true` (persists across reloads),
  `GameState.modify_heat(-20.0)` (heat reward), `queue_free()`.
- `Bullet.gd` now hits both `enemy` and `spawn_generator` group nodes.
- Placed in `TestRoom` at (850, 460) near the right fence, `generator_id = "crack_house_1"`.
- Placeholder visual: dark red square with an X (`_draw()`), same "behavior before art" pattern.

## Slice 2.20 — DONE: The Emperor confrontation (Act 3 finale)
`EmperorScene.tscn` + `EmperorScene.gd` — the Emperor's Estate in The Hills, reached
automatically when the car chase (2.19) ends. Two-part structure per the Architect's
tag-team design note:
- **Blackwood's final stand:** `BossBlackwood.gd` gained an exported `final_stand` flag
  (set in the scene, default false so the rooftop is untouched). When true: no SURPRISED
  phase (he's guarding the Emperor, expecting the crew) and no flee — fights to 0 HP,
  fades out, emits `defeated(finisher)`. Scene records it via
  `GameState.mark_boss_defeated("Blackwood", true, finisher)` — the finisher name threads
  through the existing `Bullet.shooter` → `take_damage(killer)` chain.
- **The reckoning (non-combat, per lore):** fire button hides, a dialogue panel plays the
  Emperor's confession **verbatim from the lore doc's "Final Reckoning" scene** ("I didn't
  betray you. I made a deal with The Corrupted Six to save your lives..."). Then a choice:
  FORGIVE HIM / TURN AWAY → sets `GameState.emperor_forgiven` (field + SaveSystem
  persistence already existed, first real writer now). Forgive plays Big Body's answer from
  the lore (attributed to "CREW" since the active hero varies); turn-away plays a colder
  epitaph. Either way he dies — crew walks away, no takeover. On end: heat -50 (the war
  dies with him), `"emperor_reckoning"` appended to `quests_completed`,
  `GameState.current_act = 3` (set on scene entry — Recap's act line keys off it), and the
  **first real in-game `SaveSystem.save_game()` call** — the story milestone worth
  persisting. Then back to TestRoom (epilogue is Phase 3 scope).
- The Emperor himself is `EmperorFigure.gd` — a drawn placeholder (dark suit, gold chain,
  slumped), never a combat target, fades out via Tween when the reckoning ends.

**Two real pre-existing bugs found and fixed while building this:**
1. **`Bullet.gd` never included `"boss"` in its group check** — bullets flew straight
   through Blackwood on the rooftop, so the 33 HP flee threshold (and this scene's final
   stand) was unreachable by gunfire. Nothing in 2.18's notes claims the fight was
   playtested to completion, which is consistent. Added `boss` to the hit groups.
2. **Stuck Stress combat flag on deacon cleanup:** Blackwood `queue_free()`d his deacons
   directly on flee (and now on death). `Enemy.gd` only clears its Stress combat state via
   its own `take_damage` path, so a mid-chase force-free left `Stress._in_combat` stuck
   true forever (no decay ever again). Added `Enemy.despawn()` — clears the flag, then
   frees — and both Blackwood cleanup paths use it.

**CI extended:** new step boots *every* scene in `godot/scenes/` headless (not just the
main scene) — RooftopScene/CarChaseScene/EmperorScene are only reachable via gameplay
transitions, so the main-scene boot check alone never compiled their scripts.

## Slice 3.1 — DONE: player health HUD + downed/respawn state
`HealthBar.gd` — same self-drawing `_draw()` idiom as `HeatMeter.gd` / `StressMeter.gd`.
Green fill bar proportional to `player.health / MAX_HEALTH`; turns red and shows
"DOWNED — respawning..." text when `player.is_dead()`. Finds the player via
`get_first_node_in_group("player")` (deferred, same race-condition fix as VirtualJoystick
and Enemy.gd). Added to `CanvasLayer` in `TestRoom.tscn`, `RooftopScene.tscn`, and
`EmperorScene.tscn` — not CarChaseScene, which uses `PlayerCar.gd` and already has its
own `hp_label`.

**Player.gd changes:** `downed` and `respawned` signals added. `take_damage()` now
freezes `_physics_process` when health first hits 0 (no more sliding into enemies while
dead) and kicks off a `_start_respawn()` coroutine (`await create_timer(RESPAWN_TIME)`).
After `RESPAWN_TIME = 3.0s`, health restores to `MAX_HEALTH`, physics re-enables, and
`respawned` emits. Permanent death is a separate Phase 3 mechanics module (PermanentDeath
from `Stress.gd`'s template list) — this is the soft-death / checkpoint respawn layer.

## Slice 3.2 — DONE: HUD cleanup
Permanent meters moved to compact corner positions (130×18 px each, 4px margin):
- **HealthBar** — top-left, offsets `4, 4 → 134, 22` (all three scenes).
- **HeatMeter** — top-right, `anchor_left/right = 1.0`, offsets `-134, 4 → -4, 22` (all three scenes).

Font size dropped 13→11 in both meter scripts; text shortened to `"HP N"` and `"HEAT N"` to
fit the narrower bar without wrapping. "DOWNED..." replaces the longer "DOWNED — respawning..."
in HealthBar for the same reason.

Debug elements removed from all scenes:
- **TestRoom:** `AddHeatButton` node, `StressMeter` node + `ExtResource("11")` reference,
  `RuneLabel` node. `TestRoom.gd` stripped of the matching `@onready` vars, the
  `add_heat_button.pressed.connect()`, and the rune-contribution polling loop. `load_steps`
  22→21. H-key shortcut + `_on_add_heat_pressed()` method retained for heat testing.
- **RooftopScene:** `StressLabel` node removed; `RooftopScene.gd` `@onready var stress_label`
  and its `_process` update removed.
- **EmperorScene:** same `StressLabel` removal in `.tscn` and `.gd`.

## Slice 3.3 — DONE: Stress gameplay consequences
`Player.gd` now reads `Stress.stress` every physics frame and applies two graduated penalties:

- **Elevated (stress ≥ 40):** movement speed ×0.85 (120 → 102 units/s).
- **Critical (stress ≥ 75):** speed ×0.70 (120 → 84 units/s) AND fire cooldown ×2.0
  (0.25s → 0.50s — roughly half the normal rate of fire).

Implementation: `_stress_speed_mult()` helper (3 lines) read in `_physics_process`;
`fire()` computes a `stress_mult` before setting `_fire_timer`. Uses the threshold
constants already defined in `Stress.gd` (`THRESHOLD_ELEVATED = 40`, `THRESHOLD_CRITICAL = 75`)
— no new data, no new signals, no new files.

Effect on gameplay loop: taking repeated hits in a long fight escalates into the player
moving sluggishly and shooting slowly, naturally rewarding spacing and retreating to let
Stress decay before re-engaging. Matches the intended "fraying nerves" narrative of the meter.

## Slice 3.4 — DONE: all mechanics modules wired into gameplay

All 12 stub autoload modules (registered since earlier slices but calling nothing) are now
wired into real gameplay events. No new files — every change was an additive hook into
existing scenes and `GameState.reset_for_new_game()`.

**Per-frame ticks added** — all four scenes (`TestRoom`, `RooftopScene`, `CarChaseScene`,
`EmperorScene`) now tick `Morale`, `Injury`, `DialogueIntensity`, `Hideout`, and `Scarcity`
alongside the existing `Stress.tick()` call.

**Event hooks wired:**
- `Player.take_damage()` → `Injury.on_hero_downed()` on first death hit.
- `BossBlackwood._trigger_flee()` → `Bosses.register_boss_defeat("Blackwood_rooftop",
  finisher, false)` + `Morale.on_boss_defeated()` + `Reputation.on_boss_spared()` +
  `DialogueIntensity.on_boss_defeated(false)`. Removed the duplicate bare
  `GameState.bosses_fought.append` from `RooftopScene._on_boss_fled()`.
- `BossBlackwood._die()` (final stand) → same set with `executed=true`,
  `"Blackwood_final"`, and `Reputation.on_boss_executed()`.
- `RooftopScene._ready()` → `DialogueIntensity.on_boss_encountered("Blackwood")`.
- `EmperorScene._ready()` → `DialogueIntensity.on_boss_encountered("Emperor")`.
- `EmperorScene._on_blackwood_defeated()` → `Emperor.start_reckoning()`. Removed old
  bare `GameState.mark_boss_defeated("Blackwood", ...)` — now handled by `Bosses`.
- `EmperorScene._choose()` → `Emperor.on_emperor_choice(forgive)` +
  `DialogueIntensity.on_dialogue_choice_made(15)` + `Reputation.on_crew_saved()` /
  `on_boss_executed()`.
- `EmperorScene._end_reckoning()` → `Morale.on_quest_completed(20)` +
  `Emperor.on_emperor_death()` + `Epilogue.start_epilogue()`. Removed inline quest append
  and `modify_heat(-50.0)` — both now inside `Emperor.on_emperor_death()`.

**New-game reset** — `GameState.reset_for_new_game()` now calls `reset()` on all 13
mechanics singletons. Previously a new game kept stale Stress / Injury / Morale state.

**Not wired (intentional):**
- `Alliance` / `Blame` — no faction or friendly-fire trigger exists yet; `reset()` wired.
- `PermanentDeath` — soft-respawn means no permanent deaths yet; hook exists for Phase 3.
- `Scarcity` — ticks/decays live; raise trigger will land when ammo economy is built.
- `Hideout` — ticks; `enter_hideout()` wired but no safe-house zone in any scene yet.

## Blocking / needs Architect input
- Still open: does the Phaser web build stay alive as a reference, or is it fully retired
  now that Godot is confirmed as the real target? (Carried over from a previous slice,
  still unresolved.)
- Getaway sequence design — shared mechanic across levels, or unique per level?
