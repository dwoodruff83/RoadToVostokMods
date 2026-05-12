# RTV Hideout Lights

> Nine placeable light fixtures stocked by every trader (Generalist, Gunsmith, Doctor). Vanilla-quality lamps, lanterns, candles, fluorescents, and an exit sign. Toggle some on/off via Use; ceiling fixtures wire into your shelter's existing wall switch.

Vanilla Road to Vostok has dozens of light fixtures baked into the world (industrial fluorescents, cellar sconces, exit signs) but none are placeable furniture. This mod takes those existing assets and turns them into furniture you buy from any of the three traders and place via the standard decor mode.

Ships **zero new mesh or texture data**. Every model and material loads from the game install you already have. The .vmz weighs ~1.2 MB, mostly trader catalog icons.

## Installation

1. Drop `RTVHideoutLights.vmz` into the game's `mods/` folder.
2. **Required:** [Metro Mod Loader](https://modworkshop.net/mod/55623) v3.0.0 or later. Uses Metro's `[registry]` API.
3. **Optional:** [Mod Configuration Menu (MCM)](https://modworkshop.net/mod/53713). Only used to tune the mod's logger.
4. Launch the game and head to any trader.

## What's in the catalog

Every fixture is stocked by all three currently-revealed traders (Generalist, Gunsmith, Doctor) so v1 users see them no matter where they shop. We'll narrow the per-fixture trader assignments in a future release based on feedback.

| Fixture | Mount | Toggle | Notes |
|---|---|---|---|
| **Candle** | Floor (2x2) | Use to light/extinguish | Tiny warm flame, ~1m falloff. Cheap. |
| **Kerosene Lantern** | Floor (2x3) | Use to light/extinguish | Brighter than the candle, ~4m range. |
| **Floor Lamp** | Floor (3x6) | Use to toggle | Warm 50° spotlight inside the shade. Tall (needs ~2m clearance). |
| **Vintage Desktop PC** | Floor (4x4) | Use to toggle | Cyan glow + animated lit-screen UI when on; dark monitor when off. |
| **Exit Sign** | Wall (3x2) | Always on | Green-glow sconce. Reads "EXIT" at a glance. |
| **Cellar Wall Light** | Wall (2x3) | Shelter switch | Warm bare bulb behind a metal cage. |
| **Industrial Fluorescent** | Ceiling (2x2) | Shelter switch | Square ceiling panel, neutral white. |
| **Bright Fluorescent** | Ceiling (5x2) | Shelter switch | Long fluorescent tube, high energy. Cabin/garage feel. |
| **Soft Fluorescent** | Ceiling (5x2) | Shelter switch | Same shape as Bright, lower energy, no fog beam. Bedroom feel. |

## Switch integration

Shelters with a vanilla **Light_Switch** (Cabin, Bunker, Classroom) already control their built-in lights. Place any fixture marked "Shelter switch" above and the mod auto-subscribes it to the room's switch.

**Multi-switch shelters** (the Cabin has one switch per room): the mod picks the switch whose existing static lights are nearest to your placed fixture. That's effectively "which room am I in", without needing line-of-sight or pathfinding tricks. Re-placing the fixture in a different room drops the old subscription and joins the new one.

The nearest-light heuristic can mis-assign on edge cases, like a fixture placed in a doorway between two rooms or next to a switch that's mounted on a shared wall. If the fixture wires to the wrong switch, just pick it up and re-place a step further into the room you want.

Shelters without a switch (Tent, Attic) leave wired fixtures permanently on; there's nothing to flip them off with. The Floor Lamp, PC, Candle, Lantern, and Exit Sign are independent of the switch in any shelter.

## Placement and state

Picking a fixture up to move it always turns it off for the duration of the placement preview, so the green hologram renders cleanly and the fixture lands in a known state. On commit:

- **Switch-controlled fixtures** sync to the nearest room switch's current on/off state.
- **Manual fixtures** (Floor Lamp, PC, Candle, Lantern) start off; player turns them on with Use.
- **Always-on fixtures** (Exit Sign) light back up.

When a fixture is off, both the Light3D source and the emissive lampshade material go dark (same pattern as the vanilla cabin pendants).

**State persistence (1.2.0+):** Every toggleable fixture remembers its on/off state between shelter visits. Light a Floor Lamp or Candle, leave the shelter, come back, it's still lit. Multiple fixtures in the same shelter each keep their own state. State is per-shelter and per-position, stored alongside your save in `user://rtvlights_state.cfg`. Picking up and re-placing any fixture defaults it to off (matches 1.1.0 placement behavior). Exit Sign is intentionally excluded — it's an always-on decorative fixture, like a real emergency exit sign that stays lit even in a power outage.

## Configuration (MCM)

The mod has no settings of its own. The standard Logger category (level, file output, overlay output) is exposed via MCM. See [the RTV Mod Logger reference](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/RTVModLogger/LOGGER.md).

## Compatibility

- **Metro Mod Loader v3.0.0+ required.** Fixtures register via Metro's `lib.register(SCENES/ITEMS/LOOT/TRADER_POOLS, ...)`. No `take_over_path` collisions with other registry-using mods.
- **Known incompatibility with mods that replace the live `Database` autoload script** (a pre-`[registry]` pattern for adding items). The pattern wipes Metro's `[registry]` injection, so this mod's fixtures fail to load at traders, in inventories, or on placement. Known examples: [Oldman's Immersive Overhaul](https://modworkshop.net/mod/50811) (v3.0.3 and earlier), [Swift Island](https://modworkshop.net/mod/56192) (v1.1.0 and earlier). Each mod is fine on its own; the script-replacement pattern just doesn't compose with `[registry]`-based mods. Pending Metro v3 migrations on those. Workaround until then: pick one or the other.
- **MCM is optional.**
- **Coexists with vanilla shelter lighting.** Wiring a mod fixture into the shelter switch only appends to the switch's `targets` array; vanilla lights keep working alongside.
- **Uninstalling drops your placed lights.** Saves reference each fixture via `res://mods/RTVHideoutLights/...`. Removing the .vmz silently strips them on next load. Pick everything up before uninstalling.

## Credits

Built for the Road to Vostok modding ecosystem. MCM integration via the [Mod Configuration Menu](https://modworkshop.net/mod/53713) by DoinkOink.

All meshes, textures, and materials are vanilla Road to Vostok assets, loaded from the game install at runtime. See [NOTICES.txt](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/RTVHideoutLights/NOTICES.txt).

## License

[MIT](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/RTVHideoutLights/LICENSE) (mod code only). Vanilla game assets remain the property of the Road to Vostok developers; this mod ships zero asset data.

## Source & Issues

Built in the [RoadToVostokMods workspace](https://github.com/dwoodruff83/RoadToVostokMods).
