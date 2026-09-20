# Game Architecture

## Layers
1. **World / Empire** — territories, factions, armies, routes, strategic events and massive creatures.
2. **Territory / Conquest** — a grid over a detailed local map with terrain, roads, settlements and discoveries.
3. **Dungeon** — the same grid coordinate model with walls, doors, traps, puzzles, encounters and loot.

## Core state
Future data-driven state objects: GameState, CampaignState, TerritoryState, HeroState, ArmyState, EncounterState and DungeonState.

## Design rule
Gameplay coordinates never depend on artwork pixel coordinates. A territory can receive a new painted background without changing unit positions or rules.

## Vertical slice
World map click → territory load → hero movement → hidden-site discovery → dungeon transition → relic discovery → return to map.


## Commander system
Six named commanders are data-driven in `data/commanders.json`. Each commander has three strategic roles:
1. **Personal** — abilities used directly by the commander.
2. **Army** — modifiers applied while accompanying an army.
3. **Governor** — modifiers applied while assigned to a territory.

Commander assignments are mutually exclusive at the state level: a commander can accompany an army or govern a territory, creating the intended strategic tradeoff. Commander progression is represented by three thematic ability trees per commander, and commander relationships define paired-deployment effects and story tensions.

The six initial commanders are:
- Ser Kaela Varyn — Knight Commander
- Edrin Vale — Ranger-Lord
- Lord Garrick Thorne — Crusader
- Nyra Vex — Shadow Huntress
- Hakon Blood-Eye — Warlord
- Malrec the Ashen — Warlock

Hero artwork uses the six-character layout as presentation guidance, while gameplay references stable commander IDs rather than image positions.
