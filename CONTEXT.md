# CRXCIBL3 — Agent Context Memory

**Last updated:** 2026-08-08T03:00:00Z  
**Branch:** `cursor/godot-export-release-audit-c071`  
**Version:** 1.3.2  
**Policy:** GA-READY ONLY — `.cursor/rules/ga-system-prompt.mdc` (all other rules retired)

## Current State

- **UI:** SlugHud / SlugHudTheme — MS × OC underground, no player HP bar
- **M2M:** Co-op stable; checkpoint via `M2MCheckpoint` → `~/.crawler/state.json`
- **Release:** [v1.3.2-playtest](https://github.com/zowskyy/crxcibl3/releases/tag/v1.3.2-playtest)

## Verification (run before delivery)

```bash
cd godot
godot --headless -s res://tools/ci_autoload_check.gd
godot --headless -s res://tools/ci_slug_hud_smoke.gd
godot --headless -s res://tools/ci_m2m_checkpoint_smoke.gd
godot --headless -s res://tools/ci_scene_flow_smoke.gd
```

## Key Paths

| Area | Path |
|------|------|
| GA rules | `.cursor/rules/ga-system-prompt.mdc`, `AGENTS.md`, `CONTEXT.md` |
| HUD | `godot/scenes/ui/SlugHud.gd`, `SlugHudTheme.gd` |
| M2M | `M2MCheckpoint.gd`, `M2MResilienceCore.gd`, `CoopNetwork.gd` |
| CI | `godot/tools/ci_*.gd` |

## GA Status

| Gate | Status |
|------|--------|
| Placeholders (`pass`/stubs) | ✅ Cleared (HealthBar/HeatMeter deleted) |
| Verification harness | ✅ 4 CI smoke scripts |
| Checkpoint | ✅ M2MCheckpoint save/load |
| Memory state | ✅ This file |
| Code gates | ✅ Re-gate on every changed file |

## Taylor Workers

Main agent delegates 3+ file tasks; workers implement + gate; main agent re-gates and delivers.
