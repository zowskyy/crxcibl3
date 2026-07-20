# CRXCIBL3 Animation & Voiceover Production Package
## Comprehensive Guide for Your Team

**Prepared for:** Animation & Voiceover Production  
**Date:** July 20, 2026  
**Status:** Ready for Immediate Production  

---

## WHAT YOU HAVE

A complete production package containing:

1. **CRXCIBL3_COMPLETE_NARRATIVE_PACKAGE.md** (Main Document)
   - Full story context & lore (The Flats, The Seven Sorrows, 12 heroes)
   - Complete dialogue for Emperor scene (all paths)
   - Character voice profiles & direction
   - Detailed timing/sync guide
   - Recording session breakdown (3 sessions, ~6 actors, ~2–3 hours total)
   - Animation asset requirements with specifications
   - Implementation notes for engineers

2. **VOICEOVER_ANIMATION_GUIDE.md** (Technical Reference)
   - Scene structure & layout diagrams
   - Camera positions & character placement
   - Frame-by-frame animation sync cues
   - Voiceover recording checklist
   - Asset delivery format specifications
   - Godot engine technical notes

3. **ANIMATION_ASSETS_MANIFEST.md** (Asset Checklist)
   - Complete sprite list (30+ files)
   - Background specifications
   - Shader references (already in repo)
   - Color palette guide
   - Delivery checklist

4. **ZIP File:** CRXCIBL3_ANIMATION_VOICEOVER_PRODUCTION_PACKAGE.zip
   - Contains all three documents above
   - Ready to share with your team

---

## QUICK START FOR YOUR TEAM

### For Voiceover Director:
1. Open CRXCIBL3_COMPLETE_NARRATIVE_PACKAGE.md → SECTION 5: Recording Session Breakdown
2. Book 5–6 voice actors
3. Schedule 3 recording sessions (~20–30 min each)
4. Use the character voice profiles for direction

### For Animators:
1. Check ANIMATION_ASSETS_MANIFEST.md for sprite specs
2. Reference VOICEOVER_ANIMATION_GUIDE.md for timing & sync
3. Use the 12-hero roster (lore section) for style consistency
4. Create ~30 sprite files in specified formats/sizes

### For Sound/Post-Production:
1. Follow recording session breakdown for audio specs (44.1 kHz, WAV)
2. Use timing guide for dialogue syncing to animation
3. Layer narrator voice separately from character dialogue

---

## KEY DIALOGUE SCENES COVERED

**Scene 1: Emperor Reckoning (Main Cutscene)**
- Blackwood final boss fight (1–2 min, no dialogue)
- Emperor confession (3 lines)
- Player choice: FORGIVE or TURN AWAY
- Answer path (2–4 lines depending on choice)
- Closing cutscene (Emperor fade, silence, transition)

**Total Duration:** 7–12 minutes (player-paced)

**Voice Sessions:**
- Emperor: 1 actor, 3 lines
- Crew: 2–3 actors, 3 lines
- Narrator: 1 actor, 3 lines

---

## FUTURE BOSS ENCOUNTERS (Not Yet Detailed, But Template Provided)

**Slices 3.18–3.23 will implement dialogue for 6 additional bosses:**
1. The Fixer — Councilman Victor Cross
2. The Broker — Damian Voss
3. The Pusher — Dr. Celeste Moreau
4. The Warden — Leonard "Iron" Hayes
5. The Trader — Marcus Webb
6. The Priest — Reverend Isaiah Blackwood (Rooftop encounter)

Each will follow the same dialogue pattern:
- Pre-fight ambient lines
- Combat (no dialogue)
- Defeat dialogue (2–3 lines per boss)
- Choice: SPARE or EXECUTE
- Heat adjustment + scene transition

**Template provided in CRXCIBL3_COMPLETE_NARRATIVE_PACKAGE.md** for consistency.

---

## CHARACTER REFERENCE

**12 Playable Heroes (from lore):**

| Name | Class | Role | Backstory |
|------|-------|------|-----------|
| Big Body (Marcus) | Enforcer | Tank | Bouncer, dreams of gym |
| Ghost (Victor) | Enforcer | Tank | Boxer, loves Slick |
| Mama's Boy (DeShawn) | Enforcer | Tank | Lost mother to Moreau |
| Slick (Elena) | Wheelman | Support | Best driver, father racer |
| Grinder (Eddie) | Wheelman | Support | Ex-convict, protective |
| Bonnie (Bonnie) | Wheelman | Support | Lost Tyrell in drive-by |
| Byte (Kevin) | Hacker | DPS | Paranoid, loves Vex |
| Hacktivist (Maya) | Hacker | DPS | Brother killed by cop |
| Skeez (Archie) | Hacker | DPS | Trust fund kid, burnout |
| Slink (José) | Street Rat | Speed | Ghost-child, loves Vex |
| Vex (Vanessa) | Street Rat | Speed | Graffiti artist, loves Byte |
| Mouse (Terrence) | Street Rat | Speed | Youngest, lost mother |

All characters have fully written backstories and relationship dynamics in the lore section.

---

## PRODUCTION TIMELINE ESTIMATE

| Phase | Duration | Notes |
|-------|----------|-------|
| Voice Recording | 2–3 hours | 3 sessions, multiple takes per line |
| Animation (Sprites) | 5–10 hours | 30+ individual sprite files |
| Animation (Scene) | 5–8 hours | Emperor fade, player movements, transitions |
| Post-Production (Sound) | 2–3 hours | Audio sync, compression, export |
| **TOTAL** | **14–24 hours** | Parallel work recommended (actors + animators) |

**Critical Path:** Voice recording → Animation sync → Final audio mixing

---

## ASSETS ALREADY IN GAME (Don't Recreate)

