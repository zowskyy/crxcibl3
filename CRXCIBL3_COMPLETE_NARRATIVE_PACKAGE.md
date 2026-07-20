# CRXCIBL3 — Complete Narrative & Production Package
## For Animation & Voiceover Production

**Version:** 1.0  
**Last Updated:** 2026-07-20  
**Status:** Ready for Production  

---

## TABLE OF CONTENTS

1. Story Context & Lore
2. Dialogue by Scene
3. Character Voice Profiles
4. Timing & Sync Guide
5. Recording Session Breakdown
6. Animation Asset Requirements
7. Implementation Notes

---

## SECTION 1: STORY CONTEXT & LORE

### The World: Beach Boulevard — A Portrait of Decay

Beach Boulevard is twelve miles of cracked sidewalk and boarded storefronts running along a coastline nobody comes to see anymore. The ocean's still out there somewhere behind chain-link and razor wire, but the water's the only clean thing left. The palm trees are dead or dying, bleached gray, jutting out of the concrete like bones.

Three crews carve up what's left of it, fighting over **The Rune** — an encrypted digital currency that buys anything from police protection to black-market hardware. It's the only thing worth killing over when everything else has already been picked clean.

### The Fall: The Seven Sorrows

The Emperor called it the Seven Sorrows: seven simultaneous jobs engineered by the Emperor's six most trusted advisors — **The Corrupted Six** — who wanted the Rune, the territory, and the Emperor dead. The jobs were traps. They all went wrong. The crew scattered. The Flats burned.

### The Reunion & Reckoning

One by one, the crew crawled out of the shadows. They reunited in a warehouse, broken but determined. They planned their revenge: take down each of the Corrupted Six, one at a time. Then face The Emperor and demand the truth.

### The Story Arc (Game Acts)

**Act 1–2:** Boardwalk level (TestRoom). Crew fights rival grunts, clears the Crack House generator, upgrades at the Bodega. Heat and Stress meters climb.

**Act 2 Climax:** Rooftop encounter. Blackwood (The Priest) surprise boss. He flees, triggering the car chase getaway.

**Act 2.19:** Car chase across the coastal highway. Escape the cop pursuit for 45 seconds.

**Act 3 Climax:** Emperor Estate. Blackwood makes his final stand. After defeat, the Emperor reveals his confession. Player chooses: FORGIVE or EXECUTE. Then: THE END.

---

## SECTION 2: DIALOGUE BY SCENE

### SCENE 1: BOARDWALK / TESTROOM

**Context:** Introductory level. Crew fights through enemy waves, encounters Bodega Shop (optional upgrades), optional Crack House generator. Low dialogue — mostly ambient action.

**Ambient Radio Chatter (Optional):** 
If implemented, a paranoid fixer voice over the radio broadcasts warnings/commentary:
- *"Enforcer spotted near the liquor store. Heat's rising, people. Watch your backs."*
- *"Runes flowing. Somebody's winning today. Ain't gonna be long 'fore somebody else takes that."*
- *"Heat's climbing. City's on edge. Move fast, crew. Move smart."*

**Bodega Shop Interaction (Silent):**
Player approaches the shop. NPC stands behind counter (no voice yet — placeholder for future NPC dialogue system). Player sees upgrade menu, purchases with Runes, leaves.

---

### SCENE 2: ROOFTOP SPRINT (RooftopScene)

**Context:** Act 2.18. Blackwood surprise encounter. He's defending the rooftop entrance to the apartment tower. Combat sequence with dialogue beats.

**Pre-Fight Dialogue:**

```
SCENE: Player approaches rooftop edge. Building silhouette, sunset backdrop.
TRIGGER: Player enters DETECTION_RADIUS (150 units)

LINE 1 — BLACKWOOD ENTRANCE
SPEAKER: Blackwood (encountered for the first time)
TEXT: "Well, well. Look who finally found their way up here."
TIMING: 2–3 seconds
TONE: Casual menace. He wasn't hiding; he was waiting.
VOICEOVER: Deep, measured voice. Confident. Priest-like cadence.
ANIMATION: Blackwood steps out from shadow, arms spread (open greeting or combat stance?)

LINE 2 — BLACKWOOD THREAT
SPEAKER: Blackwood
TEXT: "I've been expecting the Emperor's dogs. Didn't think you'd make it this far."
TIMING: 2–3 seconds
TONE: Praising their effort, dismissing their chances.
VOICEOVER: Same calm tone. Slight smile in the voice.
ANIMATION: Blackwood draws a staff (glowing, tech-enhanced, looks like a weapon)

LINE 3 — PLAYER RESPONSE (Flavor, internal)
SPEAKER: Player (internal monologue, no voice yet)
TEXT: "This is it. This is one of them."
TIMING: 1 second
TONE: Grim realization.
VOICEOVER: (Optional) Player voice, low and determined.
ANIMATION: Player stance shifts to combat ready. Hand moves to weapon.
```

**During Fight:**
- No dialogue (pure action combat)
- Enemy summons deacons every 8 seconds
- Blackwood cycles through orbiting attacks
- At 33 HP threshold, Blackwood flees

