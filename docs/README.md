# Documentation — Timber! Chainsaw

Tronçonneuse à essence fonctionnelle pour Project Zomboid Build 42.21 (solo et multijoueur) : démarrage, combat, abattage d'arbres, consommation et plein d'essence, bruit qui attire les zombies, avec un sous-mod facultatif de compatibilité Authentic Z.

| Document | Rôle |
|---|---|
| [architecture.md](architecture.md) | Architecture logicielle : mods et variantes, modules Lua par côté, flux et autorité, persistance, outillage. |
| [specifications-fonctionnelles.md](specifications-fonctionnelles.md) | Ce que fait le mod pour le joueur et l'administrateur (fonctionnalités `F01`…), options, solo/MP, limites connues. |
| [specifications-techniques.md](specifications-techniques.md) | Contrats précis : objets, recettes, sons, commandes réseau, clés ModData, options sandbox, traductions, API Lua, compatibilités. |
| [ameliorations-et-idees.md](ameliorations-et-idees.md) | Améliorations de code proposées et idées de fonctionnalités (propositions seulement). |
| [wiki/en/Home.md](wiki/en/Home.md) | Wiki joueur et administrateur en anglais (source du wiki GitHub). |
| [wiki/fr/Home.md](wiki/fr/Home.md) | Même wiki en français. |
| [images/screenshots/](images/screenshots/) | Captures en jeu utilisées par le wiki et le README. |
| [annexes/recherches/authenticz-compatibility.md](annexes/recherches/authenticz-compatibility.md) | Note détaillée du sous-mod de compatibilité Authentic Z : fonctionnement, ajout/retrait, preuves statiques et protocole de test en jeu. |
| [annexes/tests/autotest.md](annexes/tests/autotest.md) | Test en jeu automatique `pz-autotest` (solo et MP) : commandes, parcours nominal, contrôles client et serveur, limites. |

Hors de `docs/` : [README.md](../README.md) (présentation GitHub), [CHANGELOG.md](../CHANGELOG.md), `README.steam*` et `workshop.txt` (descriptions Workshop), `tests/` (vérifications automatiques), `source/` (générateurs des sons et des traductions).
