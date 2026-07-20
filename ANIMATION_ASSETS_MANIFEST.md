# CRXCIBL3 Animation Assets Manifest
## For Production with Voiceover Guide

---

## SPRITES NEEDED (30+ files)

### EMPEROR FIGURE (5 sprites, 256×256 each)
- `emperor_idle_seated.png` — Idle pose, sitting, defeated
- `emperor_lookaside.png` — Eyes down, shame
- `emperor_hands_open.png` — Palms open (plea gesture)
- `emperor_leaning_forward.png` — Leaning into explanation
- `emperor_slump_final.png` — Final slump before death

### PLAYER CHARACTER (5 sprites, 128×128 each)
- `player_idle.png` — Standing still, watching
- `player_step_forward.png` — Step forward (confidence)
- `player_nod.png` — Nod gesture (acknowledgment)
- `player_hand_to_chest.png` — Hand over heart (pride, climax)
- `player_turn_away.png` — Turning to leave (cold departure)

### BOSS BLACKWOOD (4 sprites, 192×192 each)
- `blackwood_ready_stance.png` — Standing ready, aggressive
- `blackwood_attack_01.png` — Attack frame 1
- `blackwood_attack_02.png` — Attack frame 2
- `blackwood_death_slump.png` — Collapsed after defeat

### DIALOGUE UI BUTTONS (6 files, 120×40 each)
- `button_default.png` — Normal state
- `button_hover.png` — Hover state
- `button_pressed.png` — Pressed state
- `button_forgive_text.png` — "FORGIVE HIM"
- `button_turn_away_text.png` — "TURN AWAY"
- `button_continue_text.png` — "CONTINUE ▶"

### BACKGROUNDS (1 required, 2 optional)
- `emperor_estate_interior.png` — Main scene (384×216)
- `estate_walls_distant.png` — Parallax layer 1 (optional)
- `estate_furniture_mid.png` — Parallax layer 2 (optional)
- `estate_foreground.png` — Parallax layer 3 (optional)

---

## SHADERS (Already in Repo, No Changes)
- `res://assets/shaders/enemy_dissolve.gdshader` — Used for Emperor death fade

---

## SPECIFICATIONS

### All Sprites
- Format: PNG with transparency (NO white/black fill)
- Style: 8-bit/16-bit retro pixel art
- Orientation: Facing right (except Blackwood, facing left)
- Reference: Match existing hero_enforcer_ghost.png for color/style

### Backgrounds
- Size: 384×216 (design canvas)
- Lighting: Twilight + candlelight + decay
- Mood: Opulent but deteriorating (gothic atmosphere)
- Ref: Godfather mansion or Training Day wealthy villain estates

### Color Palette
- Primary: Dark browns, deep reds, gold accents
- Lighting: Candlelight (orange/amber), twilight blue
- Emperor: Dark suit, gold chain/cross
- Player: Trenchcoat (dark gray), bright eyes
- Blackwood: Priest robes, glowing staff runes

---

## DELIVERY CHECKLIST
- [ ] 5 Emperor sprites (256×256)
- [ ] 5 Player sprites (128×128)
- [ ] 4 Blackwood sprites (192×192)
- [ ] 6 Button states (120×40 each)
- [ ] 1 Estate interior background (384×216)
- [ ] 3 Optional parallax layers (384×216 each)

**Total: 25–28 image files**

---

## TIMING REFERENCE (For Animation Sync)

### Confession Sequence (3 lines × ~3–5 seconds each = ~10–12 seconds total)
- Line 1: "I didn't betray you." (3–4 sec, Emperor eyes open → down)
- Line 2: "I made a deal..." (3–4 sec, hands gesture, leaning forward)
- Line 3: "I thought if I gave them..." (4–5 sec, slump, head shake)

### Forgive Path (4 lines × ~3–5 seconds each = ~12–15 seconds total)
- Line 1: "We know..." (3–4 sec, Player steps forward, nod)
- Line 2: "You made a mistake..." (3–4 sec, look down, introspection)
- Line 3: "The Flats ain't about..." (4–5 sec, stand tall, hand to chest, POWER POSE)
- Line 4: "The Emperor died..." (4–5 sec, Emperor fades, crew stands witness)

### Turn Away Path (2 lines × ~4–5 seconds each = ~8–10 seconds total)
- Line 1: "The crew said nothing..." (4–5 sec, Player turns away, walks)
- Line 2: "The Emperor died alone..." (4–5 sec, Emperor fades, isolation)

### Closing Cutscene (Non-interactive, 4–6 seconds)
- Emperor fade-out: 2 seconds (modulate.alpha 1.0 → 0.0)
- Silence: 1 second
- Transition: 1–2 seconds

---

**FULL SCENE DURATION: 7–12 minutes (player-paced, depends on how long they take to choose dialogue)**

---

## NOTES

1. All sprites must be transparency-enabled PNG files
2. Use consistent color palette across character sprites
3. Animations should feel weighty and deliberate (not rushed)
4. Emperor always appears beaten/resigned; never confident or defensive
5. Player always appears strong and resolute (never weak, kneeling, or broken)
6. Blackwood contrast: menacing in combat, shattered in death

---

**Version:** 1.0  
**Last Updated:** 2026-07-20  
**Purpose:** Guide animation production for Emperor scene cutscene
