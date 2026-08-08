# CRXCIBL3 — Agent Context Memory

**Last updated:** 2026-08-08T03:45:00Z  
**Branch:** `cursor/godot-export-release-audit-c071`  
**Version:** 1.3.4  
**Policy:** GA-READY ONLY — `.cursor/rules/ga-system-prompt.mdc`

## Visual Direction — GTA San Andreas (mandatory)

All UI/HUD on every screen must match **GTA SA**:
- **Top-right:** green `$` money (runes), wanted stars, weapon line
- **Bottom-left:** radar circle, red HP bar, blue armor bar
- **Menus:** dark olive/black wash, green button text, `LOS SANTOS · GROVE · SA`
- **Never:** Metal Slug, Arcane overlay, or generic placeholder boxes

Theme: `godot/scenes/ui/GtaSaTheme.gd` · HUD: `godot/scenes/ui/SlugHud.gd` (GtaSaHud)

## Current State

- **Load fix:** `MissionLaunch` autoload — deferred TestRoom load, `stop_session()` on solo
- **M2M:** Checkpoint + co-op stable
- **Release:** v1.3.4-gta-sa (pending publish)

## Verification

```bash
cd godot
godot --headless -s res://tools/ci_autoload_check.gd      # 32 autoloads incl MissionLaunch
godot --headless -s res://tools/ci_slug_hud_smoke.gd      # GtaSaTheme
godot --headless -s res://tools/ci_m2m_checkpoint_smoke.gd
godot --headless -s res://tools/ci_scene_flow_smoke.gd    # MissionLaunch → TestRoom
bash scripts/capture_screenshots.sh                         # UI proof PNGs (required for visual fixes)
```
