# CRXCIBL3 — Project State

Last updated: 2026-07-19 (Slice 2.2 — engine pivot back to Godot)

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
- `project.godot` — already configured for Godot **4.3**, with the **"Mobile" feature
  preset already set**. Confirms mobile was the plan even in the earlier Godot pass.
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
installer needed — just run the exe). Note: the project file targets Godot 4.3 features;
opening it in 4.7.1 will likely prompt an auto-upgrade of the project version tag — expected
and fine, not a data-loss risk for a project this small.

## Mobile/Android target
Confirmed goal: build an installable `.apk` to share directly with friends (sideload),
**not** a Play Store release — this drops Play Console/store-listing/compliance scope
entirely. Still needed before a build is possible:
- Android SDK + NDK + JDK installed and pointed to from Godot's Editor Settings →
  Export → Android (one-time, mostly automatable).
- A signing keystore (`keytool`, fully scriptable, no cost).
- Godot's Android export templates (free, downloadable from within the editor or via CLI).
- Touch controls — nothing built yet, WASD assumption from the Phaser prototype won't
  carry over.

## Next slice (2.3)
1. Open `crxcibl3/godot/` as a project in the Godot editor (Architect, one click — Import →
   point at `godot/project.godot`).
2. Register the four existing scripts as Autoloads in Project Settings, **in dependency
   order**: GameState → Stress → SaveSystem → Recap (Stress/SaveSystem/Recap all declare
   "Depends on: GameState" in their own header comments — order matters for Godot autoload
   init).
3. Set up Android SDK/NDK/JDK + export templates + keystore (mostly scriptable, will do
   once the Architect confirms the editor opens cleanly).
4. First scene: a minimal test room with a placeholder player node, just enough to confirm
   GameState reads/writes correctly at runtime before porting any real level content.

## Blocking / needs Architect input
- None currently blocking code work — SDK/export-template setup can proceed once the editor
  is confirmed working.
- Still open: does the Phaser web build stay alive as a reference, or is it fully retired
  now that Godot is confirmed as the real target? (Carried over from the previous slice,
  still unresolved.)
