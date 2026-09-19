# Shattered Realms

**Dark fantasy strategy RPG • Android-first • single-player**

Shattered Realms combines a painted-fantasy campaign atlas, territory conquest, D&D-inspired heroes, strategic armies, massive creatures, hidden sites and dungeon exploration.

## Current vertical slice
**World Map → Territory → Grid Movement → Hidden Cave → Dungeon**

The prototype uses procedural drawing so it runs with zero external art assets. The gameplay layer is deliberately independent from artwork so high-resolution painted atlas and territory art can be added later.

## Controls
- Tap/click a territory on the world map.
- Tap a grid cell or use WASD / arrow keys.
- Reach the cave marked **C**.
- Tap **ENTER CAVE**.
- Explore the dungeon and find the relic marked **R**.
- Press **ESC** to return to the campaign map.

## Roadmap
Heroes → armies → fog of war → factions → territory ownership → encounters → inventory → leveling → city battles → monster hunts → economy → strategic events → save/load.

The same grid controller is intended to power territory battles, hero encounters, dungeons, caves, monster battles, city assaults and exploration.

## Android
Built around Godot 4.x with the Compatibility renderer for broad mobile support. GitHub is the source of truth so development can continue from a phone.
