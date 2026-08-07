// GameState.js — JS port of GameState.gd autoload core logic.
// Plain global object (no bundler) — scenes reference GameState.heat etc. directly.

const GameState = {
  // Heat — hunted meter (replaces classic health)
  heat: 0,
  heatMax: 100,

  // Active crew
  squad: [],
  currentHeroIndex: 0,

  // Relationships (pairwise, -10 to +10)
  relationships: {},

  // Story progress
  secretsUnlocked: [],
  questsCompleted: [],
  bossesFought: [],
  bossExecuted: {},
  bossFinisher: {},
  emperorForgiven: null,

  // Crew-wide stats
  morale: 0,
  reputationRuthlessness: 0,
  reputationSolidarity: 0,
  resources: { Cash: 0, Ammo: 0, Intel: 0, Rune: 0 },

  // Group upgrades (shared pool)
  groupUpgrades: {},

  // Per-hero rune contributions
  runeContributions: {},
  ghostCount: 0,
  lastGhosted: '',

  // Alliances / blame
  alliancesFormed: 0,
  alliancesBroken: 0,
  alliancesBetrayed: 0,
  blameLedger: [],

  // Progress checkpoint
  currentAct: 1,
  lastScene: 'BoardwalkScene',

  relationshipKey(heroA, heroB) {
    const pair = [heroA, heroB].sort();
    return pair[0] + '_' + pair[1];
  },

  getRelationship(heroA, heroB) {
    return this.relationships[this.relationshipKey(heroA, heroB)] || 0;
  },

  modifyRelationship(heroA, heroB, delta) {
    const key = this.relationshipKey(heroA, heroB);
    const next = (this.relationships[key] || 0) + delta;
    this.relationships[key] = Phaser.Math.Clamp(next, -10, 10);
  },

  modifyHeat(delta) {
    this.heat = Phaser.Math.Clamp(this.heat + delta, 0, this.heatMax);
  },

  getHeatPercent() {
    return this.heatMax > 0 ? this.heat / this.heatMax : 0;
  },

  getHeatLevel() {
    const pct = this.getHeatPercent() * 100;
    if (pct >= 51) return 'critical';
    if (pct >= 26) return 'elevated';
    return 'calm';
  },

  addResource(kind, amount) {
    this.resources[kind] = (this.resources[kind] || 0) + amount;
  },

  addRune(amount, hero = '') {
    this.resources.Rune = (this.resources.Rune || 0) + amount;
    if (hero) {
      this.runeContributions[hero] = (this.runeContributions[hero] || 0) + amount;
    }
  },

  spendResource(kind, amount) {
    if ((this.resources[kind] || 0) < amount) return false;
    this.resources[kind] -= amount;
    return true;
  },

  purchaseUpgrade(id, cost) {
    if (this.groupUpgrades[id]) return false;
    if (!this.spendResource('Rune', cost)) return false;
    this.groupUpgrades[id] = true;
    return true;
  },

  hasUpgrade(id) {
    return !!this.groupUpgrades[id];
  },

  topContributor() {
    let best = '';
    let bestCount = 0;
    Object.keys(this.runeContributions).forEach((hero) => {
      if (this.runeContributions[hero] > bestCount) {
        bestCount = this.runeContributions[hero];
        best = hero;
      }
    });
    return best;
  },

  markBossDefeated(bossName, executed, finisher) {
    if (!this.bossesFought.includes(bossName)) {
      this.bossesFought.push(bossName);
    }
    this.bossExecuted[bossName] = executed;
    this.bossFinisher[bossName] = finisher;
  },

  getActiveHero() {
    if (this.squad.length === 0) return '';
    if (this.currentHeroIndex < 0 || this.currentHeroIndex >= this.squad.length) {
      this.currentHeroIndex = 0;
    }
    return this.squad[this.currentHeroIndex] || '';
  },

  switchToHero(index) {
    if (index >= 0 && index < this.squad.length) {
      this.currentHeroIndex = index;
    }
  },

  reset() {
    this.heat = 0;
    this.squad = [];
    this.currentHeroIndex = 0;
    this.relationships = {};
    this.secretsUnlocked = [];
    this.questsCompleted = [];
    this.bossesFought = [];
    this.bossExecuted = {};
    this.bossFinisher = {};
    this.emperorForgiven = null;
    this.morale = 0;
    this.reputationRuthlessness = 0;
    this.reputationSolidarity = 0;
    this.resources = { Cash: 0, Ammo: 0, Intel: 0, Rune: 0 };
    this.groupUpgrades = {};
    this.runeContributions = {};
    this.ghostCount = 0;
    this.lastGhosted = '';
    this.alliancesFormed = 0;
    this.alliancesBroken = 0;
    this.alliancesBetrayed = 0;
    this.blameLedger = [];
    this.currentAct = 1;
    this.lastScene = 'BoardwalkScene';
    if (typeof Stress !== 'undefined') Stress.reset();
  }
};
