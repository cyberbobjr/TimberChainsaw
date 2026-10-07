# Changelog

## 1.1.0 ? 2026-10-07

### Authentic Z compatibility
- Add **batman_Timber! Chainsaw - Authentic Z Compatibility**, an optional submod included in this same Workshop subscription, for Authentic Z Current or Lite on Build 42.21.
- Existing Authentic Z chainsaws now support Timber's start/stop, petrol refuelling, engine sounds, noise and tree cutting. Original item IDs, appearance, weight and maximum condition are retained. Wear is scaled to their native durability.
- Keep compatibility fuel separately so it is available again after reactivation. No compatibility-only item types are introduced; add/remove the submod between sessions with a full restart, keeping Authentic Z enabled.
- Keep native combat damage to avoid persistent damage overrides. DamageMod continues to affect Timber items only.

### How to enable
- Enable Authentic Z **Current OR Lite**, TooltipLib and Timber! Chainsaw, then enable **batman_Timber! Chainsaw - Authentic Z Compatibility**. For an existing save, also enable it in that save's mod settings.
- Load Authentic Z (and its optional translation patch) before Timber, and the compatibility submod after Timber. Fully restart the game and multiplayer server.
- Do not enable **AuthenticZChainsawFix** alongside the compatibility submod.
- Servers: keep the same Workshop ID and add `batman_TimberAuthenticZCompatibility` after `batman_TimberChainsaw` in `Mods=`, alongside Authentic Z and TooltipLib.

### Validation
- Compatibility tested and validated in game by the mod author.
- 64 automated Lua regression tests pass, including Current/Lite identity preservation, fuel, wear, client/server authority and simulated removal/reactivation.

## 1.0.3 — 2026-10-02

### Fixes
- Limit both chainsaw variants to 127 condition points: a damaged chainsaw could become broken when unequipped in multiplayer or after saving and reloading because the game stores condition as a signed byte.
- Preserve condition percentage when starting or stopping an item whose condition maximum differs from the replacement. Already broken items stay broken; damage already lost in an older save cannot be recovered automatically.

### Balance
- Reduce chainsaw weight from 15 to 7, whether the engine is running or stopped.
- Keep the existing wear settings. With the lower condition maximum, chainsaws have approximately 37% less durability at the same settings.

### Compatibility
- Declare loading after Better Item Info (`EURY_ITEMINFO`) when both mods are enabled, following a player report that this order restored Vorpal weapon tooltips.
- Document this load order in English, French and all Workshop description translations. Better Item Info remains optional.

### Thanks
- Thanks to **Django77** for reporting the chainsaw breaking when unequipped after cutting a tree, and for identifying the Better Item Info load order that restored Vorpal weapon tooltips.

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
