# Installation

[Home](Home.md) · Next: [Using the chainsaw](02-using-the-chainsaw.md) · [Français](../fr/01-installation.md)

## Requirements

- Project Zomboid **Build 42.21** or newer.
- [TooltipLib](https://steamcommunity.com/sharedfiles/filedetails/?id=3694097672) (mod ID `TooltipLib`), required.

## Subscribe and enable

1. Subscribe to **Timber! - Working Chainsaw** on the Steam Workshop (item 3810638546) and to TooltipLib.
2. In the **Mods** screen (or the mod settings of an existing save), enable **batman_Timber! Chainsaw** (`batman_TimberChainsaw`) and TooltipLib.
3. Optional, with Authentic Z only: also enable **batman_Timber! Chainsaw - Authentic Z Compatibility**, loaded after Authentic Z and Timber. See [FAQ and compatibility](07-faq-and-compatibility.md#authentic-z).

Do not enable the original **Chainsaw B42** (`ChainsawB42`) at the same time: both mods use the same item names.

## Dedicated server

In the server `.ini`, add the Workshop items and the mod IDs:

```
WorkshopItems=...;3694097672;3810638546
Mods=...;TooltipLib;batman_TimberChainsaw
```

With Authentic Z, add `batman_TimberAuthenticZCompatibility` after `batman_TimberChainsaw`. Restart the server completely after any change.

## Check

Right-clicking a chainsaw shows **Start the chainsaw**, and its tooltip shows the **Engine** and **Fuel** lines.

> Capture à faire : the Mods screen with Timber! Chainsaw and TooltipLib enabled.
