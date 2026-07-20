# CRXCIBL3 Voiceover & Animation Guide

## Overview
This document provides a complete breakdown of all dialogue, scene structure, timing, character positioning, and animation cues for voiceover recording and animation creation.

**Game Structure:** 4 acts, 7 major scenes (4 playable, 3 dialogue-heavy), multiple boss encounters, 1 finale.

---

## SCENES & DIALOGUE BREAKDOWN

### ACT 1–2: BOARDWALK (TestRoom)
**Location:** Beach Boulevard, decaying coastal strip. Liquor store, arcade, apartment tower, fences.
**Duration:** Variable (player-driven, 10–30 minutes typical)
**Dialogue:** Minimal. Heat/Stress meters display only. Debug UI may include radio chatter.
**Characters:** Player (1 of 12 heroes), Enemy grunts, Bodega Shop NPC (silent, UI only)
**Animation Needs:**
- Player movement (walk, run, idle, firing stance)
- Enemy grunts: idle, chase, attack, death (dissolve shader)
- Building backdrop (static)
- HUD animations: meter fills, damage flashes

**Dialogue (in-game radio/ambient, if any):**
- None scripted yet; reserved for future "paranoid fixer radio chatter" system

---

### ACT 2: ROOFTOP SPRINT (RooftopScene)
**Location:** Apartment building rooftop. Blackwood's surprise encounter.
**Duration:** 2–5 minutes
**Dialogue:** Combat ambient only (no dialogue until defeat)
**Characters:** Player, BossBlackwood, 2 Deacon grunts (summons)
**Animation Needs:**
- Blackwood idle pose (menacing, ready)
- Blackwood phase transitions: SURPRISED (relaxed → alert) → FIGHT (orbiting, dodging) → FLEE (sprint, white flashbang fade)
- Deacon summon effect
- Player and Blackwood hit reactions
- Projectile trails (Blackwood's gold light attacks)

**Boss Defeat Trigger → Scene Transition to CarChase (automatically loaded after Blackwood flees scene)**

---

### ACT 2: CAR CHASE GETAWAY (CarChaseScene)
**Location:** Coastal highway, top-down scrolling level. Escape toward the hills.
**Duration:** 45 seconds to 2 minutes (player-driven, survive duration)
**Dialogue:** None (action sequence)
**Characters:** Player (in PlayerCar vehicle), Enemy police/crew vehicles, background scenery
**Animation Needs:**
- PlayerCar: forward movement, slight sway on direction input, hit reactions (smoke, damage)
- Enemy vehicles: spawn left/right, chase pattern, hit reactions, despawn on defeat
- Road scrolling (continuous, parallax layers)
- Screen shake on collisions
- HUD: car health bar, "SURVIVE..." countdown

**Victory Condition:** Survive 45 seconds → automatic scene transition to EmperorScene

---

### ACT 3: EMPEROR ESTATE (EmperorScene)
**Location:** The Hills, Emperor's private estate. Final confrontation.
**Duration:** 5–10 minutes (2 min combat + 3–5 min dialogue/reckoning)
**Dialogue:** EXTENSIVE. See detailed breakdown below.
**Characters:** Player, BossBlackwood (final stand), EmperorFigure (non-combatant), Crew (voice-only in dialogue)

#### PHASE 1: BLACKWOOD'S FINAL STAND (Combat)
**Duration:** 1–2 minutes
**Scene Setup:**
- Blackwood enters with `final_stand=true` flag (no SURPRISED phase, fights from start)
- Emperor figure visible in background, slumped (will animate out later)
- Player fights Blackwood to 0 HP

**Blackwood Animations:**
- Entry pose (aggressive stance)
- Attack cycle: approach, strike, retreat
- Hit reactions and knockback
- Death: slump animation, fade to black (dissolve shader over 1s)

**Player Animations:**
- Weapon ready, firing stance
- Movement and evasion
- Hit reactions (damage feedback)

**Dialogue:** None during combat

---

#### PHASE 2: RECKONING (Non-Combat Dialogue Sequence)
**Duration:** 3–5 minutes
**Starts:** 1.5 seconds after Blackwood's defeat fade-out

**Dialogue Panel Appears:** ColorRect (semi-transparent black, bottom-anchored), Label text, Buttons
**Dialogue Flow:**

##### **CONFESSION SEQUENCE** (Blackwood's death triggers this)
3 lines, 1 speaker (Emperor), each advances on player input or button click.

**Line 1:**
```
SPEAKER: EMPEROR
TEXT: "I didn't betray you."
TIMING: Display 3–4 seconds, await player input (SPACE or Continue button)
CHARACTER POSITION: Emperor figure, center-right of screen
ANIMATION: Emperor looks at crew (eye contact), then down (shame)
VOICEOVER: Deep, elder male voice. Resigned. Weight of confession.
```

**Line 2:**
```
SPEAKER: EMPEROR
TEXT: "I made a deal with The Corrupted Six to save your lives."
TIMING: Display 3–4 seconds, await player input
CHARACTER POSITION: Emperor figure
ANIMATION: Emperor gestures (opens hands, plea) — explain the deal
VOICEOVER: Same voice, slightly more urgent. Justification tone.
```

**Line 3:**
```
SPEAKER: EMPEROR
TEXT: "I thought if I gave them the jobs, they'd let you walk. I was wrong."
TIMING: Display 4–5 seconds, await player input
CHARACTER POSITION: Emperor figure
ANIMATION: Emperor closes, defeated posture. Realizes failure.
VOICEOVER: Same voice, trailing off. Regret. Finality.
```

**After Line 3 completes:**
- Dialogue panel clears
- "He's waiting for an answer." appears (narrator/system text, no voiceover)
- Two choice buttons appear: **[FORGIVE HIM]** **[TURN AWAY]**
- Emperor figure freezes in defeated pose, awaiting crew response

---

##### **CHOICE PHASE**
**Input:** Player clicks FORGIVE HIM or TURN AWAY button
**Outcome:** Determines dialogue sequence and heat adjustment

**FORGIVE PATH (if player clicks FORGIVE HIM):**

```
LINE 1:
SPEAKER: CREW
TEXT: "We know. We've always known."
TIMING: 3–4 seconds
ANIMATION: Player character (active hero) steps forward slightly, nods
VOICEOVER: Mixed voice (multiple crew members, unified). Knowing. Acceptance.
EMOTIONAL_CUE: Compassion with understanding.
```

```
LINE 2:
SPEAKER: CREW
TEXT: "You made a mistake. So did we."
TIMING: 3–4 seconds
ANIMATION: Player looks at Emperor, then at ground (introspection). Gesture of acknowledgment.
VOICEOVER: Unified crew voice. Solidarity. Shared burden.
EMOTIONAL_CUE: Peer-to-peer recognition of failure.
```

```
LINE 3:
SPEAKER: CREW
TEXT: "The Flats ain't about who's right — it's about who's still standing. And we're standing."
TIMING: 4–5 seconds
ANIMATION: Player stands tall, hands to chest (pride, resolve). Emperor watches.
VOICEOVER: Crew voice. Gritty wisdom. Defiant but weary.
EMOTIONAL_CUE: Hard-won survival. Street code.
```

```
LINE 4:
SPEAKER: NARRATOR
TEXT: "The Emperor died that night, surrounded by the crew he'd failed and saved in equal measure."
TIMING: 4–5 seconds
ANIMATION: Emperor begins slump animation (shoulders drop), head bows. Peaceful acceptance.
VOICEOVER: Third-person narrator. Gravelly, radio-host tone. Elegiac.
EMOTIONAL_CUE: Finality. Tragic but dignified.
```

**TURN AWAY PATH (if player clicks TURN AWAY):**

```
LINE 1:
SPEAKER: NARRATOR
TEXT: "The crew said nothing. There was nothing left worth saying."
TIMING: 4–5 seconds
ANIMATION: Player character turns away from Emperor, faces downstage. Emperor reaches out, hand falls.
VOICEOVER: Third-person narrator. Cold. Silence as punishment.
EMOTIONAL_CUE: Coldness. Rejection. Consequence.
```

```
LINE 2:
SPEAKER: NARRATOR
TEXT: "The Emperor died that night — alone in a room full of the people he'd failed."
TIMING: 4–5 seconds
ANIMATION: Emperor slumps, alone. Camera pulls back, isolating him. Players leave frame.
VOICEOVER: Same narrator. Mournful. Solitary.
EMOTIONAL_CUE: Isolation. Consequence of choices.
```

---

#### PHASE 3: CLOSING CUTSCENE (Non-Interactive)
**Duration:** 4–6 seconds
**Trigger:** After dialogue sequence ends (either path)

**Sequence (automated via CutsceneDirector):**
1. **Fade Emperor to black** (modulate.alpha 1.0 → 0.0 over 2.0 seconds)
   - Emperor figure dissolves, dies
2. **Pause** (1.0 second)
   - Silence. Crew watches
3. **SaveSystem.save_game()** (non-visual, happens in background)
   - Game state persisted (squad, heat, relationships, bosses, choice)
4. **Scene change to Epilogue or Title** (automatic)
   - Fade to black, load next scene

**Animations:**
- Emperor fade (already described, use modulate tween)
- Camera stays on crew standing in estate
- Optional: crew walking away silhouette (added later)

**Voiceover:** None (pure visual, ambient music if implemented)

---

### ACT 3: EPILOGUE (EpilogueScene — Future)
**Location:** Sunset beach or neutral fadeout
**Duration:** 30 seconds to 2 minutes
**Dialogue:** Final narration (crew walked away, epilogue snippet based on choices)
**Characters:** None visible (or distant crew silhouettes)

**Structure (TBD, template below):**
```
[EPILOGUE TEXT]
SPEAKER: NARRATOR (or title card)
TEXT: "The crew walked away from The Flats that night.
        The Emperor's death echoed through the underworld.
        But his betrayal — and their forgiveness — changed the game."
TIMING: 5–7 seconds, fade-in over black
ANIMATION: Fade from black to credits or title screen
VOICEOVER: Same narrator voice as Emperor scene. Reflective. Distant.
```

---

## BOSS ENCOUNTER STRUCTURE (6 Bosses + Emperor)

### Boss Encounter Template
**Phase 1: Combat** (2–5 minutes)
- Player vs. boss + summons
- No dialogue during fight
- Focus on attack animations, hit reactions, phase transitions

**Phase 2: Defeat Dialogue** (2–3 minutes)
- Boss defeated, falls to knees or lies still
- Dialogue panel appears
- 2–3 boss confession lines (pre-written in lore doc)
- Player chooses: SPARE or EXECUTE

**Phase 3: Aftermath** (1–2 minutes)
- Heat adjustment (execute: +15, spare: -5)
- Scene transition (getaway sequence or next boss level)

---

### BOSS 1: THE FIXER — Councilman Victor Cross
**Location:** Cross Tower Penthouse (not yet implemented, Slice 3.18)
**Combat Duration:** 2–3 minutes
**Dialogue Lines (Defeat):** TBD from lore doc

**Defeat Dialogue (Template):**
```
LINE 1:
SPEAKER: CROSS
TEXT: "[Confession about the deal, his motivation]"
TIMING: 3–4 seconds
ANIMATION: Cross kneels, hand to chest (wound), looks up at crew
VOICEOVER: Politician tone. Urbane but broken. Defensiveness giving way to defeat.
```

```
CHOICE: SPARE or EXECUTE
SPARE: Heat -5, Cross owes crew, potential ally in endgame
EXECUTE: Heat +15, crew proves ruthlessness to remaining bosses
```

---

### BOSS 2: THE BROKER — Damian Voss
**Location:** Voss Compound Vault
**Combat Duration:** 2–3 minutes
**Dialogue Lines (Defeat):** TBD from lore doc

**Defeat Dialogue (Template):**
```
LINE 1:
SPEAKER: VOSS
TEXT: "[Confession about vault, data, financial leverage]"
TIMING: 3–4 seconds
ANIMATION: Voss slumps against safe, smile of dark irony
VOICEOVER: Smooth, calculating voice. Darkly amused even in defeat.
```

---

### BOSS 3: THE PUSHER — Dr. Celeste Moreau
**Location:** Moreau Pharmaceuticals Lab
**Combat Duration:** 2–4 minutes (includes Super Rager phase transformation)
**Dialogue Lines (Defeat):** TBD from lore doc

**Defeat Dialogue (Template):**
```
LINE 1:
SPEAKER: MOREAU
TEXT: "[Confession about chemical weapons, addiction of victims]"
TIMING: 3–4 seconds
ANIMATION: Moreau lies down, still twitching from last chemical surge
VOICEOVER: Scientist tone, unhinged. Proud of her work even dying.
```

---

### BOSS 4: THE WARDEN — Leonard "Iron" Hayes
**Location:** San Espada Correctional Facility
**Combat Duration:** 2–3 minutes
**Dialogue Lines (Defeat):** TBD from lore doc

**Defeat Dialogue (Template):**
```
LINE 1:
SPEAKER: HAYES
TEXT: "[Confession about guard network, control through fear]"
TIMING: 3–4 seconds
ANIMATION: Hayes drops riot shield, sits heavily on chair
VOICEOVER: Gravelly military voice. Cold discipline even in surrender.
```

---

### BOSS 5: THE TRADER — Marcus Webb
**Location:** Webb Industries Data Center
**Combat Duration:** 2–4 minutes (includes mech suit phase)
**Dialogue Lines (Defeat):** TBD from lore doc

**Defeat Dialogue (Template):**
```
LINE 1:
SPEAKER: WEBB
TEXT: "[Confession about mech, digital defense network]"
TIMING: 3–4 seconds
ANIMATION: Webb climbs out of mech cockpit, visibly injured
VOICEOVER: Tech-bro tone with edge of menace. Respect for worthy opponents.
```

---

### BOSS 6: THE PRIEST — Reverend Isaiah Blackwood (Rooftop)
**Location:** Rooftop Scene (already implemented, Slice 2.18)
**Combat Duration:** 2–3 minutes
**Dialogue Lines (Defeat):** Fleeing only (no defeat dialogue at rooftop; he lives until Emperor scene)

**Rooftop Encounter:**
- No defeat dialogue (Blackwood flees at 33 HP threshold)
- Heat +15 (escaped)
- Triggers car chase getaway
- Later defeated at Emperor Estate (see above)

---

### BOSS 7: THE EMPEROR (Final Boss, Non-Combat)
**Location:** Emperor Estate (implemented, Slice 2.20)
**Combat Duration:** 1–2 minutes (Blackwood final stand)
**Dialogue Duration:** 3–5 minutes (confession → choice → aftermath)

**See detailed dialogue breakdown under EmperorScene above.**

---

## CHARACTER VOICE GUIDE

### EMPEROR
**Description:** Elder, wise, measured. Once powerful, now broken.
**Accent/Dialect:** Cultured, possibly Latin American heritage (inspired by crime fiction elders)
**Tone for Confession:**
- Line 1: Resigned, no excuses ("I didn't betray you.")
- Line 2: Explanation tone, urgency ("I made a deal...")
- Line 3: Regret, finality ("I thought if I gave them the jobs...")

**Voice Acting Notes:**
- Speak slowly, let weight settle on each word
- Emphasize "I" (taking responsibility)
- Pause between lines (processing, emotion)
- Final line trails off slightly (acceptance of death)

**Reference:** Elderly crime boss from Godfather, heat-exhausted regret

---

### CREW (Collective Voice)
**Description:** Unified, working-class, street-smart. Multiple voices blending (can be 2–3 voice actors)
**Accent/Dialect:** West Coast urban, 90s vernacular. Mix of accents (Black, Latino, Asian, white working-class)
**Tone for Responses:**
- Line 1: Knowing, calm ("We know. We've always known.")
- Line 2: Peer-level acceptance ("You made a mistake. So did we.")
- Line 3: Gritty wisdom, resolve ("The Flats ain't about who's right...")

**Voice Acting Notes:**
- Crew voices should layer (not one speaker, but implied multiple)
- Speak with street confidence, not educated polish
- "The Flats" reference shows hometown pride
- Final crew line is the game's thesis — deliver with conviction

**Reference:** Dialogue from *Boyz n the Hood*, *Menace II Society*

---

### NARRATOR (Third-Person Closing)
**Description:** Radio announcer, noir voiceover artist. World-weary, observant.
**Accent/Dialect:** Neutral broadcast, possibly slight noir rasp
**Tone:**
- Epilogue lines: Elegiac, reflective. Observing outcomes of choices.

**Voice Acting Notes:**
- Deep voice, measured pace
- "The Emperor died that night..." should land as history being written
- No emotion, just observation (let the words carry weight)
- Works as implied fixer radio chatter elsewhere if added later

**Reference:** Film noir voiceover, *GTA: San Andreas* radio DJ

---

## TIMING REFERENCE

### Emperor Reckoning Sequence (Full Breakdown)
| Phase | Duration | Action | Voiceover |
|-------|----------|--------|-----------|
| Blackwood Final Stand | 1–2 min | Combat, music, no dialogue | Ambient sound, SFX |
| Blackwood Death Fade | 1 sec | Dissolve shader to black | Silence |
| Pause | 1.5 sec | Crew watches, Emperor prepares | Ambient (optional: wind, distant city) |
| Dialogue Panel Appears | 0.5 sec | UI fade-in | None |
| **CONFESSION** | | | |
| Line 1 | 4 sec | Emperor speaks, text display | **EMPEROR voice** |
| Continue (player input) | 1 sec | Player presses SPACE/button | None |
| Line 2 | 4 sec | Emperor continues | **EMPEROR voice** |
| Continue (player input) | 1 sec | Player presses SPACE/button | None |
| Line 3 | 4 sec | Emperor concludes confession | **EMPEROR voice** |
| Continue (player input) | 1 sec | Player presses SPACE/button | None |
| **CHOICE APPEARS** | 1 sec | Buttons fade in, text changes | None |
| **Player Chooses** | 5–20 sec | Player decides (FORGIVE or TURN AWAY) | None |
| **ANSWER (FORGIVE PATH)** | | | |
| Line 1 | 4 sec | Crew responds | **CREW voice** |
| Continue | 1 sec | | None |
| Line 2 | 4 sec | Crew continues | **CREW voice** |
| Continue | 1 sec | | None |
| Line 3 | 4 sec | Crew concludes | **CREW voice** |
| Continue | 1 sec | | None |
| Line 4 (Narration) | 5 sec | Narrator epilogue, Emperor fades | **NARRATOR voice** |
| **ANSWER (TURN AWAY PATH)** | | | |
| Line 1 (Narration) | 4 sec | Narrator describes silence, crew turns away | **NARRATOR voice** |
| Continue | 1 sec | | None |
| Line 2 (Narration) | 5 sec | Narrator final note, Emperor alone | **NARRATOR voice** |
| **CLOSING CUTSCENE** | | | |
| Emperor Fade-Out | 2 sec | Tween modulate.alpha 1.0 → 0.0 | Ambient silence |
| Pause | 1 sec | | Silence |
| SaveSystem.save_game() | (instant) | Data persisted, invisible | None |
| Scene Change to Epilogue/Title | 1 sec | Fade to black | Fade audio |
| **TOTAL DURATION** | **7–12 min** | Entire reckoning | **3–5 min dialogue** |

---

## SCENE LAYOUT & CAMERA POSITIONS

### EmperorScene Viewport Layout
**Base Canvas:** 384×216 (design resolution for mobile scaling)
**Safe Area:** Full screen (no letterboxing expected)

```
┌─────────────────────────────────────────┐
│         [ESTATE BACKGROUND]             │  Top: Estate building, garden
│                                          │
│  [EMPEROR]          [PLAYER]            │  Middle: Characters centered
│  (center-right)     (center-left)       │
│                                          │
│  ┌──────────────────────────────────┐   │  Bottom: Dialogue Panel
│  │ EMPEROR: "I didn't betray you." │   │  (ColorRect, semi-transparent)
│  │ [Continue ▶]                    │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

**Character Positions (World Coordinates):**
- **Emperor Figure:** x=250, y=100 (background, slumped initially, animates to death pose)
- **Player:** x=150, y=120 (foreground, moves/reacts with dialogue)
- **BossBlackwood:** x=300, y=150 (final stand location, dies here)

**Camera:**
- Fixed on scene center (no panning during reckoning)
- Focus on Emperor and Player relationship
- Dialogue panel overlays bottom (CanvasLayer, layer 1)

---

## ANIMATION TIMING FOR VOICEOVER SYNC

### Emperor Confession (Line 1: "I didn't betray you.")
**Voice Duration:** ~2.5 seconds (typical read)
**Animation Sync:**
- **0.0s:** Emperor face appears, eye contact with crew
- **0.5s:** Emperor looks down (shame) as line spoken
- **1.2s:** Emperor's hand moves to heart (earnest plea gesture)
- **2.0s:** Hold pose, await input
- **2.5s:** Line ends, pause for player interaction

**Voiceover Record Timing:** Record for 3–4 seconds, deliver naturally (will trim/sync in editor)

---

### Crew Response (Line 3: "The Flats ain't about who's right...")
**Voice Duration:** ~4 seconds
**Animation Sync:**
- **0.0s:** Player character stands tall, hand to chest
- **1.0s:** Player looks at Emperor (turning point emotionally)
- **2.0s:** Player's hand clenches (resolve, strength)
- **3.0s:** Player stands firm, maintains eye contact
- **4.0s:** Hold final pose (proud, weary)

**Voiceover Record Timing:** Record for 5 seconds, deliver with conviction building

---

## RECORDING SESSIONS BREAKDOWN

### Session 1: Emperor Confession (1 actor, ~20 minutes)
**Actor Role:** EMPEROR
**Lines to Record:**
1. "I didn't betray you."
2. "I made a deal with The Corrupted Six to save your lives."
3. "I thought if I gave them the jobs, they'd let you walk. I was wrong."

**Delivery Notes:**
- Slow, measured pace (elderly, weary)
- Each line has weight (guilt, explanation, regret)
- Record each line 2–3 takes
- Record with ambient room tone (slight reverb for intimate confession)

**Audio Format:** WAV, 44.1 kHz, mono or stereo

---

### Session 2: Crew Responses (2–3 actors, ~30 minutes)
**Actor Roles:** CREW (multiple voices layered)
**Forgive Path Lines:**
1. "We know. We've always known."
2. "You made a mistake. So did we."
3. "The Flats ain't about who's right — it's about who's still standing. And we're standing."

**Turn Away Path Lines:**
- (Recorded as NARRATOR, see below)

**Delivery Notes:**
- Multiple voices (cast 2–3 actors to layer, or same actor in different register)
- Unified tone but distinct individuals
- "The Flats" reference: hometown pride, defiance
- Record full 3-line sequence as one take (flow, rhythm)
- Record each line separately for flexibility in editing

---

### Session 3: Narrator (1 actor, ~15 minutes)
**Actor Role:** NARRATOR
**Lines to Record:**
1. "The Emperor died that night, surrounded by the crew he'd failed and saved in equal measure." (Forgive path)
2. "The crew said nothing. There was nothing left worth saying." (Turn Away path)
3. "The Emperor died that night — alone in a room full of the people he'd failed." (Turn Away path)

**Delivery Notes:**
- Noir voiceover style (film noir, GTA radio DJ)
- Deep, measured voice
- Slight world-weariness (observing, not judging)
- Record 2–3 takes per line
- Emphasize period (".") pauses

---

## FUTURE BOSS DIALOGUE STRUCTURE

For each of the 6 bosses (Slices 3.18–3.23), follow this template:

### BOSS X: [NAME] — [TITLE]
**Location:** [Location]
**Defeat Dialogue:** 2–3 lines (confession style, similar to Emperor)

**Actor:** [New voice for each boss, or shared "boss" voice]
**Line 1:** "[Confession about crime/leverage]" — tone: [defiant/resigned/boastful/broken]
**Line 2 (optional):** "[Additional context]" — tone: [escalation or resignation]
**Line 3 (if dialogue branches):** "[Final statement]" — tone: [finality]

**Choices:**
- SPARE: Heat -5, boss owes crew, potential endgame ally
- EXECUTE: Heat +15, ruthlessness message to other bosses

**Voiceover Session Time:** 15–20 minutes per boss
**Actors Needed:** 6 new voice actors (1 per boss) for distinct personalities

---

## ANIMATION ASSET CHECKLIST

**For Emperor Scene:**
- [ ] Emperor Figure sprite (slumped, defeated pose) — idle animation
- [ ] Emperor death fade animation (dissolve to transparent over 2 seconds)
- [ ] Emperor gesture animations (hand to chest, reaching out, looking down)
- [ ] Player character animations:
  - [ ] Idle (standing, watching)
  - [ ] React to dialogue (nod, step forward, turn away)
  - [ ] Hand to chest pose (pride moment)
- [ ] BossBlackwood final stand animations:
  - [ ] Entry pose
  - [ ] Attack cycle (approach, strike, retreat)
  - [ ] Hit reactions
  - [ ] Death fade (dissolve shader)
- [ ] Dialogue panel animations:
  - [ ] Fade in/out (ColorRect alpha)
  - [ ] Button appear/disappear
  - [ ] Text scroll or fade (if desired)

**For Boss Encounters (Future):**
- [ ] Boss defeat animations (kneel, slump, special death)
- [ ] Boss confession poses (vulnerable, exposed)
- [ ] Dialogue panel consistent styling across all bosses

---

## TECHNICAL NOTES FOR ANIMATORS

**Game Engine:** Godot 4.7.1
**Screen Resolution (Design Canvas):** 384×216 pixels
**Aspect Ratio:** 16:9 (mobile landscape)
**Frame Rate:** 60 FPS
**Sprite Scaling:** Use scale-to-fit; assume 1 unit ≈ 1 pixel in design space

**Animation File Format:**
- Sprite sheets: PNG with transparent background
- Frame duration: ~16.67 ms per frame (60 FPS)
- Export as separate frames or spritesheet + JSON
- Color depth: 8-bit indexed or 32-bit RGBA

**Godot Scene Structure:**
- Sprites imported with "filter: nearest" (retro pixel-art style)
- Animations driven by AnimationPlayer nodes or code (frame timing)
- Dialogue panel is UI (CanvasLayer, layer 1), always on top
- Characters are Node2D in main scene (layer 0, behind UI)

**Cutscene Sequencing:** Uses CutsceneDirector autoload (Godot-specific)
- Tweens controlled via Tween API
- Property animation: `modulate:a` for alpha fade, `position` for movement

---

## DELIVERY FORMAT & CHECKLIST

**For Voiceover:**
- [ ] WAV files, 44.1 kHz, 24-bit (or 16-bit minimum)
- [ ] One file per line (easier to sync and edit)
- [ ] Filename format: `[SPEAKER]_[LINE_NUMBER]_[TAKE].wav`
  - Example: `EMPEROR_001_TAKE02.wav`
- [ ] Metadata/markers in file (optional, helpful for editor sync)

**For Animations:**
- [ ] PNG sprites with transparent backgrounds
- [ ] Spritesheet format (labeled, grid-aligned)
- [ ] Frame list (duration per frame, sequence order)
- [ ] Color palette reference (for consistency)
- [ ] MD5/CRC checksum for version tracking

**Documentation:**
- [ ] Voiceover script (final, approved lines before recording)
- [ ] Animation storyboard (rough sketches of key poses)
- [ ] Timing spreadsheet (voice duration vs. animation frames)

---

## SUMMARY

**Total Voiceover Duration:** ~15–20 minutes of final audio (3–5 min Emperor scene, 12–15 min across 6 bosses)
**Total Animation Scenes:** 7 (1 Emperor, 6 bosses, 1 epilogue)
**Voice Actors Needed:** ~4–6 (1 Emperor, 2–3 Crew voices, 1 Narrator, 6 bosses)
**Recording Sessions:** 3–9 (depends on actor availability)
**Animation Asset Count:** 50–100 sprites/frames (depends on detail level)

**Critical Path:**
1. Finalize all dialogue lines (Architect approval)
2. Record voiceover with approved script
3. Sync voiceover to animation timing
4. Create animations timed to voice
5. Integrate animations into Godot scenes
6. Test lip-sync (if dialogue UI supports it later)

---

**Document Version:** 1.0
**Last Updated:** 2026-07-20
**Status:** Ready for voiceover & animation production
