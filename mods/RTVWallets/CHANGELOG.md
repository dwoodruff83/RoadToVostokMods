# Changelog

All notable changes to the RTV Wallets mod are documented here. Dates are
YYYY-MM-DD.

## 0.3.0 — 2026-04-26

Migrated to Metro Mod Loader v3.x's built-in registry API; dropped the
RTVModItemRegistry soft-dependency.

- **Wallet/Cash scenes registered via `lib.register(SCENES, ...)`** in Metro
  v3.x's registry instead of overriding Database.gd via `take_over_path`.
  Metro wraps Database.gd at loader startup when any mod declares
  `[registry]` in mod.txt, so multiple item-adding mods coexist without
  clobbering each other.
- **`DatabaseInject.gd` removed** from the package — Metro owns the Database
  wrapping now.
- **Soft-dependency on RTVModItemRegistry dropped.**
- **Hard requirement bump:** Metro Mod Loader v3.0.0 or later.

## 0.2.0 — 2026-04-25

Three placeable wallet items.

- **Three lootable inventory items** registered via Database injection
  (`take_over_path` + live-instance `set_script`):
  - **Wallet** (1×1, Common, 1,000 € capacity)
  - **Ammo Tin** (2×2, Rare, 5,000 €)
  - **Money Case** (3×2, Legendary, 10,000 €)
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
