# Punisher Guarantee

> Punisher boss every Area 05 entry, day one, full Boss mode. Plus a hotkey to spawn one on demand.

The vanilla Punisher event is gated three ways: a 10% possibility roll, a day-5 minimum, and a 50/50 coin flip on whether the police van that arrives is in Boss mode. This mod lifts all three gates and adds a one-shot **F10 hotkey** to spawn a Punisher next to the player. For when you want the encounter without the dice-rolling.

## Installation

1. Drop `PunisherGuarantee.vmz` into the game's `mods/` folder:
   `...\steamapps\common\Road to Vostok\mods\`
2. Ensure a compatible mod loader is installed (e.g. [Metro Mod Loader](https://modworkshop.net/mod/55623), the most popular for Road to Vostok).
3. **Recommended:** also install Mod Configuration Menu (MCM) — the mod runs without it, but settings can only be tweaked in-game when MCM is present.
4. Launch the game. Effects apply on the next scene load.

## Features

- **Possibility 10 → 100** — every Area 05 entry triggers the event.
- **Day gate removed** — the Punisher can show up from day 1.
- **Van always in Boss mode** — no more "lol, just a patrol" rolls.
- **Hotkey spawn** — press F10 (configurable) to spawn a Punisher next to the player, bypassing the van cutscene. Useful for loadout testing.

## Configuration (MCM)

| Setting | Default | Description |
|---|---|---|
| Enable Mod | On | Master toggle. Reload after disabling. |
| Guarantee Event Fires | On | Bumps the Punisher event's possibility from 10 to 100. |
| Bypass Day 5 Gate | On | Removes the day-5 minimum requirement. |
| Force Boss Mode on Van | On | Every Police van arrives in Boss mode. |
| Enable Spawn Hotkey | On | Press the configured key to spawn a Punisher near you. |
| Spawn Hotkey | F10 | Key to press for the on-demand spawn. |

Plus the standard Logger category (level, file output, overlay output). See [the RTV Mod Logger reference](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/RTVModLogger/LOGGER.md) for details.

## Compatibility

- **Stacks cleanly with mods that don't override `Scripts/Police.gd`.**
- **Conflicts with mods that also override `Scripts/Police.gd`** — only one can win; load order decides.
- **MCM is optional.** Defaults are conservative: every effect on, hotkey on, F10 as the spawn key.

## Credits

Built for the Road to Vostok modding ecosystem. In-game configuration via the [Mod Configuration Menu](https://modworkshop.net/mod/53713) by DoinkOink.

## License

[MIT](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/PunisherGuarantee/LICENSE)

## Source & Issues

Built in the [RoadToVostokMods workspace](https://github.com/dwoodruff83/RoadToVostokMods).
