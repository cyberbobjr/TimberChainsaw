# Multijoueur

[Accueil](Home.md) · Précédent : [Options sandbox](05-sandbox-options.md) · Suivant : [FAQ et compatibilité](07-faq-and-compatibility.md) · [English](../en/06-multiplayer.md)

Timber! Chainsaw fonctionne sur les serveurs dédiés et hébergés.

## Ce que décide le serveur

- Démarrer, arrêter, faire le plein, réparer et abattre un arbre sont des actions chronométrées terminées par le serveur.
- Le serveur consomme le carburant, applique l'usure et arrête les moteurs (réservoir vide, tronçonneuse cassée, lâchée, véhicule, mort, déconnexion). Le niveau de carburant est transmis au propriétaire tous les 0,05 L.
- Les dégâts au combat sont gérés par le jeu comme pour toute arme. La tronçonneuse en marche est un type d'objet distinct : toutes les machines sont d'accord sur ses caractéristiques.

## Ce que chaque joueur voit et entend

- Chaque client joue le son du moteur des joueurs proches (40 cases) qui tiennent une tronçonneuse en marche, sans trafic réseau supplémentaire.
- Le bruit du ralenti qui attire les zombies est émis par le serveur ; le bruit de travail, plus fort, par le client du joueur qui attaque ou coupe.
- Les messages (raté, réservoir vide, casse, réparation) s'affichent au-dessus du bon joueur, dans sa langue, écran partagé compris.

## Déconnexion et reconnexion

Une tronçonneuse laissée en marche à la déconnexion est sauvegardée en marche, puis arrêtée environ 5 secondes après le retour de son propriétaire. Redémarrez-la depuis le menu.

## Configuration du serveur

Voir [Installation](01-installation.md#serveur-dédié). Après un changement de mods ou d'options, redémarrez complètement le serveur.
