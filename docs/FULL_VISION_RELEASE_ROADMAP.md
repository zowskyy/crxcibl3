# CRXCIBL3 — Full-Vision Public Release Roadmap (Godot Edition)

**Engine:** Godot 4.7 (GDScript) — sole engine, GameMaker track dropped.  
**Target:** iPad + Android, touch-first, 4-player cooperative via **M2M proximity discovery** (no backend — LAN / mobile-IP / Bluetooth transport, on-device transport learning).  
**Scope:** Complete design bible — 12 hero variants, 6 Corrupted Six bosses + Emperor, Relationship System, 3-act narrative, survival-sim expansion, tracked-metric emergent epilogue.

**Last adapted:** 2026-08-08 — mapped to existing codebase at `godot/` v1.3.0.

---

## How to read this document

| Column | Meaning |
|--------|---------|
| **Status** | `DONE` · `MOSTLY_DONE` · `PARTIAL` · `NOT_STARTED` |
| **Exists** | What is already in the repo (file paths) |
| **Gap** | What still blocks the slice |
| **Deliverable gate** | Criteria that must pass before this slice is handed off — no "done" without evidence |

**Path corrections** (roadmap vs repo):

| Roadmap may say | Actual |
|-----------------|--------|
| `player/player_controller.gd` | `godot/scenes/Player.gd` (`CharacterBody2D`, no `Player.tscn`) |
| `combat/hitbox.gd` | `godot/scenes/Bullet.gd` + `Enemy.gd` (`Area2D` hit detection) |
| `RelationshipSystem.gd` (new) | `godot/autoload/RelationshipSystem.gd` (**already exists**) |
| `configs/game_config.json` | `godot/configs/game_config.json` |
| Mechanics "Phase 5" | Code comments label them **Phase 3, Slice 3.6–3.14** |

**Automation workers** (Cursor):

- `/debug-godot-android-game` — 9-category Android audit ([`.cursor/rules/debug-godot-android-game.mdc`](../.cursor/rules/debug-godot-android-game.mdc))
- `/debug-godot-android` — legacy 8-step silent hardening loop
- Quarterback re-gates every changed `.gd` before delivery

---

## Progress summary

| Phase | Name | Status | Blocker |
|-------|------|--------|---------|
| 0 | Core loop lockdown | **MOSTLY_DONE** | TileMap migration, stress HUD, iPad playtest sign-off |
| 1 | M2M co-op hardening | **PARTIAL** | Host authority, reconnect, iOS BT, 4-player, adversarial tests |
| 2 | Base hero classes | **DONE** | — |
| 3 | 12 hero variants | **MOSTLY_DONE** | Voice lines, 4-player select race conditions |
| 4 | Relationship system | **MOSTLY_DONE** | Lore reveals, side quests, narrator depth |
| 5 | Survival-sim layer | **MOSTLY_DONE** | Economy depth, permadeath default, alliance breadth |
| 6 | Save/resume | **MOSTLY_DONE** | Host-saves-sync-to-party on M2M rejoin |
| 7 | All bosses + Emperor | **DONE** | 4-player boss acceptance pass |
| 8 | 3-act narrative | **PARTIAL** | Yarn integration, act map, key dialogue scenes |
| 9 | Emergent epilogue | **MOSTLY_DONE** | Host-tracked metric audit |
| 10 | Performance validation | **NOT_STARTED** | Device profiling under 4-player M2M load |
| 11 | M2M security hardening | **NOT_STARTED** | Exploit + identity spoof tests |
| 12 | Platform compliance | **PARTIAL** | iOS export, store submission, privacy review |
| 13 | Closed test | **NOT_STARTED** | Crashlytics/Sentry, co-located 4-player groups |
| 14 | Public release | **NOT_STARTED** | Listings, staged rollout |

---

## PHASE 0 — Core Loop Lockdown

**Phase status: MOSTLY_DONE**

