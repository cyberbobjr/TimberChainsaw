# Timber! Chainsaw — améliorations de code et idées de fonctionnalités

- **Mod** : batman_Timber! Chainsaw (`id=batman_TimberChainsaw`), sous-mod `batman_TimberAuthenticZCompatibility`
- **Version analysée** : 1.2.0 (`mod.info` des deux mods), Build cible 42.21, `versionMin=42.21`
- **Date** : 2026-10-21
- **Périmètre** : lecture de tout le code (`Contents/mods/**` : Lua, scripts d'objets, sons, AnimSets, traductions, `mod.info`, options sandbox), de `README.md`, `CHANGELOG.md`, `docs/`, `tests/` et `source/`. Comparaison avec le Lua vanilla installé (`D:\SteamLibrary\steamapps\common\ProjectZomboid\media`) et le Java décompilé 42.21.0 (`E:\pz-decompiled\42.21.0\java`), en s'appuyant sur la base `.claude/pz-knowledge` (arbres, tronçonneuse vanilla, `OnWeaponHitTree`, sons, MP).
- **Vérifications faites** : `python tests/run_tests.py` passe (79 tests Lua sous lupa, luacheck, traductions, descriptions Steam). **Aucun test en jeu n'a été fait pour ce document.** Chaque point indique s'il est « confirmé statiquement » (prouvé par la lecture du code) ou « à vérifier en jeu ».

Abréviations des chemins :
- `M/` = `Contents/mods/batman_TimberChainsaw/42.21/media/`
- `AZ/` = `Contents/mods/batman_TimberAuthenticZCompatibility/42.21/media/`
- `V/` = `D:\SteamLibrary\steamapps\common\ProjectZomboid\media\lua\`
- `J/` = `E:\pz-decompiled\42.21.0\java\zombie\`

---

## Partie 1 — Améliorations de code

### C01 — Tronçonneuse en marche accrochée au dos : l'emplacement garde l'ancien objet
- **Problème** : l'action vanilla d'accroche (`ISAttachItemHotbar:animEvent`) retire l'objet des mains puis l'accroche (`setAttachedItem`) **sans changer d'objet**. À la mise à jour suivante, le moteur Timber voit une tronçonneuse `Chainsaw` qui n'est plus en main (`stopReason` → `"unequipped"`) et la remplace par une nouvelle `ChainsawOff` dans l'inventaire. `CSB42.replace` ne connaît que les mains, le sol et les conteneurs : l'emplacement du dos pointe encore sur l'ancien objet, qui n'est plus dans l'inventaire. On peut s'attendre à un modèle fantôme sur le dos, à un raccourci de barre rapide vide ou à une incohérence client/serveur en MP.
- **Preuve** : `V/shared/TimedActions/ISAttachItemHotbar.lua:82-92` (accroche puis `removeFromHands`), `:67-70` (champs d'accroche) ; `M/lua/server/ChainsawB42/CSB42_Engine.lua:104-105` (arrêt au déséquipement) et `:52-56` (`holder` nul si l'objet n'est pas dans la main principale) ; `M/lua/shared/ChainsawB42/CSB42_Core.lua:390-430` (aucun traitement de `getAttachedSlot`/`setAttachedItem`). Aucune occurrence de `Attached` dans le Lua du mod.
- **Risque** : bug visible, persistance (objet accroché qui n'existe plus), MP (le serveur et le propriétaire divergent).
- **Correction** : dans `CSB42.replace`, retrouver le propriétaire lorsque le conteneur est l'inventaire d'un `IsoPlayer`, même si l'objet n'est pas en main. Si `item:getAttachedSlot() >= 0`, retirer l'ancien objet de l'emplacement (`character:removeAttachedItem(old)`), puis accrocher le nouveau au même emplacement (`setAttachedItem`, `setAttachedSlot`, `setAttachedSlotType`, `setAttachedToModel`, comme `ISAttachItemHotbar.lua:67-70`), puis transmettre l'accroche (voie réseau à confirmer en 42.21). Autre possibilité, plus simple : arrêter le moteur avant l'accroche en enveloppant `ISAttachItemHotbar:new` ou `isValid` pour une tronçonneuse en marche. Ajouter un test lupa sur ce scénario.
- **Statut** : déduit statiquement, **à vérifier en jeu** (solo et MP : accrocher au dos une tronçonneuse en marche, puis la décrocher, la démarrer, sauvegarder et recharger).
- **Priorité** : haute. **Effort** : moyen (0,5 à 1 j avec les tests).

### C02 — Infobulle « Usure au combat » périmée dans les 10 langues
- **Problème** : l'infobulle annonce « (état 200). 20 = environ 10 zombies ». Depuis la 1.0.3, l'état maximal est 127 : avec la valeur par défaut 20, la tronçonneuse casse en **6 à 7 zombies tués**, sans compter l'usure vanilla par coup (`ConditionLowerChanceOneIn = 200`).
- **Preuve** : `M/lua/shared/Translate/EN/Sandbox.json:8` (et la même clé dans les 9 autres langues) ; source `source/build_translations.py:63, 127` ; `M/scripts/ChainsawB42_Items.txt:83` (`ConditionMax = 127`) ; `CSB42_Engine.lua:197-216` (20 points par zombie tué).
- **Risque** : traduction et équilibrage (un administrateur règle mal l'option, des joueurs voient l'outil casser « trop vite »).
- **Correction** : corriger le texte dans `build_translations.py` (« état 127 ; 20 = environ 6 zombies ») puis regénérer les 10 fichiers. Décider séparément, avec l'utilisateur, si la valeur par défaut doit passer à 12 (environ 10 zombies, comme avant la 1.0.3) : c'est un changement d'équilibrage à annoncer.
- **Statut** : confirmé statiquement.
- **Priorité** : haute. **Effort** : faible (30 min).

### C03 — Deux vitesses d'abattage : l'attaque tenue va deux fois plus vite que le menu et ignore `TreeCuttingSpeed`
- **Problème** : l'action du menu enlève 20 points toutes les 0,4 s (50 points/s), multipliés par `TreeCuttingSpeed`. Une attaque tenue face à un arbre passe par `IsoTree.WeaponHit` : 67 points (`TreeDamage`) par cycle de 0,67 s, soit environ 100 points/s, et 150 points/s avec le trait Bûcheron (`AXEMAN`, l'arme est en catégorie `Axe`). L'option `TreeCuttingSpeed` ne touche pas ce chemin, et le bonus du trait ne s'applique pas au menu.
- **Preuve** : `M/lua/shared/TimedActions/CSB42_CutTreeAction.lua:255-265` ; `M/scripts/ChainsawB42_Items.txt:95` (`TreeDamage = 67`) et `:71` (`Categories = Axe`) ; `J/iso/objects/IsoTree.java:217-232` (dégâts × 1,5 avec `AXEMAN`) ; cycle de 0,67 s : `M/AnimSets/player/melee/2handed/ChainsawDefault.xml:46` (`Bob_IdleAimChainsaw`).
- **Risque** : équilibrage et cohérence des options. L'infobulle de `TreeCuttingSpeed` promet des durées que l'attaque tenue ne respecte pas.
- **Correction** : appliquer `TreeCuttingSpeed` au `TreeDamage` de l'objet en marche, sur chaque machine, là où `applyEnduranceCost` est déjà appliqué. `TreeDamage` n'est pas sérialisé (`HandWeapon.save`), comme `EnduranceMod`. Pour le menu, appliquer le même bonus `AXEMAN` × 1,5, voire le métier `LUMBERJACK`, afin que les deux chemins suivent la même règle. Adapter les infobulles.
- **Statut** : confirmé statiquement (vitesses déduites des durées d'animation, à mesurer en jeu).
- **Priorité** : moyenne. **Effort** : faible à moyen.

### C04 — L'abattage par le menu ne coûte ni endurance ni effort et n'a aucun retour visuel
- **Problème** : contrairement à `ISChopTreeAction`, `CSB42_CutTreeAction` ne vérifie pas `isEnduranceSufficientForAction()` ni `isSitting()`. Elle n'appelle pas `useEndurance` ni `addCombatMuscleStrain` à chaque coup, et ne joue pas `WeaponHitEffects` chez les clients (tremblement de l'arbre, surface de frappe). Un personnage épuisé abat donc une forêt sans fatigue et sans tension musculaire, alors que l'attaque tenue coûte de l'endurance (option `EnduranceCost`).
- **Preuve** : `V/shared/TimedActions/ISChopTreeAction.lua:5-12` (conditions), `:65-107` (endurance, tension, effets) ; `M/lua/shared/TimedActions/CSB42_CutTreeAction.lua:281-284` et `:364-405` ; `J/iso/objects/IsoTree.java:202-214` (`WeaponHitEffects`).
- **Risque** : équilibrage et retour visuel. En MP, le coût d'endurance doit être appliqué sur le serveur (dans `hit()`), comme le vanilla dans `animEvent`.
- **Correction** : reprendre `useEndurance` et `addCombatMuscleStrain` du vanilla dans `hit()`, multipliés par `EnduranceCost` ; ajouter les deux conditions dans `isValid` ; côté client, appeler `self.tree:WeaponHitEffects(character, chainsaw)` toutes les 0,4 s dans `update()` (le son de coup de l'arme peut faire double emploi avec la boucle bois : à vérifier).
- **Statut** : confirmé statiquement ; rendu et son **à vérifier en jeu**.
- **Priorité** : moyenne. **Effort** : moyen.

### C05 — Usure et expérience d'entretien différentes entre le menu et l'attaque
- **Problème** : le menu use l'arme avec un tirage maison (`ZombRand(8)`, `ConditionLossTree`). L'attaque tenue passe par `weapon:damageCheck(...)`, qui tient compte du niveau d'arme et peut donner de l'expérience d'entretien. Le menu ne donne jamais cette expérience.
- **Preuve** : `CSB42_CutTreeAction.lua:383-390` ; `J/iso/objects/IsoTree.java:218-221`.
- **Risque** : cohérence de la progression, faible.
- **Correction** : documenter la différence, ou ajouter l'expérience d'entretien vanilla au chemin du menu (vérifier d'abord que `damageCheck` est exposé à Lua et ce qu'il rend).
- **Statut** : confirmé statiquement ; exposition de `damageCheck` à vérifier.
- **Priorité** : basse. **Effort** : faible.

### C06 — Combattre des zombies ne consomme pas plus d'essence que le ralenti
- **Problème** : l'essence brûle au ralenti (`FUEL_IDLE_PER_SECOND`) et par point d'arbre coupé, mais pas pendant les attaques sur des zombies. Pourtant, le bruit de travail, le son « plein régime » et l'endurance distinguent déjà ce cas.
- **Preuve** : `CSB42_Engine.lua:155-177` (ralenti seul) ; `CSB42_Core.lua:208-214` (arbres seulement) ; `M/lua/client/ChainsawB42/CSB42_Noise.lua:167-169` (état « au travail » connu du seul client local).
- **Risque** : cohérence et équilibrage, faible. Côté MP, l'autorité ne voit pas directement l'attaque d'un joueur distant (`isAttacking` est local, voir pz-knowledge `multiplayer.md`, « isAttackStarted »).
- **Correction** : sur le serveur, compter une consommation par coup reçu qui touche, par un événement déclenché sur l'autorité (`OnWeaponHitCharacter` ou `OnHitZombie`), à confirmer dans le Java 42.21. Ajouter une option (par exemple `FuelPerAttack`, 0 par défaut pour ne pas changer l'équilibrage existant).
- **Statut** : confirmé statiquement pour l'absence ; événement serveur **à vérifier**.
- **Priorité** : basse. **Effort** : moyen.

### C07 — `isHeldRunning` est un prédicat à effets de bord
- **Problème** : `CSB42.isHeldRunning` écrit `EnduranceMod`, et appelle `prepareRunning` pour Authentic Z (5 mutateurs Java à chaque appel). Il est appelé par l'infobulle, les menus contextuels, la boucle sonore, le bruit de travail et le moteur serveur, donc plusieurs fois par image et par joueur visible.
- **Preuve** : `CSB42_Core.lua:138-158` ; `AZ/lua/shared/TimberAuthenticZ/TAC_Compatibility.lua:17-26` ; appelants : `CSB42_Tooltip.lua:489`, `CSB42_ContextMenu.lua:54`, `CSB42_Sound.lua:381`, `CSB42_Noise.lua:176`, `CSB42_Engine.lua:104`.
- **Risque** : maintenabilité (un test de lecture modifie l'objet), coût modeste mais répété, surprises dans les tests.
- **Correction** : séparer un prédicat pur `isHeldRunning` d'une fonction `ensureRunningStats(item)`, appelée seulement depuis le moteur (autorité) et la boucle sonore (une fois toutes les `CHECK_TICKS`), et qui n'écrit que si la valeur change (déjà fait pour l'endurance, pas pour les sons d'Authentic Z).
- **Statut** : confirmé statiquement.
- **Priorité** : basse. **Effort** : faible.

### C08 — `CSB42.replace` vide les mains avant de vérifier qu'il peut remplacer
- **Problème** : si l'objet tenu n'a ni objet au sol ni conteneur, `replace` a déjà appelé `removeFromHands` avant de rendre `nil`. Le personnage reste les mains vides et l'objet n'est pas remplacé.
- **Preuve** : `CSB42_Core.lua:410-421`.
- **Risque** : cas limite, peu probable (objet tenu sans conteneur), mais silencieux.
- **Correction** : tester `worldItem or container` avant `removeFromHands`, et journaliser en anglais (`[CSB42] replace failed: ...`).
- **Statut** : confirmé statiquement ; cas réel non observé.
- **Priorité** : basse. **Effort** : très faible.

### C09 — Le bruit du moteur ignore l'invisibilité d'un administrateur
- **Problème** : le bruit de ralenti et le bruit de travail passent par `addSound(player, ...)`, sans test d'invisibilité. Le vanilla utilise `addWorldSoundUnlessInvisible` pour les armes. Un administrateur invisible qui tient une tronçonneuse en marche attire donc les zombies.
- **Preuve** : `CSB42_Engine.lua:81-86` ; `CSB42_Noise.lua:196-199` ; patron vanilla cité dans pz-knowledge `combat-and-xp.md` (tir : `addWorldSoundUnlessInvisible`).
- **Risque** : MP et administration, faible.
- **Correction** : ne pas émettre si `player:isInvisible()` (à confirmer : méthode exposée en 42.21).
- **Statut** : confirmé statiquement pour l'absence de test ; **à vérifier en jeu**.
- **Priorité** : basse. **Effort** : très faible.

### C10 — `LootChance` ne règle pas le magazine
- **Problème** : avec `LootChance = 0`, la tronçonneuse ne se trouve plus, mais le magazine apprend toujours `ForgeChainsaw`. Ses poids sont fixes.
- **Preuve** : `M/lua/server/Items/CSB42_Distributions.lua:582-586` ; `M/scripts/ChainsawB42_Magazine.txt:10` (`LearnedRecipes = ForgeChainsaw;RepairChainsaw`).
- **Risque** : attente des administrateurs (« aucune tronçonneuse » ne l'est pas tout à fait).
- **Correction** : documenter ce choix dans l'infobulle, ou ajouter une option `MagazineLootChance`.
- **Statut** : confirmé statiquement.
- **Priorité** : basse. **Effort** : faible.

### C11 — Réparation illimitée et complète, sans compteur de réparations
- **Problème** : `RepairChainsaw` remet l'état au maximum sans limite, et ne touche pas à `HaveBeenRepaired`. Le vanilla réduit l'efficacité des réparations successives par ce compteur ; Timber le conserve au démarrage et à l'arrêt (`copyState`) mais ne l'augmente jamais.
- **Preuve** : `M/lua/shared/ChainsawB42/CSB42_Recipes.lua:282-301` ; `CSB42_Core.lua:343` ; `M/scripts/ChainsawB42_Recipes.txt:164-190`.
- **Risque** : équilibrage (outil éternel pour 2 pièces de moteur) ; toute modification change le jeu des joueurs actuels.
- **Correction** : à décider avec l'utilisateur. Par exemple, incrémenter `HaveBeenRepaired` et rendre `max(30 %, 100 % − 10 % × réparations)`, derrière une option dont la valeur par défaut garde le comportement actuel.
- **Statut** : confirmé statiquement.
- **Priorité** : basse. **Effort** : faible.

### C12 — Page des options sandbox nommée « Chainsaw B42 »
- **Problème** : la page des options porte le nom du mod d'origine. Un joueur qui a les deux mods dans sa liste, ou qui cherche « Timber », ne la reconnaît pas.
- **Preuve** : `M/lua/shared/Translate/EN/Sandbox.json:2` (`"Sandbox_ChainsawB42": "Chainsaw B42"`).
- **Risque** : traduction et ergonomie. L'espace de noms `ChainsawB42` des options doit rester inchangé (compatibilité des sauvegardes).
- **Correction** : changer seulement le **texte affiché** en « Timber! Chainsaw » dans les 10 langues, par `build_translations.py`.
- **Statut** : confirmé statiquement.
- **Priorité** : basse. **Effort** : très faible.

### C13 — Ligne de carburant de l'infobulle écrite en dur
- **Problème** : `string.format("%.2f / %.1f L", ...)` impose le point décimal et l'unité « L » dans toutes les langues (« 2,35 L » attendu en français, allemand, etc.).
- **Preuve** : `M/lua/client/ChainsawB42/CSB42_Tooltip.lua:497`.
- **Risque** : traduction, cosmétique.
- **Correction** : clé `IGUI_CSB42_FuelLitres` avec `%1 / %2 L`, et séparateur décimal selon la langue (clé de traduction pour le séparateur ou `string.gsub` du point).
- **Statut** : confirmé statiquement.
- **Priorité** : basse. **Effort** : faible.

### C14 — Distance d'écoute calculée pour le seul joueur 0 en écran partagé
- **Problème** : `nearListener` mesure la distance au joueur local 0 seulement. En écran partagé, le joueur 2 près d'une tronçonneuse éloignée du joueur 1 n'entend pas la boucle du moteur.
- **Preuve** : `M/lua/client/ChainsawB42/CSB42_Sound.lua:293-300`.
- **Risque** : écran partagé seulement, faible.
- **Correction** : prendre la distance minimale à tous les joueurs locaux actifs.
- **Statut** : confirmé statiquement ; **à vérifier en jeu** (écran partagé).
- **Priorité** : basse. **Effort** : très faible.

### C15 — Couverture de test : aucun scénario en jeu automatisé
- **Problème** : les 79 tests lupa reposent sur une API simulée (`tests/lua/game_api.lua`). Les régressions qui ont coûté des versions (octet signé de l'état, déséquipement en MP, héritage XML sous Linux) dépendent du Java ou du rendu.
- **Preuve** : `tests/run_tests.py:1-16` ; `CHANGELOG.md` (1.0.1, 1.0.3, 1.1.1 « Not yet tested in game »).
- **Risque** : régressions MP et de persistance non détectées.
- **Correction** : ajouter un scénario `pz-autotest` (outil `.claude/tools/pz-autotest` du dossier de travail) : démarrer, abattre un arbre, déséquiper, accrocher au dos (C01), sauvegarder et recharger, puis la même suite en `--mp` avec reconnexion. Vérifier l'état, le type d'objet et le carburant.
- **Statut** : constat.
- **Priorité** : moyenne. **Effort** : moyen (1 j).

### C16 — Documentation : versions et chemins à resynchroniser
- **Problème** : le document de compatibilité Authentic Z annonce le sous-mod en « 1.1.1 », alors que `mod.info` indique 1.2.0. Le document est désormais `docs/annexes/recherches/authenticz-compatibility.md`.
- **Preuve** : `docs/annexes/recherches/authenticz-compatibility.md:3` (chemin après réorganisation) ; `AZ/../mod.info:8` ; `README.md` (lien « details, limitations and in-game test protocol »).
- **Risque** : maintenabilité.
- **Correction** : mettre à jour l'en-tête et les liens une fois la réorganisation de `docs/` terminée.
- **Statut** : confirmé statiquement.
- **Priorité** : basse. **Effort** : très faible.

---

## Partie 2 — Idées de fonctionnalités

> Propositions seulement. Aucune n'est validée ; les options nouvelles ne seraient livrées qu'après accord explicite.

### I01 — Faire le plein depuis le sol, un meuble, un véhicule ou une pompe
- **Description** : proposer « Faire le plein » avec un bidon posé au sol ou dans un meuble voisin, et directement depuis le réservoir d'un véhicule ou une pompe à essence alimentée.
- **Intérêt joueur** : moins de manipulations d'inventaire ; l'essence du véhicule sert à la tronçonneuse sur un chantier.
- **Faisabilité moteur** : bidons voisins, bonne (même `FluidContainer`, `sendItemStats` pour un récipient resté dans un meuble, voir pz-knowledge `multiplayer.md`). Véhicule et pompe : reprendre les actions vanilla de prise d'essence (réservoir `VehiclePart` ; pompe soumise à `hasGridPower` ou à un générateur).
- **Impact MP** : tout dans `complete()` sur le serveur, avec contrôle de distance ; partie du véhicule synchronisée par les API vanilla.
- **Dépendances** : aucune.
- **Effort** : moyen.

### I02 — Mélange deux-temps et huile de chaîne (option réaliste)
- **Description** : option désactivée par défaut. L'essence pure use le moteur plus vite, un mélange (essence + huile) l'use normalement. Un niveau d'huile de chaîne accélère l'usure lorsqu'il est vide.
- **Intérêt joueur** : entretien crédible pour les serveurs « hardcore ».
- **Faisabilité moteur** : moyenne. Aucun fluide « huile moteur » vanilla repéré dans `scripts/generated/items` (seulement des huiles alimentaires) : il faudrait un fluide de mod ou réutiliser l'huile végétale. **À vérifier** : déclaration d'un `Fluid` de mod en 42.21.
- **Impact MP** : ModData de l'objet sur l'autorité, `syncItemFields`.
- **Dépendances** : aucune.
- **Effort** : élevé.

### I03 — Débiter les bûches en planches ou en bois de chauffage
- **Description** : recettes « Débiter à la tronçonneuse » plus rapides que la scie, qui brûlent de l'essence et usent la chaîne.
- **Intérêt joueur** : prolonge la boucle abattage → construction ; c'est l'usage le plus attendu d'une tronçonneuse.
- **Faisabilité moteur** : bonne. `craftRecipe` avec `ChainsawB42.ChainsawOff mode:keep`, `OnTest` sur le carburant, `OnCreate` qui retire l'essence et use l'objet (`getAllKeepInputItems`, voir pz-knowledge `api-42-21.md`). Le moteur en marche n'est pas exigé, ce qui évite de démarrer la tronçonneuse pendant l'artisanat.
- **Impact MP** : `OnCreate` sur l'autorité, puis `syncItemFields`.
- **Dépendances** : aucune.
- **Effort** : moyen.

### I04 — Dessoucher et débroussailler
- **Description** : retirer les souches laissées par `toppleTree`, les buissons et les haies avec la tronçonneuse en marche.
- **Intérêt joueur** : défricher une base sans pioche ni hache.
- **Faisabilité moteur** : `toppleTree` pose une souche (`J/iso/objects/IsoTree.java:724-729`) ; retrait par `transmitRemoveItemFromSquare` sur l'autorité. Le tag `base:cutplant` est déjà porté par l'objet en marche (`ChainsawB42_Items.txt:126`), à vérifier pour les plantes.
- **Impact MP** : action chronométrée avec `complete()`/`animEvent` sur le serveur.
- **Dépendances** : aucune.
- **Effort** : moyen.

### I05 — Découper une barricade, une porte ou un mur en bois
- **Description** : action de menu « Découper » sur une barricade en planches, une porte en bois ou une construction en bois, bruyante et coûteuse en essence.
- **Intérêt joueur** : entrer dans un bâtiment barricadé ou dégager une issue en urgence.
- **Faisabilité moteur** : bonne. `IsoBarricade:WeaponHit`/`IsoDoor:WeaponHit` sur l'autorité, puis `sendObjectChange(STATE)` (pz-knowledge `barricades-and-constructions.md`). `DoorDamage = 50` existe déjà pour la mêlée.
- **Impact MP** : serveur seulement ; risque de vandalisme de base : respecter les refuges (`SafeHouse`) et une option serveur.
- **Dépendances** : aucune.
- **Effort** : moyen.

### I06 — Rebond (« kickback ») et équipement de protection
- **Description** : option désactivée par défaut. Petite chance de coupure aux mains ou aux jambes en abattant, plus forte avec une compétence faible, un état bas ou le trait Maladroit, et réduite par des gants ou un pantalon épais.
- **Intérêt joueur** : tension et intérêt pour l'équipement.
- **Faisabilité moteur** : blessure par la santé des parties du corps sur l'autorité, puis synchronisation (`sendDamage`, pz-knowledge `combat-and-xp.md`) ; protection lue sur les vêtements portés (`getBodyPartClothingDefense` ou équivalent, **à vérifier**).
- **Impact MP** : calcul sur le serveur seulement.
- **Dépendances** : aucune.
- **Effort** : moyen.

### I07 — Démarrage selon la compétence, le froid et l'état
- **Description** : plusieurs tirages de lanceur. La chance dépend de la Mécanique, de la température et de l'état ; expérience de Mécanique à la réussite. Remplace ou complète `JamFrequency`.
- **Intérêt joueur** : petit moment de tension au démarrage.
- **Faisabilité moteur** : bonne. `CSB42_StartAction:complete` existe déjà ; température par `getClimateManager()` ; expérience donnée sur le serveur (`addXp` est sans effet sur un client MP, pz-knowledge `combat-and-xp.md`).
- **Impact MP** : tirage sur l'autorité, message déjà routé par `CSB42.notify`.
- **Dépendances** : aucune.
- **Effort** : faible.

### I08 — Alerte de carburant bas et jauge en main
- **Description** : message au-dessus du joueur à 25 % puis 10 % du réservoir, et petite jauge facultative près de la barre rapide quand la tronçonneuse est en main.
- **Intérêt joueur** : ne plus tomber en panne au milieu d'une horde.
- **Faisabilité moteur** : bonne. Le carburant est déjà connu du client (`syncItemFields` toutes les 0,05 L) ; message par `HaloTextHelper` déjà utilisé.
- **Impact MP** : client seulement.
- **Dépendances** : aucune.
- **Effort** : faible.

### I09 — Tronçonneuse électrique sur batterie
- **Description** : variante plus silencieuse, moins puissante, rechargée avec une batterie ou un générateur.
- **Intérêt joueur** : choix tactique entre bruit et puissance.
- **Faisabilité moteur** : bonne grâce au registre `CSB42.registerFamily` (`CSB42_Core.lua:30-37`). Le type d'objet en marche doit rester exactement `Chainsaw` pour les animations vanilla (`WeaponType.java:63, 100`), donc dans un **autre module**. Batterie : repli sur `Base.Battery` (drainable).
- **Impact MP** : comme la version à essence.
- **Dépendances** : nouveaux objets, icône, sons.
- **Effort** : élevé.

### I10 — Zombies bûcherons et coffres de véhicules forestiers
- **Description** : rare tronçonneuse portée par des zombies en tenue de bûcheron, et présence dans les coffres de pick-up ou de véhicules forestiers.
- **Intérêt joueur** : nouvelles sources réalistes.
- **Faisabilité moteur** : `AttachedWeaponDefinitions.lumberjack` existe (`V/shared/Definitions/AttachedWeaponDefinitions.lua:977-978`). Sur un serveur, l'objet seulement accroché à un zombie est perdu dans le cadavre (pz-knowledge `zombies-as-npc-bodies.md`) : le ranger dans l'inventaire à `OnZombieDead` sur l'autorité. Coffres : `VehicleDistributions`.
- **Impact MP** : parade obligatoire sur le serveur, sinon le butin n'existe qu'en solo.
- **Dépendances** : aucune.
- **Effort** : moyen.

### I11 — Abattage d'une zone
- **Description** : choisir une zone et enchaîner l'abattage de tous ses arbres. L'enchaînement s'arrête si le carburant, l'endurance ou l'état manque, ou si un zombie approche.
- **Intérêt joueur** : défrichage d'un terrain sans cent clics.
- **Faisabilité moteur** : bonne. File d'actions `walkAdj` + `CSB42_CutTreeAction` ; tracé de zone par surbrillance (pz-knowledge `ui-windows.md`).
- **Impact MP** : chaque action est déjà contrôlée par le serveur.
- **Dépendances** : C04 (coût d'endurance) conseillé avant.
- **Effort** : moyen.

### I12 — Démarrer et abattre en un clic
- **Description** : avec une tronçonneuse arrêtée en main ou dans l'inventaire, le clic droit sur un arbre propose « Abattre l'arbre à la tronçonneuse ». Le jeu enchaîne équipement, démarrage et abattage.
- **Intérêt joueur** : geste naturel, moins d'étapes.
- **Faisabilité moteur** : bonne. `CSB42_ContextMenu.lua:94-118` n'affiche l'option qu'avec une tronçonneuse déjà en marche ; il suffit de mettre `doStart` puis `doCutTree` en file (l'action d'abattage revérifie tout dans `isValid`/`hit`).
- **Impact MP** : aucun nouveau paquet.
- **Dépendances** : aucune.
- **Effort** : faible.

### I13 — Arrêt automatique au repos
- **Description** : option : le moteur s'arrête seul après N secondes sans attaque ni coupe, pour économiser l'essence et le bruit.
- **Intérêt joueur** : confort, moins de pannes sèches.
- **Faisabilité moteur** : bonne. Le moteur serveur a déjà la boucle et les raisons d'arrêt (`CSB42_Engine.lua:88-117`). L'activité vient du client (`CSB42_Noise.lua`) : il faudrait que le serveur la déduise des coups reçus ou d'une commande client.
- **Impact MP** : commande client limitée en fréquence, ou déduction sur le serveur.
- **Dépendances** : aucune.
- **Effort** : faible à moyen.

### I14 — Bonus de métier et de trait
- **Description** : Bûcheron (métier) : coupe plus rapide et moins d'essence ; trait Bûcheron (`AXEMAN`) appliqué au menu (voir C03).
- **Intérêt joueur** : valorise les choix de création du personnage.
- **Faisabilité moteur** : `getDescriptor():isCharacterProfession(CharacterProfession.LUMBERJACK)` est utilisé par le vanilla (`ISChopTreeAction.lua:71`).
- **Impact MP** : calcul sur le serveur dans `hit()`.
- **Dépendances** : C03.
- **Effort** : faible.

### I15 — Options du mod côté joueur
- **Description** : volume propre de la boucle moteur, masquage des messages au-dessus du joueur, seuil d'alerte de carburant (I08).
- **Intérêt joueur** : réglages personnels sans toucher au sandbox du serveur.
- **Faisabilité moteur** : `PZAPI.ModOptions` (pz-knowledge `ui-windows.md` : passer des clés de traduction).
- **Impact MP** : client seulement.
- **Dépendances** : aucune.
- **Effort** : faible.

### I16 — Affûtage de la chaîne
- **Description** : la chaîne s'émousse en coupant ; une chaîne émoussée coupe et frappe moins fort. Affûtage avec une lime (`Base.File` existe en 42.21).
- **Intérêt joueur** : entretien courant, plus fréquent qu'une réparation complète.
- **Faisabilité moteur** : la Build 42 a un tranchant sur des armes (`Sharpness = 1.0` dans `scripts/generated/items/weapon.txt`). **À vérifier** : API Lua du tranchant, sérialisation et effet réel sur les dégâts ; sinon, valeur en ModData appliquée au `TreeDamage` et aux dégâts.
- **Impact MP** : autorité et `syncItemFields`.
- **Dépendances** : C03 (même mécanisme d'application du `TreeDamage`).
- **Effort** : moyen.

### I17 — Chaîne de rechange et réparations partielles
- **Description** : objet « Chaîne de rechange » et réparation partielle sans pièces de moteur, en plus de la grande réparation.
- **Intérêt joueur** : entretien progressif en milieu de partie.
- **Faisabilité moteur** : bloc `fixing` vanilla ou `craftRecipe` avec `OnCreate` (syntaxe dans pz-knowledge `api-42-21.md`).
- **Impact MP** : autorité.
- **Dépendances** : C11 (politique de réparation).
- **Effort** : moyen.

### I18 — Tronçonneuse posée au sol en marche (piège sonore)
- **Description** : poser la tronçonneuse en marche au ralenti pour attirer les zombies ailleurs, jusqu'à la panne sèche.
- **Intérêt joueur** : diversion tactique cohérente avec le bruit du moteur.
- **Faisabilité moteur** : moyenne. Le moteur serveur suit aujourd'hui un objet tenu ; il faudrait une entrée « au sol » (bruit `addSound(nil, …)` sur la case, boucle jouée localement par chaque client sur un émetteur libre `playSoundImpl(nom, false, nil)`, voir pz-knowledge `sounds-and-noise.md`). Arrêt au déchargement du chunk.
- **Impact MP** : état à diffuser aux clients proches (commande serveur) ; persistance non souhaitée (arrêt au rechargement, comme aujourd'hui).
- **Dépendances** : aucune.
- **Effort** : élevé.

---

## Partie 3 — Priorisation : les 5 actions les plus rentables

1. **C02 — Corriger l'infobulle « Usure au combat »** (30 min, 10 langues regénérées) et trancher avec l'utilisateur la valeur par défaut (20 ou 12). C'est le gain le plus immédiat pour les administrateurs et les retours « ça casse trop vite ».
2. **C01 — Tester puis corriger l'accroche au dos d'une tronçonneuse en marche.** C'est le seul bug potentiel de persistance et de MP repéré ; il se vérifie en quelques minutes en jeu.
3. **C03 + C04 — Aligner l'abattage du menu et de l'attaque tenue** : `TreeCuttingSpeed` sur les deux chemins, trait Bûcheron, coût d'endurance, tension et tremblement de l'arbre. Une seule règle, des options qui disent vrai.
4. **C15 — Scénario `pz-autotest` solo et MP** : démarrer, abattre, déséquiper, accrocher, recharger, se reconnecter. Il protège les correctifs ci-dessus et les régressions déjà payées (octet signé, déséquipement en MP).
5. **I12 puis I08 — « Démarrer et abattre » en un clic et alerte de carburant bas.** Deux gains d'ergonomie bon marché, côté client, sans nouveau paquet ni option d'équilibrage.

Ensuite, si une grosse fonctionnalité est voulue : **I03 (débiter les bûches)**, qui prolonge la boucle de jeu principale avec un risque technique faible.

---

## Note finale

Ce document est une **proposition**. Il ne modifie aucun fichier du mod, et aucune correction ni fonctionnalité ne sera implémentée sans validation explicite de l'utilisateur. Cela vaut en particulier pour les changements d'équilibrage (C02, C06, C11) et les nouvelles options. Les points « à vérifier en jeu » n'ont pas été reproduits. Les constats sur l'API vanilla valent pour 42.21.0 (sources décompilées et Lua installés) et sont à revérifier après une mise à jour du jeu.
