# FAQ and compatibility

[Home](Home.md) · Previous: [Multiplayer](06-multiplayer.md) · [Français](../fr/07-faq-and-compatibility.md)

## Chainsaw B42

Timber is a from-scratch remake inspired by **Chainsaw B42** by Likit (Workshop 3692027888). It uses the same item names and fuel data: replacing one by the other keeps your chainsaws and their fuel. **Never enable both.**

## Authentic Z

The optional submod **batman_Timber! Chainsaw - Authentic Z Compatibility** (in the same Workshop item) gives Authentic Z Current **or** Lite chainsaws Timber's engine, fuel, sounds, noise and tree cutting. They keep their item IDs, look, weight, condition maximum and native combat damage.

- Load order: Authentic Z (and its optional translation patch), then Timber, then the submod.
- Do not enable **AuthenticZChainsawFix** with it.
- Add or remove it between sessions, with a full game and server restart, keeping Authentic Z enabled.
- The Timber repair recipe does not apply to Authentic Z chainsaws; their own repairs remain.

## Better Item Info

If you use **Better Item Info** (`EURY_ITEMINFO`), load it **before** Timber. Timber declares this order, but a mod order you already saved is not changed automatically: check it in the Mods screen, then restart the game.

## Questions

**My chainsaw was running when I saved; now it is stopped.** Engines do not survive a reload. Start it again.

**Refuel is greyed out.** The chainsaw must be stopped and not full, and you need a container of pure petrol in your inventory.

**Start is greyed out.** It is broken, the tank is empty, or you are in a vehicle.

**It sometimes refuses to start.** Below half condition it can fail (Starting failures option). Repair it.

**Why is the condition maximum 127?** A damaged item's condition is saved and sent as a signed byte; above 127 a damaged chainsaw could become broken. Durability is about 37 % lower than with the old 200-point maximum, and condition already lost while loading an older save cannot be recovered.

**Zombies are not knocked down.** Build 42.21 ignores the weapon's knockdown value; the zombie's hit reaction decides.

**The sounds are too loud.** Lower the Sound effects slider, or each chainsaw sound in Options > Audio > Advanced (Weaponry).
