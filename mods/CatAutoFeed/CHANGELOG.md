# Changelog

All notable changes to the Cat Auto Feed mod are documented here. Dates are
YYYY-MM-DD.

## 1.1.6 — 2026-05-01

- **Bowl rarity demoted from Legendary to Rare.** Previously
  `rarity = 2` (Legendary), now `rarity = 1` (Rare). Two reasons:
  - Gunsmith trader was effectively never stocking the bowl with the
    "Bowl at Gunsmith" MCM toggle on. Trader supply pools are random
    samples, and a Legendary item competes against a much larger pool
    for limited supply slots; in practice the bowl rarely surfaces.
    Demoting to Rare puts the bowl in a smaller, more-frequently-drawn
    bucket so the toggle actually does something visible.
  - Loot-spawn frequency in civilian containers also goes up. The old
    ~1-in-120-containers spawn rate at Legendary was tuned for the
    "rescue safety net" pitch but felt punishing for players who just
    wanted to find a bowl without crafting or buying. Rare is the
    right tier — uncommon enough to feel like a find, common enough
    that you'll see one within a hideout-clearing run.
- **Item value, weight, and tetris size unchanged.** This is a tier
  shift for spawn frequency and trader-pool behavior only; the bowl's
  in-game economy and inventory footprint stay the same.

## 1.1.5 — 2026-04-30

- Bowl no longer teleports up onto an upper shelf when placed near
  another item on the shelf below. Root cause: the periodic
  clip-correction raycast (`BowlPickup._compute_lift_to_clear_surface`)
  starts 0.5m above the bowl to handle the "buried in surface" case,
  but if a shelf was within that 0.5m it became the first hit and the
  correction lifted the bowl onto it. 1.1.4 reduced this by tightening
  collision but the raycast itself still found the wrong surface. Two
  guards added:
  - Reject ray hits more than 10cm above the bowl origin. A genuinely
    buried bowl's surface sits at most ~3-4cm above origin (bowls are
    ~7cm tall); anything farther is a different surface and we skip.
  - Skip lifts smaller than 5mm. The physics solver self-resolves
    shallow penetration tick-by-tick; our half-second lift was fighting
    the solver when a bowl placed touching another item was being
    nudged microscopically each tick, producing a perceptible bump
    cycle every 0.5s. Real clip-throughs that need rescue (the case
    1.1.4 originally addressed) are cm-scale and unaffected.
  - Reported via ModWorkshop comments on mod 56407.

## 1.1.4 — 2026-04-29

Bowl placement and rendering polish. No gameplay or save changes —
existing saves carry forward.

- Bowls placed quickly while upright no longer clip into the surface
  they are being placed on. Multi-layer collision detection and
  continuous in-process correction handle all known cases.
- Faint dark lines visible on the bowl from a few metres away are
  gone. Mild rim aliasing at distance is the trade-off.
- Fixed a regression in the placement preview where the bowl would
  snap onto nearby shelves above the aim point instead of staying
  where the player was aiming.

## 1.1.3 — 2026-04-28

Bowl-storage corruption fix and a user-requested in-shelter auto-feed
toggle. Both reported via ModWorkshop comments on mod 56407 — thanks to
Hun Alexander for the bug report and the feature suggestion.

- **Bowl-storage sharing fix.** Cat Food Bowls were sharing a single
  `SlotData` object across every spawned instance because
  `Cat_Bowl.tscn`'s inline `SlotData` sub-resource lacked
  `resource_local_to_scene = true`. Symptoms: food added to one bowl
  appeared in every bowl simultaneously, and placing a new bowl wiped the
  existing one's contents (because instantiation re-initialised the shared
  storage). Two-part fix:
  - `Cat_Bowl.tscn`: set `resource_local_to_scene = true` on the embedded
    `SlotData`. Each new bowl spawn now gets its own independent SlotData
    and its own storage Array.
  - `BowlPickup.gd._ready()`: defensive heal that duplicates
    non-local-to-scene SlotData on load. Auto-fixes existing-save bowls
    that were serialised while shared. Self-disables after one trigger
    per bowl per save. No-op for fresh installs (the `.tscn` flag means
    new bowls already pass the check).
- **New MCM toggle "Auto-Feed Even In Cat's Shelter"** (default OFF).
  When ON, the auto-feed tick runs even when the player is physically
  inside the cat's shelter, instead of deferring to vanilla in-shelter
  feeding. Useful for players who prefer fully hands-off bowl management.
  Default OFF preserves prior behaviour exactly.

Known minor issues deferred to a future patch: bowl mesh occasionally
clips into the surface it's placed on (intermittent physics), and dark
shading lines visible on the bowl at moderate distance (likely auto-LOD
related).

## 1.1.2 — 2026-04-27

Critical performance fix. Players reported severe FPS drops (e.g. 140 → 30)
after installing the mod; root cause was the per-frame mental-buff hot path
calling a "cache" that re-validated itself with a disk read on every frame.

- **`_find_cat_shelter()` now trusts the cache** instead of re-validating it
  on every call. The previous implementation called `_shelter_has_catbox()`
  to confirm the cache, which loaded the shelter `.tres` from disk and
  iterated its items each call. From `_maybe_buff_mental_from_cat()` (running
  every frame) that became a per-frame disk read. Trade-off: if the player
  relocates the catbox to a different shelter mid-session, the buff/feed
  tracks the original shelter until next game launch. Catboxes rarely move,
  so this is the right trade.
