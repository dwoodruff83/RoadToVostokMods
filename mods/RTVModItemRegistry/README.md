# RTV Mod Item Registry

> Lets multiple mods add new items to the vanilla `Database` autoload without
> clobbering each other.

A coordination shim for Road to Vostok mods that introduce new items (custom
loot, traders, placeables, etc.). Vanilla items are registered as `const`
entries on `res://Scripts/Database.gd` and resolved via `Database.get(name)`.
Mods that add new items each independently call `take_over_path` + `set_script`
on Database — and the last loader wins, breaking every mod that loaded before
it.

This mod runs *before* consumers (`priority=-50`), takes over the Database
script *once*, and exposes a `register(file_name, scene)` API that consumers
call instead of doing their own injection. Registered items resolve through
the same `Database.get(name)` path the vanilla game already uses, so loot
spawners, traders, drop/pickup, and shelter saves all see them as normal
items.

## Installation

1. Drop `RTVModItemRegistry.vmz` into the game's `mods/` folder.
2. Ensure a compatible mod loader is installed (e.g. [Metro Mod Loader](https://modworkshop.net/mod/55623)).
3. **Recommended:** also install [Mod Configuration Menu (MCM)](https://modworkshop.net/mod/53713) — the registry runs without it, but settings can only be tweaked in-game when MCM is present.
4. Install any consumer mods that use the registry (CatAutoFeed, Wallet, etc.). They pick it up automatically via soft dependency.

## For mod authors

See [REGISTRY.md](REGISTRY.md) for the integration guide. TL;DR:

```gdscript
var registry = get_node_or_null("/root/ModItemRegistry")
if registry and registry.has_method("register"):
    registry.register("My_Item", preload("res://mods/MyMod/My_Item.tscn"))
else:
    _legacy_in_place_inject()  # fallback when registry isn't installed
```

## Configuration (MCM)

The registry has no behavior toggles — only the standard Logging category for
adjusting verbosity, file output, and overlay output of its diagnostic
messages.

## Compatibility

- **Loads with priority `-50`** so it sits between MCM (`-100`) and consumer
  mods (default `0`).
- **Soft dependency:** consumer mods check `get_node_or_null("/root/ModItemRegistry")`. If absent, they're expected to fall back to legacy in-place injection (which works fine in single-mod setups).
- **Cooperating mods coexist cleanly.** Verified in testing — multiple consumers calling `register()` all keep their items.

## Known limitation: non-cooperating siblings can still clobber

If you install a mod that does its own `take_over_path("res://Scripts/Database.gd")` alongside RTVModItemRegistry — i.e., a mod that's *not* aware of the registry's `register()` API — that mod's `set_script()` call will reset the registry's internal state, and **every item registered before that point becomes unresolvable** (`Database.get()` returns `null`).

This is a Godot engine reality, not something the registry can patch around: `set_script` re-initializes a node's instance variables to the new script's defaults. We can't detect or undo that without arms-racing the very mods we're trying to coexist with.

**Practical impact:**
- Vanilla items continue to work (they're resolved on a parent script).
- Consumer mods that fall back to legacy injection (CatAutoFeed, Wallet, etc.) still get their items in — the cost is that they're back to last-loader-wins between each other.

**The mitigation is social, not technical:** RTVModItemRegistry only protects mods that opt in. We're inviting other item-mod authors to integrate via the `register()` API. If you maintain such a mod, see [REGISTRY.md](REGISTRY.md) — integration is ~5 lines of code.

## How it works

`Main.gd` runs at `_ready` and:

1. Loads `DatabaseInject.gd` (which extends `res://Scripts/Database.gd`).
2. Calls `take_over_path("res://Scripts/Database.gd")` — future loads return our extension.
3. Calls `set_script(inject)` on the running `/root/Database` autoload — the live instance now has our `register()` method and `_get` override.
4. Exposes `register()`, `is_registered()`, `registered_items()` for consumer mods.

`DatabaseInject.gd` keeps a `Dictionary[String, PackedScene]` of registered items. The override of `_get(property)` checks the dictionary before letting Godot's default lookup find vanilla consts. Registered items shadow vanilla consts of the same name; vanilla consts continue to work unmodified for everything else.

## Credits

Built for the Road to Vostok modding ecosystem. In-game diagnostic configuration via the [Mod Configuration Menu](https://modworkshop.net/mod/53713) by DoinkOink. Logging output via [RTV Mod Logger](https://modworkshop.net/mod/PENDING).

## License

[MIT](LICENSE) — mod code only. Embed `Logger.gd` and the registry's API patterns freely.

## Source & Issues

Built in the [RoadToVostokMods workspace](https://github.com/dwoodruff83/RoadToVostokMods).
