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
    if registry == null:
        registry = get_tree().root.find_child("ModItemRegistry", true, false)
    if registry and registry.has_method("register"):
        var ok_a: bool = registry.register("My_Item", preload("res://mods/MyMod/My_Item.tscn"))
        var ok_b: bool = registry.register("My_Other_Item", preload("res://mods/MyMod/My_Other_Item.tscn"))
        if ok_a and ok_b:
            return
        # Some registration was rejected — fall through to legacy so the
        # mod still works in this user's setup.

    # Soft-dep fallback: registry not installed (or rejected an item).
    # Do your own in-place injection so the mod still works in a single-mod
    # setup. Document in your README that multi-mod compatibility
    # requires RTVModItemRegistry to be installed.
    _legacy_inject_database()
```

**Always check the return value.** If the registry rejected your call —
e.g., because another mod already registered the same name, or because
your name collides with a vanilla const — `register()` returns `false`.
A safe consumer falls back to legacy injection in that case so the user
still gets your items.

Items you `register()` resolve via `Database.get(name)` exactly like
vanilla items — no special handling needed in callers.

## API

| Method | Purpose |
|--------|---------|
| `register(file_name: String, scene: PackedScene, overwrite: bool = false, force: bool = false) -> bool` | Add an item. `file_name` should match the `file` field on the item's `ItemData.tres`. Returns `true` on success, `false` on bad args, collision (without `overwrite`), or vanilla-const shadowing (without `force`). |
| `is_registered(file_name: String) -> bool` | Check whether a name is in the registry. |
| `registered_items() -> Array[String]` | Snapshot of registered names. Useful for diagnostics. |

## Collision and shadowing policy

Both safety checks default to **reject** so authors notice conflicts loudly
during development instead of silently breaking each other in users' setups.

### Collision: two mods register the same `file_name`

Default: the second `register()` call returns `false` and logs a warn.
The first registration wins.

If you genuinely want to replace another mod's item (e.g., you're building
a "vanilla rebalance" pack that overrides another mod's tuning), pass
`overwrite=true`:

```gdscript
registry.register("Their_Item", my_replacement_scene, true)  # overwrite=true
```

### Vanilla-const shadowing: `file_name` collides with a vanilla const

Default: rejected with a warn. Vanilla items like `Cat`, `Cat_Food`,
`Makarov`, etc. cannot be shadowed by accident. The registry snapshots
the full vanilla const list at injection time via
`get_base_script().get_script_constant_map()`.

If you genuinely need to shadow a vanilla item, pass `force=true`:

```gdscript
registry.register("Cat_Food", my_better_cat_food, false, true)  # force=true
```

Use sparingly — vanilla items are referenced by save files, trader
inventories, recipes, and AI loot tables. Shadowing them changes behavior
across systems you may not have tested.

## Deferred registration (call `register()` before our `_ready`)

If your mod has a lower priority than `-50` (e.g., `priority=-100` to
match MCM), your `_ready` may run before the registry's. In that case
`register()` queues your entry and returns `true`. The registry flushes
the queue at the end of its own `_ready`. From your perspective, calling
`register()` early is safe — you don't need to `await` or check
`/root/ModItemRegistry` ready state.

Validation still happens at queue time: empty `file_name` and null scene
are rejected immediately. Collision and shadow checks happen at flush time.

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

See [Collision and shadowing policy](#collision-and-shadowing-policy)
above. Short version: the second mod's `register()` returns `false` by
default. Pass `overwrite=true` to opt in to replacement.

Name your items with a mod-unique prefix to avoid this entirely
(e.g. `MyMod_Wallet` instead of just `Wallet`).

## What about runtime un-registering?

Not supported. The registry is append-only for the session. If two mods
genuinely need to swap an item, do it through your own coordination layer.

## What this does NOT solve

- **Mods that don't use the registry.** If `Mod A` uses the registry and
  `Mod B` does its own `take_over_path` on `Scripts/Database.gd`, Mod B
  will clobber Mod A's items. The registry only coordinates between
  cooperating mods. **See "Failure mode under non-cooperating siblings"
  below for the exact behavior we observed in testing.**
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

## Failure mode under non-cooperating siblings

**Tested behavior.** When a sibling mod calls
`take_over_path("res://Scripts/Database.gd")` and `set_script(...)` on
`/root/Database` AFTER the registry has done so, Godot's `set_script`
re-initializes the live Node's instance variables to the new script's
defaults. For our `DatabaseInject` script that means:

- `_registered: Dictionary = {}` is reset to empty
- `_vanilla_consts: Dictionary = {}` is reset to empty
- `_log_callback: Callable = Callable()` is reset

The inherited methods still exist (because Godot's
`extends "res://Scripts/Database.gd"` resolves to `DatabaseInject` after
the registry's earlier take-over, so any sibling mod's script is
implicitly `DatabaseInject`-derived). But every item registered before
the clobber is **lost**, and `Database.get(name)` returns `null` for
those names.

**What this means in practice:**

- Vanilla items continue to work (the parent `Database.gd` const lookup
  is unaffected).
- Items registered AFTER the clobber are stored on the new instance dict
  and can be looked up — but only until the next clobber.
- Consumer mods that fall back to legacy in-place injection when
  `register()` returns `false` will still get their items in. The cost
  is that they no longer coexist with each other; they're back to the
  original last-loader-wins problem.

**Why we don't programmatically detect or recover from this.** Detecting
script swap on `/root/Database` would require polling or monkey-patching
`set_script`, both of which arms-race against the very mods we're trying
to coexist with. The intended mitigation is **social, not technical**:
ship the registry early, evangelize to other item-mod authors, and make
the register-cooperatively-or-fall-back-to-legacy pattern the norm.

If you maintain an item-adding mod and want to avoid this failure mode
entirely, integrate with the registry's `register()` API — or DM the
author and we'll help.
