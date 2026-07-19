// BoardwalkScene.js -- the actual game level.
//
// Uses generated placeholder textures (matching the CRXCIBL3 palette) so this
// runs immediately with zero setup -- no PNGs needed yet. See README.md for
// exactly how to swap in your real Bing-generated art once it's cleaned up.

const TILE = 16;
const COLS = 46;
const ROWS = 26;

// CRXCIBL3 palette
const PALETTE = {
  ground: 0x6b6b6b,
  groundAlt: 0x5A5A5A,
  sand: 0x7a6a4a,
  fence: 0x1A1A1A,
  fenceLine: 0x333333,
  wallBase: 0x8B4513,
  wallDark: 0x5c2e0d,
  roof: 0x3d2609,
  roofEdge: 0x1f1305,
  palmTrunk: 0x6b5335,
  palmLeaf: 0x88AA77,
  signOrange: 0xFF6600,
  signPink: 0xFF00FF,
  playerBody: 0xCC0000,
  playerDark: 0x7a0000,
  enemyBody: 0x3a3a3a,
  enemyDark: 0x1A1A1A,
  heatFill: 0xFF6600,
  heatBg: 0x1A1A1A,
  exitGlow: 0xE6C200
};

class BoardwalkScene extends Phaser.Scene {
  constructor() {
    super('BoardwalkScene');
    this.map = [];
    this.gameWon = false;
    this.playerInvulnUntil = 0;
  }

  preload() {
    // First real art asset -- everything else still uses generated placeholders below
    this.load.image('hero_enforcer_ghost', 'assets/heroes/hero_enforcer_ghost.png');
  }

  create() {
    GameState.reset();
    this.gameWon = false;

    this.generatePlaceholderTextures();
    this.buildMap();
    this.createLevel();
    this.createPlayer();
    this.createEnemy();
    this.createExit();
    this.setupCamera();
    this.setupInput();
    this.createHUD();
  }

  // ---- Texture generation (placeholder art) ----
  generatePlaceholderTextures() {
    const g = this.add.graphics();

    const rect = (key, w, h, drawFn) => {
      g.clear();
      drawFn(g, w, h);
      g.generateTexture(key, w, h);
    };

    rect('tile_ground', TILE, TILE, (g, w, h) => {
      g.fillStyle(PALETTE.ground, 1).fillRect(0, 0, w, h);
    });

    rect('tile_sand', TILE, TILE, (g, w, h) => {
      g.fillStyle(PALETTE.sand, 1).fillRect(0, 0, w, h);
    });

    rect('tile_fence', TILE, TILE, (g, w, h) => {
      g.fillStyle(PALETTE.ground, 1).fillRect(0, 0, w, h);
      g.fillStyle(PALETTE.fence, 1).fillRect(0, 0, w, h * 0.85);
      g.lineStyle(1, PALETTE.fenceLine).strokeRect(2, 2, w - 4, h * 0.85 - 4);
    });

    rect('wall_base', TILE, TILE, (g, w, h) => {
      g.fillStyle(PALETTE.wallBase, 1).fillRect(0, 0, w, h);
      g.fillStyle(PALETTE.wallDark, 1).fillRect(0, h * 0.7, w, h * 0.3);
    });

    rect('roof_plain', TILE, TILE, (g, w, h) => {
      g.fillStyle(PALETTE.roof, 1).fillRect(0, 0, w, h);
      g.fillStyle(PALETTE.roofEdge, 1).fillRect(0, h - 4, w, 4);
    });

    rect('roof_sign_orange', TILE, TILE, (g, w, h) => {
      g.fillStyle(PALETTE.roof, 1).fillRect(0, 0, w, h);
      g.fillStyle(PALETTE.signOrange, 1).fillRect(w * 0.15, h * 0.25, w * 0.7, h * 0.3);
    });

    rect('roof_sign_pink', TILE, TILE, (g, w, h) => {
      g.fillStyle(PALETTE.roof, 1).fillRect(0, 0, w, h);
      g.fillStyle(PALETTE.signPink, 1).fillRect(w * 0.15, h * 0.25, w * 0.7, h * 0.3);
    });

    rect('palm', TILE, TILE, (g, w, h) => {
      g.fillStyle(PALETTE.ground, 1).fillRect(0, 0, w, h);
      g.fillStyle(PALETTE.palmTrunk, 1).fillRect(w * 0.42, h * 0.35, w * 0.16, h * 0.65);
      g.fillStyle(PALETTE.palmLeaf, 1).fillRect(w * 0.15, h * 0.05, w * 0.7, h * 0.35);
    });

    // Player texture is now real art (hero_enforcer_ghost.png, loaded in preload())
    // -- no placeholder generated for it anymore.

    // Enemy -- rival crew grunt placeholder, distinct silhouette/color from player
    rect('enemy', 12, 16, (g, w, h) => {
      g.fillStyle(PALETTE.enemyBody, 1).fillRect(0, 0, w, h);
      g.fillStyle(PALETTE.enemyDark, 1).fillRect(0, h - 3, w, 3);
    });

    // Getaway exit tile -- glowing gold
    rect('exit_tile', TILE, TILE, (g, w, h) => {
      g.fillStyle(PALETTE.exitGlow, 1).fillRect(0, 0, w, h);
      g.fillStyle(0xffffff, 0.35).fillRect(2, 2, w - 4, h - 4);
    });

    g.destroy();
  }

