# Test en jeu automatique (pz-autotest)

Scénario nominal de Timber! Chainsaw joué sans personne devant le PC par l'outil générique
`.claude/tools/pz-autotest` du dossier de travail (`C:\Users\cyber\Zomboid\Workshop`). Il complète les tests lupa
(`tests/run_tests.py`), qui reposent sur une API simulée : ici, le vrai Java 42.21, le vrai réseau et les vraies
actions chronométrées.

- Configuration : [`autotest.json`](../../../autotest.json) (mods copiés : TooltipLib, lu dans le Workshop Steam, puis
  `batman_TimberChainsaw` ; sauvegarde solo copiée, jamais modifiée).
- Hooks : [`autotest/timber_hooks.lua`](../../../autotest/timber_hooks.lua).
- Résultats : `runs/<date>-<mode>-<jeton>/` (ignoré par git).

## Commandes

Depuis `C:\Users\cyber\Zomboid\Workshop` :

```powershell
python .claude/tools/pz-autotest/pz_autotest.py check TimberChainsaw
python .claude/tools/pz-autotest/pz_autotest.py sp    TimberChainsaw --wait-idle 3600
python .claude/tools/pz-autotest/pz_autotest.py mp    TimberChainsaw --client-run --wait-idle 3600
```

`--client-run` est aussi posé par `mp.clientRun` : le client 1 joue les gestes, le serveur contrôle sa propre copie du
joueur. Un seul jeu à la fois sur le PC (`--wait-idle`).

## Parcours

Le client avance d'une étape à chaque sondage du hook `done` (toutes les 250 ms), chaque étape ayant un délai propre.
Les gestes passent par les vrais menus du mod (événements `OnFillInventoryObjectContextMenu` et
`OnFillWorldObjectContextMenu`, puis l'option choisie) et par l'action vanilla de la barre rapide.

| Étape | Geste | Contrôle (client, et serveur en MP) |
|---|---|---|
| `prepare` | L'autorité (solo, ou serveur sur commande `PZATTimber/prepare`) donne une `ChainsawOff` pleine et choisit l'arbre le plus proche à 12 cases, sinon en plante un (`IsoTree.new` + `AddTileObject` / `transmitAddObjectToSquare`). | Tronçonneuse reçue, arbre visible chez le client. |
| `started` | Menu d'inventaire « Démarrer » (équipement à deux mains + `CSB42_StartAction`). | `Chainsaw` dans les deux mains, **nouvel objet** (ID différent de la `ChainsawOff`), aucune `ChainsawOff` restante. |
| `fuel` | Moteur au ralenti. | Carburant (`CurrentFuel`) inférieur à celui du démarrage (synchronisé tous les 0,05 L en MP). |
| `tree` | Menu du monde « Abattre l'arbre » (marche, `CSB42_CutTreeAction`). | Plus d'arbre sur la case. |
| `combat` | L'autorité fait apparaître un zombie et le tue au nom du joueur (solo `Kill(arme, joueur)`, serveur `setAttackedBy` + `die()`), ce qui passe par l'abonné `OnZombieDead` du moteur. | État diminué d'exactement `ConditionLossCombat` (20 par défaut). |
| `stopped` | Menu d'inventaire « Arrêter ». | `ChainsawOff` dans les deux mains, aucune `Chainsaw` restante. |
| `restarted` | « Démarrer » de nouveau. | Comme `started`. |
| `attached` | Accroche au dos par `ISHotbar:attachItem(…, true)` (action vanilla `ISAttachItemHotbar`), 5 s d'attente. | Un seul objet tronçonneuse accroché, de type `ChainsawOff`, **différent de l'objet en marche**, présent dans l'inventaire, emplacement ≥ 0 ; aucune `Chainsaw` restante, rien en main (bug C01). |

Une étape critique (`prepare`, `started`, `stopped`, `restarted`) en échec arrête le parcours. Le serveur termine quand
le client envoie `finished`. Réussite : 8 PASS côté client (ou `sp`), 8 PASS côté serveur en MP.

## Limites

- Non couverts : sauvegarde puis rechargement, reconnexion MP, plein d'essence, panne d'essence, enrayage, bruit,
  attaque tenue sur un arbre. À ajouter comme étapes suivantes (C15).
- Le combat ne simule pas un coup réel de l'arme : il vérifie l'usure par zombie tué (`OnZombieDead`), pas les dégâts.
- Rendu (modèle sur le dos, animations) et son : à vérifier à l'œil ; seule une capture finale est rangée.
- Le scénario a été vérifié par `check` et luacheck ; il n'a pas encore été lancé en jeu à sa création (2026-10-21).
