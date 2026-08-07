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

(Once art loads from `assets/` via `this.load.image(...)`, opening
`index.html` directly may fail due to browser CORS rules — use
`run-game.ps1` or `python3 -m http.server` instead.)

## Controls: **WASD** or **Arrow Keys** -- free 8-directional movement, not
grid-locked. **SPACE** attacks when close to an enemy. Walk toward a building
and watch your character tuck behind the roof row instead of drawing on top
of it -- that's the "walk behind buildings" depth trick from the visual
direction doc, done with a fixed render-depth on roof tiles rather than
anything fancy.

## What's actually built
- Real Phaser 3 game (not a mockup) -- physics-based movement, collision
  against buildings/fences/palm trees, camera follow with world bounds
- The boardwalk layout from the earlier level mockup, ported over
- **GameState.js** + **Stress.js** -- JS ports of `GameState.gd` / `Stress.gd`
  autoload logic (heat, resources, relationships, stress thresholds)
- Heat HUD bar wired to live `GameState.heat` with vignette feedback at 26%
  and 51% thresholds; stress meter shows crew stress from combat
- Hero sprite (`assets/heroes/hero_enforcer_ghost.png`) and enemy grunt sprite
  (`assets/enemies/enemy_grunt_idle.png`); procedural palette-matched tiles for
  ground/buildings until PNG tilesets land in `assets/`
- Folder structure under `assets/` matching your art categories, ready
  for your real files

## Adding your real art (once cleaned up via Pixel It / Piskel)
The hero and enemy already load from `assets/`. Tiles still generate in-code
(see `generateTileTextures()` in `js/BoardwalkScene.js`) for zero-setup runs.
To swap in a real tile or building image:

1. Drop the PNG into the matching `assets/` subfolder, e.g.
   `assets/tiles/tile_ground.png`
2. In `BoardwalkScene.js`, add a load line inside `preload()`:
   ```js
   this.load.image('tile_ground', 'assets/tiles/tile_ground.png');
   ```
3. Remove the matching `rect('tile_ground', ...)` block from
   `generateTileTextures()` so the loaded PNG is used instead.

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
1. Drop real tile/building PNGs into `assets/` and load them in `preload()`
2. Add a second scene (e.g. `TitleScene`) once the main menu art is ready
3. Port remaining Godot autoloads (Morale, Reputation, QuestManager) as
   those systems get built in the web client
