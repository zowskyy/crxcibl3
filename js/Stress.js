// Stress.js — JS port of Stress.gd autoload logic.
// Crew-wide combat stress meter (separate from Heat / hunted meter).

const Stress = {
  stress: 0,
  stressMax: 100,
  decayPerSecond: 1.5,
  combatHitTaken: 4.0,
  combatHitDealt: 1.0,
  crewMemberDowned: 20.0,
  crewMemberGhosted: 40.0,
  thresholdElevated: 40.0,
  thresholdCritical: 75.0,

  _inCombat: false,
  _lastLevel: 'calm',
  _listeners: [],

  onThresholdChanged(callback) {
    this._listeners.push(callback);
    return () => {
      this._listeners = this._listeners.filter((cb) => cb !== callback);
    };
  },

  _emitThreshold(level) {
    this._listeners.forEach((cb) => cb(level));
  },

  enterCombat() {
    this._inCombat = true;
  },

  exitCombat() {
    this._inCombat = false;
  },

  onHitTaken() {
    this._addStress(this.combatHitTaken);
  },

  onHitDealt() {
    this._addStress(this.combatHitDealt);
  },

  onCrewMemberDowned() {
    this._addStress(this.crewMemberDowned);
  },

  onCrewMemberGhosted(heroName) {
    this._addStress(this.crewMemberGhosted);
    GameState.ghostCount += 1;
    GameState.lastGhosted = heroName;
  },

  tick(delta) {
    if (!this._inCombat && this.stress > 0) {
      this.stress = Math.max(0, this.stress - this.decayPerSecond * delta);
      this._checkThreshold();
    }
  },

  _addStress(amount) {
    this.stress = Phaser.Math.Clamp(this.stress + amount, 0, this.stressMax);
    this._checkThreshold();
  },

  _checkThreshold() {
    let level = 'calm';
    if (this.stress >= this.thresholdCritical) level = 'critical';
    else if (this.stress >= this.thresholdElevated) level = 'elevated';

    if (level !== this._lastLevel) {
      this._lastLevel = level;
      this._emitThreshold(level);
    }
  },

  reset() {
    this.stress = 0;
    this._inCombat = false;
    this._lastLevel = 'calm';
  }
};
