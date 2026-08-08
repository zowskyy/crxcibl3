---
name: godot-android-debug
description: Godot Android release debugging worker — runs the 8-step master sequence silently until 100% pass. Use when the user invokes /debug-godot-android or asks to debug, harden, or release-build the Godot Android game.
---

# Godot Android Debug Worker

Delegate to a **Task subagent worker** that follows [`.cursor/rules/debug-godot-android.mdc`](../../rules/debug-godot-android.mdc).

## Quarterback workflow

1. Read `.cursor/rules/debug-godot-android.mdc` for the full 8-step sequence.
2. Launch a `generalPurpose` Task worker with:
   - Project root: `godot/`
   - Instruction: execute all 8 steps, loop until zero findings, gate every changed file, return file list + gate status only.
3. Merge worker changes; **re-run both gate scripts on every changed file** before delivering to the user.
4. Commit, push, and update PR.

## Worker constraints

- Worker never messages the user.
- Worker fixes issues directly; no permission prompts.
- Worker loops step 1→8 until a full re-audit is clean.
- Config/scene/asset changes do not require gate scripts; `.gd` and `.cs` files do.

## Quick invoke

User command: `/debug-godot-android`

Quarterback response to user: final report only after worker completes and quarterback re-gates.