- **`_maybe_buff_mental_from_cat()` early-returns on empty cache.** Until the
  5-second `_try_auto_feed` tick has populated `_cached_cat_shelter`, the
  per-frame buff function is now a single property read and return — no
  config calls, no `gameData` reads, no node lookups. Once the cache is
  populated the function does its existing gates (config, gameData, current
  map) and applies the buff. Cheap checks reordered to the front.
- **Cache population hoisted in `_try_auto_feed()`.** The tick now calls
  `_find_cat_shelter()` immediately after the early-exit gates, before the
  hunger-threshold check. Previously the lookup only ran when the cat was
  actually hungry, so a fed cat never populated the cache, which meant the
  per-frame mental buff stayed dormant indefinitely. With the hoist, the
  cache fills within ~5s of game load whenever the cat is rescued and the
  catbox is placed.
- **First-buff latency:** up to ~5 seconds after game load (one auto-feed
  tick) before the cat company mental buff activates. After that it ticks
  every frame until the player leaves the cat shelter. Mental gain rate
  (`delta / 4.0`, ~0.25/sec) and all gates (cat alive / rescued /
  not-in-menu / in-the-cat-shelter) unchanged.

## 1.1.1 — 2026-04-26

Re-upload to register the ModWorkshop mod id (`modworkshop=56407` in
`[updates]`). No functional changes from 1.1.0.

## 1.1.0 — 2026-04-26

Migrated to Metro Mod Loader v3.x's built-in registry API; dropped the
RTVModItemRegistry soft-dependency.

- **Cat_Bowl now registered via `lib.register(SCENES, ...)`** in Metro v3.x's
  registry instead of overriding Database.gd via `take_over_path`. Metro
  wraps Database.gd at loader startup when any mod declares `[registry]` in
  mod.txt, so multiple item-adding mods coexist without clobbering each
  other. Replaces the previous RTVModItemRegistry coordination shim.
- **Cat_Bowl loot-table inject migrated** from direct `LT_Master.items.append`
  to `lib.register(LOOT, "catautofeed_bowl_master", {...})`. Idempotent and
  conflict-checked by Metro.
- **`DatabaseInject.gd` removed** from the package — Metro owns the Database
  wrapping now, no per-mod inject script needed.
- **Soft-dependency on RTVModItemRegistry dropped.** Metro v3.0+ replaces it
  natively; no third-party coordination library required.
- **Hard requirement bump:** Metro Mod Loader v3.0.0 or later. Earlier
  versions won't recognise the `[registry]` opt-in and the bowl won't appear
  in-game.

## 1.0.0 — 2026-04-26

First public release. Feature set frozen at 0.3.0; this entry captures the
pre-publish polish pass.

- **Cat company mental buff.** Being in the same shelter as your cat now
  raises mental at the same rate as sitting near a fire (`delta / 4.0`).
  Vanilla shelter doesn't normally restore mental — this is the cat's
  contribution. Gated on the cat being alive and rescued; bails on menu /
  settings / scene transitions (mirrors the auto-feed gates). Toggleable
  via the new "Cat Company Mental Buff" MCM entry, default ON.
- **Optional Cat Bowl sale at the Gunsmith.** New MCM toggle "Bowl at
  Gunsmith" (default OFF) routes the bowl into the Gunsmith trader's
  random-supply bucket. The Gunsmith only unlocks at day 10 in vanilla,
  so when enabled this gives players a guaranteed late-game purchase
  path if they haven't found a bowl in loot. Default off keeps bowls
  loot-only out of the box. Implementation toggles `Cat_Bowl.tres
  gunsmith` flag at mod load — reload after changing the toggle.
- **Multi-bowl-aware empty warning.** Players with multiple Cat Food
  Bowls in the same shelter no longer get a false "Bowl is empty —
  refill it for the cat" alert when one bowl drains while siblings
  still have food. The warning fires only when THIS bowl just hit zero
  AND no other bowl in the shelter holds cat food.
- **Soft-dependency on RTV Mod Item Registry.** When the registry is
  installed (recommended), `Cat_Bowl` is registered cooperatively so the
  mod coexists cleanly with other item-adding mods. Falls back to legacy
  direct Database injection in single-mod setups.
- **Logger 6/6 API coverage.** All status messages now route through the
  shared logger (`debug` / `info` / `success` / `warn` / `error` /
  `notify`) so users can tune verbosity and output channels per-mod via
  MCM. No raw `print()` calls remain in shipped code.
- **Quiet boot.** Demoted load-time diagnostics from `info` to `debug` so
  the in-game overlay stays clean at the default log level.
- **Clean uninstall path documented** in README under Compatibility.
- **`.vmz` now bundles** README, CHANGELOG, NOTICES, LICENSE so anyone
  who unzips the package gets the full context.

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
  - Green `Cat ate from bowl: <food>` when the bowl was the source
  - Orange `<bowl name> is empty — refill it for the cat` when the cat just
    took the last serving
  - Orange `Cat hungry — fill the bowl in <Shelter>` when bowl-only mode is
    active and the bowl is empty (now throttled to fire once per hunger cycle)
  - Orange `Inventory full — make space to take food out` when a Take fails
  - Orange `Bowl is full (N/10)` when an Add is rejected at capacity
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