**Flee Sequence:**

```
SCENE: Blackwood health drops to ~35 HP. He stops attacking.

LINE 1 — BLACKWOOD FLEE TRIGGER
SPEAKER: Blackwood
TEXT: "You're tougher than I expected. But you ain't gonna stop what's coming."
TIMING: 1–2 seconds
TONE: Retreat, but defiant.
VOICEOVER: Slight panic breaking through confidence. Realizes he's losing.
ANIMATION: Blackwood looks for escape route. Eyes dart.

ACTION: Blackwood triggers a white flashbang ColorRect fade (visual escape effect)
        Crew shielding eyes from flash

LINE 2 — BLACKWOOD FINAL LINE
SPEAKER: Blackwood (from offscreen, distance)
TEXT: "See you in the Hills."
TIMING: 1 second
TONE: Chilling promise. He knows where they're going next.
VOICEOVER: Voice echoing, distant, cold.
ANIMATION: (Visual only) Blackwood sprints offscreen left. Dust/motion blur.
```

**Post-Flee State:**
- GameState.bosses_fought.append("Blackwood_rooftop")
- GameState.modify_heat(+15.0)
- Scene auto-transitions to CarChaseScene after 1.5-second delay

---

### SCENE 3: CAR CHASE GETAWAY (CarChaseScene)

**Duration:** 45 seconds to 2 minutes (player-driven, survive duration)
**Dialogue:** NONE (pure action)

**HUD Text (Visual, no voice):**
- "BLACKWOOD HEADED FOR THE HILLS..."
- "SURVIVE THE CHASE..."
- Timer countdown visible on screen

**On Victory (automatic transition to Emperor scene):**

```
VISUAL ONLY (no dialogue):
Car pulls into estate gates. Engine stops. Crew steps out.

LABEL TEXT (on-screen, no voiceover):
"THE EMPEROR'S ESTATE"

Heat adjustment: +25 (adrenaline from chase)
Next scene: EmperorScene (automatic load)
```

---

### SCENE 4: EMPEROR ESTATE RECKONING (EmperorScene)

**Duration:** 5–10 minutes total (2 min combat + 3–5 min dialogue)
**This is the game's narrative climax.**

#### PHASE 1: BLACKWOOD'S FINAL STAND (Combat)

```
SCENE: Estate interior. Blackwood stands between crew and the Emperor figure.

DURATION: 1–2 minutes (player-driven combat)

TRIGGER: Player enters BossBlackwood encounter (final_stand=true, no SURPRISED phase)

NO DIALOGUE during fight. Pure action.
- Blackwood attacks aggressively from start (no 2-second idle period like rooftop)
- Emperor figure visible in background, slumped
- Status: Fight until Blackwood health = 0

UPON DEATH:
- Blackwood slumps to ground
- Dissolve fade (shader) over 1 second
- 1.5-second pause (crew catches breath)
- GameState.mark_boss_defeated("Blackwood", executed=true, finisher=active_hero_name)

HEAT ADJUSTMENT: None during fight transition
```

#### PHASE 2: THE RECKONING (Dialogue Sequence)

```
SCENE: Dialogue panel appears at bottom of screen.
SETUP: 1.5 seconds after Blackwood dissolves

ColorRect panel fades in (semi-transparent black)
Label text starts displaying

PACING: Each line displays for 3–5 seconds, then player clicks SPACE or 
        Continue button to advance to next line.
```

##### **CONFESSION SEQUENCE**

The Emperor confesses his betrayal. Three lines, one speaker.

```
===============================================================================
LINE 1: EMPEROR CONFESSION (Part 1 of 3)
===============================================================================

SPEAKER: EMPEROR
REAL_NAME: (Not named yet in game, but from lore: "The Emperor")

TEXT:
"I didn't betray you."

TIMING: Display 3–4 seconds, await player input (SPACE or Continue button)

CHARACTER_POSITION: Emperor figure, center-right, slumped in chair

ANIMATION_CUE:
- 0.0s:  Emperor face appears on-screen, eyes closed (defeated)
- 0.5s:  Emperor opens eyes, looks at crew (eye contact, shame)
- 1.5s:  Emperor looks down (avoiding continued eye contact)
- 2.0s:  Emperor's hand trembles slightly
- 3.0s:  Hold pose (awaiting player input)

VOICEOVER_DIRECTION:
- Deep, elder male voice (age 60–70s)
- Resigned, not defensive
- Speaks slowly, each word has weight
- Slight rasp (been smoking, drinking)
- Tone: Confession, not plea. He's accepting consequences.
- Emphasis: Slight pause after "betray" — the most important negation

VOICE_LENGTH: Record for ~3 seconds naturally; will be trimmed/synced to display

REFERENCE: Godfather Part II — Vito's final scenes, or Omar Bradley's soft-spoken regret
```

