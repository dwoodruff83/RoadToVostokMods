# Changelog

All notable changes to RTVModItemRegistry are documented here. Dates are
YYYY-MM-DD.

## 1.0.0 — 2026-04-25

API frozen for public release. Reject-by-default for collisions and vanilla
shadowing; added deferred-register queue; tightened typing.

- **API change:** `register(file_name, scene)` is now
  `register(file_name, scene, overwrite: bool = false, force: bool = false) -> bool`.
  Defaults are conservative — caller must opt in to override safety checks.
  Existing single-arg-pair calls continue to work because the new params have
  defaults.
- **Reject-by-default for collisions.** If two mods try to register the same
  `file_name`, the second call returns `false` and logs a warn. Pass
  `overwrite=true` to replace.
- **Reject-by-default for vanilla const shadowing.** If a mod tries to
  register a name that already exists as a `const` on the vanilla
  `Database.gd` (e.g. `Cat`, `Cat_Food`, `Makarov`), the call returns
  `false` and logs a warn. Pass `force=true` to shadow anyway. Vanilla
  const names are snapshotted from `get_base_script().get_script_constant_map()`
  on first `register()` call.
- **Deferred-register queue.** Consumer mods that load before the registry
  (priority < -50) can now call `register()` from their own `_ready` —
  calls are queued and flushed at the end of the registry's `_ready`. The
  call returns `true` to signal the registration will be honored.
- **`registered_items()` now returns `Array[String]`** (was untyped
  `Array`), matching what REGISTRY.md has always claimed.
- **Logger plumbing:** DatabaseInject now routes its rejection warnings
  through the registry's logger (`set_log_callback`), so they reach
  MCM-configured file/overlay outputs instead of just the engine console.
- **RTV Wallets integration fixed:** the consumer mod now checks each
  `register()` return value and falls back to legacy injection if the
  registry rejected any item.

## 0.1.0 — 2026-04-25

Initial release.

- Single autoload `/root/ModItemRegistry` exposing `register(file_name, scene)`,
  `is_registered(file_name)`, and `registered_items()` to consumer mods.
- One-time `take_over_path("res://Scripts/Database.gd")` plus `set_script`
  on the live `/root/Database` autoload — replaces the per-consumer-mod
  injection pattern that was previously last-loader-wins.
- `DatabaseInject.gd` overrides `_get(property)` so registered items resolve
  through the standard `Database.get(name)` lookup callers already use.
- `priority=-50` in mod.txt, sitting between MCM (`-100`) and consumer mods
  (default `0`).
- Standard Logger integration (level / file / overlay), with a "Logging"
  category in MCM.
- See [REGISTRY.md](REGISTRY.md) for the integration guide.
