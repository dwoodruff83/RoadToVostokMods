# ModItemRegistry — integration guide for mod authors

> Distributed as part of [RTVModItemRegistry](README.md). This document
> targets mods that add new items to the game and want to coexist with other
> item-adding mods.

## What problem this solves

Vanilla `res://Scripts/Database.gd` looks like:

```gdscript
extends Node

const Cat = preload("res://Items/Misc/Cat/Cat.tscn")
const Cat_Food = preload("res://Items/Consumables/Cat_Food/Cat_Food.tscn")
# ...
```

Game systems resolve items via `Database.get(file_name)`. To add an item,
mods extend the script:

```gdscript
extends "res://Scripts/Database.gd"
const My_Item = preload("res://mods/MyMod/My_Item.tscn")
```

…and call `take_over_path("res://Scripts/Database.gd")` plus
`set_script(inject)` on the live `/root/Database` autoload.

**The problem**: any other mod doing the same thing replaces your script.
Last loader wins. Every mod after the loser silently loses its items.

## What this mod does instead

`RTVModItemRegistry` runs at `priority=-50` (before consumer mods), takes
over the Database script *once*, and offers a `register(file_name, scene)`
API. Multiple mods can call `register()` and they all coexist.

## Quick start

In your mod's `Main.gd` `_ready`, replace your direct
`take_over_path` / `set_script` block with:

```gdscript
func _inject_database() -> void:
    var registry = get_node_or_null("/root/ModItemRegistry")
    if registry and registry.has_method("register"):
        registry.register("My_Item", preload("res://mods/MyMod/My_Item.tscn"))
        registry.register("My_Other_Item", preload("res://mods/MyMod/My_Other_Item.tscn"))
        # … one call per item your mod adds …
        return

    # Soft-dep fallback: registry not installed. Do your own in-place
    # injection so the mod still works in a single-mod setup. Document
    # in your README that multi-mod compatibility requires
    # RTVModItemRegistry to be installed.
    _legacy_inject_database()
```

That's it. Items you `register()` resolve via `Database.get(name)` exactly
like vanilla items — no special handling needed in callers.

## API

| Method | Purpose |
|--------|---------|
| `register(file_name: String, scene: PackedScene) -> bool` | Add an item. `file_name` should match the `file` field on the item's `ItemData.tres`. Returns true on success, false on bad args or pre-init call. |
| `is_registered(file_name: String) -> bool` | Check whether a name is in the registry. |
| `registered_items() -> Array[String]` | Snapshot of registered names. Useful for diagnostics. |

## Soft-dependency pattern

The registry is a *recommended* runtime dependency, not a hard one. Mirror
the same pattern mods use for MCM:

```gdscript
var registry = get_node_or_null("/root/ModItemRegistry")
if registry and registry.has_method("register"):
    # use the cooperative path
else:
    # fall back to your previous direct-injection path
```

In your mod's README, recommend (don't require) `RTVModItemRegistry`:

> **Recommended:** install [RTVModItemRegistry](https://…) so this mod
> coexists cleanly with other mods that add items. Without it, a single-mod
> setup still works.

## Load order

| Mod | Priority | Why |
|-----|----------|-----|
| Mod Configuration Menu | `-100` | First — consumer mods may register MCM categories during their own `_ready` |
| **RTVModItemRegistry** | **`-50`** | Before consumers so `register()` is ready when they call it |
| Your consumer mod | default `0` | Calls `register()` for its items |

Set `priority=-50` only if you're modifying / forking the registry. Consumer
mods don't need any special priority.

## What if two mods register the SAME `file_name`?

Last-call-wins, by `Dictionary` semantics. The registry doesn't currently
detect or warn on collisions — file your mod IDs uniquely, by convention
(e.g. prefix item names with your mod tag if there's any chance of conflict).
Future versions may add collision warnings.

## What about runtime un-registering?

Not supported. The registry is append-only for the session. If two mods
genuinely need to swap an item, do it through your own coordination layer.

## What this does NOT solve

- **Mods that don't use the registry.** If `Mod A` uses the registry and
  `Mod B` does its own `take_over_path` on `Scripts/Database.gd`, Mod B
  will clobber Mod A's items. The registry only coordinates between
  cooperating mods.
- **Adding items to other vanilla resources** (e.g. `LT_Master.items`,
  loot tables, trader supply). For loot, you append to `LT_Master.items`
  directly — see CatAutoFeed's `_inject_loot_table` for a working pattern.
  A future version of this mod may add a similar registry for loot tables.

## Inspecting the registry at runtime

From the Godot debugger console while in-game:

```gdscript
get_node("/root/ModItemRegistry").registered_items()
```

…returns the full list of registered file names.