```
===============================================================================
LINE 2: EMPEROR CONFESSION (Part 2 of 3)
===============================================================================

SPEAKER: EMPEROR

TEXT:
"I made a deal with The Corrupted Six to save your lives."

TIMING: Display 3–4 seconds, await player input

CHARACTER_POSITION: Emperor figure

ANIMATION_CUE:
- 0.0s:  Emperor looks up (direct eye contact, explanation)
- 0.8s:  Emperor's hands move (open palms, plea gesture)
- 1.5s:  Emperor leans forward slightly (urgency)
- 2.5s:  Emperor leans back (resignation)
- 3.0s:  Hold pose

VOICEOVER_DIRECTION:
- Same voice as Line 1
- Slightly more urgent here (explanation, not just confession)
- Emphasis: "deal" — the word that explains everything
- Pace: Slower, deliberate. Let the words land.
- Sub-text: "I thought this would save you"

VOICE_LENGTH: Record for ~4 seconds
```

```
===============================================================================
LINE 3: EMPEROR CONFESSION (Part 3 of 3)
===============================================================================

SPEAKER: EMPEROR

TEXT:
"I thought if I gave them the jobs, they'd let you walk. I was wrong."

TIMING: Display 4–5 seconds, await player input

CHARACTER_POSITION: Emperor figure

ANIMATION_CUE:
- 0.0s:  Emperor's expression darkens (realization of failure)
- 1.0s:  Emperor closes eyes (accepting guilt)
- 2.0s:  Emperor's shoulders slump further (defeat)
- 3.5s:  Emperor looks down, shakes head slightly (regret)
- 4.0s:  Hold final pose (exhausted, broken)

VOICEOVER_DIRECTION:
- Same voice, now trailing off (giving up)
- Emphasis: "I was wrong" — final acceptance
- Tone: Finality. No more explaining. This is the end.
- Emotional arc: Plea → realization → acceptance

VOICE_LENGTH: Record for ~5 seconds (longest line, needs breathing room)
```

**After Line 3 completes:**

```
VISUAL: Dialogue panel text clears

NEW TEXT (System/Narrator, no voiceover):
"He's waiting for an answer."

DURATION: 2 seconds (just enough to read)

ANIMATION: Emperor sits in stillness, awaiting judgment

THEN: Two buttons fade in
  [FORGIVE HIM]  |  [TURN AWAY]

Emperor freezes in defeated pose
Player has 5–30 seconds to decide (no time limit, player-paced)
```

---

##### **CHOICE PHASE**

Player clicks one of two buttons. This determines the dialogue path.

```
CHOICE POINT (Player clicks button):
├─ FORGIVE HIM
│   └─ Go to ANSWER_FORGIVE path (below)
│
└─ TURN AWAY
    └─ Go to ANSWER_TURN_AWAY path (below)
```

---

##### **ANSWER PATH 1: FORGIVE HIM**

If player clicks FORGIVE HIM, the crew responds with compassion and solidarity.

```
===============================================================================
LINE 1: CREW RESPONSE (Forgive Path, Part 1 of 4)
===============================================================================

SPEAKER: CREW (multiple voices blended, or 1 actor varied)
IMPLIED_SPEAKER: Big Body or active hero, answering on behalf of crew

TEXT:
"We know. We've always known."

TIMING: Display 3–4 seconds, await player input

CHARACTER_POSITION: Player character (active hero), steps forward

ANIMATION_CUE:
- 0.0s:  Player character walks forward (1 step, confident)
- 0.3s:  Player character nods (acknowledgment)
- 1.0s:  Player character looks at Emperor (eye contact, understanding)
- 2.0s:  Player character places hand over heart (earnest)
- 3.0s:  Hold pose

VOICEOVER_DIRECTION:
- Multiple crew voices layered (or 1 actor in slightly lower register than Emperor)
- Calm, knowing tone
- Not accusatory — understanding
- Emphasis: "We know" — they figured it out long ago
- Sub-text: "You couldn't hide this from us"

VOICE_LENGTH: Record for ~3–4 seconds
```

```
===============================================================================
LINE 2: CREW RESPONSE (Forgive Path, Part 2 of 4)
===============================================================================

SPEAKER: CREW

TEXT:
"You made a mistake. So did we."

TIMING: Display 3–4 seconds, await player input

CHARACTER_POSITION: Player character

ANIMATION_CUE:
- 0.0s:  Player character looks at Emperor (continued eye contact)
- 1.0s:  Player character looks down at ground (introspection)
- 1.5s:  Player character nods slightly (acceptance of shared guilt)
- 2.5s:  Player character looks back up (peace, forgiveness)
- 3.5s:  Hold pose

VOICEOVER_DIRECTION:
- Crew voice, steady and mature
- Emphasis: Both clauses equally weighted ("You...mistake" = "We...did")
- Tone: Peer-to-peer. Not absolving, just equalizing.
- Sub-text: "We're all broken. We're all trying."

VOICE_LENGTH: Record for ~4 seconds
```

