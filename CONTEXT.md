# CRXCIBL3 — Agent Context Memory

**Last updated:** 2026-08-08T03:35:00Z  
**Branch:** `cursor/godot-export-release-audit-c071`  
**Version:** 1.3.3  
**Policy:** GA-READY ONLY — `.cursor/rules/ga-system-prompt.mdc`

## Current State

- **UI:** GtaSaHud / GtaSaTheme — GTA San Andreas HUD on every screen (green money, wanted stars, radar, HP/armor bars, olive panels)
- **M2M:** Checkpoint → `~/.crawler/state.json`; co-op stable
- **Release:** [v1.3.3-playtest](https://github.com/zowskyy/crxcibl3/releases/tag/v1.3.3-playtest)

## Verification (run before delivery)

```bash
cd godot
godot --headless -s res://tools/ci_autoload_check.gd
godot --headless -s res://tools/ci_slug_hud_smoke.gd
godot --headless -s res://tools/ci_m2m_checkpoint_smoke.gd
godot --headless -s res://tools/ci_scene_flow_smoke.gd   # MainMenu → HeroSelection → TestRoom
```

## GA Status

| Gate | Status |
|------|--------|
| Placeholders | ✅ No bare `pass` in godot/**/*.gd |
| Verification | ✅ 4 CI smoke scripts (all PASS) |
| Checkpoint | ✅ M2MCheckpoint |
| Scene E2E | ✅ TestRoom load + player spawn verify |
| Code gates | ✅ Re-gate on every changed `.gd` |

## Taylor Workers

Main agent delegates 3+ file tasks; workers implement + gate; main agent re-gates and delivers.
