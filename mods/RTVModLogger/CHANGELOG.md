# Changelog

All notable changes to the RTV Mod Logger are documented here. Dates are
YYYY-MM-DD.

## 0.1.0 — 2026-04-25

Initial release as a standalone mod.

- **`Logger.gd` library** with five filterable log calls (`debug`, `info`,
  `success`, `warn`, `error`) and one always-show user notification
  (`notify`). Routes through the vanilla `Loader.Message` system so output
  matches in-game notification style.
- **`success()` method** added — same severity as `info()` but rendered in
  green to match the game's "Cat Fed" / "Boss Killed" / "Task Completed"
  style. Fills the gap that previously required modders to call
  `Loader.Message` directly.
- **`notify(msg, color)` method** added — bypasses the log-level filter
  and overlay toggle. Use for messages the player must see (boss spawned,
  save loaded, etc.). Accepts any Godot `Color`; defaults to white.
- **Demo entry point** (`Main.gd`) listens for a user-configurable hotkey
  and fires the test sequence so the visual style of each level is obvious
  at a glance. "Test All" staggers six calls (DEBUG → NOTIFY) with 350 ms
  delays so they stack as distinct entries.
- **MCM integration**:
  - Demo settings: Welcome on Start (Bool), Test Hotkey (Keycode, default F12),
    Test Action (Dropdown).
  - Standard Logging category contributed by the logger itself: Log Level
    (Dropdown: Debug / Info / Warn / Error / Off), Log to File (Bool), Log
    to Overlay (Bool).
- **File output** to `user://MCM/RTVModLogger/rtv_mod_logger.log` when
  enabled. Auto-creates the directory.
- **Schema-preserving migration** in `config.gd` so future setting changes
  preserve user values across mod updates.
- **`LOGGER.md` reference docs** moved into the mod (formerly in `shared/`)
  documenting the API, MCM integration pattern, level semantics, schema
  migration, and troubleshooting.
