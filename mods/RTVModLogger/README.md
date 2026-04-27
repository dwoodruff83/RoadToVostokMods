# RTV Mod Logger

> A drop-in logging library for Road to Vostok mods. One file, no dependencies.

> **For mod developers, not players.** This mod has no gameplay effect. If you
> installed another mod that uses RTV Mod Logger internally (e.g. CatAutoFeed,
> RTV Wallets), **you don't need to install this** — consumer mods bundle
> their own copy of `Logger.gd` directly into their `.vmz`. This package
> exists as a reference + a live demo so modders can see what each log level
> looks like in-game before integrating.

A modder tool. Copy `Logger.gd` into your mod, edit three lines, autoload it — and you get filterable log levels, file output, in-game overlay routed through the vanilla `Loader.Message` system, and an MCM integration helper. Ships with a demo so you can see what each level looks like in-game before integrating.

## Installation (for evaluating the demo)

1. Drop `RTVModLogger.vmz` into the game's `mods/` folder:
   `...\steamapps\common\Road to Vostok\mods\`
2. Ensure a compatible mod loader is installed (e.g. [Metro Mod Loader](https://modworkshop.net/mod/55623), the most popular for Road to Vostok).
3. **Recommended:** also install Mod Configuration Menu (MCM) — needed to change the test hotkey or log settings in-game.
4. Launch the game. A cyan *"RTVModLogger ready — press your Test Hotkey"* message confirms it loaded.

## Features

- **Six log calls** — `debug` (gray), `info` (white), `success` (green), `warn` (orange), `error` (red), and `notify(msg, color)` which always shows regardless of filters.
- **Three output targets**, each toggleable in MCM — Console, File (`user://MCM/<mod_id>/<filename>.log`), and in-game overlay (via `Loader.Message`).
- **MCM integration helper** — one call adds Level / File / Overlay controls to your mod's existing MCM page.
- **Schema-preserving migration** pattern (see [LOGGER.md](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/RTVModLogger/LOGGER.md)) — adding new settings between mod versions doesn't lose user values.
- **Coexistence** — each mod that uses the library has its own identity, log file, and MCM page. They don't conflict.

## Configuration (MCM)

| Setting | Default | Description |
|---|---|---|
| Welcome on Game Start | Off | Show the cyan "ready" notification when the mod loads. Default off — turn on if you're actively using the demo and want a hotkey reminder. |
| Test Hotkey | F12 | Press in-game to fire the configured test action. |
| Test Action | Test All | What the hotkey fires: `Test All` runs every level + a notify in sequence; or pick one specific level. |

Plus the standard Logger category (level, file output, overlay output). See [LOGGER.md](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/RTVModLogger/LOGGER.md) for details.

## For modders: using `Logger.gd` in your mod

1. Copy [`Logger.gd`](Logger.gd) into your mod folder.
2. Edit the three identity vars in `_init()`:

   ```gdscript
   func _init() -> void:
       mod_id = "MyMod"
       mod_display_name = "My Mod"
       log_filename = "my_mod.log"
   ```

3. Autoload it *first* in your `mod.txt`:

   ```ini
   [autoload]
   MyModLog="res://mods/MyMod/Logger.gd"
   MyModConfig="res://mods/MyMod/config.gd"
   MyMod="res://mods/MyMod/Main.gd"
   ```

4. Use it from anywhere:

   ```gdscript
   var _log = get_node("/root/MyModLog")
   _log.success("Mod activated")
   _log.notify("Boss spawned!", Color.RED)
   ```

Full reference (MCM integration pattern, schema migration, troubleshooting): [LOGGER.md](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/RTVModLogger/LOGGER.md).

## Compatibility

- **MCM is optional.** The demo runs without it but the hotkey and settings can't be changed in-game.
- **Coexists with other mods using this library** — each carries its own identity, autoload name, log file, and MCM Logging category.

## Credits

Built for the Road to Vostok modding ecosystem. In-game configuration via the [Mod Configuration Menu](https://modworkshop.net/mod/53713) by DoinkOink.

## License

[MIT](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/RTVModLogger/LICENSE) — embed `Logger.gd` freely, with or without attribution.

## Source & Issues

Built in the [RoadToVostokMods workspace](https://github.com/dwoodruff83/RoadToVostokMods).
