# Spécifications techniques — Timber! Chainsaw

Version 1.2.0. Contrainte : Build 42.21 (`versionMin=42.21`, variante unique `42.21`). Vue d'ensemble : [architecture.md](architecture.md) ; comportements joueur : [specifications-fonctionnelles.md](specifications-fonctionnelles.md).

## Identifiants

| Élément | Valeur |
|---|---|
| Objet Workshop | 3810638546 (« Timber! - Working Chainsaw ») |
| Mod principal | `id=batman_TimberChainsaw`, `name=batman_Timber! Chainsaw` |
| Sous-mod | `id=batman_TimberAuthenticZCompatibility`, `name=batman_Timber! Chainsaw - Authentic Z Compatibility` |
| Prérequis | TooltipLib (`TooltipLib`, Workshop 3694097672) |
| Incompatible | `ChainsawB42` (mod d'origine, Workshop 3692027888) ; sous-mod : aussi `AuthenticZChainsawFix` |
| Module de script | `ChainsawB42` (repris du mod d'origine pour la compatibilité des sauvegardes) |
| Module réseau / table Lua | `CSB42.MODULE = "ChainsawB42"` / globale `CSB42` |

## Objets (`media/scripts/ChainsawB42_Items.txt`, `ChainsawB42_Magazine.txt`)

| Propriété | `ChainsawB42.ChainsawOff` (arrêtée) | `ChainsawB42.Chainsaw` (en marche) |
|---|---|---|
| `ItemType` / `Categories` | `base:weapon` / `Axe` | idem |
| `Weight` | 7.0 | 7.0 |
| `ConditionMax` / `ConditionLowerChanceOneIn` | 127 / 200 | 127 / 200 |
| `MinDamage`–`MaxDamage` | 0.1–0.5 | 1.2–2.4 (× `DamageMod`/100 au démarrage) |
| `TreeDamage` / `DoorDamage` | 1 / 1 | 67 / 50 |
| `CriticalChance` / `CritDmgMultiplier` | 0 / 1 | 25 / 3 |
| `SwingTime` / `MinimumSwingTime` | 10 / 10 | 3 / 3 |
| Sons | `BaseballBatSwing`, `BaseballBatHit` | `ChainsawB42_Attack`, `ChainsawB42_ZombieHit` (coup, porte), `ChainsawB42_Attack` (sol) |
| `Tags` | `base:hasmetal` | `base:hasmetal;base:cutplant` |
| Communes | `TwoHandWeapon`, `RequiresEquippedBothHands`, `AttachmentType = BigBlade`, `MaxRange 1.2`, `MinRange 0.6`, `KnockdownMod 0`, `MetalValue 150`, modèles `ChainsawB42_Chainsaw` / `ChainsawB42_WorldItem_Chainsaw` (maillage et texture vanilla `Chainsaw`) |

Pourquoi 127 : l'état d'un objet abîmé est sauvegardé et transmis sur un octet signé ; au-delà, une tronçonneuse abîmée devenait cassée.

`ChainsawB42.ChainsawMaintenanceMagazine` : `base:literature`, poids 0.35, `BoredomChange -10`, `StressChange -10`, `LearnedRecipes = ForgeChainsaw;RepairChainsaw`.

## Recettes (`ChainsawB42_Recipes.txt`, module `Base`)

| Recette | Compétences | Temps | Lua | Sortie |
|---|---|---|---|---|
| `ForgeChainsaw` | `Blacksmith:5;MetalWelding:3`, apprise, tag `PrimitiveForge`, XP `Blacksmith:50;MetalWelding:25` | 500 | — | `ChainsawB42.ChainsawOff` |
| `RepairChainsaw` | `Mechanics:3`, apprise, tag `AnySurfaceCraft`, XP `Mechanics:20` | 300 | `OnTest = CSB42_Recipes.canRepair`, `OnCreate = CSB42_Recipes.onRepair` | `ChainsawB42.ChainsawOff` |

Entrées exactes : voir le fichier de script. `RepairChainsaw` prend `[ChainsawB42.ChainsawOff] flags[AllowDestroyedItem]`.

- `canRepair(item, character)` : vrai pour tout objet qui n'est pas une tronçonneuse ; pour une tronçonneuse, vrai si `getCondition() < getConditionMax()`.
- `onRepair(craftRecipeData, character)` : retrouve l'ancienne (`getAllConsumedItems`) et la nouvelle (`getAllCreatedItems`), copie la ModData, le carburant, met l'état au maximum, copie favori et nom personnalisé, `syncItemFields()` sur le serveur, notification `IGUI_CSB42_Repaired`.

## Sons (`ChainsawB42_Sounds.txt`)

Événements `ChainsawB42_Idle`, `_Start`, `_Stop`, `_Attack`, `_Rev`, `_WoodCut`, `_ZombieHit`, catégorie `Weaponry`, fichiers `media/sound/Chainsaw/*.ogg`. Les sons fichiers ne suivent pas le VCA « Effets sonores » : `CSB42.adjustVolume` leur applique `getCore():getOptionSoundVolume() / 10`.

## Animations

| Fichier | Rôle |
|---|---|
| `AnimSets/player/actions/CSB42Start.xml` | Nœud `CSB42Start`, clip `Bob_IdleChainsaw_Start`, condition `PerformingAction = CSB42Start`. |
| `AnimSets/player/actions/CSB42CutTree.xml` | Nœud `CSB42CutTree`, clip en boucle `Bob_ChainsawCutTree_Loop`. |
| `AnimSets/player/melee/2handed/ChainsawDefault.xml` | Remplace le fichier vanilla : clip `Bob_IdleAimChainsaw` (0,67 s), `AttackCollisionCheck` à 50 %, `ZombieHitReaction=Chainsaw`, sans `PlaySwingSound`. |
| `AnimSets/player/melee/2handed/ChainsawMiss.xml` | Nœud autonome (aucun `x_extends`, pour les serveurs Linux), conditions `AttackType=miss`, `AimFloorAnim=false`. |

Le sous-mod Authentic Z livre des copies octet pour octet des deux nœuds de combat (vérifié par `tests/run_tests.py`).

## Actions chronométrées

| Classe | Arguments | Durée | `isValid` / revérification dans `complete` |
|---|---|---|---|
| `CSB42_StartAction` | `(character, chainsaw)` | 60 (1 si instantané) | type arrêté, non cassée, carburant > 0, tenue à deux mains, hors véhicule. Raté : condition × 2 < max et `ZombRand(100) < JamFrequency`. |
| `CSB42_StopAction` | `(character, chainsaw)` | 15 | `CSB42.isHeldRunning`. |
| `CSB42_RefuelAction` | `(character, chainsaw, petrol)` | 40 + 40 × litres | type arrêté, les deux objets dans l'inventaire principal, `refuelAmount > 0`. Écrit `fluid:adjustAmount(getAmount() - quantité)` (`adjustAmount` fixe la quantité, `FluidContainer.java:647`). |
| `CSB42_CutTreeAction` | `(character, tree)` | -1 (jusqu'à `forceComplete`) | `hit()` sur l'autorité toutes les 0,4 s : tronçonneuse en marche tenue, arbre présent (`getObjectIndex() >= 0`), carburant, distance ≤ 3 cases et même étage. Dégâts `max(1, floor(20 × TreeCuttingSpeed/100 + 0.5))`. Événement d'animation émulé `CSB42Cut` côté serveur. |

Côté client, `isValid()` rend vrai une fois l'action démarrée (`self.started`) pour ne pas être annulée par l'échange d'objet effectué par le serveur.

## Commandes réseau

| Sens | Module / commande | Arguments | Contrôles |
|---|---|---|---|
| serveur → propriétaire | `ChainsawB42` / `notify` | `{ key = "IGUI_CSB42_…", playerOnlineId = <onlineID> }` | Le client n'accepte que `type(args) == "table"` et une clé préfixée `IGUI_CSB42_` ; affichage sur le joueur local d'`onlineID` correspondant, sinon joueur 0. |

Aucune commande client → serveur : les demandes passent par les actions chronométrées réseau. Synchronisations d'objet utilisées : `syncItemFields`, `sendAddItemToContainer`, `sendRemoveItemFromContainer`, `transmitRemoveItemFromSquare`, `sendEquip`.

## Clés ModData

Sur `item:getModData()` :

| Clé | Type | Sens |
|---|---|---|
| `CurrentFuel` | nombre (L) | Carburant restant, borné à `[0, FuelCapacity]`. Absent ou non numérique = plein. |
| `FuelCapacity` | nombre (L) | Capacité, 4.0 par défaut (réécrite à chaque `setFuel`). |
| `batman_TimberAuthenticZCompatibility` | table | Familles Authentic Z seulement : `{ CurrentFuel, FuelCapacity, wearRemainder }`. Créée à la première écriture à partir des clés racine éventuelles. |

`wearRemainder` : reste fractionnaire de l'usure proportionnée (`amount × ConditionMax / 127`).

## Options sandbox (`media/sandbox-options.txt`)

Espace de noms `ChainsawB42` (mêmes noms que l'original), page `ChainsawB42`, `VERSION = 1`, toutes de type `integer`. Lecture par `CSB42.option(nom)` avec repli sur la valeur par défaut si `SandboxVars.ChainsawB42.<nom>` n'est pas un nombre.

| Option | Défaut | Min | Max | Lue par |
|---|---|---|---|---|
| `FuelConsumption` | 100 | 0 | 500 | `CSB42_Engine` (ralenti), `CSB42.burnCuttingFuel` |
| `DamageMod` | 100 | 25 | 500 | `applyDamageMod` (familles sans `keepDamage`) |
| `ConditionLossCombat` | 20 | 0 | 100 | `onZombieDead` |
| `ConditionLossTree` | 1 | 0 | 20 | `CSB42_CutTreeAction:hit` |
| `TreeCuttingSpeed` | 100 | 25 | 400 | `hitDamage` |
| `EnduranceCost` | 50 | 0 | 200 | `applyEnduranceCost` |
| `NoiseIdle` | 20 | 0 | 100 | `CSB42_Engine.makeNoise` |
| `NoiseWorking` | 40 | 0 | 100 | `CSB42_Noise` |
| `JamFrequency` | 25 | 0 | 100 | `CSB42_StartAction` |
| `LootChance` | 3 | 0 | 10 | `CSB42_Distributions` |

Constantes (`CSB42_Core`) : `FUEL_CAPACITY = 4.0`, `FUEL_IDLE_PER_SECOND = 0.004`, `FUEL_PER_TREE_POINT = 0.0008`, `MIN_PETROL = 0.01` ; `HIT_SECONDS = 0.4`, `HIT_DAMAGE = 20` (`CSB42_CutTreeAction`) ; bruit toutes les 2 s, synchronisation tous les 0,05 L, délai de reconnexion 5 000 ms (`CSB42_Engine`).

Le temps est mesuré par `getGameTime():getMultiplier() / 48` (≈ secondes réelles à ×1).

## Butin (`CSB42_Distributions.lua`)

`ChainsawB42.ChainsawOff` (poids × `LootChance`/3, retiré si 0) : `LoggingFactoryTools` 3, `RangerTools` 2, `ForestFireTools` 2, `FireStorageTools` 2, `BarnTools` 2, `GarageTools` 2, `FarmerTools` 1.5, `MechanicTools` 1.5, `ToolStoreTools` 1, `GardenStoreTools` 1, `CrateTools` 1.

`ChainsawB42.ChainsawMaintenanceMagazine` (poids fixes) : `LoggingFactoryTools` 4, `RangerMagazines` 4, `CarSupplyMagazines` 6, `ToolStoreBooks` 6, `MechanicShelfBooks` 6, `BookstoreMisc` 4, `MagazineRackMixed` 4, `LibraryMagazines` 3, `LibraryBooks` 3.

En solo, les options de la sauvegarde ne sont connues qu'après la fusion des distributions : `OnInitGlobalModData` réapplique les poids et appelle `ItemPickerJava.Parse()` si le ratio a changé.

## Traductions

Fichiers `.json` seulement, générés par `source/build_translations.py`, langues `CN DE EN ES FR IT PL PT PTBR RU`, fichiers `ContextMenu`, `GameSound`, `IG_UI`, `ItemName`, `Recipes`, `Sandbox`, `Tooltip`.

| Préfixe | Fichier | Exemples |
|---|---|---|
| `ContextMenu_CSB42_` | `ContextMenu.json` | `Start`, `Stop`, `Refuel`, `CutTree` |
| `IGUI_CSB42_` | `IG_UI.json` | `Engine`, `Running`, `Stopped`, `Fuel`, `Jammed`, `OutOfFuel`, `Broken`, `Repaired`, `TooltipProvider` |
| `Tooltip_CSB42_` | `Tooltip.json` | `Broken`, `NoFuel`, `InVehicle`, `NoPetrol` |
| `Sandbox_ChainsawB42` | `Sandbox.json` | titre de page, `_<Option>` et `_<Option>_tooltip` |
| `GameSound_ChainsawB42_` | `GameSound.json` | noms des sons dans Options > Audio |
| `ChainsawB42.<Type>` / nom de recette | `ItemName.json` / `Recipes.json` | noms d'objets et de recettes |

`%` littéral écrit `%%`. Toutes les langues listent toutes les clés (pas de repli autre que l'anglais).

## API Lua publique

Table globale `CSB42` (partagée sauf mention).

| Fonction | Contrat |
|---|---|
| `registerFamily{ off, running, dataKey?, keepDamage?, prepareRunning? }` | Enregistre deux types complets distincts d'objets existants. `dataKey` : sous-table ModData du carburant ; `keepDamage` : ne pas appliquer `DamageMod` ; `prepareRunning(item)` : appelé à chaque contrôle de tenue et au démarrage (pour des champs non sauvegardés). |
| `getFamily(item)`, `isChainsaw`, `isStoppedType`, `isRunningType`, `stateType(item, running)` | Lecture du registre (`nil`/`false` pour un non-`InventoryItem`). |
| `isHeldRunning(character, item)`, `getHeldRunning(character)` | Tenue à deux mains d'un objet en marche ; réapplique le coût d'endurance et `prepareRunning`. |
| `getFuel`, `getCapacity`, `hasFuel`, `freeCapacity` | Lecture du carburant. |
| `setFuel(item, litres)`, `burnCuttingFuel(item, points)`, `applyWear(item, points)`, `replace(item, fullType, character)` | **Autorité seulement.** |
| `isPetrolCan`, `refuelAmount`, `findPetrolCan(inventory)` | Récipient d'essence pure (≥ 0,01 L). |
| `option(nom)` | Option sandbox avec repli. |
| `notify(character, key)` | Message localisé au propriétaire. |
| `onStarted(player, item)`, `stopEngine(player, item, noticeKey?)` | Serveur/solo seulement (définies par `CSB42_Engine`). |
| `adjustVolume`, `effectsVolume`, `treeAhead`, `showNotice` | Client seulement (`CSB42_Sound`). |

## Compatibilités vérifiées

| Mod | Statut | Source |
|---|---|---|
| Chainsaw B42 (Likit) | Incompatible déclaré ; sauvegardes reprises (mêmes types et clés). | `mod.info`, `CSB42_Core.lua` |
| Authentic Z Current / Lite | Sous-mod ; validé en jeu par l'utilisateur le 2026-10-07 (scénarios non détaillés). | [annexes/recherches/authenticz-compatibility.md](annexes/recherches/authenticz-compatibility.md) |
| AuthenticZChainsawFix | Incompatible avec le sous-mod (reconnaît les tronçonneuses sans filtrer le module). | idem |
| Better Item Info (`EURY_ITEMINFO`) | Charger avant Timber (`loadModAfter`) ; conflit d'infobulles rapporté par un joueur, non reproduit localement. | [README.md](../README.md) |
| TooltipLib | Requis. | `CSB42_Tooltip.lua` |

## Points à confirmer

- L'infobulle `Sandbox_ChainsawB42_ConditionLossCombat_tooltip` (toutes langues) indique « condition 200 » et « 20 = about 10 zombies » ; avec l'état maximal de 127, 20 points correspondent à environ 6 zombies.
- La capture `images/screenshots/tooltip-engine-fuel.png` montre une ancienne version (poids 15, mode debug) : à refaire avec la 1.2.0.
- Le multijoueur des versions 1.1.1 et 1.2.0 est couvert par les tests Lua ; aucun test MP en jeu n'est consigné.
