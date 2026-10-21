# Installation

[Accueil](Home.md) · Suivant : [Utiliser la tronçonneuse](02-using-the-chainsaw.md) · [English](../en/01-installation.md)

## Prérequis

- Project Zomboid **Build 42.21** ou plus récent.
- [TooltipLib](https://steamcommunity.com/sharedfiles/filedetails/?id=3694097672) (ID de mod `TooltipLib`), obligatoire.

## Abonnement et activation

1. Abonnez-vous à **Timber! - Working Chainsaw** sur le Workshop Steam (objet 3810638546) et à TooltipLib.
2. Dans l'écran **Mods** (ou les réglages de mods d'une partie existante), activez **batman_Timber! Chainsaw** (`batman_TimberChainsaw`) et TooltipLib.
3. Facultatif, avec Authentic Z seulement : activez aussi **batman_Timber! Chainsaw - Authentic Z Compatibility**, chargé après Authentic Z et Timber. Voir [FAQ et compatibilité](07-faq-and-compatibility.md#authentic-z).

N'activez pas en même temps le mod d'origine **Chainsaw B42** (`ChainsawB42`) : les deux mods utilisent les mêmes noms d'objets.

## Serveur dédié

Dans le fichier `.ini` du serveur, ajoutez les objets Workshop et les ID de mods :

```
WorkshopItems=...;3694097672;3810638546
Mods=...;TooltipLib;batman_TimberChainsaw
```

Avec Authentic Z, ajoutez `batman_TimberAuthenticZCompatibility` après `batman_TimberChainsaw`. Redémarrez complètement le serveur après chaque changement.

## Vérification

Un clic droit sur une tronçonneuse propose **Démarrer la tronçonneuse**, et son infobulle affiche les lignes **Moteur** et **Carburant**.

> Capture à faire : l'écran des mods avec Timber! Chainsaw et TooltipLib activés.
