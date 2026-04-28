# Changelog

All notable changes to the RTV Wallets mod are documented here. Dates are
YYYY-MM-DD.

## 1.0.1 — 2026-04-26

Re-upload to register the ModWorkshop mod id (`modworkshop=56408` in
`[updates]`). No functional changes from 1.0.0.

## 1.0.0 — 2026-04-26

First public release. Trader integration polished, MCM trimmed to settings
that actually do something, and cash behavior tuned to vanilla parity.

- **Trader "Sell for €" button** on the Deal panel, enabled whenever the
  player has selected items to offer with nothing requested in return.
  Drain-first flow mirrors vanilla barter: sold items vacate their cells,
  cash payment fills the freed slots, any overflow drops at the player's
  feet via our `Drop()` override. No more "your inventory is too full"
  blocking the sale.
- **Drag-overlay icon swap** — when dragging Cash over a wallet/case, the
  global three-bullet load overlay (`Icon_Combine_Load.png`) is replaced
  with a € symbol. Bullet texture restores automatically when you drop the
  cash or grab a non-Cash item next.
- **Cash drops as clean stacks** — vanilla `Drop()` splits stackables by
  `defaultAmount` (200) into multiple pickups spawned at the same physics
  position, where they routinely tunnel through floors. Our override
  chunks Cash by `maxAmount` (500) so a 500 € stack drops as **one**
  pickup, and staggers spawn positions when multiple chunks are needed.
- **Material dimming for Cash pickups** — the Sketchfab Euro-stack GLB
  ships with emissive PBR baked in, so cash glowed like a beacon in
  RTV's dim shelter/loot lighting. `WalletPickup` now duplicates the
  GLB's surface materials at `_ready`, kills emission, and halves albedo
  for Cash specifically. Wallets unchanged.
- **MCM cleanup** — removed four non-functional toggles that never gated
  any runtime code: master "Enable Wallets", "Notify On Transfer", and
  the three per-tier enables. Kept Stash Report Hotkey (works) and the
  standard Logger category. README and `wallets.gd` (only used by the
  dead per-tier loop) deleted to match.
- **Empty weights tuned to real-world references** — Leather Wallet
  0.10 kg / 0.20 full, Ammo Tin 1.50 / 2.00, Money Case 2.00 / 3.00.
  Tiers now feel like meaningful trade-offs instead of all being
  suspiciously light.
- **Cash registered 3× in `LT_Master.tres`** to triple natural drop
  frequency without changing rarity (still Common loot).

### Compatibility

- **Requires Metro Mod Loader v3.0.0 or later** for the `[registry]` API.
- **Incompatible with Wallet & Cash by domfrags** — both mods rewire the
  trader Buy/Sell flow. Pick one or the other.

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
