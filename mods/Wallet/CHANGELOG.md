# Changelog

All notable changes to the Wallet mod are documented here. Dates are
YYYY-MM-DD.

## 0.2.0 — 2026-04-25

Three placeable wallet items.

- **Three lootable inventory items** registered via Database injection
  (`take_over_path` + live-instance `set_script`):
  - **Wallet** (1×1, Common, 5,000 ₽ capacity)
  - **Ammo Tin** (2×2, Rare, 25,000 ₽)
  - **Money Case** (3×2, Legendary, 150,000 ₽)
- **3D world scenes** — RigidBody3D with `WalletPickup.gd` script. Auto-fits
  an axis-aligned BoxShape3D collision to the merged AABB of every
  MeshInstance3D under the pickup, so wallets with multiple parts (body +
  button) get full-body collision and pickup hitbox.
- **Inventory tetris scenes** matching the game's 64-pixel-per-cell rendering
  (Sprite2D at scale 0.5 with 128-per-cell PNG sources).
- **Sketchfab GLB models** (CC BY 4.0 — see NOTICES.txt) imported through
  Godot, with `.import` cache and `.godot/imported/*.ctex` packed in the VMZ
  for runtime texture resolution.
- **MCM schema migration** preserves user-edited values when the mod's config
  schema changes between versions.

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