```
===============================================================================
LINE 3: CREW RESPONSE (Forgive Path, Part 3 of 4)
===============================================================================

SPEAKER: CREW

TEXT:
"The Flats ain't about who's right — it's about who's still standing. And we're standing."

TIMING: Display 4–5 seconds, await player input

CHARACTER_POSITION: Player character

ANIMATION_CUE:
- 0.0s:  Player character straightens posture (resolve)
- 0.5s:  Player character brings hand to chest (pride)
- 1.5s:  Player character stands tall (strength)
- 2.5s:  Player character looks at Emperor (closure)
- 4.0s:  Hold final power pose

VOICEOVER_DIRECTION:
- Crew voice, full strength and conviction
- Emphasis: "still standing" — the thesis of the entire game
- Tone: Street wisdom. Hard-won. This is the code.
- Emotional arc: Builds from acceptance → strength → defiance
- Reference: West Coast hip-hop closing statements (Tupac, Too $hort, Cypress Hill vibes)

VOICE_LENGTH: Record for ~5 seconds (power ending)

SPECIAL NOTE: This is the game's thematic climax. The narrative crux. 
             The crew's answer to everything that happened. 
             Deliver with absolute conviction.
```

```
===============================================================================
LINE 4: NARRATOR EPILOGUE (Forgive Path, Part 4 of 4)
===============================================================================

SPEAKER: NARRATOR (Third-person, omniscient)
TONE: Elegiac, final, historical

TEXT:
"The Emperor died that night, surrounded by the crew he'd failed and saved in equal measure."

TIMING: Display 4–5 seconds, await player input

CHARACTER_POSITION: Wide shot — Emperor still in chair, crew standing around him

ANIMATION_CUE:
- 0.0s:  Emperor begins fade animation (modulate.alpha 1.0 → 0.0)
- 0.5s:  Emperor's expression becomes peaceful (no more struggle)
- 1.5s:  Emperor's eyes close (acceptance)
- 2.0s:  Emperor nearly transparent (fading)
- 4.0s:  Emperor fully transparent/gone

VOICEOVER_DIRECTION:
- Separate voice from Emperor and Crew
- Narrator voice: deep, measured, noir tone
- Like a radio announcer or documentary voice-over
- Emphasis: "surrounded" and "equal measure" — the balance of his life
- Tone: Not sad, not celebratory — observational. Historical.
- Sub-text: "This is how history records it"

VOICE_LENGTH: Record for ~5 seconds

SPECIAL NOTE: This line is NARRATOR, not dialogue. 
             No character is speaking on-screen.
             Pure observation of events.
```

**After Line 4 completes:**

```
VISUAL: Dialogue panel fades to black
        Emperor is gone (fully faded)
        Crew stands in the empty space

AUTOMATIC PROGRESSION (no player input):
1. Wait 1 second (silence, absorption)
2. GameState.boss_executed["Blackwood"] = true
3. GameState.emperor_forgiven = true
4. GameState.modify_heat(-50.0)  # War dies with him
5. Record "emperor_reckoning" quest completion
6. (PAUSE) 1 second (eerie silence)
7. CutsceneDirector sequences final beats...
```

---

##### **ANSWER PATH 2: TURN AWAY**

If player clicks TURN AWAY, the crew rejects the Emperor. Colder, lonelier ending.

```
===============================================================================
LINE 1: NARRATOR REJECTION (Turn Away Path, Part 1 of 2)
===============================================================================

SPEAKER: NARRATOR

TEXT:
"The crew said nothing. There was nothing left worth saying."

TIMING: Display 4–5 seconds, await player input

CHARACTER_POSITION: Active player character turns away from Emperor (turns to face downstage)

ANIMATION_CUE:
- 0.0s:  Player character looks at Emperor one last time (finality)
- 0.5s:  Player character turns around slowly (back to Emperor)
- 1.5s:  Player character walks away (1–2 steps downstage)
- 2.5s:  Player character stops, looks down (guilt, but resolved)
- 4.0s:  Hold pose (back to Emperor, facing away)

VOICEOVER_DIRECTION:
- Same narrator voice as Forgive path
- Colder, more distant
- Emphasis: "nothing left worth saying" — finality, rejection
- Tone: Judgment without mercy. Silence as punishment.
- Sub-text: "Some things can't be forgiven"

VOICE_LENGTH: Record for ~5 seconds
```

```
===============================================================================
LINE 2: NARRATOR DEATH ALONE (Turn Away Path, Part 2 of 2)
===============================================================================

SPEAKER: NARRATOR

TEXT:
"The Emperor died that night — alone in a room full of the people he'd failed."

TIMING: Display 4–5 seconds, then auto-progress

CHARACTER_POSITION: Wide shot — Emperor slumped alone, crew walking away

ANIMATION_CUE:
- 0.0s:  Emperor reaches out hand (plea, now unheard)
- 0.5s:  Emperor's hand falls (accepted rejection)
- 1.0s:  Crew walks away from screen (downstage, leaving him)
- 2.0s:  Camera pulls back (isolating Emperor in the space)
- 2.5s:  Emperor begins fade (modulate.alpha 1.0 → 0.0)
- 4.0s:  Emperor gone (isolation, finality)

VOICEOVER_DIRECTION:
- Same narrator voice
- Emphasis: "alone" and "failed" — twin sorrows
- Tone: Mournful, cold. Not sad — final.
- Sub-text: "He earned this solitude"

VOICE_LENGTH: Record for ~5 seconds
```