Godot-native movement/combat/Heat — largely validated. Test room uses `StaticBody2D` layout, not `TileMap`.

### SLICE 0.1 — Core Movement Feel (Touch-First)
- **Status:** **DONE**
- **Exists:** `godot/scenes/Player.gd` (`CharacterBody2D`, `_physics_process`), `godot/scenes/VirtualJoystick.gd`, `@export`-style tuning via hero stats in `godot/configs/game_config.json`
- **Gap:** Formal iPad 10-minute playtest sign-off; `@export` vars not consolidated on a single controller resource
- **Deliverable gate:** Cold playtester, touch-only, 10 min on real iPad — no drift at rest, no stuck input after scene change

### SLICE 0.2 — Combat Hit Registration
- **Status:** **DONE**
- **Exists:** `godot/scenes/Bullet.gd` (pooled `Area2D`, crit/variance, friendly-fire → `Blame`), `godot/scenes/Enemy.gd` (hurtbox via collision), `Player.gd` fire loop
- **Gap:** Scripted 3-distance automated test not in CI
- **Deliverable gate:** Enemy dies in exactly N hits per config; each swing registers once per target; friendly-fire logged

### SLICE 0.3 — Heat Mechanic Confirmation
- **Status:** **DONE**
- **Exists:** `GameState.heat` in `godot/autoload/GameState.gd`, `godot/scenes/HeatMeter.gd` in `TestRoom.tscn`, cash/heat interactions in gameplay
- **Gap:** Timed regression test not automated
- **Deliverable gate:** Timed run confirms heat crosses 100 at expected rate; cash pickup reduces heat by documented amount

### SLICE 0.4 — MVP Room / TileMap
- **Status:** **PARTIAL**
- **Exists:** `godot/scenes/TestRoom.tscn` + `TestRoom.gd` — boardwalk, buildings, `SpawnGenerator.gd`, `TestRoomBossAccess.gd`, exit/boss triggers
- **Gap:** **No `TileMap`** — geometry is `StaticBody2D` + sprites. Roadmap TileMap slice not started
- **Deliverable gate:** Full playthrough, no collision gaps — **met for current layout**; TileMap migration is optional unless art pipeline requires it

### SLICE 0.5 — Phase 0 Acceptance
- **Status:** **NOT_STARTED** (human sign-off)
- **Deliverable gate:** 10 min solo, touch-only, real iPad, net-positive from cold playtester

---

## PHASE 1 — M2M Co-op Hardening (Not From-Scratch Networking)

**Phase status: PARTIAL**

M2M stack is **built** — this phase hardens it for 4-player permanent-death gameplay.

**Exists (do not rebuild):**

| Component | Path |
|-----------|------|
| M2MSession | `godot/autoload/M2MSession.gd` |
| M2MMachineIdentity | `godot/autoload/M2MMachineIdentity.gd` |
| M2MResilienceCore | `godot/autoload/M2MResilienceCore.gd` |
| M2MTransportLearner | `godot/autoload/M2MTransportLearner.gd` |
| TransportPolicy | `godot/autoload/TransportPolicy.gd` |
| CoopNetwork | `godot/autoload/CoopNetwork.gd` |
| CoopDiscovery / CoopLanUtil / CoopBluetooth | `godot/autoload/` |
| Lobby UI | `godot/scenes/CoopLobbyScene.gd` |
| In-game sync | `godot/scenes/TestRoomCoopSync.gd`, `RemotePlayer.gd` |
| Docs | `docs/COOP_MULTIPLAYER.md` |

### SLICE 1.1 — Host-Authoritative Gameplay State
- **Status:** **PARTIAL**
- **Exists:** Heat is host-authoritative (`CoopNetwork.broadcast_heat`, `@rpc("authority")`). Position/health via `sync_player_state` — **clients report outcomes**
- **Gap:** Input-intent-only model; host rejects fabricated RPCs
- **Files to change:** `godot/autoload/CoopNetwork.gd`, `godot/scenes/TestRoomCoopSync.gd`, `godot/scenes/Player.gd`
- **Deliverable gate:** Test client sending fabricated position/health is rejected or overridden by host

