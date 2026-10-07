# Timber! Chainsaw — Authentic Z Compatibility

Build cible : 42.21.0. Sous-mod : `batman_TimberAuthenticZCompatibility` (1.1.1).
Requiert le cœur Timber 1.1.0 et TooltipLib. Activer Authentic Z Current **ou** Lite,
puis Timber et le sous-mod ; ne pas activer les deux variantes Authentic Z ensemble.
Le sous-mod n'exige pas une variante précise pour éviter d'activer Current derrière Lite.

## Fonctionnement

Les quatre types Authentic Z d'origine sont enregistrés dans le moteur Timber :
`AuthenticZClothing.ChainsawOff`, `AuthenticZClothing.Chainsaw`,
`AuthenticZLite.ChainsawOff`, `AuthenticZLite.Chainsaw`.
Les actions de démarrage et d'arrêt remplacent l'objet par son autre état dans
**le même module Authentic Z**. Aucune distribution ni définition de script d'objet
n'est remplacée. Les objets existants, découverts dans un conteneur ou récupérés
sur un zombie, sont pris en charge sans migration globale de la sauvegarde.

L'apparence, le poids et le maximum d'état restent ceux d'Authentic Z (copie
inspectée : poids 3, état maximal 15). Le pourcentage d'état, le nombre de
réparations, le favori, le nom personnalisé et les ModData sont conservés au
changement d'état. L'usure supplémentaire Timber est proportionnée à 127 points,
avec un reste fractionnaire persistant. L'usure native de l'arme reste applicable.

Le sous-mod utilise les menus et infobulles traduits de Timber, les sons de moteur,
le bruit attirant les zombies, la consommation et le plein d'essence pure, et
l'action d'abattage sur l'autorité solo/serveur. Il ne fournit pas de nouvelle
recette de réparation Authentic Z ; les réparations restent celles disponibles
pour les objets d'origine.

Les dégâts de combat natifs sont conservés : le réglage Timber `DamageMod` ne
s'applique pas aux objets Authentic Z, pour ne pas inscrire de nouveaux dégâts
persistants. Les autres réglages moteur et d'usure s'appliquent ; `LootChance`
continue à régler uniquement les distributions Timber.

Le carburant et le reste d'usure sont dans
`item:getModData().batman_TimberAuthenticZCompatibility`. Une valeur de carburant
ancienne est lue sans écraser les données originales. Sans donnée valide, le
réservoir commence plein (4 L), comme Timber. Les mises à jour serveur utilisent
`syncItemFields`. Le retrait laisse les données présentes mais inutilisées ; la
réactivation retrouve le carburant conservé.

## Ajout et retrait

Ajouter ou retirer **entre deux sessions**, avec redémarrage complet du jeu et
du serveur. Conserver Authentic Z actif : c'est lui qui définit les objets.
Le sous-mod n'introduit aucun type d'objet, donc aucun objet ne dépend de son ID
pour être rechargé. Il ne supprime pas les effets normaux de l'utilisation :
usure, essence prélevée dans un bidon et arbres abattus restent acquis.

Les seules propriétés d'arme modifiées en runtime sont les sons et `TreeDamage`.
Le code de `HandWeapon.save` en 42.21 ne les sérialise pas : après retrait et
redémarrage, les définitions Authentic Z les fournissent à nouveau. Les dégâts
MinDamage/MaxDamage, le modèle, le poids et le maximum d'état ne sont pas modifiés.
Un objet enregistré comme `AuthenticZ*.Chainsaw` reste de ce type au retrait :
il retrouve le comportement natif, y compris les limitations d'Authentic Z 42.

Une tronçonneuse de type `Chainsaw` qui n'a pas été démarrée par Timber est arrêtée
lorsqu'un joueur la tient. En MP, le moteur attend le délai de reconnexion Timber.
Cela permet ensuite de la démarrer normalement avec le menu.

Authentic Z conserve un OnCreate déclaré dont l'implémentation est commentée.
Le sous-mod fournit uniquement la fonction manquante ; il ne remplace jamais une
implémentation déjà présente. Après retrait, les éventuelles erreurs natives
d'Authentic Z redeviennent possibles.

Ne pas activer `AuthenticZChainsawFix` avec cette compatibilité : il reconnaît les
tronçonneuses sans filtrer le module et peut intervenir aussi sur les objets Timber.
Le sous-mod doit se charger après Authentic Z, son éventuel correctif de traduction
et Timber. Les deux nœuds d'animation de combat Timber sont inclus dans le sous-mod
pour gagner sur les fichiers Authentic Z ; leur contenu est vérifié identique.

## Validation

Vérification statique le 2026-10-07 : journal local `version=42.21.0 4a0e9546ec` ;
sources décompilées `E:/pz-decompiled/42.21.0/java/zombie/core/Core.java:5094`
et révision correspondante. `HandWeapon.java:1243` (sauvegarde),
`WeaponType.java:63,100` (type Chainsaw), `ItemPickerJava.java:603,1030,1244`
(limites de OnFillContainer). Copie Authentic Z : Workshop 2335368829, variante
42 ; Current `items_AuthenticZ_Chainsaw.txt`, Lite `AuthenticZ_item_Chainsaw.txt`.

Les tests Lua utilisent une API simulée : ils couvrent Current/Lite, les actions,
le maintien des identifiants et de l'état, le carburant isolé, l'usure fractionnaire,
l'autorité client/serveur, l'arrêt automatique et une simulation de retrait/réactivation.
Ils ne prouvent pas la sérialisation Java, le rendu ni la connexion réelle MP.

Test en jeu à effectuer sur une copie de sauvegarde :

1. Redémarrer, activer Current ou Lite, Timber et le sous-mod ; vérifier l'ordre
   et les lignes `overrides` des animations, puis l'absence de nouvelle erreur f:0.
2. Essayer un ancien exemplaire, un objet de conteneur et un objet récupéré sur
   Ash/Leatherface/Chainsaw Maid : démarrage, combat, abattage, arrêt et plein.
3. Vérifier état, favori, nom, poids et carburant après démarrage/arrêt et recharge.
4. En MP : vérifier chez le propriétaire et un observateur les sons, l'arrêt à
   l'épuisement, l'abattage, le déséquipement puis la reconnexion.
5. Sauvegarder avec un objet arrêté et un objet allumé ; retirer uniquement le
   sous-mod, redémarrer, vérifier leur présence et leur état. Réactiver et vérifier
   la reprise du carburant. Authentic Z reste actif pendant tout le test.

Validation en jeu : l?utilisateur a indiqu? avoir test? et valid? la compatibilit? le 2026-10-07. Les sc?narios pr?cis et le mode de jeu n?ont pas ?t? d?taill?s.
