# Multiplayer

[Home](Home.md) · Previous: [Sandbox options](05-sandbox-options.md) · Next: [FAQ and compatibility](07-faq-and-compatibility.md) · [Français](../fr/06-multiplayer.md)

Timber! Chainsaw works on dedicated and hosted servers.

## What the server decides

- Starting, stopping, refuelling, repairing and felling trees are timed actions completed by the server.
- The server burns the fuel, applies wear and stops engines (empty tank, broken chainsaw, unequipped, vehicle, death, disconnection). The fuel level reaches the owner every 0.05 L.
- Combat damage is handled by the game like any weapon. The running chainsaw is a separate item type, so every machine agrees on its stats.

## What each player sees and hears

- Every client plays the engine sound of nearby players (40 tiles) holding a running chainsaw, without extra network traffic.
- The idle noise that attracts zombies is emitted by the server; the louder working noise by the client of the player who attacks or cuts.
- Messages (failure to start, empty tank, broken, repaired) appear above the right player, in their own language, split screen included.

## Disconnection and reconnection

A chainsaw left running when its owner disconnects is saved as running and is stopped about 5 seconds after the owner comes back. Start it again from the menu.

## Server setup

See [Installation](01-installation.md#dedicated-server). After changing mods or options, restart the server completely.
