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