  // ---- Map data ----
  buildMap() {
    for (let r = 0; r < ROWS; r++) {
      this.map.push(new Array(COLS).fill('ground'));
    }

    const setRect = (r0, c0, r1, c1, val) => {
      for (let r = r0; r <= r1; r++) {
        for (let c = c0; c <= c1; c++) {
          if (r >= 0 && r < ROWS && c >= 0 && c < COLS) this.map[r][c] = val;
        }
      }
    };

    // Border fence
    setRect(0, 0, 0, COLS - 1, 'fence');
    setRect(ROWS - 1, 0, ROWS - 1, COLS - 1, 'fence');
    setRect(0, 0, ROWS - 1, 0, 'fence');
    setRect(0, COLS - 1, ROWS - 1, COLS - 1, 'fence');

    // Sand strip near the top ("ocean" side)
    setRect(2, 2, 3, COLS - 3, 'sand');

    this.buildings = [];
    const building = (r0, c0, r1, c1, roofType) => {
      setRect(r0 + 1, c0, r1, c1, 'wall');
      setRect(r0, c0, r0, c1, roofType || 'roof');
      this.buildings.push({ r0, c0, r1, c1 });
    };

    building(4, 5, 6, 9, 'roof_sign_orange');
    building(4, 12, 6, 15, 'roof_sign_pink');
    building(4, 19, 6, 22, 'roof_sign_orange');
    building(4, 26, 6, 30, 'roof_sign_pink');
    building(4, 34, 6, 39, 'roof_plain');

    building(15, 6, 18, 10, 'roof_plain');
    building(15, 15, 18, 19, 'roof_sign_orange');
    building(15, 24, 18, 27, 'roof_plain');
    building(15, 32, 18, 37, 'roof_sign_pink');

    building(20, 38, 22, 42, 'roof_sign_orange'); // chop shop corner

    // Dead palm trees scattered around
    const palmSpots = [
      [8, 3], [9, 17], [8, 24], [9, 31], [9, 42],
      [12, 8], [13, 20], [12, 29], [22, 14], [23, 20], [22, 30]
    ];
    palmSpots.forEach(([r, c]) => {
      if (this.map[r][c] === 'ground') this.map[r][c] = 'palm';
    });
  }

