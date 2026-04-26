# ModLogger — single-file logging library for Road to Vostok mods

> Distributed as part of [RTVModLogger](README.md) (the demo mod). Copy
> `Logger.gd` into your own mod to use it standalone.

`Logger.gd` is a drop-in reusable logging framework. Copy the file into your
mod, edit three lines, autoload it, and you get:

- Four log levels: **Debug / Info / Warn / Error** (plus **Off**), each
  filterable via the user's MCM settings
- A **`success()`** method — same severity as INFO but rendered in green to
  match vanilla "Cat Fed" / "Boss Killed" notifications
- A **`notify()`** method — always-show user-facing messages that bypass the
  log-level filter and overlay toggle. Use for events the player must see.
- Three output targets, all toggleable at runtime:
  - **Console** — Godot stdout → `%APPDATA%\Road to Vostok\logs\godot.log`
  - **File** — `user://MCM/{mod_id}/{log_filename}` by default
  - **In-game overlay** — routed through RTV's `Loader.Message` so lines match
    vanilla notifications, color-coded
- An **MCM integration helper** — one call adds a "Logging" category with
  Level / File / Overlay controls to *your mod's* MCM page

## Quick start

1. **Copy** `Logger.gd` into your mod folder.
2. **Edit** the three identity vars in `_init()`:

   ```gdscript
   func _init() -> void:
       mod_id = "MyMod"
       mod_display_name = "My Mod"
       log_filename = "my_mod.log"
   ```

3. **Autoload** it *first* in `mod.txt` so other autoloads can log during
   `_ready`:

   ```
   [autoload]
   MyModLog="res://mods/MyMod/Logger.gd"
   MyModConfig="res://mods/MyMod/config.gd"
   MyMod="res://mods/MyMod/Main.gd"
   ```

4. **Use it** from any script:

   ```gdscript
   var _log_node: Node

   func _ready():
       _log("info", "Mod loaded")

   func _log(lvl: String, msg: String):
       if _log_node == null or !is_instance_valid(_log_node):
           _log_node = get_node_or_null("/root/MyModLog")
           if _log_node == null:
               _log_node = get_tree().root.find_child("MyModLog", true, false)
       if _log_node:
           _log_node.call(lvl, msg)
       else:
           print("[MyMod] [", lvl.to_upper(), "] ", msg)
   ```

## The five log calls + `notify()`

| Method | Color | Severity | Filtered by level? | Filtered by overlay toggle? |
|--------|-------|----------|---|---|
| `debug(msg)` | gray | DEBUG | yes | yes |
| `info(msg)` | white | INFO | yes | yes |
| `success(msg)` | green | INFO | yes | yes |
| `warn(msg)` | orange | WARN | yes | yes |
| `error(msg)` | red | ERROR | yes | yes |
| `notify(msg, color)` | configurable | n/a | **no** | **no** |

`debug` / `info` / `success` / `warn` / `error` are **developer logs** — they
respect the user's MCM-configured threshold and overlay toggle. Use them for
anything you'd write to a log file.

`notify(msg, color)` is a **user-facing notification** — it always shows
regardless of logger settings. Use it for messages the player must see (boss
spawned, save loaded, mod activated). Defaults to white; pass any `Color`.

```gdscript
_log.success("Mod activated")               # green, like "Cat Fed"
_log.notify("Boss spawned!", Color.RED)     # always shows, even if logger off
```

## Log levels and when to use each

Higher-severity messages are always visible when a lower level is selected.
Pick the level that matches the *intent*, not the frequency.

### `_log("debug", ...)` — high-frequency diagnostics

Use for tick-level traces and fine-grained state changes. Noisy by default.
Users enable Debug only when investigating a problem.

```gdscript
_log("debug", "Tick: cat=%d/%d map=%s" % [int(cat), int(threshold), map_name])
_log("debug", "Scanning %s for items" % shelter_name)
_log("debug", "Scene not ready (no /root/Map), skip")
_log("debug", "Tier '%s' disabled in config, skipping" % tier.id)
```

### `_log("info", ...)` — notable state changes

Use for one-shot events a user or developer would want a timeline of. Fires
once per event, not on every tick.

```gdscript
_log("info", "Wallet mod loaded")
_log("info", "Registered %d wallet tiers" % count)
_log("info", "Cat shelter detected: %s" % shelter_name)
_log("info", "Player bought M4A1 for 2500 coins")
_log("info", "Fed cat: Cat Food (Attic / Freezer)")
```

### `_log("warn", ...)` — anomalies the user might want to know about

Use when something's unexpected but recoverable. A warning means "this isn't
how it's supposed to go, but I'm handling it."

```gdscript
_log("warn", "No food available in %s" % shelter_name)
_log("warn", "Wallet shelter save missing: %s" % path)
_log("warn", "deposit called with negative amount %d" % amount)
_log("warn", "Hotkey pressed but no AISpawner in this scene")
_log("warn", "Save file locked for writing, retry in 1s")
```

### `_log("error", ...)` — serious failures, likely bugs

Use when an expected operation fails and the user's experience is affected.
Errors usually point to a bug or bad external state.

