# RTV Hideout Lights

> Nine placeable light fixtures stocked by every trader (Generalist, Gunsmith, Doctor). Vanilla-quality lamps, lanterns, candles, fluorescents, and an exit sign. Toggle some on/off via Use; ceiling fixtures wire into your shelter's existing wall switch. State persists across shelter visits as of v1.2.0.

Vanilla Road to Vostok has dozens of light fixtures baked into the world (industrial fluorescents, cellar sconces, exit signs) but none are placeable furniture. This mod takes those existing assets and turns them into furniture you buy from any of the three traders and place via the standard decor mode.

Ships **zero new mesh or texture data**. Every model and material loads from the game install you already have. The .vmz weighs ~1.2 MB, mostly trader catalog icons.

---

## ⚠ Compatibility

- ❌ **[Oldman's Immersive Overhaul](https://modworkshop.net/mod/50811)** (v3.0.3 and earlier) — different Metro integration patterns don't currently compose; our fixtures silently fail to load. Pending a Metro v3 update on Oldman's side. Run one or the other, not both.
- ✅ **Coexists with other registry-using mods** (Cat Auto Feed, RTV Wallets, etc.). No `Database.gd` takeover — uses Metro's `[registry]` API.
- ✅ **Coexists with vanilla shelter lighting.** Wiring a mod fixture into the shelter switch only appends to the switch's `targets` array; vanilla lights keep working alongside.

---

## What's in the catalog

Every fixture is stocked by all three currently-revealed traders (Generalist, Gunsmith, Doctor) so v1 users see them no matter where they shop.

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

Shelters with a vanilla **Light_Switch** (Cabin, Bunker, Classroom) already control their built-in lights. Place any fixture marked "Shelter switch" above and the mod auto-subscribes it to the room's switch. Multi-switch shelters (the Cabin has one switch per room) get smart room-aware routing: the mod picks the switch whose existing static lights are nearest, so a fixture in the bedroom joins the bedroom's switch, not the kitchen's.

Shelters without a switch (Tent, Attic) leave wired fixtures permanently on. The Floor Lamp, PC, Candle, Lantern, and Exit Sign work in any shelter — they have their own toggle (Use action) or are always-on.

## Placement and state

Picking a fixture up to move it always turns it off for the placement preview, so the green hologram renders cleanly and the fixture lands in a known state. On commit, switch-controlled fixtures sync to the nearest room switch, manual fixtures start off (player turns them on with Use), and always-on fixtures (Exit Sign) light back up.

**State persistence (1.2.0+).** Every toggleable fixture remembers its on/off state between shelter visits. Light a Floor Lamp or Candle, leave the shelter, come back, it's still lit. Multiple fixtures in the same shelter each keep their own state independently. Re-placing a fixture defaults it to off (matches 1.1.0 placement behavior). State lives in a small sidecar config alongside your save (`user://rtvlights_state.cfg`); no vanilla save format changes.

## Configuration (MCM)

The mod has no settings of its own. The standard Logger category (level, file output, overlay output) is exposed via MCM if you want to tune it.

## Requirements

- **[Metro Mod Loader](https://modworkshop.net/mod/55623) v3.0.0 or later** — required. Uses Metro's `[registry]` API.
- **[Mod Configuration Menu (MCM)](https://modworkshop.net/mod/53713)** — optional. The mod runs with sensible defaults if MCM is absent; only required if you want to tune the logger.

## Uninstalling

Save files reference each fixture via `res://mods/RTVHideoutLights/...`. Removing the `.vmz` silently strips placed lights from saves on next load. **Pick everything up before uninstalling.**

## Credits

All meshes, textures, and materials are vanilla Road to Vostok assets, loaded from the game install at runtime. The mod ships zero asset data.

In-game configuration via [Mod Configuration Menu](https://modworkshop.net/mod/53713) by DoinkOink. Mod-loader infrastructure by Metro.

## License

[MIT](https://opensource.org/license/mit) for the mod code. Vanilla game assets remain the property of the Road to Vostok developers; this mod ships zero asset data.