### SLICE 1.2 — Reconnection Mid-Match
- **Status:** **NOT_STARTED**
- **Exists:** `M2MMachineIdentity` + `ProcessDeathSnapshot` save scene on pause; no mid-match grace rejoin
- **Gap:** Server-side hold + `machine_id`-based resync
- **Files:** `godot/autoload/M2MResilienceCore.gd`, `CoopNetwork.gd`
- **Deliverable gate:** Walk device out of BT/Wi-Fi range and back; rejoins with correct position, health, relationship values

### SLICE 1.3 — iOS Bluetooth Discovery Path
- **Status:** **NOT_STARTED**
- **Exists:** `CoopBluetooth.gd` — Android-only (`JavaClassWrapper`)
- **Gap:** Godot 4.x iOS Core Bluetooth plugin; `NSBluetoothAlwaysUsageDescription`, `NSLocalNetworkUsageDescription`
- **Deliverable gate:** iPad + Android discover each other via BT with Wi-Fi disabled on both

### SLICE 1.4 — Real-Network Conditions Test Pass
- **Status:** **NOT_STARTED**
- **Exists:** `M2MTransportLearner.record_success/failure`, `TransportPolicy.learned_bonus()`
- **Gap:** No documented test under 150ms+ RTT / 5% packet loss
- **Deliverable gate:** Degraded transport down-ranked on next session (observable in lobby transport label or logs)

### SLICE 1.5 — Extend to 4-Player Sessions
- **Status:** **PARTIAL**
- **Exists:** ENet `create_server(GAME_PORT, 8)`; `HeroSelectionUI` supports squad 1–4
- **Gap:** No verified 4-device M2M session; async lobby race conditions
- **Deliverable gate:** 4 real devices (iPad + Android mix) join one session via proximity discovery (not manual IP)

### SLICE 1.6 — Phase 1 Acceptance
- **Status:** **NOT_STARTED**
- **Deliverable gate:** Full MVP room, 4 devices, M2M discovery, one out-of-range/reconnect, one fabricated-state attack fails

---

## PHASE 2 — Base Hero Classes

**Phase status: DONE**

### SLICE 2.1 — Four Base Hero Classes
- **Status:** **DONE**
- **Exists:** Enforcer, Wheelman, Hacker, Street Rat in `godot/configs/game_config.json`; `HeroDefinitions.gd`, `HeroFactory.gd`, distinct stats/abilities
- **Deliverable gate:** All 4 mechanically distinct; playable in co-op session

### SLICE 2.2 — Wheelman Driving Mechanic
- **Status:** **DONE**
- **Exists:** `godot/scenes/PlayerCar.gd`, `PursuitCar.gd`, `CarChaseScene.gd`, `GetawayScene.gd`
- **Deliverable gate:** Vehicle mode playable on touch without control confusion

---

## PHASE 3 — All 12 Hero Variants

**Phase status: MOSTLY_DONE**

### SLICE 3.1–3.4 — Variant Rosters (all 4 classes × 3)
- **Status:** **DONE**
- **Exists:** 12 variants in `game_config.json`; portraits `godot/assets/heroes/portraits/`; animation sheets `godot/assets/sprites/heroes/<variant_id>/`
- **Deliverable gate:** All 12 visually/mechanically distinguishable

### SLICE 3.5 — Character Select (12 variants, 4-player lobby)
- **Status:** **PARTIAL**
- **Exists:** `godot/scenes/HeroSelectionUI.gd` — 4×3 grid, squad 1–4, host starts mission
- **Gap:** Staggered M2M join duplicate-lock race conditions
- **Deliverable gate:** 4 players joining at different times each lock a unique variant