```gdscript
_log("error", "Failed to load shelter save: %s (code %d)" % [path, err])
_log("error", "Could not open Character.tres for writing")
_log("error", "Override script missing at %s" % path)
_log("error", "Could not load %s" % EVENTS_PATH)
```

### `_log.success(...)` — positive outcomes, vanilla style

Use when something the user cares about *worked*. Green to match the game's
own "Cat Fed", "Boss Killed", "Task Completed" notifications. Filtered by the
INFO threshold (so it shows whenever info-level chatter is on).

```gdscript
_log.success("Mod activated")
_log.success("Settings saved")
_log.success("Save migrated to v2")
```

### `_log.notify(msg, color)` — always-show user notifications

Bypasses both the level filter and the overlay toggle. Use sparingly, for
things the player needs to see no matter their logger settings. The color
argument is a Godot `Color`; defaults to white.

```gdscript
_log.notify("Boss spawned near base!", Color.RED)
_log.notify("Mod ready — press F12 to test", Color.CYAN)
_log.notify("Save loaded successfully", Color.GREEN)
```

## MCM integration

Skip writing your own three logger settings — let the logger contribute them
under a "Logging" category on your mod's existing MCM page.

### In your `config.gd` `_ready()`:

After defining your mod's own settings and **before** calling
`RegisterConfiguration`:

```gdscript
var logger = _resolve_logger()
if logger:
    logger.attach_to_mcm_config(config, "Logging", 100)
```

Arguments:

| Param | Purpose | Default |
|---|---|---|
| `config` | Your `ConfigFile` being built | required |
| `category` | MCM category name | `"Logging"` |
| `base_menu_pos` | Starting `menu_pos` for the 3 entries | `10` |

Use a high `base_menu_pos` (e.g. 100) if you want the Logging section to
appear *below* your own settings.

### In your `config.gd` `_apply(config)`:

After reading your own settings:

```gdscript
var logger = _resolve_logger()
if logger:
    logger.apply_from_config(config)
```

### Helper:

```gdscript
func _resolve_logger():
    var n = get_node_or_null("/root/MyModLog")
    if n == null:
        n = get_tree().root.find_child("MyModLog", true, false)
    return n
```

## Category ordering — set `menu_pos` for ALL your categories

MCM sorts categories alphabetically **unless each one has an explicit `menu_pos`**.
If you only set `menu_pos` for some categories (e.g. only Logging), MCM groups
the ones that have a `menu_pos` separately from the ones that don't, and the
page ends up looking wrong.

The logger automatically sets `Category "Logging" menu_pos = 999` so Logging
sorts to the bottom. But for that to work reliably, **your own categories need
explicit `menu_pos` values too**. Add this at the top of your `_ready()` right
after creating the `ConfigFile`:

```gdscript
var config := ConfigFile.new()

# Order the mod's own categories
config.set_value("Category", "General", { "menu_pos": 1 })
config.set_value("Category", "Tiers",   { "menu_pos": 2 })
# ... then your setting definitions and logger.attach_to_mcm_config (Logging = 999)
```

Any categories you forget to position will display alphabetically **before**
the numbered ones — so always number all of them.

To move Logging somewhere other than the bottom, pass `category_menu_pos`:

```gdscript
logger.attach_to_mcm_config(config, "Logging", 10, 5)  # Logging appears at pos 5
```

## Example: what it looks like in-game

With Log Level = Debug, File = On, Overlay = On:

- **Console** (godot.log):
  ```
  [MyMod] [15:50:59] [INFO] Mod loaded
  [MyMod] [15:51:04] [DEBUG] Tick: state=idle
  [MyMod] [15:52:10] [WARN] Unexpected null slot
  ```
