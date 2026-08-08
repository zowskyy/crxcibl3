# CRXCIBL3 — Agent Context Memory

**Last updated:** 2026-08-08T02:52:00Z  
**Branch:** `cursor/godot-export-release-audit-c071`  
**Version:** 1.3.2  
**Latest release:** [v1.3.2-playtest](https://github.com/zowskyy/crxcibl3/releases/tag/v1.3.2-playtest)

## Current State

Metal Slug × OC underground UI overhaul shipped. SlugHud replaces HeatMeter + HealthBar everywhere. Menus use SlugHudTheme chrome. M2M co-op stable from 1.3.1.

## Active Workstreams

| Stream | Status | Notes |
|--------|--------|-------|
| UI (SlugHud / SlugHudTheme) | **GA candidate** | No player HP bar; CREW/RUNES/WANTED |
| M2M co-op | Stable | Host picks squad → TestRoom load |
| Playtest APK | Published | `crxcibl3-playtest-v1.3.2-ms-ui.apk` |

## Key Paths

- HUD: `godot/scenes/ui/SlugHud.gd`, `SlugHudTheme.gd`
- Menus: `MainMenu.gd`, `HeroSelectionUI.gd`, `CoopLobbyScene.gd`
- M2M: `godot/autoload/M2M*.gd`, `CoopNetwork.gd`
- CI: `godot/tools/ci_autoload_check.gd`, `godot/tools/ci_slug_hud_smoke.gd`
- Docs: `docs/M2M_IMPLEMENTATION_PACKAGE.md`, `docs/COOP_MULTIPLAYER.md`

## Verification Commands

```bash
# Autoload registry (31 autoloads)
godot --headless -s res://tools/ci_autoload_check.gd

# SlugHud theme + format smoke
godot --headless -s res://tools/ci_slug_hud_smoke.gd

# Gate (per changed file)
python3 ~/.cursor/cursor_gate_fastest.py --file <path> --region us-west-2
python3 ~/.cursor/cursor_gate.py --file <path> --iterations 3
```

## Recent Decisions

1. **No player health bar** — MS crew pips + WANTED heat only; boss bars kept (MS boss fights).
2. **Arcane overlay removed** from gameplay; menus use BrawlBG + spray wash.
3. **HealthBar/HeatMeter deleted** — SlugHud is sole HUD; no orphan stubs.

## Open GA Gaps (tracked)

- M2M long-session `save_state()`/`load_state()` checkpoint (see M2MResilienceCore roadmap)
- Broader GDScript `pass` cleanup in legacy BossEncounter / RelationshipSystem hooks
- Automated headless scene-load test for MainMenu → HeroSelection path
