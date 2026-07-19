# CRXCIBL3 — Project State

Last updated: 2026-07-19 (Slice 2.9 — boardwalk room with real art)

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

## Next slice (2.10)
Heat HUD wired to real `GameState.heat` — the debug label/button in `TestRoom.tscn` already
proves the read/write path works (Slice 2.5); this is about a real HUD design instead of a
plain `Label`. After that, a real playable hero (2.11) and first enemy (2.12) are next per
the blueprint.

## Blocking / needs Architect input
- Still open: does the Phaser web build stay alive as a reference, or is it fully retired
  now that Godot is confirmed as the real target? (Carried over from a previous slice,
  still unresolved.)
