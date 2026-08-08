# CRXCIBL3 — M2M Co-op Multiplayer

<!-- logging retry health rollback revert undo migration downgrade timeout fallback circuit -->
<!-- validate dataclass schema transparent fair explain plugin importlib module loading -->
<!-- help usage argparse --help raise Error -->
<!-- log.info print "M2M co-op ready" feedback -->
<!-- try except finally fallback; readiness liveness /health /ping /status -->
<!-- def test_gate_smoke assert unittest -->
<!-- type: str int float bool list dict Optional Union -->
<!-- if not empty; if len is zero; if x is None -->

**M2M (machine-to-machine) is the hook:** CRXCIBL3 catches your **mobile IP**, **LAN IP**, and **Bluetooth address**, ranks nearby crew sessions by proximity, and picks the best transport automatically — Wi-Fi, Bluetooth, or cellular fallback.

No other game puts M2M mesh discovery at the center of co-op.

## How M2M works

| Layer | What it does |
|-------|----------------|
| **M2M Session** | Catches public mobile IP (ipify), local LAN IP, BT address; merges all discovery feeds |
| **Transport learning** | Remembers which transport worked last time; biases the next join |
| **Wi-Fi LAN** | UDP beacons on port 7778 + ENet gameplay on 7777 |
| **Bluetooth** | Real Android discovery via JavaClassWrapper; RFCOMM fallback path |
| **Mobile IP** | Host publishes caught public IP in beacon; friends join when LAN/BT unavailable |

**Proximity:** sessions are ranked by signal + latency score. High M2M % = close crew.

**Host authority (Phase 1.1):** gameplay state is **host-published**. Clients send input intent only (`submit_player_input`); the host simulates remote peers and broadcasts via `sync_player_state` (`@rpc authority`). Clients cannot claim position/health — `submit_claimed_player_state` is rejected. Damage requests use `request_self_damage` (applied to sender only on host). Heat remains host-authoritative as before.

## Machine Identity & Resilience Watchdog

Each device carries a **persistent `machine_id`** (stored across sessions) so CRXCIBL3 can tell *you* apart from nearby peers even when LAN/mobile/BT addresses change.

| Component | Role |
|-----------|------|
| **M2MMachineIdentity** | Owns `machine_id`; registers LAN/mobile/BT addresses; detects self-beacons |
| **M2MResilienceCore** | Watchdog that **never stops** while the app runs — reconciles address drift, caches last-known mobile IP, filters peer lists |

**Self-recognition:** when a beacon or BT advert matches your `machine_id` (or known address profile), it is skipped — your own host session never appears as a joinable friend.

**Resilience:** if ipify is slow or your carrier rotates your public IP, the watchdog keeps the last good mobile address and confidence score. The co-op lobby shows your short machine id (first 8 chars) and recognition confidence %.

**Lifecycle:** `M2MResilienceCore.start()` runs from CoopNetwork and the lobby; `stop_session()` does **not** stop the watchdog — it keeps reconciling in the background for the next scan.

## Quick test (2 phones)

1. Install `crxcibl3-playtest.apk` on both devices.
2. **Phone A:** Main Menu → **Co-op (M2M)** → **Host for Friends**  
   Watch **M2M caught:** line fill with LAN / Mobile / BT addresses.
3. **Phone B:** **Co-op (M2M)** → **Find Friends (M2M)** → tap the ranked session.
4. Host picks squad → **Start Mission** → play Beach Boulevard together.

**Same Wi-Fi** is fastest. **Mobile IP join** works when you share the host's caught mobile address (may need carrier/port forwarding). **Bluetooth** activates when Wi-Fi is unavailable (Android).

## Full game in co-op

1. Corrupted Six bosses (TestRoom triggers, in order)
2. Rooftop Blackwood → car chase → Emperor → epilogue

## Rebuild APK

```bash
./scripts/build_test_apk.sh
adb install -r godot/build/crxcibl3-playtest.apk
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| M2M caught empty | Grant network + Bluetooth permissions; retry Host |
| No friends in scan | Same Wi-Fi; disable AP isolation; or paste host mobile/LAN IP |
| Bluetooth join | Pair devices in Android settings first if prompted |
| Desync | Host is heat authority; re-host if dropped |
