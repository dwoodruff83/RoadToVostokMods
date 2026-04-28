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
var _vanilla_consts: Dictionary = {}
var _vanilla_consts_loaded: bool = false
var _log_callback: Callable = Callable()


# Snapshot vanilla const names from the parent script so we can detect
# attempts to shadow vanilla items. Done lazily on first register() call
# because set_script() on the live autoload doesn't re-run _init.
func _ensure_vanilla_const_snapshot() -> void:
    if _vanilla_consts_loaded:
        return
    _vanilla_consts_loaded = true
    var s: Script = get_script()
    if s == null:
        return
    var base: Script = s.get_base_script()
    if base == null:
        return
    var consts: Dictionary = base.get_script_constant_map()
    for k in consts.keys():
        _vanilla_consts[String(k)] = true


# Plumb the registry's logger in so warnings about rejected register() calls
# reach the user's MCM-configured outputs (file / overlay / console) instead
# of just push_warning.
func set_log_callback(cb: Callable) -> void:
    _log_callback = cb


# Cooperative item registration. See REGISTRY.md for the full contract.
#
# Returns true on success.
# Returns false (and warns) for: empty file_name, null scene,
#   collision with a vanilla const (unless force=true),
#   collision with another mod's registered item (unless overwrite=true).
func register(file_name: String, scene: PackedScene, overwrite: bool = false, force: bool = false) -> bool:
    _ensure_vanilla_const_snapshot()
    if file_name == "":
        _warn("register() called with empty file_name")
        return false
    if scene == null:
        _warn("register('%s') called with null scene" % file_name)
        return false
    if _vanilla_consts.has(file_name) and not force:
        _warn("register('%s') would shadow a vanilla Database const; pass force=true if intentional" % file_name)
        return false
    if _registered.has(file_name) and not overwrite:
        _warn("register('%s') already registered by another mod; pass overwrite=true if intentional" % file_name)
        return false
    _registered[file_name] = scene
    return true


func is_registered(file_name: String) -> bool:
    return file_name in _registered


# Snapshot of registered names. Caller-mutable Array (we build a fresh one
# each call), so consumers can sort/filter without affecting internal state.
func registered_items() -> Array[String]:
    var arr: Array[String] = []
    for k in _registered.keys():
        arr.append(String(k))
    return arr


# Godot calls _get(property) when standard property access doesn't find the
# named member. Returning null falls through to the engine's default lookup,
# which then resolves vanilla consts on the parent script. Registered items
# shadow vanilla consts of the same name (only allowed when force=true was
# passed at registration); vanilla consts continue to work unchanged for
# everything else.
func _get(property: StringName):
    var key := String(property)
    if key in _registered:
        return _registered[key]
    return null


func _warn(msg: String) -> void:
    if _log_callback.is_valid():
        _log_callback.call(msg)
    else:
        push_warning("[RTVModItemRegistry] %s" % msg)
