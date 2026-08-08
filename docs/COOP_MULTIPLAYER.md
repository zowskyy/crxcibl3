# CRXCIBL3 — Co-op Multiplayer (Playtest)

Friends co-op on **the same Wi-Fi network** (with mobile-data IP join as fallback).

## Transport priority

| Priority | Mode | How it works |
|----------|------|----------------|
| 1 | **M2M policy** | `TransportPolicy` scores probes (latency, same subnet) and picks the best peer path |
| 2 | **Wi-Fi LAN** | ENet on port **7777** + UDP discovery beacons on **7778** |
| 3 | **Bluetooth** | Discovery stub today — falls back to Wi-Fi when no BLE plugin is present |
| 4 | **Mobile data** | Manual **Join IP** with host's public/LAN address |

**Proximity:** sessions broadcasting on your LAN appear under **Scan Nearby** (same broadcast domain ≈ nearby).

## Quick test (2 phones, same Wi-Fi)

1. Install the playtest APK on both devices.
2. **Phone A:** Main Menu → **Co-op** → **Host Game**
3. **Phone B:** Main Menu → **Co-op** → **Scan Nearby** → tap the host session (or enter host IP → **Join**)
4. **Host** picks squad in hero selection → **Start Mission**
5. Both players appear on Beach Boulevard; move with joystick, **FIRE** to shoot
6. Host drives heat / spawn generators; crew positions sync ~10×/sec

## Full game in co-op

Same solo progression:

1. Corrupted Six bosses (TestRoom building triggers, in order)
2. Rooftop Blackwood (after all six defeated)
3. Car chase → Emperor → epilogue

RPG synergy bonds apply per-player hero; relationship bonuses stack locally.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| No sessions in Scan Nearby | Same Wi-Fi; disable guest isolation on router; try Join IP with host LAN IP |
| Join failed | Allow CRXCIBL3 through firewall; confirm host pressed Host Game first |
| Desync | Host is authoritative for heat; re-host if connection dropped |

## Rebuild APK

```bash
./scripts/build_test_apk.sh
adb install -r godot/build/crxcibl3-playtest.apk
```