### SLICE 3.6 — ElevenLabs Voice Line Integration
- **Status:** **NOT_STARTED**
- **Exists:** `godot/assets/audio/MANIFEST.txt`; no wired `AudioStream` voice barks per variant
- **Deliverable gate:** All 12 variants play correct voice lines on select/combat/story triggers

---

## PHASE 4 — Relationship System

**Phase status: MOSTLY_DONE**

### SLICE 4.1 — Relationship Value Storage
- **Status:** **DONE**
- **Exists:** `godot/autoload/RelationshipSystem.gd` — pair values, synergy tiers, RPG bonuses; persisted via `SaveSystem`
- **Gap:** Host-authoritative validation (depends on Phase 1.1)

### SLICE 4.2 — Relationship-Modifying Actions
- **Status:** **PARTIAL**
- **Exists:** Hooks in `Player.gd`, `Bullet.gd`, `Enemy.gd`, `BossGeneric.gd`, `QuestManager.gd`
- **Gap:** Not all documented actions (revive, steal, level-complete) host-evaluated

### SLICE 4.3 — Stat Modifier Bands
- **Status:** **DONE**
- **Exists:** Tier scaling in `RelationshipSystem.gd`; `SynergyHUD.gd` displays bond tier

### SLICE 4.4 — Fixer/Narrator Commentary
- **Status:** **PARTIAL**
- **Exists:** `DialogueBox.gd` narrator mode; `DialogueIntensity.gd`
- **Gap:** Threshold-triggered commentary not fully scripted

### SLICE 4.5 — Threshold-Triggered Lore Reveals
- **Status:** **NOT_STARTED**

### SLICE 4.6 — Relationship-Specific Side Quests
- **Status:** **PARTIAL**
- **Exists:** `QuestManager.gd`, `QuestHUD.gd`
- **Gap:** At least one full relationship-gated quest end-to-end

---

## PHASE 5 — Full Survival-Sim Layer

**Phase status: MOSTLY_DONE**

All autoloads exist and are registered in `project.godot`:

| System | File | Status |
|--------|------|--------|
| Scarcity | `autoload/Scarcity.gd` | PARTIAL — ticks, no full ammo economy |
| Stress | `autoload/Stress.gd` | DONE logic; HUD removed from production scenes |
| Hideout | `autoload/Hideout.gd` + `scenes/HideoutZone.gd` | PARTIAL |
| Injury | `autoload/Injury.gd` | DONE |
| Morale | `autoload/Morale.gd` | DONE |
| Reputation | `autoload/Reputation.gd` | DONE |
| Alliance | `autoload/Alliance.gd` | PARTIAL — bodega only |
| DialogueIntensity | `autoload/DialogueIntensity.gd` | DONE |
| PermanentDeath | `autoload/PermanentDeath.gd` | PARTIAL — off unless `permadeath_mode` |
| Blame | `autoload/Blame.gd` | PARTIAL — friendly-fire only |

### SLICE 5.9 — Permanent Death / Ghost System
- **Status:** **PARTIAL**
- **Exists:** `PermanentDeath.gd`, ghost tracking in `GameState`
- **Gap:** Host-broadcast ghost transition + survives Phase 1.2 reconnect
- **Deliverable gate:** All 4 clients agree on ghost status simultaneously; survives reconnect test

### SLICE 5.10 — Blame System
- **Status:** **PARTIAL**
- **Exists:** Friendly-fire attribution in `Bullet.gd`; ledger in save
- **Deliverable gate:** Blame feeds Relationship System with correct attribution

---

## PHASE 6 — Save/Resume System

**Phase status: MOSTLY_DONE**

### SLICE 6.1 — Serialization Format
- **Status:** **DONE**
- **Exists:** `SaveSystem.gd` + `SaveSystemLoad.gd` — `SAVE_VERSION=1`, atomic write-temp-then-rename, `user://crxcibl3_save.txt`; relationships, blame, inventory, alliances, permadeath
- **Also:** `ProcessDeathSnapshot.gd` for scene restore on process death

