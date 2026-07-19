// GameState.js -- JS port of the GameState.gd autoload's core logic.
// Kept as a plain global object (no build step/bundler needed) so any
// scene can reference `GameState.heat` etc. directly.
//
// This starts with just what Phase 1 needs (Heat, Resources). The rest of
// GameState.gd (relationships, bosses_fought, squad, etc.) ports over the
// same way when those systems actually get built -- no need to port it
// all up front.

const GameState = {
  heat: 0,
  heatMax: 100,
  resources: { Cash: 0, Ammo: 0, Intel: 0 },

  modifyHeat(delta) {
    this.heat = Phaser.Math.Clamp(this.heat + delta, 0, this.heatMax);
  },

  addResource(kind, amount) {
    this.resources[kind] = (this.resources[kind] || 0) + amount;
  },

  spendResource(kind, amount) {
    if ((this.resources[kind] || 0) < amount) return false;
    this.resources[kind] -= amount;
    return true;
  },

  reset() {
    this.heat = 0;
    this.resources = { Cash: 0, Ammo: 0, Intel: 0 };
  }
};
