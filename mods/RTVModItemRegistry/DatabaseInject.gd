extends "res://Scripts/Database.gd"

# Extends the vanilla Database autoload with runtime mod-item registration.
#
# Vanilla Database.gd is a Node script with `const Cat = preload(...)` style
# entries. Calls like `Database.get("Cat")` rely on Godot's Object.get()
# resolving these consts through the script. Mods can't add `const` entries
# at runtime, so we layer a Dictionary on top and override `_get` to make
# the registered items resolvable through the same `Database.get(name)` API
# the rest of the game already uses.
#
# Owned by RTVModItemRegistry/Main.gd via take_over_path + set_script. Do
# not call register() on this script directly from consumer mods — go
# through `/root/ModItemRegistry.register(...)` so future internal changes
# don't break the soft-dep contract.

var _registered: Dictionary = {}


func register(file_name: String, scene: PackedScene) -> bool:
    if file_name == "" or scene == null:
        return false
    _registered[file_name] = scene
    return true


func is_registered(file_name: String) -> bool:
    return file_name in _registered


func registered_items() -> Array:
    return _registered.keys()


# Godot calls _get(property) when standard property access doesn't find the
# named member. Returning null falls through to the engine's default lookup,
# which then resolves vanilla consts on the parent script. So registered
# items shadow vanilla consts of the same name, vanilla consts continue to
# work unchanged for everything else.
func _get(property: StringName):
    var key := String(property)
    if key in _registered:
        return _registered[key]
    return null
