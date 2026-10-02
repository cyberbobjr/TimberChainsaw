# Timber! Chainsaw

**Build 42.21 · Singleplayer & Multiplayer**

Working gasoline chainsaw for Project Zomboid: fell trees, shred zombies with a fixed stance and a roaring engine, burn and refuel petrol.

Inspired by **Chainsaw B42** by **Likit** (Steam Workshop [3692027888](https://steamcommunity.com/sharedfiles/filedetails/?id=3692027888)) and remade from scratch with the same features.
Only the idea, the item names (kept for save compatibility) and the base weapon stats come from the original.
No asset of the original is used: sounds cut from CC0 recordings by Joseph Sardin ([BigSoundBank](https://bigsoundbank.com) 0707, 0982, 0983, see `source/build_sounds.py`),
new poster, preview and icons; the 3D model, texture and animations are vanilla Project Zomboid assets.

*Français plus bas.*

## Requirements

- [TooltipLib](https://steamcommunity.com/sharedfiles/filedetails/?id=3694097672) (`TooltipLib`).
- Incompatible with the original `ChainsawB42`: enable one or the other. Same item names (`ChainsawB42.ChainsawOff`, `ChainsawB42.Chainsaw`) and ModData keys: chainsaws of a save made with the original keep their fuel.

## Compatibility and load order

If you enable **Better Item Info** (`EURY_ITEMINFO`), load it **before Timber! Chainsaw**. Timber declares `loadModAfter=\EURY_ITEMINFO`; Better Item Info is optional. In Build 42.21, this metadata informs the load-order panel and its automatic sort; it does not force an existing saved order to change. Check the order in the Mods screen.

A player reported missing Vorpal weapon tooltips and restored them by putting Timber after Better Item Info. Timber and Vorpal were also tested together without reproducing the issue. This order addresses the reported combination; the exact tooltip hook conflict has not been reproduced locally. Better Item Info is a different mod from Better Clothing Info (`EURY_CLOTHINGINFO`). Restart the game completely after changing the order.

## Weight and condition

Both stopped and running chainsaws weigh **7** and have **127 condition points**. The lower maximum avoids damaged chainsaws becoming broken when the game saves or transmits their condition as a signed byte. Existing wear settings are unchanged, so durability is approximately 37% lower than with the previous 200-point maximum.

Starting and stopping preserve condition; when the source item's maximum differs, its remaining percentage is transferred to the new maximum. This is not a full migration of old saves: condition already lost while loading an older save cannot be recovered automatically, and broken chainsaws still need repairs.

## How to use

1. Right-click the chainsaw: **Start the chainsaw** (it goes in both hands, needs fuel).
2. Hold the attack button (left click): the chainsaw stays pointed forward at full throttle and cuts zombies or the tree in front (fixed pose: `AnimSets/player/melee/2handed/ChainsawDefault.xml` replaces the vanilla swing).
3. Trees: right-click a tree, **Cut down the tree with the chainsaw**.
4. **Stop the chainsaw**, then **Refuel the chainsaw** with a container of pure petrol.

## Improvements over the original (player reports on its Workshop page)

| Report | Cause in the original | Fix |
|---|---|---|
| Trees are not cut, "only ~9 damage", a whole tank for nothing | `IsoTree:Damage(10)` removes 10 × 0.05 = 0.5 point, truncated to 1 (`IsoTree.java:185`); trees have 40 to 560 points | 50 points per second (`TreeCuttingSpeed`), tree felled by `toppleTree` (logs, removal for everyone) |
| Refuelling empties the whole can ("10 L for a 4 L saw"), takes any liquid | `FluidContainer:adjustAmount(-x)` **sets** the amount, clamped to 0 (`FluidContainer.java:647`); any fluid container accepted | Only the missing litres, pure petrol only (`ISAddFuel` pattern) |
| `FuelConsumption` option has no effect | never read (`modData.FuelConsumption` fixed to 0.4) | read, 0 = no consumption |
| Errors when looking at a liquid container (water dispenser...) | `ISToolTipInv.render` replaced, `self.item:IsWeapon()` on a `FluidContainer` (`ISFluidBar.lua:220`) | tooltip through TooltipLib, items only |
| Sound too loud, cannot be lowered | audio-file sounds ignore the Sound effects slider (FMOD VCA for bank events only) | engine loop and action sounds at the Sound effects volume; each sound adjustable in Options > Audio > Advanced (category Weaponry) |
| Does it work in MP? | damage to trees/zombies and fuel written by the client; `InventoryItem` has no `transmitModData`; refuel action without `complete()` | everything decided by the server (`complete()`, server tick, emulated animation events), state = item type, synchronised by the game |

Also: `NoiseMod`, `DamageMod` and `LootChance` options were ignored; 10 of the 21 loot lists do not exist in 42.21; the repair recipe never called its Lua (`getAllOutputItems` does not exist) and gave a full tank; a broken chainsaw got its condition back (`ensureModData` "restore"), so it could never break and repairs were undone.

## Multiplayer design

- **Running state = item type**: `ChainsawOff` (stopped) is replaced by `Chainsaw` (running) in both hands by the server (`CSB42_StartAction:complete`). The game gives the vanilla chainsaw animations and attack to an item of type `Chainsaw` held in both hands (`WeaponType.java:63, 100`).
- **Server tick** (`server/ChainsawB42/CSB42_Engine.lua`): fuel in game time, noise every 2 s, stop when the chainsaw leaves the hands, breaks, runs dry, owner dies/disconnects/enters a vehicle. Fuel sent to the owner every 0.05 L (`syncItemFields`).
- **Tree cutting**: hits on the server via `emulateAnimEvent` (like the vanilla `ISChopTreeAction`).
- **Engine sound**: each client plays the loop of nearby players holding a running chainsaw, without network messages.

## Tests

```
python tests/run_tests.py
```

luacheck, Lua 5.1 syntax, no `next()` (absent from Kahlua), translations (10 languages), keys used by the code, and 56 Lua tests under `lupa` with a simulated game API (`tests/lua/game_api.lua`). The regressions cover cutting then unequipping in multiplayer, signed-byte serialization, start/stop, repair, both item weights and changed condition maxima. Not a substitute for an in-game test.

In-game verification on Build 42.21: restart completely, cut down a tree until condition decreases, then unequip the still-running chainsaw. Verify it stops without becoming broken; also start/stop manually, repair, and save/reload. In multiplayer, check the owning client's condition after unequipping and reconnecting. Check weight 7 for both variants on a freshly created or replaced item.

## License

Code under the MIT license (`LICENSE`). Sounds derived from CC0 recordings (Joseph Sardin, BigSoundBank). Poster and icons made for this mod.

---

# Français

Tronçonneuse à essence fonctionnelle, inspirée de **Chainsaw B42** de **Likit** (Workshop 3692027888) et refaite entièrement avec les mêmes fonctionnalités. Build 42.21, solo et multijoueur. Prérequis : TooltipLib. Incompatible avec l'original (mêmes objets, le carburant des sauvegardes est conservé). Aucune ressource de l'original n'est reprise : sons CC0 (Joseph Sardin, BigSoundBank), affiche et icônes nouvelles, modèle et animations du jeu.

Utilisation : clic droit sur la tronçonneuse, **Démarrer** ; zombies : viser (clic droit) et frapper (clic gauche) ; arbres : clic droit sur l'arbre, **Abattre l'arbre à la tronçonneuse** ; **Arrêter**, puis **Faire le plein** avec un récipient d'essence pure.

Compatibilité : si **Better Item Info** (`EURY_ITEMINFO`) est activé, il doit se charger **avant Timber! Chainsaw**. Cet ordre est déclaré dans le mod ; Better Item Info reste facultatif. En Build 42.21, la déclaration est reconnue par le panneau d'ordre et son tri automatique, mais ne modifie pas d'office une liste déjà enregistrée : vérifier l'ordre dans l'écran des mods. Un joueur a rétabli ses infobulles d'armes Vorpal en appliquant cet ordre. Timber et Vorpal seuls ont aussi été testés ensemble sans reproduire le problème ; le conflit exact n'a pas été reproduit localement. Ne pas confondre Better Item Info avec Better Clothing Info (`EURY_CLOTHINGINFO`). Redémarrer complètement le jeu après un changement d'ordre.

Poids : **7**, moteur arrêté ou allumé. État maximal : **127**, pour éviter qu'une tronçonneuse abîmée devienne cassée lors de sa sauvegarde ou de sa transmission au client. Les réglages d'usure sont conservés : la durée de vie diminue donc d'environ 37 % par rapport au plafond de 200. Le remplacement au démarrage ou à l'arrêt conserve l'état, ou son pourcentage si les plafonds diffèrent. Il ne peut pas récupérer l'état déjà perdu au chargement d'une ancienne sauvegarde ; une tronçonneuse cassée doit toujours être réparée.

Corrections : les arbres tombent vraiment ; le plein ne prend que l'essence nécessaire, et seulement de l'essence ; l'option de consommation est lue ; plus d'erreur d'infobulle sur les jauges de liquide ; volume des sons réglé par le curseur des effets ; tout est décidé par le serveur en multijoueur.
