# FAQ et compatibilité

[Accueil](Home.md) · Précédent : [Multijoueur](06-multiplayer.md) · [English](../en/07-faq-and-compatibility.md)

## Chainsaw B42

Timber est une réécriture complète inspirée de **Chainsaw B42** de Likit (Workshop 3692027888). Il utilise les mêmes noms d'objets et les mêmes données de carburant : remplacer l'un par l'autre conserve vos tronçonneuses et leur carburant. **N'activez jamais les deux.**

## Authentic Z

Le sous-mod facultatif **batman_Timber! Chainsaw - Authentic Z Compatibility** (dans le même objet Workshop) donne aux tronçonneuses d'Authentic Z Current **ou** Lite le moteur, le carburant, les sons, le bruit et l'abattage de Timber. Elles gardent leur identifiant, leur apparence, leur poids, leur état maximal et leurs dégâts de combat d'origine.

- Ordre de chargement : Authentic Z (et son éventuel correctif de traduction), puis Timber, puis le sous-mod.
- N'activez pas **AuthenticZChainsawFix** avec lui.
- Ajoutez-le ou retirez-le entre deux sessions, avec un redémarrage complet du jeu et du serveur, en gardant Authentic Z actif.
- La recette de réparation de Timber ne s'applique pas aux tronçonneuses Authentic Z ; leurs propres réparations restent disponibles.

## Better Item Info

Si vous utilisez **Better Item Info** (`EURY_ITEMINFO`), chargez-le **avant** Timber. Timber déclare cet ordre, mais un ordre de mods déjà enregistré n'est pas modifié d'office : vérifiez-le dans l'écran des mods, puis redémarrez le jeu.

## Questions

**Ma tronçonneuse tournait quand j'ai sauvegardé ; elle est maintenant arrêtée.** Les moteurs ne survivent pas à un rechargement. Redémarrez-la.

**« Faire le plein » est grisé.** La tronçonneuse doit être arrêtée et non pleine, et il faut un récipient d'essence pure dans l'inventaire.

**« Démarrer » est grisé.** Elle est cassée, le réservoir est vide ou vous êtes dans un véhicule.

**Elle refuse parfois de démarrer.** Sous la moitié de son état, elle peut avoir des ratés (option « Ratés au démarrage »). Réparez-la.

**Pourquoi un état maximal de 127 ?** L'état d'un objet abîmé est sauvegardé et transmis sur un octet signé ; au-delà de 127, une tronçonneuse abîmée pouvait devenir cassée. La durée de vie est environ 37 % plus courte qu'avec l'ancien plafond de 200, et l'état déjà perdu au chargement d'une ancienne sauvegarde ne peut pas être récupéré.

**Les zombies ne tombent pas.** La Build 42.21 ignore la valeur de renversement de l'arme ; c'est l'animation de réaction du zombie qui décide.

**Les sons sont trop forts.** Baissez le curseur Effets sonores, ou chaque son de tronçonneuse dans Options > Audio > Avancé (Weaponry).
