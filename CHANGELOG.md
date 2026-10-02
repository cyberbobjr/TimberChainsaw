# Changelog

## 1.0.1 — 2026-10-02

### Fixes
- Fix chainsaw miss animations failing to load on Linux: remove relative XML inheritance that lowercased the mod path.
- Preserve the existing combat animation parameters, collision events and idle transition.

## 1.0.0 — 2026-09-29

First version of Timber! Chainsaw, inspired by Chainsaw B42 (Likit, Workshop 3692027888) and remade from scratch with the same features.

### Improvements over the original
- Trees really fall: 50 points per second at `TreeCuttingSpeed` 100, felled with the game's own `toppleTree`.
- Refuelling takes only the missing litres and only pure petrol (the original emptied the whole container and accepted any liquid).
- `FuelConsumption`, `NoiseMod`, `DamageMod` and `LootChance` sandbox options are applied.
- No more tooltip error on liquid containers: tooltip lines through TooltipLib.
- Sounds follow the Sound effects volume; each chainsaw sound can be adjusted in Options > Audio > Advanced.
- Repair recipe keeps the fuel, the name and the ModData (no repair limit).
- A broken chainsaw stays broken (the original restored its condition).
- Loot lists that exist in 42.21.

### Assets
- New sounds cut from CC0 recordings by Joseph Sardin (BigSoundBank): start, stop, engine idle, wood cutting, attack, hit.
- New poster, Workshop preview, mod icon and inventory icon.

### Changes
- Cutting wood (menu or held attacks) burns extra fuel: about 0.45 L for the biggest tree.
- The running chainsaw is a real weapon with the vanilla chainsaw animations. Holding the attack button keeps the chainsaw pointed forward (fixed pose, a hit every 0.67 s instead of a 2.5 s swing) and cuts zombies or the tree in front; the engine sound loops at full throttle, or cuts wood when a tree is ahead. Trees can also be cut from the context menu (vanilla `Bob_ChainsawCutTree` animation). The original "hold right click" loop is gone.
- Multiplayer: server-authoritative start, stop, fuel, wear and tree cutting.
- Translations: English, French, German, Spanish, Italian, Polish, Portuguese (Portugal and Brazil), Russian, Simplified Chinese.
