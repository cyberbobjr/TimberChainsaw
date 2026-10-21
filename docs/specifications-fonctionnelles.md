# Spécifications fonctionnelles — Timber! Chainsaw

Version décrite : 1.2.0, Build 42.21. Les valeurs chiffrées sont celles des options par défaut. Les contrats techniques (noms exacts, formats) sont dans [specifications-techniques.md](specifications-techniques.md).

## F01 — La tronçonneuse

- Objet « Tronçonneuse » (« Chainsaw »), deux états visibles dans l'inventaire : arrêtée (« Tronçonneuse ») et en marche (« Tronçonneuse (en marche) »).
- Arme à deux mains, catégorie Hache, poids **7** dans les deux états, état maximal **127**.
- Arrêtée, c'est une massue lourde et faible (dégâts 0,1 à 0,5). En marche, dégâts 1,2 à 2,4, 25 % de critiques (×3), forte efficacité contre les arbres et les portes.
- Réservoir de **4 L**. Une tronçonneuse neuve ou jamais remplie est pleine.
- Modèle 3D, texture et animations vanilla ; sons propres au mod.

## F02 — Démarrer

- Clic droit sur la tronçonneuse (inventaire, ou monde si elle est en main) → **Démarrer la tronçonneuse**. Elle est d'abord prise à deux mains si nécessaire.
- Option grisée, avec la raison en infobulle : tronçonneuse cassée, réservoir vide, joueur dans un véhicule.
- Action d'environ 60 unités de temps avec animation et son de lanceur ; la marche annule l'action seulement en course.
- **Raté** : sous la moitié de son état, une tronçonneuse a `JamFrequency` % (25 %) de chances de ne pas démarrer ; message « *Toussotement* La tronçonneuse ne démarre pas... ». On peut réessayer.

## F03 — Combattre