**After Line 2 completes:**

```
VISUAL: Dialogue panel fades to black
        Emperor is gone
        Crew is gone
        Empty estate room

AUTOMATIC PROGRESSION (no player input):
1. Wait 1 second (profound silence)
2. GameState.boss_executed["Blackwood"] = false  # He was spared, technically
3. GameState.emperor_forgiven = false
4. GameState.modify_heat(+10.0)  # World knows crew is merciless
5. Record "emperor_reckoning" quest completion
6. (PAUSE) 1 second
7. CutsceneDirector sequences final beats...
```

---

#### PHASE 3: CLOSING CUTSCENE (Automated, Non-Interactive)

After either dialogue path ends, the same closing sequence plays:

```
VISUAL SEQUENCE (2–3 seconds per step, 6–9 seconds total):

STEP 1: Emperor Fade (already in progress from dialogue)
- modulate.alpha tween: 1.0 → 0.0 over 2.0 seconds
- Emperor figure dissolves, dies
- Sound: Soft, ambient (wind? distant city?)

STEP 2: Silence (1.0 second)
- Black screen, crew position (they're standing in the dark)
- No sound, no movement
- Silence is the statement

STEP 3: SaveSystem.save_game() [invisible, background]
- Player's choices are permanently recorded
- Game state written to file
- No on-screen indication

STEP 4: Final Transition (1.0–2.0 seconds)
- Fade to black complete
- Scene change to Epilogue or Title screen (future implementation)
- Music swells (to be composed)
```

**This is the end of Act 3. Game concludes.**

---

## SECTION 3: CHARACTER VOICE PROFILES

### PRIMARY VOICES

#### 1. THE EMPEROR
**Age:** 60–75 years old  
**Accent/Dialect:** Cultured West Coast, possibly Spanish/Latin heritage  
**Vocal Quality:** Deep baritone, slightly raspy (smoking/age)  
**Emotional Range:** Resigned, ashamed, seeking forgiveness without begging  
**Reference:** Vito Corleone (Godfather), Michael Corleone in final scene, or real-world figures like retired mafia dons or political elder statesmen in defeat

**How to Record:**
- Speak slowly, emphasize individual words
- Don't rush lines; let weight settle
- Slight quaver on emotional peaks (guilt breaking through)
- Pause between sentences (processing, regret)
- Three takes per line; pick the one with most authenticity

**Key Lines:**
1. "I didn't betray you." — Quiet, factual, unapologetic
2. "I made a deal with The Corrupted Six to save your lives." — Explanation, urgency, then resignation
3. "I thought if I gave them the jobs, they'd let you walk. I was wrong." — Long exhale, failure, finality

---

#### 2. THE CREW (Collective Voice)
**Composition:** 2–3 voice actors blended, or 1 actor varied in register  
**Accent/Dialect:** West Coast urban, 90s vernacular, Black/Latino/Asian/white working-class mix  
**Vocal Quality:** Grounded, authentic, streetwise but not exaggerated  
**Emotional Range:** Knowing calm, peer-level understanding, street wisdom, righteous strength  
**Reference:** Characters from *Menace II Society*, *Boyz n the Hood*, *Training Day* — not stereotypical, but authentic urban voices

**How to Record:**
- Don't over-perform; underplay strength (confidence doesn't need volume)
- "We know. We've always known." — Calm certainty, like stating fact
- "You made a mistake. So did we." — Equalize; neither accusatory nor absorbent
- "The Flats ain't about who's right..." — Build from understanding → conviction → power. This is the crescendo.
- Record with slight reverb (suggest the space of the estate)

**Key Lines:**
1. "We know. We've always known." — Calm, knowing
2. "You made a mistake. So did we." — Balanced, mature
3. "The Flats ain't about who's right — it's about who's still standing. And we're standing." — Full conviction, thesis statement

---

#### 3. NARRATOR (Third-Person Voice-Over)
**Age:** 40–60, ageless quality  
**Accent/Dialect:** Neutral broadcast or slight noir rasp  
**Vocal Quality:** Deep, measured, authoritative without emotion  
**Emotional Range:** Observational, historical, contemplative but detached  
**Reference:** Film noir voice-over (*Blade Runner*, *Sin City*), GTA radio DJ, or documentary narrator

**How to Record:**
- Speak as if recording history, not narrating drama
- No sentimentality; let the facts carry weight
- Slight pause before key words ("surrounded," "alone," "equal measure")
- Deeper register than character voices
- Ambient space (cathedral-like echo)

**Key Lines:**
1. "The Emperor died that night, surrounded by the crew he'd failed and saved in equal measure." — Balanced, elegiac
2. "The crew said nothing. There was nothing left worth saying." — Cold, final
3. "The Emperor died that night — alone in a room full of the people he'd failed." — Mournful, isolated

---

### FUTURE BOSS VOICES

**Slice 3.18–3.23** will implement dialogue for each of the 6 bosses. Here's the template:

#### BOSS ENCOUNTER VOICE TEMPLATE

