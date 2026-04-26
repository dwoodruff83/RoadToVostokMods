extends Node

# RTVModItemRegistry — coordinated injection of mod-added items into the
# vanilla `res://Scripts/Database.gd` autoload.
#
# Why this exists
# ---------------
# Multiple mods adding new items (e.g., CatAutoFeed's Cat Food Bowl, Wallet's
# wallet tiers) each independently call `take_over_path("res://Scripts/
# Database.gd")` and `set_script(extension)` on the running `/root/Database`
# autoload. This is last-loader-wins — only one mod's items survive.
#
# RTVModItemRegistry replaces that fight: it runs ONCE (priority=-50, before
# any consumer mod), takes over the Database script ONCE, and offers a
# `register(file_name, scene)` API that consumers call instead.
#
# Public API
# ----------
#   register(file_name: String, scene: PackedScene) -> bool
#   is_registered(file_name: String) -> bool
#   registered_items() -> Array[String]
#
# Consumer pattern (soft dependency, mirrors how mods use MCM):
#
#   var registry = get_node_or_null("/root/ModItemRegistry")
#   if registry and registry.has_method("register"):
#       registry.register("My_Item", preload("res://mods/MyMod/My_Item.tscn"))
#   else:
#       # fallback to legacy in-place injection (incompatible with siblings)
#       _legacy_inject()
#
# Database.get(file_name) keeps working for both vanilla items (resolved as
# script consts on Database.gd) and registered items (resolved through the
# extended script's `_get` override).

const INJECT_SCRIPT_PATH := "res://mods/RTVModItemRegistry/DatabaseInject.gd"
const VANILLA_DATABASE_PATH := "res://Scripts/Database.gd"
const DEMO_STUB_NAME := "_RegistryDemo_StubItem"

var _db: Node = null
var _ready_done := false
var _log_node: Node = null


func _ready() -> void:
    name = "ModItemRegistry"
    _log_node = _resolve_log_node()
    _log("debug", "RTVModItemRegistry loading (priority=-50)")
    _inject_database()
    _maybe_register_demo_stub()
    set_process_unhandled_input(true)
    _ready_done = true
    _log("debug", "Registry online at %s; %d items currently registered" % [str(get_path()), registered_items().size()])


# --- Public API ---

# Register a mod item under its `file` field name. The PackedScene becomes
# resolvable via Database.get(file_name) the same way vanilla items are.
# Returns true on success, false if the registry isn't ready or args are bad.
func register(file_name: String, scene: PackedScene) -> bool:
    if _db == null or not _db.has_method("register"):
        _log("warn", "register('%s') called before injection complete" % file_name)
        return false
    if file_name == "":
        _log("warn", "register() called with empty file_name")
        return false
    if scene == null:
        _log("warn", "register('%s') called with null scene" % file_name)
        return false
    var ok: bool = _db.register(file_name, scene)
    if ok:
        _log("debug", "Registered item: %s" % file_name)
    return ok


func is_registered(file_name: String) -> bool:
    if _db == null or not _db.has_method("is_registered"):
        return false
    return _db.is_registered(file_name)


func registered_items() -> Array:
    if _db == null or not _db.has_method("registered_items"):
        return []
    return _db.registered_items()


# --- Demo / self-check ---

# Construct a tiny PackedScene at runtime (just a single Node, no mesh, no
# script, no behavior) and register it under DEMO_STUB_NAME. This lets the
# self-check verify the full registration path even without consumer mods
# installed. The stub never appears in loot, traders, or inventory — it's
# only ever returned by Database.get(DEMO_STUB_NAME) when explicitly asked.
func _maybe_register_demo_stub() -> void:
    var cfg = _config()
    if cfg == null or not cfg.demo_self_register:
        return
    var stub := PackedScene.new()
    var node := Node.new()
    node.name = DEMO_STUB_NAME
    stub.pack(node)
    register(DEMO_STUB_NAME, stub)


func _unhandled_input(event: InputEvent) -> void:
    if !(event is InputEventKey) or !event.pressed or event.echo:
        return
    var cfg = _config()
    if cfg == null:
        return
    if event.keycode != cfg.test_hotkey_keycode:
        return
    run_self_check()


# Public: list every registered item, call Database.get(name) on each, and
# log a per-item pass/fail plus a summary line. Bound to the configured
# Test Hotkey, but also callable directly from other mods or the debugger.
func run_self_check() -> void:
    var names: Array = registered_items()
    _log("info", "=== Registry self-check (%d item%s) ===" % [names.size(), "" if names.size() == 1 else "s"])

    if names.is_empty():
        _log("warn", "No items registered. Install a consumer mod (CatAutoFeed, Wallet, etc.) or enable Demo Self-Register.")
        return

    var passed := 0
    var failed := 0
    for n in names:
        var resolved = _db.get(n) if _db else null
        if resolved != null:
            _log("info", "  PASS  %s -> %s" % [n, str(resolved)])
            passed += 1
        else:
            _log("error", "  FAIL  %s -> null (not resolvable via Database.get)" % n)
            failed += 1

    if failed == 0:
        _log("info", "Self-check PASSED (%d/%d resolved)" % [passed, names.size()])
        if _log_node and _log_node.has_method("notify"):
            _log_node.notify("Registry self-check PASSED (%d items)" % passed, Color.GREEN)
    else:
        _log("error", "Self-check FAILED (%d ok, %d broken)" % [passed, failed])
        if _log_node and _log_node.has_method("notify"):
            _log_node.notify("Registry self-check FAILED (%d/%d broken)" % [failed, names.size()], Color.RED)


func _config():
    var n = get_node_or_null("/root/RTVModItemRegistryConfig")
    if n == null:
        n = get_tree().root.find_child("RTVModItemRegistryConfig", true, false)
    return n


# --- Database injection (runs once on _ready) ---

func _inject_database() -> void:
    var inject = load(INJECT_SCRIPT_PATH)
    if inject == null:
        _log("error", "Could not load DatabaseInject.gd at %s" % INJECT_SCRIPT_PATH)
        return
    # take_over_path so any future load() of Database.gd returns our extension.
    inject.take_over_path(VANILLA_DATABASE_PATH)

    _db = get_node_or_null("/root/Database")
    if _db == null:
        _db = get_tree().root.find_child("Database", true, false)
    if _db == null:
        _log("error", "Database autoload not found; registry will reject register() calls")
        return

    # Replace the script on the live instance so .get() and our register()
    # method both work immediately, not just after the next load().
    _db.set_script(inject)
    _log("debug", "Database extended; registry methods live")


# --- Logger plumbing (mirrors RTVModLogger pattern) ---

func _resolve_log_node() -> Node:
    var n = get_node_or_null("/root/RTVModItemRegistryLog")
    if n == null:
        n = get_tree().root.find_child("RTVModItemRegistryLog", true, false)
    return n


func _log(lvl: String, msg: String) -> void:
    if _log_node == null or !is_instance_valid(_log_node):
        _log_node = _resolve_log_node()
    if _log_node:
        _log_node.call(lvl, msg)
    else:
        print("[RTVModItemRegistry] [", lvl.to_upper(), "] ", msg)