- **File** (`user://MCM/MyMod/my_mod.log`): same content, persisted
- **Overlay** (game's notification area): each line fades in/out — gray for
  DEBUG, white for INFO, **green for SUCCESS**, orange for WARN, red for
  ERROR. `notify()` calls always show in whatever color you pass.

## Keeping copies in sync across mods

Each mod carries its own `Logger.gd` with identity baked in. When you fix a
bug in the canonical `shared/Logger.gd`, propagate it with:

```
python tools/sync_logger.py          # sync every mod in mods/*
python tools/sync_logger.py MyMod    # sync one mod only
python tools/sync_logger.py --check  # dry run — report without writing
```

The sync script:

1. Reads `shared/Logger.gd` as the template
2. For each mod folder that contains a `Logger.gd`, extracts its identity
   (`mod_id`, `mod_display_name`, `log_filename`) from the existing `_init()`
3. Rewrites the file with the canonical content + preserved identity

Mods that don't use the logger (no `Logger.gd` file) are skipped silently.

## Coexistence with other mods

- Each mod's logger writes to its own log file
  (`user://MCM/{mod_id}/{filename}`), so file output never collides.
- Overlay output goes through `Loader.Message`, which stacks in the game's
  notification area. Multiple mods' overlay messages interleave cleanly.
- Each mod gets its own Logging category on its own MCM page — users can
  tune verbosity per mod.

## Handling schema changes (new settings added, renamed, removed)

When you add or remove an MCM setting in a published mod, existing users have
an older `config.ini` on disk. MCM's built-in `CheckConfigurationHasUpdated`
does NOT reliably inject new keys into an existing saved file — the user
launches the updated mod and their new settings are **invisible** (falling
through to defaults) because `config.load()` overwrites the in-memory schema
with the stale disk version.

**Fix: a silent merge that preserves user values while migrating the schema.**
Drop this helper into your `config.gd` and call it *once*, after you've
built your in-memory schema (including `logger.attach_to_mcm_config`) and
before `_apply` and `RegisterConfiguration`.

### The merge helper

```gdscript
# Silent schema migration. Adds new keys from our in-memory schema, drops
# keys no longer in the schema, and preserves each setting's user-edited
# "value" from disk. Writes the merged result back to disk.
func _merge_schema(fresh: ConfigFile, path: String) -> void:
    var dir := path.get_base_dir()
    if !DirAccess.dir_exists_absolute(dir):
        DirAccess.make_dir_recursive_absolute(dir)

    if !FileAccess.file_exists(path):
        fresh.save(path)
        return

    var disk := ConfigFile.new()
    if disk.load(path) != OK:
        fresh.save(path)
        return

    for section in fresh.get_sections():
        for key in fresh.get_section_keys(section):
            if !disk.has_section_key(section, key):
                continue
            var schema_entry = fresh.get_value(section, key)
            var disk_entry = disk.get_value(section, key)
            if schema_entry is Dictionary and disk_entry is Dictionary and disk_entry.has("value"):
                schema_entry["value"] = disk_entry["value"]
                fresh.set_value(section, key, schema_entry)
            elif !(schema_entry is Dictionary):
                fresh.set_value(section, key, disk_entry)

    fresh.save(path)
```

### The updated `_ready` pattern

```gdscript
var config := ConfigFile.new()
# ... your mod's set_value calls ...

var logger = _resolve_logger()
if logger:
    logger.attach_to_mcm_config(config, "Logging", 10)

_merge_schema(config, FILE_PATH + "/config.ini")     # ← one line, silent migration

if _mcm_helpers == null:
    _apply(config)
    return

_mcm_helpers.CheckConfigurationHasUpdated(MOD_ID, config, FILE_PATH + "/config.ini")
_apply(config)

_mcm_helpers.RegisterConfiguration(MOD_ID, MOD_NAME, FILE_PATH,
    "Mod description.", { "config.ini" = _apply })
```

### What this guarantees

| Scenario | Behavior |
|---|---|
| First install (no config.ini) | Fresh schema written to disk with defaults |
| No schema changes, user has custom values | Values preserved, nothing on disk changes |
| New setting added to schema | New key appears on disk with default value; existing user values untouched |
| Setting removed from schema | Old key silently dropped from disk |
| Setting renamed | Old key dropped (user loses that customization); new key appears with default |
| Disk file corrupted or unreadable | Fresh schema written, replacing bad file |

### What it does NOT do

- **Rename-aware migration.** If you rename `feed_threshold` → `auto_feed_threshold`,
  the old value is lost. If that matters to your users, add an explicit migration
  block before `_merge_schema` that reads the old key and writes it to the new one.
- **Type changes.** If you change a setting from `Bool` to `Dropdown`, the old
  value may not make sense in the new schema. Handle via an explicit migration.

### When to add an explicit migration

```gdscript
# Before _merge_schema, handle renames you care about:
if FileAccess.file_exists(FILE_PATH + "/config.ini"):
    var disk := ConfigFile.new()
    if disk.load(FILE_PATH + "/config.ini") == OK:
        if disk.has_section_key("Float", "feed_threshold"):
            var old = disk.get_value("Float", "feed_threshold")
            if old is Dictionary and old.has("value"):
                var schema_entry = config.get_value("Float", "auto_feed_threshold")
                schema_entry["value"] = old["value"]
                config.set_value("Float", "auto_feed_threshold", schema_entry)
```

## Troubleshooting

**Nothing appears in the overlay even with Overlay = On:**
- Overlay messages expire after ~12 seconds. If your mod isn't actively
  logging, the overlay will be empty. Enable Debug to get periodic ticks.

**Log level changes via MCM don't seem to take effect:**
- Make sure your `_apply(config)` calls `logger.apply_from_config(config)`
  at the end.
- Confirm your `config.gd` does a fresh disk reload in `_apply` (MCM
  sometimes passes a stale in-memory ConfigFile):
  ```gdscript
  var fresh := ConfigFile.new()
  if fresh.load(FILE_PATH + "/config.ini") == OK:
      config = fresh
  ```

**The logger autoload isn't found at `/root/MyModLog`:**
- Some loaders place autoloads elsewhere in the tree. Use the
  dual lookup shown in the Quick Start example:
  ```gdscript
  _log_node = get_node_or_null("/root/MyModLog")
  if _log_node == null:
      _log_node = get_tree().root.find_child("MyModLog", true, false)
  ```

## License

`Logger.gd` is released under the MIT license — embed it freely with or
without attribution.
