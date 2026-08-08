# Agent Instructions — GA-READY ONLY

**Single source of truth:** [`.cursor/rules/ga-system-prompt.mdc`](.cursor/rules/ga-system-prompt.mdc)

All prior policies (ship-finished-work, quarterback-worker, gate-only `.cursorrules`) are **retired**. Only the GA system prompt applies.

## Quick reference

- Memory: `CONTEXT.md` (project root, update every major interaction)
- Checkpoint: `~/.crawler/state.json` via M2M modules
- Verification: `godot/tools/ci_autoload_check.gd`, `godot/tools/ci_slug_hud_smoke.gd`, `godot/tools/ci_scene_flow_smoke.gd`
- Gates: `python3 ~/.cursor/cursor_gate_fastest.py` + `python3 ~/.cursor/cursor_gate.py` on every changed file

## Taylor workers

Main agent delegates 3+ file work to Task subagents; workers implement and gate; main agent re-gates and delivers.
