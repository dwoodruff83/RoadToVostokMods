# Changelog

All notable changes to the Cat Auto Feed mod are documented here. Dates are
YYYY-MM-DD.

## 0.3.0 — 2026-04-25

Bowl capacity, fallback toggle, loot integration, item-tier tuning, and
clearer messaging.

- **Bowl capacity:** the Cat Food Bowl now caps at 10 servings. Add buttons in
  the management panel disable when the bowl is full; the panel shows
  `N / 10 servings` and turns amber at capacity. World tooltip shows
  `Cat Food Bowl (5/10)`.
- **MCM toggle "Allow Shelter Fallback":** new option, *default OFF*. When off,
  the cat eats *only* from the bowl — keep it filled or your cat goes hungry.
  When on, the cat falls back to raw food on the floor or in cabinets/fridges
  in its shelter (the previous behaviour).
- **Spawns in legendary loot:** Cat_Bowl is injected into `LT_Master.items` at
  mod load, so it spawns in civilian containers at Legendary rarity (~1 in
  120 containers). New MCM toggle "Bowl in Loot Tables" (*default ON*).
- **Item tier tuning:**
  - `type` changed from `"Furniture"` to `"Misc"` — bowls bought from a
    trader now go straight to inventory (the old `"Furniture"` value routed
    them to the placeable catalog). No effect on selling.
  - `rarity` set to `2` (Legendary) — surfaces a purple "Legendary" badge in
    the tooltip and routes the bowl into the legendary loot bucket.
  - `value` set to `750 €` — middle of the Legendary-civilian band.
- **Bowl-aware messages:**
  - 🟢 `Cat ate from bowl: <food>` when the bowl was the source
  - 🟠 `<bowl name> is empty — refill it for the cat` when the cat just took
    the last serving
  - 🟠 `Cat hungry — fill the bowl in <Shelter>` when bowl-only mode is active
    and the bowl is empty (now throttled to fire once per hunger cycle)
  - 🟠 `Inventory full — make space to take food out` when a Take fails
  - 🟠 `Bowl is full (N/10)` when an Add is rejected at capacity
  - Shelter-source feeds now suffix the source: `(<Shelter> floor)` or
    `(<Shelter> / <container>)`
- **Defensive bug fixes:**
  - Auto-feed loop skips ticks during scene transitions (`gameData.transition`)
    to avoid racing `Loader.SaveShelter` writes.
  - Shelter saves are loaded with `CACHE_MODE_REPLACE` so the next
    `Loader.LoadShelter` sees our just-edited `.tres` instead of a stale
    cached copy.
  - `BowlContentsPanel` checks `is_instance_valid(bowl)` before refreshing —
    a bowl freed mid-panel (explosion, mod reload) closes the panel cleanly
    instead of crashing.
  - "Pick up bowl" button tooltip clears when the button is enabled.
- **Bowl-first feed priority** is unchanged: when both a bowl and shelter food
  exist (with fallback enabled), the bowl is consumed first.

## 0.2.0 — 2026-04-25

Cat Food Bowl item.

- **New item: Cat Food Bowl** — a 2x2 placeable inventory item with a custom
  3D model. Sellable, droppable, behaves like any other Pickup. Distributed via
  Database injection (`take_over_path` + live-instance `set_script`).
- **Bowl-as-storage:** the bowl can hold cat-edible items
  (Cat_Food / Canned_Meat / Canned_Tuna / Perch). Storage uses the vanilla
  `SlotData.storage` array, so contents persist through inventory ↔ world ↔
  shelter transitions for free.
- **Custom management panel** opens on middle-click of a placed bowl:
  - Two-column layout: bowl contents (Take buttons) ↔ inventory cat-edibles
    (Add buttons)
  - Inherits the vanilla theme; item icons; row-level hover; capacity
    indicator; "Pick up bowl" button (enabled only when empty)
  - Locks player input and inventory toggle (Tab) while open; Esc closes
- **Cat-feed loop now scans bowls first.** When the cat is hungry and there's
  a bowl with food in its shelter, the cat eats from the bowl before scanning
  loose items or cabinet storage.

## 0.1.0 — 2026-04-19

Initial release.

- Continuous auto-feed: cat gets topped up to 100% when hunger drops below the
  threshold, anywhere on the map.
- Shelter detection via CatBox item — no hardcoded shelter name.
- Skips feed when player is inside the cat's shelter (vanilla feeder handles).
- Consumes loose placed items first, then container storage.
- Patches `Character.tres` directly so the fed value persists across
  `LoadCharacter()` calls triggered by scene transitions.
- Orange hunger warning on-screen once per hunger cycle.
- MCM integration: enable toggle, feed threshold, fed notification, hunger
  warning (all separately toggleable).
- Default threshold = 25 (matches the in-game red-stat threshold).
- Feeds the same item set as the vanilla CatFeeder: Cat Food, Canned Meat,
  Canned Tuna, Perch.
