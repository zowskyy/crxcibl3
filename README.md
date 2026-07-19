# CRXCIBL3 -- Web Build (Phaser 3)

## Running it -- one script, every time
```
.\run-game.ps1
```
That's the whole process: starts a local server and opens the game in your
browser automatically. No need to remember commands, ports, or URLs.

First time only, if PowerShell blocks it:
```
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

To stop: close the black server window `run-game.ps1` opened, or run
`.\stop-game.ps1` if it gets stuck/the window got closed by accident.

(You can still double-click `index.html` directly for now since nothing
loads external files yet -- but once real art gets added via
`this.load.image(...)`, that stops working and the server becomes
required. Using `run-game.ps1` from the start avoids hitting that
confusing switch later.)

## Controls: **WASD** or **Arrow Keys** -- free 8-directional movement, not
grid-locked. Walk toward a building and watch your character tuck behind
the roof row instead of drawing on top of it -- that's the "walk behind
buildings" depth trick from the visual direction doc, done with a fixed
render-depth on roof tiles rather than anything fancy.

## What's actually built
- Real Phaser 3 game (not a mockup) -- physics-based movement, collision
  against buildings/fences/palm trees, camera follow with world bounds
- The boardwalk layout from the earlier level mockup, ported over
- A Heat HUD bar in the corner (currently a static demo value -- see
  "Next steps" below for wiring it to real game state)
- Folder structure under `assets/` matching your art categories, ready
  for your real files

## Adding your real art (once cleaned up via Pixel It / Piskel)
Right now every texture is generated in code (see
`generatePlaceholderTextures()` in `js/BoardwalkScene.js`) instead of
loaded from a file, which is why this needs zero setup to run. To swap
in a real image:

1. Drop the PNG into the matching `assets/` subfolder, e.g.
   `assets/heroes/hero_enforcer_bigbody.png`
2. In `BoardwalkScene.js`, add a load line inside `preload()`:
   ```js
   this.load.image('hero_enforcer_bigbody', 'assets/heroes/hero_enforcer_bigbody.png');
   ```
3. Use that key instead of a placeholder key wherever it's referenced,
   e.g. change `'player'` to `'hero_enforcer_bigbody'` in `createPlayer()`

**Important:** once you add even one `this.load.image(...)` call, opening
`index.html` directly by double-clicking will likely fail (browsers block
local file loading for security reasons -- this is the same CORS issue
that would've come up in Godot too, just earlier here). At that point,
run a tiny local server instead -- you already have Python installed:
```
cd crxcibl3-web
python3 -m http.server
```
Then open `http://localhost:8000` in your browser instead of
double-clicking the file. This is a permanent step from that point on,
not a one-time thing -- but it's one command, and you can leave that
terminal window open while you work.

## Next steps, in order
1. Swap the player placeholder for a real hero sprite (once cleaned up)
2. Replace tile/building placeholders with real art the same way
3. Port `GameState.gd` / `Stress.gd` logic into a plain JS module (e.g.
   `js/GameState.js`) and wire `this.currentHeat` in the HUD to it for
   real
4. Add a second scene (e.g. `TitleScene`) once the main menu art is ready,
   using the same "generate placeholder, swap in real art later" pattern
