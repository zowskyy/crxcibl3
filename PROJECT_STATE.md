# CRXCIBL3 — Project State

Last updated: 2026-07-19 (Slice 2.4 — Android build toolchain fully set up)

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
## Slice 2.5 — DONE (code side), NOT YET VISUALLY VERIFIED
`godot/scenes/TestRoom.tscn` (+ `TestRoom.gd`, `Player.gd`) — minimal scene, set as the
project's `run/main_scene`:
- A placeholder player: a drawn crimson square (`Player.gd`, `_draw()`/`queue_redraw()`, no
  real art yet) that moves with arrow keys — a stopgap until touch controls (Slice 2.6).
- A `HeatLabel` + `AddHeatButton` wired directly to `GameState.modify_heat(10.0)`, so pressing
  the button (or the H key) visibly bumps the Heat value on screen — the actual proof that
  `GameState` reads/writes work at runtime, which was the point of this slice.
- Room named `TestRoom` deliberately, to match the default value already hardcoded in
  `GameState.gd`'s `last_scene` field.
- CI extended with a second check that boots this scene headless
  (`godot --headless --path godot --quit`) and greps for script/load errors — confirmed
  green, so the scene compiles and boots cleanly with no errors.

**What CI does *not* prove:** that the label/button actually look right or respond correctly
to a click, or that `--export-debug` actually produces a working APK. CI only catches
compile/load errors, not visual or interactive correctness, and no export has been attempted
yet (still avoiding local Godot invocations from a shell after the earlier GUI-dialog
incident). **Architect action needed:** open the project in the editor, run the scene
(F5) to confirm heat updates visibly on click/H-press, and — once that looks right —
either run a test export from the editor's Export menu, or ask to have it attempted via CI
(GitHub Actions can build the APK too, using the same free toolchain, as a follow-up).

## Next slice (2.6)
Touch controls — replace `Player.gd`'s arrow-key input with a virtual joystick or
tap-to-move scheme, since the confirmed target is mobile and arrow keys won't exist there.

## Blocking / needs Architect input
- Visual/interactive confirmation of the TestRoom scene (see above) — first real "does this
  actually work" checkpoint since CI only proves it compiles, not that it behaves correctly.
- Still open: does the Phaser web build stay alive as a reference, or is it fully retired
  now that Godot is confirmed as the real target? (Carried over from a previous slice,
  still unresolved.)