**Boss Name:** [The Fixer / The Broker / etc.]  
**Actor:** (Cast new actor for each boss, or use ensemble with distinctive register modulation)  
**Defeat Dialogue (2–3 lines):**
1. **Approach** — "The [location/operation] was mine. You can't take what's mine."
2. **Revelation** — "[Confession about their crime, their motivation, their weakness]"
3. **Final Word** — "[Acceptance of death or defiance]"

**Voice Direction:** 
- Each boss has a distinct vocal personality reflecting their crime
- The Fixer (politician): smooth, urbane, convincing
- The Broker (businessman): colder, transactional, calculating
- The Pusher (doctor): unhinged, self-convinced, proud
- The Warden (authority): gravelly, military, commanding
- The Trader (tech): young, arrogant, dismissive
- The Priest (Blackwood): already done (rooftop + final stand)

---

## SECTION 4: TIMING & SYNC GUIDE

### Overall Pacing

| Phase | Duration | Description |
|-------|----------|-------------|
| Blackwood Final Stand (Combat) | 1–2 min | Player-driven, no dialogue |
| Dialogue Panel Setup | 0.5 sec | Fade-in |
| Confession Lines (3×) | ~10 sec | 3–4 sec each, await input |
| Choice Reveal & Decision | 5–30 sec | Player-paced, no time limit |
| Answer Lines (2–4×) | ~12 sec | 3–5 sec each, await input (forgive path is 4 lines) |
| Narrator Closing | ~5 sec | Auto-plays, no input needed |
| Closing Cutscene (Emperor fade, silence, transition) | 4–6 sec | Non-interactive |
| **TOTAL** | **7–12 min** | (Dialogue: 3–5 min) |

### Line-by-Line Timing

#### Confession Sequence

| Line # | Speaker | Text | Display Time | Voice Length | Animation Notes |
|--------|---------|------|--------------|--------------|-----------------|
| 1 | Emperor | "I didn't betray you." | 3–4 sec | 2–3 sec | Eyes open, eye contact → down |
| 2 | Emperor | "I made a deal with The Corrupted Six to save your lives." | 3–4 sec | 3–4 sec | Hands gesture, leaning forward |
| 3 | Emperor | "I thought if I gave them the jobs, they'd let you walk. I was wrong." | 4–5 sec | 4–5 sec | Slump, head shake, acceptance |

#### Forgive Path

| Line # | Speaker | Text | Display Time | Voice Length | Animation Notes |
|--------|---------|------|--------------|--------------|-----------------|
| 1 | Crew | "We know. We've always known." | 3–4 sec | 3–4 sec | Player steps forward, nod |
| 2 | Crew | "You made a mistake. So did we." | 3–4 sec | 3–4 sec | Look down, introspection, look back up |
| 3 | Crew | "The Flats ain't about who's right — it's about who's still standing. And we're standing." | 4–5 sec | 4–5 sec | Stand tall, hand to chest, power pose |
| 4 | Narrator | "The Emperor died that night, surrounded by the crew he'd failed and saved in equal measure." | 4–5 sec | 4–5 sec | Emperor fades, crew stands witness |

#### Turn Away Path

| Line # | Speaker | Text | Display Time | Voice Length | Animation Notes |
|--------|---------|------|--------------|--------------|-----------------|
| 1 | Narrator | "The crew said nothing. There was nothing left worth saying." | 4–5 sec | 4–5 sec | Player turns away, walks |
| 2 | Narrator | "The Emperor died that night — alone in a room full of the people he'd failed." | 4–5 sec | 4–5 sec | Emperor alone, fades, isolation |

---

## SECTION 5: RECORDING SESSION BREAKDOWN

### Session 1: THE EMPEROR (1 actor, ~30 minutes)

**Lines to Record:**
1. "I didn't betray you."
2. "I made a deal with The Corrupted Six to save your lives."
3. "I thought if I gave them the jobs, they'd let you walk. I was wrong."

**Recording Notes:**
- Book an actor who can do "elder statesman in defeat" — gravitas + vulnerability
- Record in a quiet room with slight reverb (ecclesiastical space)
- 2–3 takes per line, pick the most authentic
- Let pauses breathe; don't fill silence
- Director note: "This is a confession, not a plea. You're accepting consequences."

**Audio Specs:**
- WAV, 44.1 kHz, 24-bit (or 16-bit minimum)
- One file per line (easier to sync and edit)
- Filename: `EMPEROR_001_Didnt_Betray_TAKE02.wav` etc.
- Ambient room tone: record 30 seconds of silence for background hum

---

### Session 2: THE CREW (2–3 actors, ~45 minutes)

**Lines to Record:**

**Forgive Path:**
1. "We know. We've always known."
2. "You made a mistake. So did we."
3. "The Flats ain't about who's right — it's about who's still standing. And we're standing."

**Turn Away Path:**
- (None; narrator only)

**Recording Notes:**
- Cast 2–3 actors with distinct voices (if layering) or 1 actor who can vary register
- If using multiple actors:
  - Actor 1 (lead): lines 1–3, primary voice
  - Actor 2: layer underneath, harmony/echo (optional, for "crew" texture)
  - Actor 3: backing layer (optional, for depth)