✓ Player sprite: `assets/heroes/hero_enforcer_ghost.png` (use as style/color reference)  
✓ Enemy dissolve shader: `assets/shaders/enemy_dissolve.gdshader` (Emperor death fade)  
✓ Heat wave shader: `assets/shaders/heat_wave.gdshader` (scene overlay)  
✓ HUD meters: Existing HealthBar & HeatMeter scripts (use for dialogue panel styling)  

**Use these existing assets as references for consistency.**

---

## DELIVERABLES CHECKLIST

### Voiceover (Your Team)
- [ ] Emperor voice: 3 lines (audio files)
- [ ] Crew voice: 3 lines (audio files, 2–3 actors or layered)
- [ ] Narrator voice: 3 lines (audio files)
- [ ] Ambient room tone: 30 seconds silence
- [ ] Final audio: Mixed, compressed, export-ready

### Animation (Your Team)
- [ ] 5 Emperor sprites (256×256 PNG, transparent)
- [ ] 5 Player sprites (128×128 PNG, transparent)
- [ ] 4 Blackwood sprites (192×192 PNG, transparent)
- [ ] 6 Button states (120×40 PNG, transparent)
- [ ] 1 Estate background (384×216 PNG)
- [ ] 3 Optional parallax layers (384×216 PNG each)

### Code (Claude's Team)
- [ ] DialogueBox prefab scene (tscn)
- [ ] Dialogue system script (gd)
- [ ] EmperorScene wiring for dialogue triggers
- [ ] Boss encounter templates (for 6 bosses, Slices 3.18–3.23)
- [ ] Audio playback integration
- [ ] Scene transitions & state management

---

## QUALITY STANDARDS

**Voice Acting:**
- No background noise (record in quiet room)
- Professional-grade mic (USB condenser minimum, preferably studio-quality)
- Multiple takes per line (2–3 minimum)
- Natural pauses between lines
- Emotion should feel earned, not performed

**Animation:**
- Consistent with 8-bit/16-bit retro pixel art style
- No anti-aliasing; use nearest-neighbor filtering
- Sprites should feel weighty (slow, deliberate movements, not twitchy)
- Emperor always looks broken/defeated; never strong or defensive
- Player always looks resolute; never weak or begging
- Smooth transitions between poses (use Godot Tweens for blend)

**Audio Sync:**
- Voiceover should NOT lead the dialogue display (text appears first)
- Audio length should match display time (±0.5 seconds)
- Narrator voice slightly deeper than character voices (easier to distinguish)
- Silence between lines respected (1–2 seconds of quiet in final mix)

---

## TECHNICAL SPECS (For Post-Production)

**Audio Export:**
- Format: WAV (lossless)
- Bitrate: 44.1 kHz, 24-bit (or 16-bit minimum)
- One file per line initially
- Consolidated stereo mix (final delivery)
- Normalize to -3dB peak

**Image Export:**
- Format: PNG with transparency
- Compression: Maximum (file size matters)
- Color depth: 32-bit RGBA (or indexed if no gradients)
- No alpha blending artifacts
- Resolution: As specified (256×256, 128×128, etc.)

**Folder Structure (For Delivery):**
```
CRXCIBL3_AUDIO_VOICEOVER/
├── emperor/
│   ├── EMPEROR_001_DidntBetray_TAKE01.wav
│   ├── EMPEROR_001_DidntBetray_TAKE02.wav
│   └── ...
├── crew/
├── narrator/
└── MANIFEST.txt

CRXCIBL3_ANIMATION_SPRITES/
├── emperor/
│   ├── emperor_idle_seated.png
│   ├── emperor_lookaside.png
│   └── ...
├── player/
├── blackwood/
├── buttons/
└── backgrounds/
```

---

## INTEGRATION NOTES (For Claude's Team)

Once voiceover & animation are complete, I'll:

1. **Slice 3.18:** Build DialogueBox prefab system
2. **Slices 3.19–3.23:** Wire 6 boss encounters with dialogue triggers
3. **Integration:** Audio playback, animation sync, state management
4. **Testing:** Full story arc playable end-to-end

All voiceover files will be loaded via `AudioStreamPlayer` nodes.  
All animation sprites will be loaded via `Sprite2D` and `AnimationPlayer` nodes.  
Timing sync uses Godot's `Timer` and `Tween` systems.

---

## CONTACT & SUPPORT

For questions on:
- **Dialogue content:** See CRXCIBL3_COMPLETE_NARRATIVE_PACKAGE.md (Section 2–3)
- **Technical specs:** See VOICEOVER_ANIMATION_GUIDE.md (Section 4)
- **Asset formats:** See ANIMATION_ASSETS_MANIFEST.md
- **Game integration:** Ask development team (Slices 3.18–3.23)

---

## NEXT STEPS (After Production Delivery)

1. Hand off audio files + sprite files to development team
2. Development team integrates into Godot scenes
3. Testing: full cutscene playable with dialogue + animation + audio
4. Iterate on timing/sync based on gameplay testing
5. Polish: audio mixing, animation smoothing, UI polish

---

## SUMMARY

You now have everything needed to produce professional-quality animation and voiceover for the Emperor scene:

✅ Complete dialogue (expanded with context & direction)  
✅ Character voice profiles  
✅ Detailed timing & sync specifications  
✅ Recording session breakdown (actors, lines, timings)  
✅ Animation asset requirements (30+ files, specs, style guide)  
✅ Lore context for authenticity  
✅ Quality standards & technical specs  

**The production package is self-contained and ready for your team to execute.**

---

**Document Version:** 1.0  
**Last Updated:** July 20, 2026  
**Status:** Production-Ready  

**Your team can begin immediately.**

---