### SLICE 6.2 — Host-Saves-Syncs-to-Party (M2M Rejoin)
- **Status:** **NOT_STARTED**
- **Gap:** Host save broadcast to guests on later M2M rediscovery session
- **Deliverable gate:** Host saves/quits; guests rejoining via M2M receive full synced state

---

## PHASE 7 — All Corrupted Six + Emperor

**Phase status: DONE**

### SLICE 7.1–7.6 — Corrupted Six
- **Status:** **DONE**
- **Exists:** `BossCrossScene`, `BossVossScene`, `BossMoreauScene`, `BossHayesScene`, `BossWebbScene`, `BossBlackwood` (rooftop + final stand); data in `godot/data/bosses.json` + per-boss `*_scene.json`; `TestRoomBossAccess.gd` triggers

### SLICE 7.7 — The Emperor (Final Boss)
- **Status:** **DONE**
- **Exists:** `Emperor.gd`, `EmperorScene.tscn` — forgive/turn-away, epilogue handoff

### SLICE 7.8 — Phase 7 Acceptance
- **Status:** **NOT_STARTED** (4-player extended session)
- **Deliverable gate:** All 7 bosses completable in sequence by 4-player M2M party in one session

---

## PHASE 8 — 3-Act Narrative + Dialogue

**Phase status: PARTIAL**

### SLICE 8.1 — Yarn Dialogue Integration
- **Status:** **NOT_STARTED**
- **Exists:** Custom `DialogueBox.gd` + `CutsceneDirector.gd` + `PatternBuilder.gd` (JSON beats)
- **Gap:** Yarn Spinner addon evaluation for Godot 4.7

### SLICE 8.2 — Act Structure Scaffolding
- **Status:** **PARTIAL**
- **Exists:** `GameState.current_act`, `ActProgression.gd`, `Recap.gd`
- **Gap:** Full act-map / mission order beyond TestRoom + boss triggers

### SLICE 8.3 — Six Key Dialogue Scenes
- **Status:** **PARTIAL**
- **Exists:** Boss encounter dialogue via `BossEncounter.gd`, `CutsceneDirector`
- **Gap:** All six scripted key scenes with one-shot completion flags

---

## PHASE 9 — Tracked-Metric Emergent Epilogue

**Phase status: MOSTLY_DONE**

### SLICE 9.1 — Playthrough Metric Tracking
- **Status:** **PARTIAL**
- **Exists:** `GameState` tracks heat, relationships, bosses, morale, reputation, blame, ghosts
- **Gap:** Host-tracked metric audit (Phase 1.1 dependency)

### SLICE 9.2 — Epilogue Generation Logic
- **Status:** **DONE**
- **Exists:** `Epilogue.gd` — 4 ending types; `EpilogueScene.tscn` with run summary
- **Deliverable gate:** Two test playthroughs produce visibly different epilogues

---

## PHASE 10 — Performance Validation

**Phase status: NOT_STARTED**

### SLICE 10.1 — Asset Pipeline Confirmation
- **Status:** **PARTIAL**
- **Exists:** VRAM compression enabled; play store icons; extensive `.import` files
- **Gap:** Full-device audit for blur/scaling on iPad + Android

### SLICE 10.2 — Frame Rate Under Worst-Case Load
- **Status:** **NOT_STARTED**
- **Gap:** 4-player M2M + Emperor VFX + transport polling on lowest-spec device
- **Deliverable gate:** Sustained target FPS (60) through worst-case scenario on target hardware

### SLICE 10.3 — Phase 10 Acceptance
- **Deliverable gate:** Full campaign start-to-epilogue within performance targets on target hardware

---

## PHASE 11 — M2M Security Hardening

**Phase status: NOT_STARTED**

Depends on Phase 1.1 completion.