- If single actor: record twice with different registers, layer them slightly offset
- Record with reverb to suggest estate space (cathedral-like, not intimate)
- Director note: "Underplay strength. You're confident, not loud. Peer-level, not condescending."

**Emotional Arc:**
- Line 1: Calm, knowing. State a fact.
- Line 2: Balanced, mature. Neither punishing nor absolving.
- Line 3: Build from Line 2 → conviction → power. This is the climax. "We're standing." — deliver with full belief.

**Audio Specs:**
- Same as Emperor session
- If layering: record main take + harmony take separately
- Merge in post-production with slight delay/pan

---

### Session 3: NARRATOR (1 actor, ~20 minutes)

**Lines to Record:**

**Forgive Path:**
1. "The Emperor died that night, surrounded by the crew he'd failed and saved in equal measure."

**Turn Away Path:**
1. "The crew said nothing. There was nothing left worth saying."
2. "The Emperor died that night — alone in a room full of the people he'd failed."

**Recording Notes:**
- Cast a voice actor with noir/documentary sensibility — not character acting, just observation
- Record in a smaller room (intimate, not vast) but add subtle reverb in post
- 2 takes per line; pick the one with least strain
- Pause before key words: "surrounded," "alone," "equal measure," "failed"
- Director note: "You're recording history. No sentimentality. The facts speak."

**Audio Specs:**
- Same as above
- These are "narrator V.O." files, separate from character dialogue
- Filename: `NARRATOR_FORGIVE_001_Surrounded_TAKE01.wav` etc.

---

### Estimated Total Time

| Session | Actor(s) | Lines | Estimated Time |
|---------|----------|-------|-----------------|
| 1 | 1 (Emperor) | 3 | 20–30 min |
| 2 | 2–3 (Crew) | 3 | 30–45 min |
| 3 | 1 (Narrator) | 3 | 15–20 min |
| **TOTAL** | **5–6 actors** | **9 lines** | **65–95 min** |

**Studio Rental:** 2–3 hours (buffer for setup, retakes, ambient tone)

---

## SECTION 6: ANIMATION ASSET REQUIREMENTS

### Character Sprites

**Emperor Figure**
- Idle pose (seated, defeated): `emperor_idle_seated.png` (size: ~256×256)
- Look down pose: `emperor_lookaside.png` (256×256)
- Hands gesture (open palms): `emperor_hands_open.png` (256×256)
- Lean forward: `emperor_leaning_forward.png` (256×256)
- Final slump (before fade): `emperor_slump_final.png` (256×256)
- All sprites: transparent background, facing right

**Player Character (Active Hero)**
- Standing idle: `player_idle.png` (128×128)
- Step forward: `player_step_forward.png` (128×128)
- Nod gesture: `player_nod.png` (128×128, head animation)
- Hand to chest (pride): `player_hand_to_chest.png` (128×128)
- Turn around (turn-away path): `player_turn_away.png` (128×128)
- All sprites: transparent background, facing right

**Boss Blackwood (Final Stand & Death)**
- Standing ready pose: `blackwood_ready_stance.png` (192×192)
- Attack animation frame 1: `blackwood_attack_01.png` (192×192)
- Attack animation frame 2: `blackwood_attack_02.png` (192×192)
- Death pose (slump): `blackwood_death_slump.png` (192×192)
- All sprites: transparent background, facing left (mirror of player)

### Animation Dissolve Shader Asset
- **File:** `enemy_dissolve.gdshader` (already in repo at `res://assets/shaders/`)
- **Usage:** Emperor figure uses this shader for death fade (modulate.alpha tween 1.0 → 0.0 over 2 seconds)
- **No modifications needed** — already implemented

### Dialogue UI Assets
- **Dialogue Panel:** ColorRect (semi-transparent black background)
  - Size: Full-width bottom area (384×80 pixels in design space)
  - Color: RGB(10, 10, 10) with 0.88 alpha
  - **Needed:** If a portrait frame is desired, provide `dialogue_portrait_frame.png` (100×120, border art)
- **Button Assets** (for FORGIVE / TURN AWAY / CONTINUE buttons):
  - Button normal: `button_default.png` (120×40)
  - Button hover: `button_hover.png` (120×40)
  - Button pressed: `button_pressed.png` (120×40)
  - All: transparent background, centered text

### Background/Scene Assets

**Emperor Estate Room**
- Background image: `emperor_estate_interior.png` (384×216, full viewport)
  - Style: Opulent, decaying. Hint of Gothic/estates. Muted colors.
  - Furniture: chairs, tables, shadows
  - Lighting: Twilight coming through windows, candlelight

**Optional Parallax Layers** (if adding depth):
- Layer 1 (far back): `estate_walls_distant.png`
- Layer 2 (mid): `estate_furniture_mid.png`
- Layer 3 (front): `estate_foreground.png`

---

### Asset Checklist

