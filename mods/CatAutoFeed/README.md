# Cat Auto Feed

> Automatically feeds your cat from a placed Cat Food Bowl from anywhere on the map.

No more returning to base every 40 minutes to drop a can of tuna in the feeder. The mod ships a 2x2 placeable **Cat Food Bowl** item that auto-feeds the cat when hunger drops below a configurable threshold, regardless of where you are on the map. An opt-in shelter-fallback toggle lets the cat raid raw food in cabinets/fridges if the bowl is empty.

## Installation

1. Drop `CatAutoFeed.vmz` into the game's `mods/` folder:
   `...\steamapps\common\Road to Vostok\mods\`
2. Ensure a compatible mod loader is installed (e.g. [Metro Mod Loader](https://modworkshop.net/mod/55623), the most popular for Road to Vostok).
3. **Recommended:** also install Mod Configuration Menu (MCM) — the mod runs without it, but settings can only be tweaked in-game when MCM is present.
4. Launch the game. The mod auto-detects the cat's shelter on the first check (it scans each shelter save for the litter-box / cat-carrier item placed when you rescued the cat).

## Features

- **Cat Food Bowl item** — 2x2 placeable inventory item with a custom 3D model. Sellable, droppable. Holds up to 10 servings of cat-edible food (Cat Food, Canned Meat, Canned Tuna, Perch).
- **Bowl management panel** — middle-click a placed bowl to open a custom UI: two-column layout (bowl ↔ inventory), Take/Add buttons, capacity indicator, "Pick up bowl" button (enabled when empty).
- **Spawns in legendary loot** — the bowl is registered in the master loot table, so it can spawn in civilian containers at Legendary rarity (~1 in 120 containers). Toggleable in MCM.
- **Auto-feed from anywhere** — when cat hunger drops below the threshold and you are outside the shelter, the cat eats one serving from its bowl.
- **Hunger and bowl-empty warnings** — orange on-screen notifications, once per hunger cycle.
- **Opt-in shelter fallback** — when off (default), the cat eats *only* from the bowl. When on, it falls back to raw food on the floor or in cabinets/fridges in its shelter.
- **Manual feeding preserved** — when you are inside the cat's shelter, the mod defers to the vanilla CatFeeder.
- **Shelter-agnostic** — works with Cabin, Attic, Classroom, Tent, or Bunker.

## Configuration (MCM)

| Setting | Default | Description |
|---|---|---|
| Enable Auto-Feed | On | Master toggle. |
| Feed Threshold | 25 | Cat hunger % below which the mod acts. |
| Show Fed Notification | On | Green "Cat ate from bowl: …" / "Cat Auto-Fed: …" messages. |
| Show Hunger Warning | On | Orange "Cat is hungry" / "Bowl is empty" messages. |
| Allow Shelter Fallback | **Off** | When off, cat eats only from the bowl. When on, the cat raids raw food in cabinets in its shelter. |
| Bowl in Loot Tables | On | Adds the bowl to the master loot table at Legendary rarity (~1 in 120 civilian containers). Reload the game after toggling. |

Plus the standard Logger category (level, file output, overlay output). See [the RTV Mod Logger reference](../RTVModLogger/LOGGER.md) for details.

## Compatibility

- **Incompatible with** other cat-feeding mods (e.g. *Cat Food Shelter*). Remove them before installing to avoid double-feeding.
- **MCM is optional** — the mod runs with sensible defaults if MCM is absent. It is only required for in-game configuration.
- **Uninstalling drops bowls and contents.** Save files reference the bowl via `res://mods/CatAutoFeed/Cat_Bowl.tres`. If you remove the .vmz, the game silently strips bowls (and any food they hold) from saves on next load. To migrate, empty all bowls before uninstalling.

## Credits

Built for the Road to Vostok modding ecosystem. In-game configuration via the [Mod Configuration Menu](https://modworkshop.net/mod/53713) by DoinkOink.

### 3D Models

- **"Cat bowl"** by Justyna.sliwinska — [source](https://skfb.ly/otWXJ) — licensed under [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).

See [NOTICES.txt](NOTICES.txt) for the verbatim attributions.

## License

[MIT](LICENSE) (mod code only — third-party 3D models retain their own CC BY 4.0 license; see NOTICES.txt).

## Source & Issues

Built in the [RoadToVostokMods workspace](https://github.com/dwoodruff83/RoadToVostokMods).
