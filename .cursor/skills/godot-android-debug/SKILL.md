---
name: godot-android-debug
description: Godot Android game audit worker — 9 categories (export, resilience, performance, input, audio, display, multiplayer, privacy, store readiness). Use for /debug-godot-android-game or Android Play Store hardening.
---

# Godot Android Game Debug Worker

Delegate to a **Task subagent worker** that follows [`.cursor/rules/debug-godot-android-game.mdc`](../../rules/debug-godot-android-game.mdc).

## Quarterback workflow

1. Read `.cursor/rules/debug-godot-android-game.mdc`.
2. Launch a `generalPurpose` Task worker with project root `godot/`.
3. Worker emits `[C1]`–`[C9]` checkpoint lines plus evidence-based final report.
4. Merge changes; **re-run both gate scripts on every changed `.gd`/`.cs` file** before delivery.
5. Commit, push, update PR.

## Invoke

- `/debug-godot-android-game` — 9-category audit with evidence (current)
- `/debug-godot-android` — legacy 8-step silent loop ([`debug-godot-android.mdc`](../../rules/debug-godot-android.mdc))
