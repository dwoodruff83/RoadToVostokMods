# ModLogger (single-file version)

`Logger.gd` in this mod doubles as a reusable logging framework for any Road to
Vostok mod. Copy the file, edit the identity block, autoload it — done.

## Features

- Four log levels: **Debug / Info / Warn / Error** (plus **Off**)
- Three output targets, all toggleable at runtime:
  - **Console** — Godot stdout → `%APPDATA%\Road to Vostok\logs\godot.log`
  - **File** — user-configurable path, defaults to
    `user://MCM/{mod_id}/{log_filename}`
  - **In-game overlay** — routes each log line through the game's native
    `Loader.Message` system, color-coded by level (gray/white/orange/red) and
    matching vanilla notifications
- MCM-friendly: single `apply_settings(level, file, overlay)` call from your
  config callback drives everything

## Reuse in another mod

1. **Copy** `Logger.gd` into your mod folder (any path works, e.g.
   `res://mods/MyMod/Logger.gd`).
2. **Edit the three identity vars** in `_init()`:

   ```gdscript
   func _init() -> void:
       mod_id = "MyMod"
       mod_display_name = "My Mod"
       log_filename = "my_mod.log"
   ```

3. **Autoload it** in your `mod.txt` — put it first so other autoloads can
   log from their `_ready`:

   ```
   [autoload]
   MyModLog="res://mods/MyMod/Logger.gd"
   ```

4. **Use it** from any script:

   ```gdscript
   var _log_node: Node

   func _ready():
       _log_node = get_node_or_null("/root/MyModLog")

   func _log(lvl: String, msg: String):
       if _log_node:
           _log_node.call(lvl, msg)
       else:
           print("[MyMod] [", lvl.to_upper(), "] ", msg)

   # Use like: _log("info", "Hello"), _log("warn", "Something odd")
   ```

5. **Drive from MCM** — add these three config entries to your `config.gd`:

   ```gdscript
   config.set_value("Dropdown", "log_level", {
       "name" = "Log Level",
       "default" = 1, "value" = 1,
       "options" = ["Debug", "Info", "Warn", "Error", "Off"],
       "category" = "Logging",
   })
   config.set_value("Bool", "log_to_file", {
       "name" = "Log to File",
       "default" = false, "value" = false,
       "category" = "Logging",
   })
   config.set_value("Bool", "log_to_overlay", {
       "name" = "Log to In-Game Overlay",
       "default" = false, "value" = false,
       "category" = "Logging",
   })
   ```

   Then in your `_apply(config)` callback:

   ```gdscript
   var log_level = int(config.get_value("Dropdown", "log_level", {"value": 1})["value"])
   var log_to_file = config.get_value("Bool", "log_to_file", {"value": false})["value"]
   var log_to_overlay = config.get_value("Bool", "log_to_overlay", {"value": false})["value"]

   var logger = get_node_or_null("/root/MyModLog")
   if logger == null:
       logger = get_tree().root.find_child("MyModLog", true, false)
   if logger:
       logger.apply_settings(log_level, log_to_file, log_to_overlay)
   ```

## Coexistence with other mods

- Each mod's logger gets its own file (different `mod_id` = different folder),
  so file output never collides.
- Overlay output goes through `Loader.Message`, which stacks in the game's
  notification area — multiple mods will interleave cleanly.
- If you prefer a dedicated overlay panel per mod (fallback path when
  `Loader` isn't available), the class has a `_append_overlay` helper that
  creates a `RichTextLabel` via a `CanvasLayer`. Override `overlay_position` in
  `_init` to avoid stacking with other mods using the same fallback.

## License

`Logger.gd` is released under the MIT license — embed it freely with or
without attribution.
