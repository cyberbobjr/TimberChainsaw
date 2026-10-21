# Changelog

## Unreleased

### Fixes
- A running chainsaw put on your back (or returned to its hotbar slot) stops as before, but now stays attached: the stopped chainsaw is shown on the back and in the hotbar, also in multiplayer.
- The **Combat wear** sandbox tooltip now gives the right figures in every language: condition 127, and the default 20 means about 6 zombies (it said condition 200 and about 10 zombies). The default value is unchanged.

## 1.2.0 — 2026-10-12

### Combat balance
Players reported that the running chainsaw got them killed: weak hits, a crowd of zombies and no stamina left to switch weapons.
- **Damage**: a running chainsaw now deals 1.2 to 2.4 instead of 0.6 to 1.1. This is more than the vanilla axe (0.8 to 2.0) and less than the wood axe (1.3 to 3.0). The `Damage` option now ranges from 25 to 500 % (previously 50 to 200 %).
- **New option: endurance cost** (default 50 %). The 7 kg chainsaw repeats its attack every 0.67 s and used to drain endurance about 2 to 3 times faster than an axe. 100 % restores the previous cost; 0 % removes it. The option also applies to Authentic Z chainsaws when the compatibility submod is enabled.
- **Noise split into two options**: **idle** (default 20 tiles) and **attacking or cutting** (default 40 tiles), each repeated every 2 seconds. The previous single setting (`Noise radius`, 50 tiles even when idling) is removed. If you had changed it, set the two new options instead; existing saves use the new defaults.

### Not changed
- Zombies are still not knocked back by the running chainsaw. Build 42.21 never reads the weapon's `KnockdownMod`, and the zombie's hit reaction animation decides whether it falls.

## 1.1.1 — 2026-10-07

### Multiplayer fixes
- A chainsaw left running when its owner died is now stopped in the corpse even when the dead player has already left the server's player list. Previously it could stay "running" in the corpse.
- Split screen on a server: jam, empty tank, broken and repair messages now appear above the player concerned instead of always above the first local player.

### Fixes
- A renamed chainsaw no longer collects state words in its name ("Betty (Bloody, Worn) (Worn)") each time it is started, stopped or repaired; on a server these words were also written in the server's language. Names already affected are cleaned at the next start, stop or repair when the words match the language of the game (singleplayer) or of the server (multiplayer). Chainsaws that were never renamed are unaffected.

### Validation
- 72 automated Lua regression tests pass, including the cases above. Not yet tested in game.

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