  // ---- Build the actual scene objects from map data ----
  createLevel() {
    this.wallGroup = this.physics.add.staticGroup();
    this.roofLayer = this.add.group();

    for (let r = 0; r < ROWS; r++) {
      for (let c = 0; c < COLS; c++) {
        const val = this.map[r][c];
        const x = c * TILE + TILE / 2;
        const y = r * TILE + TILE / 2;

        if (val === 'wall' || val.startsWith('roof')) {
          // Ground underneath buildings, drawn first
          this.add.image(x, y, 'tile_ground').setDepth(-1);
        }

        switch (val) {
          case 'ground':
            this.add.image(x, y, 'tile_ground').setDepth(-1);
            break;
          case 'sand':
            this.add.image(x, y, 'tile_sand').setDepth(-1);
            break;
          case 'fence': {
            const fence = this.wallGroup.create(x, y, 'tile_fence');
            fence.setDepth(y);
            break;
          }
          case 'wall': {
            const wall = this.wallGroup.create(x, y, 'wall_base');
            wall.setDepth(y);
            break;
          }
          case 'palm': {
            const palm = this.wallGroup.create(x, y, 'palm');
            palm.setDepth(y);
            break;
          }
          default:
            if (val.startsWith('roof')) {
              // Roof/sign row -- collidable (part of the building) but always
              // drawn ABOVE the player via a fixed high depth. This is the
              // "walk behind buildings" trick from the visual direction doc.
              const roof = this.wallGroup.create(x, y, val);
              roof.setDepth(10000);
              this.roofLayer.add(roof);
            }
        }
      }
    }
  }

  // ---- Player ----
  createPlayer() {
    // Real source image is 238x628 -- much higher-res than a game sprite needs,
    // so it's scaled down in-code rather than requiring you to resize the file
    // yourself. Targeting ~48px tall (about 3 tiles, roughly matching building
    // height) -- change TARGET_HEIGHT below any time you want it bigger/smaller.
    const SOURCE_HEIGHT = 628;
    const TARGET_HEIGHT = 48;
    const scale = TARGET_HEIGHT / SOURCE_HEIGHT;

    this.player = this.physics.add.sprite(12 * TILE, 10 * TILE, 'hero_enforcer_ghost');
    this.player.setScale(scale);
    this.player.setCollideWorldBounds(true);

    // Physics body size/offset are in the ORIGINAL (unscaled) texture's pixel
    // space -- Phaser auto-scales them to match setScale() above. These are
    // estimated to roughly cover the character's lower body/feet (where
    // collision should happen) -- nudge the numbers below if it feels off
    // once you see it moving around in-browser.
    this.player.body.setSize(100, 140);
    this.player.body.setOffset(69, 468);

    this.player.speed = 90; // pixels/sec

    this.physics.world.setBounds(0, 0, COLS * TILE, ROWS * TILE);
    this.physics.add.collider(this.player, this.wallGroup);
  }

  // ---- Enemy (one chasing rival crew grunt -- Phase 1 combat proof) ----
  createEnemy() {
    this.enemy = this.physics.add.sprite(25 * TILE, 12 * TILE, 'enemy');
    this.enemy.setCollideWorldBounds(true);
    this.enemy.body.setSize(12, 10);
    this.enemy.body.setOffset(0, 6);
    this.enemy.speed = 45; // slower than player -- outrunnable
    this.enemy.hp = 2; // dies in 2 player attacks, matching the original design note

    this.physics.add.collider(this.enemy, this.wallGroup);
    this.physics.add.overlap(this.player, this.enemy, this.onPlayerHit, null, this);
  }

  onPlayerHit() {
    if (this.time.now < this.playerInvulnUntil || this.gameWon) return;
    GameState.modifyHeat(15);
    this.playerInvulnUntil = this.time.now + 800; // brief invulnerability window
    this.player.setTintFill(0xffffff);
    this.time.delayedCall(100, () => this.player.clearTint());
  }

  tryAttack() {
    if (this.gameWon || !this.enemy || !this.enemy.active) return;

    const dist = Phaser.Math.Distance.Between(
      this.player.x, this.player.y, this.enemy.x, this.enemy.y
    );

    if (dist < 20) {
      this.enemy.hp -= 1;
      this.enemy.setTintFill(0xffffff);
      this.time.delayedCall(100, () => this.enemy.active && this.enemy.clearTint());

      if (this.enemy.hp <= 0) {
        this.enemy.destroy();
        GameState.addResource('Cash', 10);
      }
    }
  }

