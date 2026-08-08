# CRXCIBL3

> **Beach Boulevard — Godot 4.7.1 crew shooter with JSON-driven cutscenes, the Blackwood arc, and all five Corrupted Six boss encounters.**

[![Godot 4.7.1](https://img.shields.io/badge/Godot-4.7.1-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version: 1.2.1](https://img.shields.io/badge/Version-1.2.1-blue.svg)](CHANGELOG.md)
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

# Optional: boot a Corrupted Six boss directly (QA / demo)
godot --path godot -s res://tools/play_boss_demo.gd -- --boss-cross
godot --path godot -s res://tools/play_boss_demo.gd -- --boss-voss
godot --path godot -s res://tools/play_boss_demo.gd -- --boss-moreau
godot --path godot -s res://tools/play_boss_demo.gd -- --boss-hayes
godot --path godot -s res://tools/play_boss_demo.gd -- --boss-webb
```

**Play flow (pick one):**

- **Act 3 boss run:** enter the Corrupted Six trigger zones in TestRoom (Cross Tower, Voss compound, Moreau lab, correctional yard, Webb data center).
- **Full story arc:** TestRoom → rooftop trigger (Building3) → Blackwood fight → car chase → Emperor estate reckoning → epilogue.

---

## What's built

| Area | Status |
|------|--------|
| **Boardwalk combat** | Heat / stress / HP, enemies, bodega shop, hideout, crack-house generator, squad TAB switch |
| **Blackwood arc** | Rooftop surprise → car chase → Emperor final stand → JSON reckoning → epilogue |
| **Corrupted Six bosses** | Cross, Voss, Moreau, Hayes, Webb — playable encounters via `BossGeneric` + JSON beats |
| **Cutscene system** | `CutsceneDirector` beat sequencer + `DialogueBox` UI + JSON data in `godot/data/` |
| **25 autoloads** | GameState, Stress, SaveSystem, Bosses, Emperor, Epilogue, … |
| **12 heroes** | From `configs/game_config.json` via HeroDefinitions / HeroFactory |
| **Export** | Android, Web, Windows Desktop, Linux/X11 presets; CI debug APK artifact |

Godot 4.7.1 is the **sole shipping client** — the legacy Phaser web prototype has been retired.

---

## Cutscene beats (Slices 3.18+)

Hand declarative beats to `CutsceneDirector.play()`. Lines render as **captions** with lip flap — no voiceover:

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

Live sequences: `godot/data/emperor_scene.json`, `godot/data/blackwood_scene.json`, plus per-boss encounter JSON.

---

## Project layout

```
.
├── godot/                      # ← open this in Godot
│   ├── autoload/               # 25+ singletons incl. CutsceneDirector, GameState
│   ├── scenes/                 # MainMenu, TestRoom, boss scenes, DialogueBox, …
│   ├── data/                   # JSON beat sequences + boss metadata
│   ├── assets/                 # Sprites, shaders, environment art, audio/
│   ├── configs/game_config.json
│   ├── export_presets.cfg      # Android / Web / Windows / Linux
│   ├── tools/                  # play_demo.gd, play_boss_demo.gd, CI helpers
│   └── project.godot           # version 1.2.0, brand icon
├── scripts/                    # generate_icon.py, check_tscn.py, check_gd.py, gates
├── CHANGELOG.md
├── ATTRIBUTIONS.md
├── LICENSE                     # MIT code; story/characters reserved
└── README.md
```

---

## Adding a new boss

1. Copy `godot/data/_beat_encounter_template.json` → `godot/data/<boss>_scene.json` (beat sequences).
2. Add combat metadata to `godot/data/bosses.json` (HP, phases, gimmick).
3. Subclass `BossGeneric.gd` (or `BossEncounter.gd` for cutscene-only) and wire the scene.
4. Register id in `Bosses.gd` `BOSS_LIST`.
5. Add a TestRoom trigger zone; CI headless-boots every `godot/scenes/*.tscn`.

See `godot/assets/audio/MANIFEST.txt` for VO filenames.

---

## Export

1. **Editor → Manage Export Templates…** — download Godot 4.7.1 templates.
2. **Project → Export…** — pick Android / Web / Windows / Linux.
3. **Friends sideload:** push to `main`, download `crxcibl3-debug-apk` from GitHub Actions.
4. **Google Play Store:** see [docs/PLAY_STORE.md](docs/PLAY_STORE.md) — release keystore, signed AAB via `scripts/export_android_play_store.sh`, store listing, content rating, and data safety.

---

## Documentation index

| Doc | Purpose |
|-----|---------|
| [docs/PLAY_STORE.md](docs/PLAY_STORE.md) | Google Play submission checklist |
| [docs/PRIVACY_POLICY.md](docs/PRIVACY_POLICY.md) | Hostable privacy policy (Play Store required) |
| [CHANGELOG.md](CHANGELOG.md) | Release history |
| [ATTRIBUTIONS.md](ATTRIBUTIONS.md) | Engine / tool credits |
| [CREDITS.md](CREDITS.md) | Art credits |
| [PROJECT_STATE.md](PROJECT_STATE.md) | Slice-by-slice build log |
| [PROJECT_BLUEPRINT.md](PROJECT_BLUEPRINT.md) | Roadmap checklist |
| [godot/assets/audio/MANIFEST.txt](godot/assets/audio/MANIFEST.txt) | VO WAV filenames |

**Godot:** 4.7.1 · **Project version:** 1.2.1 · **Updated:** 2026-08-08
