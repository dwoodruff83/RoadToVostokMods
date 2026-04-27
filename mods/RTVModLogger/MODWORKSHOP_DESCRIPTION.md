# RTV Mod Logger

> A drop-in logging library for Road to Vostok mods. One file, no dependencies.

A modder tool. Copy `Logger.gd` into your mod, edit three lines, autoload it — and you get filterable log levels, file output, in-game overlay routed through the vanilla `Loader.Message` system, and an MCM integration helper. Ships with a small in-game demo so you can see what each level looks like before integrating.

---

## ⚠ For mod developers, not players

This mod has **no gameplay effect**. If you installed another mod that uses RTV Mod Logger internally (e.g. CatAutoFeed, RTV Wallets), **you don't need to install this** — consumer mods bundle their own copy of `Logger.gd` directly into their `.vmz`.

This package exists as:
- A **reference implementation** for modders to copy `Logger.gd` from.
- A **live in-game demo** so you can see what each of the six log levels looks like before integrating.
- The home of `LOGGER.md`, the full API reference (bundled in the `.vmz`).

---

## What you get

### Six log calls

| Call | Color | Use |
|---|---|---|
| `_log.debug(msg)` | gray | Per-tick or per-frame diagnostics — filtered out at default level |
| `_log.info(msg)` | white | Notable state changes |
| `_log.success(msg)` | green | Positive outcomes ("Cat fed", "Sale completed") |
| `_log.warn(msg)` | orange | Recoverable anomalies |
| `_log.error(msg)` | red | Serious failures |
| `_log.notify(msg, color)` | any | Always shows in-game, regardless of filter — for messages players must see |

### Three output targets, each toggleable in MCM

- **Console** — standard `print()` output, prefixed with `[<mod_id>]`.
- **File** — `user://MCM/<mod_id>/<filename>.log`, rotated between sessions.
- **In-game overlay** — routed through the vanilla `Loader.Message` system, so styling matches the rest of the game.

### MCM integration in one call

```gdscript
logger.attach_to_mcm_config(config, "Logging", 100)
```

That's it. Adds a "Logging" category to your mod's existing MCM page with Level / File / Overlay controls. Each consumer mod gets its own page — they don't collide.

### Schema-preserving migration

Add a new MCM setting in v1.1 of your mod, your users keep their v1.0 values. Pattern documented in `LOGGER.md`.

### Per-mod isolation

Each mod that uses this library has its own identity, autoload name, log file, and MCM page. Two consumer mods both depending on the logger? Fine — no conflicts.

---

## Integrating it into your mod

1. Copy `Logger.gd` from this `.vmz` into your mod folder (`mods/MyMod/Logger.gd`).
2. Edit the three identity vars in `_init()`:

   ```gdscript
   func _init() -> void:
       mod_id = "MyMod"
       mod_display_name = "My Mod"
       log_filename = "my_mod.log"
   ```

3. Autoload it *first* in your `mod.txt` (so other autoloads can grab a reference at `_ready` time):

   ```ini
   [autoload]
   MyModLog="res://mods/MyMod/Logger.gd"
   MyModConfig="res://mods/MyMod/config.gd"
   MyMod="res://mods/MyMod/Main.gd"
   ```

4. Use it from anywhere in your mod:

   ```gdscript
   var _log = get_node_or_null("/root/MyModLog")
   if _log:
       _log.success("Mod activated")
       _log.notify("Boss spawned!", Color.RED)
   ```

Full reference (MCM helper details, schema migration pattern, troubleshooting): see `LOGGER.md` bundled in the `.vmz`.

---

## Trying the demo

1. Drop `RTVModLogger.vmz` into the game's `mods/` folder.
2. Launch the game. A cyan *"RTVModLogger ready — press your Test Hotkey"* message confirms it loaded.
3. Open MCM → RTV Mod Logger page.
4. Toggle **Log to In-Game Overlay** on (default off so the demo is silent unless invited).
5. Press **F12** in-game. The six log levels fire in sequence as labeled notifications, so you can see the visual style of each before integrating.

The demo's MCM also exposes the Logger's standard Logging category (Level / File / Overlay), so you can experiment with the toggles before wiring them into your own mod.

---

## Requirements

- **A compatible mod loader** — [Metro Mod Loader](https://modworkshop.net/mod/55623) is the most popular for Road to Vostok. Any `.vmz`-aware loader should work.

## Optional

- **[Mod Configuration Menu (MCM)](https://modworkshop.net/mod/53713)** — needed to change the demo's Test Hotkey or the Logger's output toggles in-game. The mod runs without it (sensible defaults).

## Compatibility

- ✅ **Coexists with any number of consumer mods** using this library — each carries its own identity.
- ✅ **No `take_over_path` overrides.** Doesn't touch any vanilla scripts.
- ⚠ **MCM is optional**, but without it the in-game toggles can't be changed.

## Credits

Built for the Road to Vostok modding ecosystem. In-game configuration via [Mod Configuration Menu](https://modworkshop.net/mod/53713) by DoinkOink.

## License

[MIT](https://opensource.org/license/mit) — embed `Logger.gd` in your own mods freely, with or without attribution.
