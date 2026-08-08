# CRXCIBL3

> **Beach Boulevard — Godot 4.7.1 crew shooter with a JSON-driven cutscene system for the Emperor reckoning, Blackwood arc, and future Corrupted Six bosses.**

[![Godot 4.7.1](https://img.shields.io/badge/Godot-4.7.1-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-blue.svg)](CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Web%20%7C%20Windows%20%7C%20Linux-lightgrey)](godot/export_presets.cfg)

---

## Quickstart

```bash
# 1. Clone / open this repo
# 2. Install Godot 4.7.1 — https://godotengine.org/download
# 3. Godot Project Manager → Import → godot/project.godot
# 4. Press F5 — Main menu → New Game → hero selection → boardwalk TestRoom

# Optional: regenerate brand icon
python3 scripts/generate_icon.py

# Optional: structural checks (no Godot editor required)
python3 scripts/check_tscn.py
python3 scripts/check_gd.py
```

**Play the story arc:** TestRoom → rooftop trigger (Building3) → Blackwood fight → car chase → Emperor estate reckoning → epilogue.

---

## What's built

| Area | Status |
|------|--------|
| **Boardwalk combat** | Heat / stress / HP, enemies, bodega shop, hideout, crack-house generator, squad TAB switch |
| **Blackwood arc** | Rooftop surprise → car chase → Emperor final stand → JSON reckoning → epilogue |
| **Cutscene system** | `CutsceneDirector` beat sequencer + `DialogueBox` UI + JSON data in `godot/data/` |
| **25 autoloads** | GameState, Stress, SaveSystem, Bosses, Emperor, Epilogue, … |
| **12 heroes** | From `configs/game_config.json` via HeroDefinitions / HeroFactory |
| **5 future bosses** | Cross, Voss, Moreau, Hayes, Webb — data-templated (`bosses.json` + beat template) |
| **Export** | Android, Web, Windows Desktop, Linux/X11 presets; CI debug APK artifact |

Phaser 3 web prototype under `js/` is **legacy reference only**.

---

## Cutscene beats (Slices 3.18+)

Hand declarative beats to `CutsceneDirector.play()`:

```gdscript
CutsceneDirector.play("emperor", [
    { "type": "line", "speaker": "EMPEROR", "text": "I didn't betray you.",
      "gesture": "lookaside", "target": "emperor", "duration": 3.0 },
    { "type": "choice", "choices": [
        { "id": "forgive", "label": "FORGIVE HIM" },
        { "id": "turn_away", "label": "TURN AWAY" } ] },
    { "type": "branch", "map": {
        "forgive": "@forgive_sequence",
        "turn_away": "@turn_away_sequence" } },
])
```

Live sequences: `godot/data/emperor_scene.json`, `godot/data/blackwood_scene.json`.

---

## Project layout

```
.
├── godot/                      # ← open this in Godot
│   ├── autoload/               # 25+ singletons incl. CutsceneDirector, GameState
│   ├── scenes/                 # MainMenu, TestRoom, Blackwood arc, DialogueBox, …
│   ├── data/                   # JSON beat sequences + boss metadata
│   ├── assets/                 # Sprites, shaders, audio/ (VO drop-in)
│   ├── configs/game_config.json
│   ├── export_presets.cfg      # Android / Web / Windows / Linux
│   └── project.godot           # version 1.0.0, brand icon
├── scripts/                    # generate_icon.py, check_tscn.py, check_gd.py, gates
├── CHANGELOG.md
├── ATTRIBUTIONS.md
├── LICENSE                     # MIT code; story/characters reserved
└── README.md
```

---

## Adding a new boss (Slices 3.18–3.23)

1. Copy `godot/data/_beat_encounter_template.json` → `godot/data/fixer_scene.json` (beat sequences).
2. Add combat metadata to `godot/data/bosses.json` (HP, phases, gimmick).
3. Create `BossX.gd` / scene modeled on `BossBlackwood.gd`.
4. Register id in `Bosses.gd` `BOSS_LIST`.
5. Wire a level trigger; CI headless-boots every `godot/scenes/*.tscn`.

See `godot/assets/audio/MANIFEST.txt` for VO filenames.

---

## Export

1. **Editor → Manage Export Templates…** — download Godot 4.7.1 templates.
2. **Project → Export…** — pick Android / Web / Windows / Linux.
3. Friends sideload: push to `main`, download `crxcibl3-debug-apk` from GitHub Actions.

---

## Documentation index

| Doc | Purpose |
|-----|---------|
| [CHANGELOG.md](CHANGELOG.md) | Release history |
| [ATTRIBUTIONS.md](ATTRIBUTIONS.md) | Engine / tool credits |
| [CREDITS.md](CREDITS.md) | Art credits |
| [PROJECT_STATE.md](PROJECT_STATE.md) | Slice-by-slice build log |
| [PROJECT_BLUEPRINT.md](PROJECT_BLUEPRINT.md) | Roadmap checklist |
| [godot/assets/audio/MANIFEST.txt](godot/assets/audio/MANIFEST.txt) | VO WAV filenames |

**Godot:** 4.7.1 · **Project version:** 1.0.0 · **Updated:** 2026-08-08
