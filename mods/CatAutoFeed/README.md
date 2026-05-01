# Cat Auto Feed

> Auto-feeds your cat from a placed bowl, anywhere on the map — with an optional shelter-food fallback so the cat never starves on a forgotten refill.

No more returning to base every 40 minutes to drop a can of tuna in the feeder. A 2x2 placeable **Cat Food Bowl** auto-feeds your cat from anywhere on the map when hunger drops below a configurable threshold. Optional safety net: if the bowl runs dry, the cat raids raw food from cabinets / fridges in its shelter so it doesn't starve.

## Installation

1. Drop `CatAutoFeed.vmz` into the game's `mods/` folder:
   `...\steamapps\common\Road to Vostok\mods\`
2. **Required:** [Metro Mod Loader](https://modworkshop.net/mod/55623) v3.0.0 or later. The mod uses Metro's built-in registry API (`[registry]` opt-in in mod.txt) to add the Cat Food Bowl to the game's item database — earlier loaders without the registry won't recognise the bowl.
3. **Recommended:** also install [Mod Configuration Menu (MCM)](https://modworkshop.net/mod/53713) — the mod runs without it, but settings can only be tweaked in-game when MCM is present.
4. Launch the game. The mod auto-detects the cat's shelter on the first check (it scans each shelter save for the litter-box / cat-carrier item placed when you rescued the cat).

## Features

- **Auto-feed from anywhere** — when cat hunger drops below the threshold and you're outside the shelter, the cat eats one serving from its bowl. No more returning to base just to refill.
- **Opt-in shelter-food fallback (safety net)** — if the bowl runs dry, the cat raids raw food on the floor or in cabinets/fridges in its shelter so it doesn't starve. Toggle on in MCM if you want the safety net; off by default for purist bowl-only play.
- **Hunger and bowl-empty warnings** — orange on-screen notifications, once per hunger cycle, so you know to refill before it's a problem.
- **Manual feeding preserved** — when you're inside the cat's shelter, the mod defers to the vanilla CatFeeder. Same UX as before.
- **Cat Food Bowl item** — 2x2 placeable inventory item with a custom 3D model. Sellable, droppable. Holds up to 10 servings of cat-edible food (Cat Food, Canned Meat, Canned Tuna, Perch).
- **Bowl management panel** — middle-click a placed bowl to open a custom UI: two-column layout (bowl ↔ inventory), Take/Add buttons, capacity indicator, "Pick up bowl" button (enabled when empty).
- **Spawns in rare loot** — the bowl is registered in the master loot table, so it can spawn in civilian containers at Rare rarity. Toggleable in MCM. Optionally the Gunsmith trader (unlocks day 10) can also stock bowls — opt-in via MCM, default off so bowls remain loot-only.
- **Cat company mental buff** — being in the same shelter as your cat slowly raises mental at the same rate as sitting near a fire. Vanilla shelter doesn't normally restore mental — this is the cat's contribution. Cat must be alive and rescued. Toggleable in MCM.
- **Shelter-agnostic** — works with Cabin, Attic, Classroom, Tent, or Bunker.

## Configuration (MCM)

| Setting | Default | Description |
|---|---|---|
| Enable Auto-Feed | On | Master toggle. |
| Feed Threshold | 25 | Cat hunger % below which the mod acts. |
| Show Fed Notification | On | Green "Cat ate from bowl: …" / "Cat Auto-Fed: …" messages. |
| Show Hunger Warning | On | Orange "Cat is hungry" / "Bowl is empty" messages. |
| Allow Shelter Fallback | **Off** | When off, cat eats only from the bowl. When on, the cat raids raw food in cabinets in its shelter. |
| Bowl in Loot Tables | On | Adds the bowl to the master loot table at Rare rarity. Reload the game after toggling. |
| Bowl at Gunsmith | **Off** | Lets the Gunsmith trader (day-10 unlock) stock bowls in his random supply. Off by default — bowls are loot-only out of the box. Reload the game after toggling. |
| Cat Company Mental Buff | On | While in the cat's shelter (cat alive), raise mental at the same rate as a fire. |

Plus the standard Logger category (level, file output, overlay output). See [the RTV Mod Logger reference](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/RTVModLogger/LOGGER.md) for details.

## Compatibility

- **Metro Mod Loader v3.0.0+ required.** Cat_Bowl is added via Metro's registry (`lib.register(SCENES, ...)` and `lib.register(LOOT, ...)`), which means it coexists cleanly with any other mod also using the registry — no `take_over_path` collisions.
- **Incompatible with** other cat-feeding mods (e.g. *Cat Food Shelter*). Remove them before installing to avoid double-feeding.
- **Likely incompatible with [Put Food Out](https://modworkshop.net/mod/56098)** — both mods touch the cat-feeding loop. Pick one. Untested in combination; if you run both you may get double-feeds or fight over the same hunger ticks.
- **MCM is optional** — the mod runs with sensible defaults if MCM is absent. It is only required for in-game configuration.
- **Uninstalling drops bowls and contents.** Save files reference the bowl via `res://mods/CatAutoFeed/Cat_Bowl.tres`. If you remove the .vmz, the game silently strips bowls (and any food they hold) from saves on next load. To migrate, empty all bowls before uninstalling.

## Known issues

- **Bowl can rarely fall through the floor when bumped during placement.** If you're mid-placement and the bowl collides with another item (fishing rod on a shelf, lantern, anything), vanilla physics releases the placement (`Placer.Collided` → `Unfreeze()`) and the bowl can be ejected through a floor seam in the moment between kinematic preview and gravity-active modes. The vanilla "Item Returned" rescue only catches items that fall past the killbox volume far below the world (`y < -50`); a bowl that wedges a few cm under the floor never reaches it, and shallow falls aren't pruned by the save-time `y < -10` threshold either, so the bowl persists in the shelter save just below where you can see or interact with it. Recovery is currently a manual save-file edit: open `%APPDATA%\Road to Vostok\<Shelter>.tres`, find the `Cat Food Bowl` ItemSave block with a negative `position.y`, and either remove it or change `position.y` to a sensible above-floor value (e.g. `0.05`). **Always back up the `.tres` first.** A proper in-mod fix (overlap-aware clip correction that can distinguish "stuck under floor" from "shelf overhead") is on the to-do list.

## Credits

Built for the Road to Vostok modding ecosystem. In-game configuration via the [Mod Configuration Menu](https://modworkshop.net/mod/53713) by DoinkOink.

### 3D Models

- **"Cat bowl"** by Justyna.sliwinska — [source](https://skfb.ly/otWXJ) — licensed under [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).

See [NOTICES.txt](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/CatAutoFeed/NOTICES.txt) for the verbatim attributions.

## License

[MIT](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/CatAutoFeed/LICENSE) (mod code only — third-party 3D models retain their own CC BY 4.0 license; see NOTICES.txt).

## Source & Issues

Built in the [RoadToVostokMods workspace](https://github.com/dwoodruff83/RoadToVostokMods).