### SLICE 11.1 — Host-Authority Exploit Testing
- **Deliverable gate:** Fabricated relationship, ghost, and metric RPCs rejected by host

### SLICE 11.2 — Self-Beacon and Identity Spoofing
- **Exists:** `M2MMachineIdentity.is_self_beacon()`
- **Deliverable gate:** Fabricated `machine_id` rejoin cannot hijack another player's state

### SLICE 11.3 — Phase 11 Acceptance
- **Deliverable gate:** Cold adversarial pass — all manipulation attempts fail

---

## PHASE 12 — Platform Compliance

**Phase status: PARTIAL**

### SLICE 12.1 — Apple Developer + TestFlight
- **Status:** **NOT_STARTED** — no iOS export preset

### SLICE 12.2 — Android Signing + Play Console
- **Status:** **PARTIAL**
- **Exists:** `export_presets.cfg` Play Store preset, `scripts/export_android_play_store.sh`, `docs/PLAY_STORE.md`, debug APK release [`v1.3.0-android-debug`](https://github.com/zowskyy/crxcibl3/releases/tag/v1.3.0-android-debug)

### SLICE 12.3 — Privacy, Content Rating, Data Disclosures
- **Status:** **PARTIAL**
- **Exists:** `docs/PRIVACY_POLICY.md`, `android/build/res/xml/data_safety.xml`, permission rationales in `strings.xml`, `PermissionRationale.gd`

### SLICE 12.4 — App Store Review Pass
- **Status:** **NOT_STARTED**

---

## PHASE 13 — Closed Test

**Phase status: NOT_STARTED**

### SLICE 13.1 — Crash/Error Reporting
- **Status:** **PARTIAL**
- **Exists:** `AndroidPlatform.log_crash()` → `user://crash_log.txt` stub
- **Gap:** Crashlytics/Sentry native SDK

### SLICE 13.2 — Closed Testing (4-Player M2M, Full Campaign)
- **Deliverable gate:** Multiple co-located 4-player groups complete full campaign via M2M discovery (not manual IP)

### SLICE 13.3 — Phase 13 Acceptance
- **Deliverable gate:** Crash-free rate at target; zero open P0 bugs

---

## PHASE 14 — Public Release

**Phase status: NOT_STARTED**

### SLICE 14.1 — Store Listings
- **Pitch:** "No internet required — just be near your crew" (M2M differentiator)

### SLICE 14.2 — Staged Rollout
- **Status:** **NOT_STARTED**

---

## Recommended execution order (critical path)

```
Phase 1.1 (host authority)
  → Phase 1.2 (reconnect)
  → Phase 1.5 (4-player)
  → Phase 6.2 (host save sync)
  → Phase 5.9 (permadeath + reconnect)
  → Phase 11 (security pass)
  → Phase 1.3 (iOS BT)
  → Phase 10 (performance)
  → Phase 13 (closed test)
  → Phase 12 + 14 (ship)
```

Phases 0 acceptance, 3.6 voice, 8 Yarn, and 4.5–4.6 lore can run in parallel with Phase 1 hardening.

---

## Deliverable checklist (before any phase handoff)

- [ ] All slice **deliverable gates** for the phase have evidence (test log, video, or CI artifact)
- [ ] `python3 scripts/check_gd.py` passes
- [ ] Gate review PASS on every changed `.gd` file
- [ ] Device-only items explicitly flagged — never marked DONE without device evidence
- [ ] M2M changes tested on ≥2 physical devices when applicable
- [ ] Debug APK or TestFlight build linked in release notes when platform-facing

---

## Related docs

- [COOP_MULTIPLAYER.md](COOP_MULTIPLAYER.md) — M2M player guide
- [PLAY_STORE.md](PLAY_STORE.md) — Android release process
- [PROJECT_BLUEPRINT.md](../PROJECT_BLUEPRINT.md) — original slice numbering (differs from this doc)
- [PROJECT_STATE.md](../PROJECT_STATE.md) — historical session log