- En marche et tenue à deux mains, la tronçonneuse est une vraie arme de mêlée du jeu : viser (clic droit), attaquer (clic gauche).
- Bouton d'attaque maintenu : la lame reste pointée devant, à plein régime, et chaque cycle de 0,67 s cherche une cible (pose fixe au lieu des grands mouvements vanilla).
- **Usure au combat** : `ConditionLossCombat` (20) points d'état par zombie tué avec la tronçonneuse en marche.
- **Endurance** : coût d'endurance de l'arme réduit à `EnduranceCost` % (50 %).
- Les zombies ne sont pas renversés par la tronçonneuse (la Build 42.21 ne lit pas `KnockdownMod` ; la chute dépend de l'animation de réaction).

## F04 — Arrêter

- Clic droit → **Arrêter la tronçonneuse** (action courte, son d'arrêt).
- Arrêt automatique (retour à l'état arrêté, là où se trouve l'objet) quand :
  - la tronçonneuse quitte les deux mains (rangée, posée au sol, dans un sac ou un meuble) ;
  - le réservoir est vide (message « La tronçonneuse n'a plus d'essence ») ;
  - elle casse (message « La tronçonneuse a cassé ») ;
  - le joueur entre dans un véhicule, meurt (la tronçonneuse est arrêtée dans le cadavre ou au sol) ;
  - la partie est rechargée ou le joueur se reconnecte : une tronçonneuse en marche tenue sans avoir été démarrée dans la session est arrêtée (après 5 s sur un serveur).
- Lors d'un démarrage ou d'un arrêt, la nouvelle tronçonneuse garde le carburant, l'état (en pourcentage si les maxima diffèrent), le nombre de réparations, le favori, le sang et le nom personnalisé.

## F05 — Carburant

- Au ralenti, un plein dure environ **16 minutes réelles** à la vitesse ×1 (`FuelConsumption` 100 %). La consommation suit le temps de jeu : en accéléré, elle est plus rapide.
- La coupe d'arbres consomme en plus, proportionnellement aux points d'arbre retirés (le plus gros arbre ≈ 0,45 L de plus).
- `FuelConsumption` 0 = aucune consommation.

## F06 — Faire le plein

- Clic droit sur une tronçonneuse **arrêtée** et non pleine → **Faire le plein de la tronçonneuse**.
- Exige un récipient d'**essence pure** dans l'inventaire (sacs portés compris ; il est sorti du sac si besoin). Le récipient le plus rempli est choisi. Sans récipient, l'option est grisée (« Il faut un récipient d'essence pure dans l'inventaire »).
- Seuls les litres manquants sont prélevés ; aucun autre liquide n'est accepté.
- Durée : environ 40 unités de temps plus 40 par litre transféré ; annulée en marchant.

## F07 — Abattre un arbre

- Tronçonneuse en marche en main, clic droit sur un arbre → **Abattre l'arbre à la tronçonneuse**. Le joueur va à côté de l'arbre, puis coupe jusqu'à sa chute.
- 50 points d'arbre par seconde à `TreeCuttingSpeed` 100 % : un petit arbre (40 à 160 points) tombe en 1 à 3 s, le plus gros (560) en 11 s environ. L'arbre tombe et laisse ses bûches comme un abattage vanilla.
- Attaque tenue face à un arbre (chemin vanilla `IsoTree.WeaponHit`) : `TreeDamage` 67 × `TreeCuttingSpeed`/100 par coup (arrondi, au moins 1), × 1,5 avec le trait Bûcheron (moteur). Les deux chemins gardent des vitesses différentes (environ 100 points/s pour l'attaque à 100 %).
- Usure : `ConditionLossTree` (1) point, une chance sur 8 par coupe (2,5 coupes par seconde).
- La coupe s'arrête si le joueur s'éloigne, marche, si le réservoir est vide ou si la tronçonneuse casse.
- Frapper un arbre en attaquant normalement l'abîme aussi (dégâts d'arbre de l'arme) et consomme le même carburant de coupe.

## F08 — Bruit et zombies

- Moteur au ralenti : bruit de rayon `NoiseIdle` (20 cases) toutes les 2 s.
- Attaque ou abattage : bruit de rayon `NoiseWorking` (40 cases) toutes les 2 s, en plus.
- Un rayon à 0 supprime le bruit correspondant.

## F09 — Sons

- Lanceur, arrêt, ralenti en boucle, plein régime en attaque, coupe de bois (en abattant ou en attaquant face à un arbre), impact sur zombie.
- Chaque joueur entend les tronçonneuses des joueurs proches (40 cases).
- Volume réglé par le curseur « Effets sonores » ; chaque son est aussi réglable dans Options > Audio > Avancé (catégorie Weaponry).

## F10 — Infobulle

Ligne « Moteur : En marche / Arrêté », jauge « Carburant » et litres (`3.10 / 4.0 L`). Fournie par TooltipLib, seulement sur les tronçonneuses.

![Infobulle d'une tronçonneuse en marche](images/screenshots/tooltip-engine-fuel.png)

## F11 — Réparer

- Recette **Réparer la tronçonneuse** (apprise par le magazine, Mécanique 3, toute surface) : tronçonneuse arrêtée (cassée acceptée), 2 pièces de moteur, 2 débris électroniques, 2 ferrailles, 4 vis, 1 chalumeau ; tournevis et clé gardés.
- Refusée pour une tronçonneuse intacte. Nombre de réparations illimité.
- Résultat : état maximal, carburant, favori, ModData et nom conservés ; message « Tronçonneuse réparée » ; 20 XP de Mécanique.

## F12 — Fabriquer

- Recette **Forger une tronçonneuse** (apprise par le magazine, Forge 5, Soudure 3, forge primitive) : 4 tôles, 2 petites tôles, 5 pièces de moteur, 5 débris électroniques, 2 fils, 2 tuyaux métalliques, 10 vis, 5 charbons, 2 chalumeaux, 1 chaîne lourde ; marteau, pince ou tenailles, masque de soudure gardés.
- Magazine **Réparation et entretien des petits moteurs** (« Small Engine Repair & Maintenance ») : apprend les deux recettes, réduit ennui et stress.

## F13 — Trouver

- Tronçonneuse arrêtée dans 11 listes de butin (scieries, gardes forestiers, pompiers, granges, garages, fermes, mécaniciens, quincailleries, jardineries, caisses d'outils), 1 à 3 % par tirage, multiplié par `LootChance`/3.
- Magazine dans 9 listes (scieries, gardes forestiers, magasins auto, quincailleries, mécaniciens, librairies, présentoirs, bibliothèques), indépendamment de `LootChance`.

## F14 — Messages

Raté, panne d'essence, casse et réparation s'affichent au-dessus du joueur concerné, dans sa langue (écran partagé compris).

## F15 — Reprise d'une sauvegarde Chainsaw B42

Mêmes noms d'objets et mêmes clés de carburant que le mod d'origine Chainsaw B42 (Likit) : remplacer l'un par l'autre conserve les tronçonneuses et leur carburant. Les deux mods ne doivent pas être actifs ensemble.

## F16 — Compatibilité Authentic Z (sous-mod facultatif)

Avec **batman_Timber! Chainsaw - Authentic Z Compatibility**, les tronçonneuses existantes d'Authentic Z Current ou Lite gagnent démarrage, carburant, plein, sons, bruit et abattage Timber, en gardant leur identifiant, apparence, poids, état maximal et dégâts natifs. Détails, ajout/retrait et protocole : [annexes/recherches/authenticz-compatibility.md](annexes/recherches/authenticz-compatibility.md).

## F17 — Options sandbox (page « Tronçonneuse B42 » / « Chainsaw B42 »)

| Option | Défaut | Bornes | Effet |
|---|---|---|---|
| Consommation de carburant | 100 % | 0–500 | Multiplie la consommation au ralenti et en coupe ; 0 = aucune. |
| Dégâts | 100 % | 25–500 | Dégâts d'une tronçonneuse Timber en marche (appliqué au démarrage). |
| Usure au combat | 20 | 0–100 | Points d'état perdus par zombie tué. |
| Usure à l'abattage | 1 | 0–20 | Points perdus, 1 chance sur 8 par coupe. |
| Vitesse d'abattage | 100 % | 25–400 | Points d'arbre par coupe (20 × %). |
| Coût en endurance | 50 % | 0–200 | Part du coût d'endurance de l'arme. |
| Portée du bruit (ralenti) | 20 | 0–100 | Rayon en cases toutes les 2 s. |
| Portée du bruit (attaque, coupe) | 40 | 0–100 | Rayon en cases toutes les 2 s. |
| Ratés au démarrage | 25 % | 0–100 | Chance de raté sous la moitié de l'état. |
| Tronçonneuses trouvables | 3 | 0–10 | Multiplie les poids de butin (3 = défaut, 0 = aucune). Appliqué au lancement de la partie. |

## F18 — Multijoueur

- Tout ce qui change l'objet ou le monde est décidé par le serveur : démarrage, arrêt, carburant, usure, plein, abattage, réparation.
- Le bruit de travail vient du client du joueur qui attaque ; les sons sont joués par chaque client.
- Une tronçonneuse laissée en marche à la déconnexion est retrouvée arrêtée à la reconnexion.

## Limites connues

- Les moteurs ne survivent pas à un rechargement ou une reconnexion (volontaire).
- Pas de démarrage ni de plein dans un véhicule ; plein uniquement tronçonneuse arrêtée.
- L'état maximal de 127 réduit la durée de vie d'environ 37 % par rapport à l'ancien plafond de 200 ; l'état déjà perdu au chargement d'une ancienne sauvegarde n'est pas récupéré.
- La recette de réparation ne vise que la tronçonneuse Timber arrêtée (`ChainsawB42.ChainsawOff`), pas les objets Authentic Z.
- L'ordre de chargement déclaré (`loadModAfter`) ne réordonne pas une liste de mods déjà enregistrée.
- L'infobulle de l'option « Usure au combat » parle encore d'un état de 200 (voir les points à confirmer de [specifications-techniques.md](specifications-techniques.md#points-à-confirmer)).