**Sprites to Create/Edit:**
- [ ] Emperor idle seated
- [ ] Emperor lookaside
- [ ] Emperor hands gesture
- [ ] Emperor leaning forward
- [ ] Emperor slump final
- [ ] Player idle
- [ ] Player step forward
- [ ] Player nod
- [ ] Player hand to chest
- [ ] Player turn away
- [ ] Blackwood ready stance
- [ ] Blackwood attack 01–02
- [ ] Blackwood death slump
- [ ] Dialogue panel border (optional)
- [ ] Button assets (normal/hover/pressed)
- [ ] Emperor estate background

**Shaders (Already Exist, No Changes):**
- ✓ `enemy_dissolve.gdshader` (used for Emperor fade)
- ✓ `heat_wave.gdshader` (scene overlay, unrelated to dialogue)

---

## SECTION 7: IMPLEMENTATION NOTES FOR ENGINEERS

### Sprite Animation Specifications

**All sprites should be:**
- PNG format with transparency
- No anti-aliasing (nearest-neighbor filter on import in Godot)
- Scaled to fit 384×216 design canvas proportionally
- Anchored consistently (e.g., Emperor at center-right, Player at center-left)

### Dialogue Panel Implementation

**Godot Structure:**
```
DialogueBox (CanvasLayer, layer 1)
├── Panel (ColorRect, semi-transparent background)
├── DialogueLabel (Label, centered, wrapped text)
├── ButtonContainer (HBoxContainer)
│   ├── ForgiveButton (Button, toggle_mode=false)
│   ├── TurnAwayButton (Button, toggle_mode=false)
│   └── ContinueButton (Button, toggle_mode=false)
└── ChoiceQuestion (Label, displayed only during choice phase)
```

**Dialogue Flow Script:**
- See `DialogueBox.gd` in Slice 3.18 implementation
- Exposes: `show_text(text)`, `show_choice(question, options)`, signals for state changes

### Signal Flow

**Signals emitted during reckoning:**
1. `Emperor.defeated` → triggers `EmperorScene._on_blackwood_defeated()`
2. `DialogueBox.continued` → triggers `_advance()` to next line
3. `DialogueBox.choice_made(index)` → triggers `_choose(index)` for choice path
4. `CutsceneDirector.cutscene_ended` → triggers scene transition

### Timing/Sync

- Voiceover timing: Use Godot's `Timer` nodes for delays between lines
- Animation timing: Use `Tween` for smooth transitions (2.0s fade for Emperor death)
- Audio playback: Use `AudioStreamPlayer` with `wait_to_finish = true` for sequential playback

### Future Extensibility

**For Slices 3.18–3.23 (boss encounters):**
- Reuse `DialogueBox` prefab across all 6 boss scenes
- Each boss scene will have its own dialogue script inheriting from a base `BossEncounter` class
- Dialogue triggers on boss defeat (health ≤ 0, similar to Emperor)
- Choices determine `GameState.boss_executed[boss_name]` and heat adjustment

---

## APPENDIX: CHARACTER REFERENCE (From Lore)

### The 12 Playable Heroes

| Name | Real Name | Class | Archetype | Backstory Snippet |
|------|-----------|-------|-----------|-------------------|
| Big Body | Marcus Williams | Enforcer | Tank | Bouncer, dreams of opening a gym. Code: no women, kids, innocents. |
| Ghost | Victor Reyes | Enforcer | Tank | Boxer, too many hits. Loves Slick (unrequited). |
| Mama's Boy | DeShawn Johnson | Enforcer | Tank | Lost mother to Moreau's opioids. Half-brother to Mouse (secret). |
| Slick | Elena Rodriguez | Wheelman | Support | Best driver. Father died racing. Never rats, never hurts civilians. |
| Grinder | Eddie Kowalski | Wheelman | Support | 5 years in San Quentin. Protective, angry, secretly noble. |
| Bonnie | Bonnie Greene | Wheelman | Support | Lost boyfriend Tyrell in drive-by. Fast, reckless, untouchable. |
| Byte | Kevin Chen | Hacker | Glass Cannon | Burned-out prodigy. Paranoid, hunted. Secret relationship with Vex. |
| Hacktivist | Maya Park | Hacker | Glass Cannon | Brother killed by cop. Political activist. Fierce, ideological. |
| Skeez | Archie Whitmore III | Hacker | Glass Cannon | Trust fund kid, disowned, living in van. Brilliant, burnout. |
| Slink | José Reyes | Street Rat | Speed | Ghost-child, tunnels, mother taken by Blackwood. Loves Vex. |
| Vex | Vanessa Martinez | Street Rat | Speed | Graffiti artist, father died of overdose. Independent, artistic. Secret relationship with Byte. |
| Mouse | Terrence Johnson | Street Rat | Speed | Youngest, projects, lost mother to Cross's police. Half-brother to Mama's Boy (doesn't know). |

---

## DOCUMENT INFORMATION

**Purpose:** Comprehensive narrative guide for animation, voiceover production, and gameplay implementation  
**Target Audience:** Voice actors, animators, game engineers, narrative designers  
**Status:** Production-Ready  
**Last Updated:** July 20, 2026  
**Maintained By:** Development Team  

---

**END OF DOCUMENT**
