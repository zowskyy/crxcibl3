# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- Broader 3-act map / level set beyond the boardwalk TestRoom + Blackwood arc
- Final production art pass

## [1.2.0] - 2026-08-08

### Added
- **Five Corrupted Six boss encounters** — playable fights for Cross, Voss, Moreau, Hayes, and Webb (slices 3.18–3.22)
- **`BossGeneric` template system** — shared combat + JSON cutscene pipeline built on `BossEncounter`; per-boss scripts subclass the template and pull metadata from `godot/data/bosses.json`
- **TestRoom boss triggers** — dedicated trigger zones on the boardwalk jump straight into each Corrupted Six encounter for QA and act-3 progression
- **`play_boss_demo.gd`** — headless/editor launcher with `--boss-cross` (and sibling flags) to boot any Corrupted Six scene directly

### Changed
- Act progression: TestRoom boss triggers **or** the full story arc (TestRoom → Blackwood rooftop → car chase → Emperor reckoning → epilogue)
- Corrupted Six marked **GA scope** — all five bosses are playable, not data-only templates

## [1.1.0] - 2026-08-08

### Added
- Arcane visual grade + production environment art on Beach Boulevard
- Caption-only cutscenes with lip flap (`SpeakCapable`)
- Shared `GetawayScene` mechanic; RPG synergy bond HUD
- Rooftop Blackwood intro from JSON enter_sequence

### Removed
- Phaser 3 web prototype (`js/`, root HTML runner scripts)

## [1.0.0] - 2026-08-08

### Added
- JSON-driven cutscene infrastructure: `CutsceneDirector` beat API, `DialogueBox` UI, `EncounterData` loader, `BossEncounter` template
- Beat sequence data: `godot/data/emperor_scene.json`, `blackwood_scene.json`, `_beat_encounter_template.json`
- Boss metadata registry: `godot/data/bosses.json` for Cross / Voss / Moreau / Hayes / Webb / Blackwood / Emperor
- Brand icon (`godot/assets/sprites/icon.png`) + `scripts/generate_icon.py`
- Windows Desktop and Linux/X11 export presets; project version `1.0.0`
- Validation scripts: `scripts/check_tscn.py`, `scripts/check_gd.py`
- VO drop-in manifest: `godot/assets/audio/MANIFEST.txt`
- `GameState.record_boss_choice()` for JSON encounter branches
- Main menu (`MainMenu.tscn`) with optional Recap panel, flowing into hero selection
- Hero selection lobby for all **12** crew variants (3 enforcer / 3 wheelman / 3 hacker / 3 street rat) from `configs/game_config.json`
- Boardwalk **TestRoom** combat loop: heat / stress / HP meters, enemy grunts, bodega upgrade shop, hideout zone, crack-house spawn generator
- Playable **Blackwood arc**: rooftop surprise fight → car chase getaway → Emperor estate reckoning → epilogue scene
- **25** autoload systems registered in `project.godot`, including GameState, Stress, SaveSystem, Recap, Blame, Alliance, Hideout, Scarcity, PermanentDeath, Bosses, Emperor, Epilogue, HeroDefinitions, HeroFactory, CutsceneDirector, EnemyRegistry, Injury, Morale, Reputation, DialogueIntensity, RelationshipSystem, NPCManager, SquadController, Inventory, QuestManager
- Android and Web export presets in `godot/export_presets.cfg`
- GitHub Actions friends-sideload APK CI (debug APK artifact via `godot-check.yml`)
- Animation sprite pipeline (`AnimationLoader.gd`) for hero variants, enemies, and Blackwood boss strips under `godot/assets/sprites/`

### Notes
- Godot 4.7.1 is the sole shipping engine (Phaser web prototype retired in 1.1.0)