  // ---- Getaway exit ----
  createExit() {
    const x = 43 * TILE + TILE / 2;
    const y = 10 * TILE + TILE / 2;
    this.exit = this.physics.add.staticSprite(x, y, 'exit_tile');
    this.physics.add.overlap(this.player, this.exit, this.onReachExit, null, this);
  }

  onReachExit() {
    if (this.gameWon) return;
    this.gameWon = true;
    this.player.setVelocity(0, 0);

    this.winText = this.add.text(
      this.cameras.main.width / 2, this.cameras.main.height / 2,
      'GETAWAY!', { fontFamily: 'monospace', fontSize: '20px', color: '#E6C200' }
    ).setOrigin(0.5).setScrollFactor(0).setDepth(30000);
  }

  setupCamera() {
    this.cameras.main.setBounds(0, 0, COLS * TILE, ROWS * TILE);
    this.cameras.main.startFollow(this.player, true, 0.15, 0.15);
  }

  setupInput() {
    this.cursors = this.input.keyboard.createCursorKeys();
    this.wasd = this.input.keyboard.addKeys('W,A,S,D');
    this.input.keyboard.on('keydown-SPACE', () => this.tryAttack());
  }

  // ---- HUD ----
  createHUD() {
    const barX = 8, barY = 8, barW = 60, barH = 6;

    this.add.rectangle(barX, barY, barW, barH, PALETTE.heatBg)
      .setOrigin(0, 0).setScrollFactor(0).setDepth(20000);

    this.heatFillBar = this.add.rectangle(barX + 1, barY + 1, 1, barH - 2, PALETTE.heatFill)
      .setOrigin(0, 0).setScrollFactor(0).setDepth(20001);

    this.add.text(barX, barY - 10, 'HEAT', {
      fontFamily: 'monospace', fontSize: '8px', color: '#E6C200'
    }).setScrollFactor(0).setDepth(20000);

    this.cashText = this.add.text(barX, barY + 12, 'CASH: 0', {
      fontFamily: 'monospace', fontSize: '8px', color: '#E6C200'
    }).setScrollFactor(0).setDepth(20000);
  }

  updateHUD() {
    const barW = 58;
    const pct = Phaser.Math.Clamp(GameState.heat / GameState.heatMax, 0, 1);
    this.heatFillBar.width = Math.max(1, barW * pct);
    this.cashText.setText('CASH: ' + GameState.resources.Cash);
  }

  // ---- Frame update ----
  update() {
    if (this.gameWon) return;

    const speed = this.player.speed;
    let vx = 0, vy = 0;

    if (this.cursors.left.isDown || this.wasd.A.isDown) vx -= 1;
    if (this.cursors.right.isDown || this.wasd.D.isDown) vx += 1;
    if (this.cursors.up.isDown || this.wasd.W.isDown) vy -= 1;
    if (this.cursors.down.isDown || this.wasd.S.isDown) vy += 1;

    // Normalize diagonal movement so it isn't faster than cardinal movement
    if (vx !== 0 && vy !== 0) {
      vx *= Math.SQRT1_2;
      vy *= Math.SQRT1_2;
    }

    this.player.setVelocity(vx * speed, vy * speed);

    // Depth-sort the player against wall bases so it draws correctly in
    // front of/behind them based on vertical position (roofs always stay
    // above via their fixed depth set in createLevel)
    this.player.setDepth(this.player.y);

    // Simple chase AI -- move toward the player each frame
    if (this.enemy && this.enemy.active) {
      const angle = Phaser.Math.Angle.Between(
        this.enemy.x, this.enemy.y, this.player.x, this.player.y
      );
      this.enemy.setVelocity(
        Math.cos(angle) * this.enemy.speed,
        Math.sin(angle) * this.enemy.speed
      );
      this.enemy.setDepth(this.enemy.y);
    }

    this.updateHUD();
  }
}
