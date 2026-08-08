# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project aims to follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Planned
- Full encounters for the remaining five Corrupted Six bosses (Cross, Voss, Moreau, Hayes, Webb) — registered in `Bosses.BOSS_LIST` and data-templated; combat scenes not yet shipped
- Broader 3-act map / level set beyond the boardwalk TestRoom + Blackwood arc
- Final production art and voiceover pass

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
- Phaser 3 web prototype under `js/` remains as legacy reference only; Godot is the shipping engine
