# Cat Auto Feed

> A real auto-feeder you build into your base. Placeable bowl, lootable, manageable — the middle ground between Immortal Cat (too easy) and vanilla (too punishing).

No more returning to base every 40 minutes to drop a can of tuna in the feeder. The mod ships a 2×2 placeable **Cat Food Bowl** item that auto-feeds the cat when hunger drops below a configurable threshold, regardless of where you are on the map. An opt-in shelter-fallback toggle lets the cat raid raw food in cabinets/fridges if the bowl is empty.

---

## ⚠ Compatibility

- ❌ **Cat Food Shelter** (and any other cat auto-feeder mod) — remove before installing to avoid double-feeding.
- ⚠ **Likely incompatible with [Put Food Out (#56098)](https://modworkshop.net/mod/56098)** by Improvise — both mods touch the cat-feeding loop. Pick one. Untested in combination; running both may cause double-feeds or contention over hunger ticks.
- ✅ **Coexists with other registry-using mods** (RTV Wallets, etc.). No `Database.gd` takeover — uses Metro's `[registry]` API.

This mod is a **different aesthetic** from "cat doesn't starve" mods like [Immortal Cat (#55927)](https://modworkshop.net/mod/55927). The cat-anxiety problem is *solved*, not *removed* — you still build, loot, and manage a bowl. If you'd rather skip the mechanic entirely, Immortal Cat is the right pick.

---

## Features

- **Cat Food Bowl item** — 2×2 placeable inventory item with a custom 3D model. Sellable, droppable. Holds up to 10 servings of cat-edible food (Cat Food, Canned Meat, Canned Tuna, Perch).
- **Bowl management panel** — middle-click a placed bowl to open a vanilla-styled UI: two-column layout (bowl ↔ inventory), Take/Add buttons, capacity indicator, "Pick up bowl" button (enabled only when empty).
- **Spawns in legendary loot** — registered in the master loot table at Legendary rarity (~1 in 120 civilian containers). Toggleable in MCM.
- **Optional Gunsmith supply** — opt-in MCM toggle (default OFF) lets the Gunsmith trader (day-10 unlock) stock bowls as a guaranteed late-game purchase path. Off by default so bowls remain loot-only out of the box.
- **Cat company mental buff** — being in the same shelter as your cat slowly raises mental at the same rate as sitting near a fire. Vanilla shelter doesn't normally restore mental — this is the cat's contribution. Cat must be alive and rescued. Toggleable in MCM.
- **Auto-feed from anywhere** — when cat hunger drops below the configured threshold and you're outside the shelter, the cat eats one serving from the bowl.
- **Hunger and bowl-empty warnings** — orange on-screen notifications, once per hunger cycle. Multi-bowl-aware: no false alarms when one bowl drains while siblings still have food.
- **Opt-in shelter fallback** — when off (default), the cat eats *only* from the bowl. When on, it falls back to raw food on the floor or in cabinets/fridges in its shelter.
- **Manual feeding preserved** — when you're inside the cat's shelter, the mod defers to the vanilla CatFeeder.
- **Shelter-agnostic** — works with Cabin, Attic, Classroom, Tent, or Bunker.

## Configuration (MCM)

Eight in-game toggles, all hot-swappable except the two loot-table options (require a reload):

| Setting | Default |
|---|---|
| Enable Auto-Feed | On |
| Feed Threshold | 25% |
| Show Fed Notification | On |
| Show Hunger Warning | On |
| Allow Shelter Fallback | **Off** |
| Bowl in Loot Tables | On |
| Bowl at Gunsmith | **Off** |
| Cat Company Mental Buff | On |

Plus a standard Logger category (level, file output, overlay output).

## Requirements

- **[Metro Mod Loader](https://modworkshop.net/mod/55623) v3.0.0 or later** — required. Uses Metro's `[registry]` API to add Cat_Bowl to the game's database without `take_over_path` collisions. Earlier loaders won't recognise the bowl.
- **[Mod Configuration Menu (MCM)](https://modworkshop.net/mod/53713)** — recommended. The mod runs with sensible defaults if MCM is absent; MCM is only required for in-game configuration.

## Uninstalling

Save files reference the bowl via `res://mods/CatAutoFeed/Cat_Bowl.tres`. Removing the `.vmz` causes the game to silently strip bowls (and any food they hold) on next load. **To migrate cleanly, empty all bowls before uninstalling.**

## Credits

### 3D Models

- **"Cat bowl"** by Justyna.sliwinska — [source](https://skfb.ly/otWXJ) — licensed under [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).

See `NOTICES.txt` in the `.vmz` for the verbatim attribution.

### Tooling

In-game configuration via [Mod Configuration Menu](https://modworkshop.net/mod/53713) by DoinkOink. Mod-loader infrastructure by Metro.

## License

[MIT](https://opensource.org/license/mit) for the mod code. The third-party 3D model retains its own CC BY 4.0 license — see `NOTICES.txt` bundled in the `.vmz`.
