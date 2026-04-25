# Changelog

All notable changes to the Wallet mod are documented here. Dates are
YYYY-MM-DD.

## 0.1.0 — 2026-04-19

Initial scaffold.

- Tier registry defined for three wallet types: Wallet, Ammo Tin, Money Case.
- Per-tier capacity, weight, value, rarity, inventory size, loot flags, and
  trader stocking rules configured.
- Runtime `ItemData` builder wired (Database injection still a TODO).
- MCM configuration with master toggle, transfer notifier, and per-tier
  enable switches.
- 3D models sourced from Sketchfab (CC BY 4.0 — see NOTICES.txt).
- Inventory icons rendered at game convention of 128 px per grid cell
  (128×128, 256×256, 384×256).
