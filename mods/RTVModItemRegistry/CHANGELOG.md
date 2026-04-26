# Changelog

All notable changes to RTVModItemRegistry are documented here. Dates are
YYYY-MM-DD.

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
