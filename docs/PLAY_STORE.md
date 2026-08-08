# CRXCIBL3 — Google Play Store Submission Guide

Complete checklist for publishing **CRXCIBL3** (`com.zowskyy.crxcibl3`) on Google Play.

**Game:** Beach Boulevard — retro crew shooter with JSON-driven cutscenes, the Blackwood arc, and five Corrupted Six boss encounters.  
**Engine:** Godot 4.7.1 · **Package:** `com.zowskyy.crxcibl3` · **Privacy policy:** [PRIVACY_POLICY.md](PRIVACY_POLICY.md)

---

## Prerequisites

Complete these before your first upload.

| Requirement | Notes |
|-------------|-------|
| **Google Play Console account** | One-time **$25 USD** registration fee. [Create a developer account](https://play.google.com/console/signup). |
| **Godot 4.7.1** | Match the project version. Download export templates in-editor: **Editor → Manage Export Templates…** |
| **Android SDK + NDK + JDK** | Point Godot at them: **Editor → Editor Settings → Export → Android** (SDK path, JDK path). CI uses the same toolchain via `.github/workflows/godot-check.yml`. |
| **Release keystore** | **Required for Play Store.** Debug keystore (`godot/debug.keystore`) is for sideload/CI only — never upload debug-signed builds to production. |
| **Privacy policy URL** | Host [PRIVACY_POLICY.md](PRIVACY_POLICY.md) at a public HTTPS URL (GitHub Pages, project site, etc.) and paste the link in Play Console. |

---

## Step-by-step: release build

### 1. Generate a release keystore (one time)

Store the keystore and passwords securely. **Losing the release keystore means you cannot update the app on Play Store.**

```bash
keytool -genkeypair -v \
  -keystore ~/crxcibl3-release.keystore \
  -alias crxcibl3 \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass '<STORE_PASSWORD>' \
  -keypass '<KEY_PASSWORD>' \
  -dname "CN=CRXCIBL3, OU=Mobile, O=Zowskyy, L=Unknown, ST=Unknown, C=US"
```

**Do not commit** the release keystore or passwords to git. Add local paths to `.gitignore` if needed.

Configure Godot Android export (**Project → Export → Android → Keystore**):

| Field | Value |
|-------|-------|
| Release Keystore | Path to `crxcibl3-release.keystore` |
| Release User | `crxcibl3` |
| Release Password | Your store/key password |

Alternatively, set environment variables consumed by the export script (see step 3).

### 2. Generate launcher icons

Regenerate the brand icon, then ensure Play-required sizes exist:

```bash
python3 scripts/generate_icon.py
```

Default output: `godot/assets/sprites/icon.png` (256×256). For Play:

- **Store listing icon:** 512×512 PNG (32-bit, no alpha required for legacy icon slot — upscale from brand icon or export from Godot).
- **Adaptive launcher icons:** 432×432 foreground + background (configure under **Project → Export → Android → Launcher Icons** in `export_presets.cfg`).

Godot reads `config/icon="res://assets/sprites/icon.png"` from `project.godot`.

### 3. Export a signed AAB (Android App Bundle)

Use the project export script (release-signed, Play-ready AAB):

```bash
# Set release signing (never commit these values)
export CRXCIBL3_RELEASE_KEYSTORE="$HOME/crxcibl3-release.keystore"
export CRXCIBL3_RELEASE_KEY_ALIAS="crxcibl3"
export CRXCIBL3_RELEASE_STORE_PASS="<STORE_PASSWORD>"
export CRXCIBL3_RELEASE_KEY_PASS="<KEY_PASSWORD>"

./scripts/export_android_play_store.sh
```

The script runs Godot headless with `--export-release` and writes an **AAB** to `build/` (exact filename defined in the script / export preset).

**Manual fallback (Godot editor):**

1. **Project → Export… → Android**
2. Set export path to `build/crxcibl3-release.aab` (or `.aab` as required by your preset).
3. Enable **Export With Debug** = off.
4. **Export Project**

Play Store requires **AAB** format for new apps (not APK).

### 4. Increment version before each upload

Edit `godot/export_presets.cfg` (Android preset):

```ini
version/code=2        # integer — MUST increase every Play Console upload
version/name="1.2.1"  # user-visible version string
```

Also keep `config/version` in `godot/project.godot` aligned with `version/name` for in-game display.

| Upload | `version/code` | `version/name` |
|--------|----------------|----------------|
| First Play release | `1` | `1.2.1` |
| Each subsequent upload | previous + 1 | semver bump as appropriate |

**Policy:** Never reuse a `version/code`. Google Play rejects equal or lower codes for the same package name.

---

## Store listing copy

Use in **Play Console → Main store listing**.

### App name

**CRXCIBL3**

### Short description (max 80 characters)

```
Crew shooter on decayed Beach Boulevard. Heists, heat, and the Corrupted Six.
```

*(72 characters)*

### Full description

```
CRXCIBL3 drops you on Beach Boulevard — twelve miles of cracked sidewalk, dead palms, and neon that still flickers when the power grid fails.

Pick your crew from twelve heroes across four archetypes: Enforcer, Wheelman, Hacker, and Street Rat. Survive the boardwalk, manage Heat and Stress, and push through JSON-driven cutscenes that remember your choices.

FEATURES
• Retro top-down crew shooter with virtual joystick controls
• The Blackwood arc: rooftop surprise, car chase, Emperor reckoning, epilogue
• Five playable Corrupted Six boss fights — Cross, Voss, Moreau, Hayes, Webb
• Local save only — progress stays on your device
• Fully offline — no account, no ads, no analytics

MATURE THEMES
Satirical 90s West Coast crime drama tone. Violence, strong language, and criminal activity are depicted as stylized pixel-art fiction — not endorsement of real-world behavior.

Built with Godot 4.7.1. Package: com.zowskyy.crxcibl3
```

### Category suggestions

- **Primary:** Action
- **Tags (if available):** Offline, Single player, Pixel graphics

---

## Content rating (IARC questionnaire)

Complete **Play Console → Policy → App content → Content rating**. Answer honestly; ratings propagate to other stores via IARC.

| Topic | CRXCIBL3 guidance |
|-------|-------------------|
| **Violence** | Yes — stylized pixel combat, gunplay, boss fights, car chase. Not realistic gore; no dismemberment focus. Likely **Teen** or regional equivalent depending on intensity answers. |
| **Language** | Yes — mature / profane dialogue in captions (gangster satire). Select **infrequent or mild** vs **frequent** based on actual line density in shipped builds. |
| **Sexual content** | No explicit content. Satirical mature themes only. |
| **Drugs / alcohol / tobacco** | Thematic references (crack-house spawn points, decayed urban setting). Disclose **referenced** or **simulated** as appropriate — not a glorification mechanic. |
| **Gambling** | No real-money gambling. In-fiction "Rune" currency is not loot boxes or real-money mechanics. |
| **User interaction / sharing** | No chat, no UGC, no online multiplayer. |
| **Location / personal info** | None collected (see Data safety). |

**Mature themes satire:** In the questionnaire free-text or "other" fields, note that the game is a satirical reskin of classic arcade dungeon crawlers using 90s crime-cinema tropes; violence and language serve narrative tone, not realism.

After submission, attach the generated **IARC certificate** PDF if Play Console requests it.

---

## Required assets

| Asset | Spec | Status / notes |
|-------|------|----------------|
| **App icon** | 512×512 PNG | Generate via `scripts/generate_icon.py`; upscale to 512×512 for listing |
| **Feature graphic** | 1024×500 PNG or JPG | **Placeholder OK for internal testing tracks.** Replace with branded Beach Boulevard art before production launch. No text-heavy clutter — readable at thumbnail size. |
| **Phone screenshots** | Min 2; recommend 4–8 | Capture from Android device or emulator: main menu, boardwalk combat, boss encounter, cutscene caption |
| **7-inch tablet screenshots** | Optional unless targeting tablets | Same scenes, tablet aspect |
| **10-inch tablet screenshots** | Optional | Same |
| **Promo video** | Optional | YouTube URL |

Screenshot tips:

- Minimum long edge **1080 px** recommended.
- Show actual gameplay (not splash-only).
- No misleading content vs shipped build.

---

## Data safety form

**Play Console → App content → Data safety.** CRXCIBL3 is offline-first with no third-party SDKs.

| Declaration | Answer |
|-------------|--------|
| **Data collected** | **No** personal or sensitive user data collected |
| **Data shared** | **No** |
| **Encryption in transit** | N/A (no network calls) |
| **Encryption at rest** | Local save file in app sandbox only |
| **Account creation** | No |
| **Analytics** | No Firebase, no Google Analytics, no custom telemetry |
| **Advertising** | No ads SDKs |
| **Purchase history** | No IAP in current build |

**Local save details (disclose if asked about "files and docs" or "app activity"):**

- Save path: `user://crxcibl3_save.txt` (Godot sandbox → private app storage on Android)
- Contains game progress only (heat, squad, act, relationships, boss flags, etc.)
- Never leaves the device
- Deleted when the user clears app data or uninstalls

Link the public **privacy policy URL** hosting [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

---

## Play Console upload checklist

Use this immediately before each release:

- [ ] `version/code` incremented in `godot/export_presets.cfg`
- [ ] `version/name` and `project.godot` `config/version` updated
- [ ] Release keystore configured (not debug)
- [ ] `./scripts/export_android_play_store.sh` produced a signed AAB
- [ ] Tested AAB on a physical device (internal testing track)
- [ ] Store listing text and graphics uploaded
- [ ] Content rating questionnaire current
- [ ] Data safety form matches offline/no-collection behavior
- [ ] Privacy policy URL live and linked
- [ ] Target audience / news apps / COVID declarations completed if prompted
- [ ] **Internal testing → Closed testing → Production** rollout plan set

---

## Testing tracks (recommended flow)

1. **Internal testing** — upload AAB, install via Play Console tester list (fast iteration).
2. **Closed testing** — wider friend group; validate touch controls and save/load on real devices.
3. **Production** — public release after checklist complete.

Friends sideload without Play Store: continue using the CI debug APK artifact (`crxcibl3-debug-apk` from GitHub Actions) documented in [README.md](../README.md).

---

## Related files

| File | Purpose |
|------|---------|
| `godot/export_presets.cfg` | Android package id, version code/name, keystore paths |
| `godot/project.godot` | Display version, app icon path |
| `scripts/generate_icon.py` | Brand icon generation |
| `scripts/export_android_play_store.sh` | Release AAB export automation |
| `docs/PRIVACY_POLICY.md` | Hostable privacy policy |
| `godot/autoload/SaveSystem.gd` | Local save implementation (`user://crxcibl3_save.txt`) |

---

*Last updated: 2026-08-08*
