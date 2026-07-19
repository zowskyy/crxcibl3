// main.js -- game config and boot.
// This is the only file you'd touch to add more scenes later
// (title screen, mission select, etc.) -- just add them to the scene array.

const config = {
  type: Phaser.AUTO,
  parent: 'game-container',
  width: 384,
  height: 216,
  zoom: 3, // native res x3 -- gives a reasonable window size while staying pixel-perfect
  pixelArt: true, // critical: disables texture smoothing, keeps pixel art crisp
  backgroundColor: '#1A1A1A',
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { y: 0 }, // top-down game, no gravity
      debug: false
    }
  },
  scene: [BoardwalkScene]
};

new Phaser.Game(config);
