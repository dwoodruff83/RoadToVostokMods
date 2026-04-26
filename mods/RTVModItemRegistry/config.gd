extends Node

# MCM config for RTVModItemRegistry. The registry has no user-tunable
# *behavior*, so the bulk of this is the standard Logging category plus a
# small Diagnostics category with a self-check stub registration and a
# hotkey that lists/verifies everything currently in the registry.

const MOD_ID := "RTVModItemRegistry"
const MOD_NAME := "RTV Mod Item Registry"
const FILE_PATH := "user://MCM/RTVModItemRegistry"

var demo_self_register := true
var test_hotkey_keycode: int = KEY_F11

var _mcm_helpers = null


func _ready() -> void:
    name = "RTVModItemRegistryConfig"

    _mcm_helpers = load("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")

    var config := ConfigFile.new()

    config.set_value("Category", "Diagnostics", { "menu_pos": 1 })

    config.set_value("Bool", "demo_self_register", {
        "name" = "Enable Diagnostic Test Item",
        "tooltip" = "When ON (default), the registry adds a hidden stub item to itself at startup. This lets the self-check hotkey verify the registry is working even when no other item-adding mods are installed. The stub is invisible to gameplay — it never appears in loot, traders, or inventory.",
        "default" = true,
        "value" = true,
        "category" = "Diagnostics",
        "menu_pos" = 1,
    })

    config.set_value("Keycode", "test_hotkey", {
        "name" = "Self-Check Hotkey",
        "tooltip" = "Press in-game to verify every item registered with this library is reachable. Useful when troubleshooting why an item-adding mod isn't showing items in your game. Output goes to the in-game log overlay (if enabled in Logging) and the Godot console.",
        "default" = KEY_F11,
        "default_type" = "Key",
        "value" = KEY_F11,
        "type" = "Key",
        "category" = "Diagnostics",
        "menu_pos" = 2,
    })

    var logger_for_schema = _resolve_logger()
    if logger_for_schema:
        logger_for_schema.attach_to_mcm_config(config, "Logging", 10)

    _merge_schema(config, FILE_PATH + "/config.ini")

    if _mcm_helpers == null:
        _apply(config)
        return

    _mcm_helpers.CheckConfigurationHasUpdated(MOD_ID, config, FILE_PATH + "/config.ini")
    _apply(config)

    _mcm_helpers.RegisterConfiguration(
        MOD_ID,
        MOD_NAME,
        FILE_PATH,
        "Library mod that lets multiple item-adding mods coexist without crashing. Settings here are diagnostic-only — install other mods that depend on this one to see their items.",
        { "config.ini" = _apply }
    )


# Silent schema migration — same pattern as the consumer mods. Adds new keys
# from our in-memory schema, drops keys no longer in the schema, preserves
# user-edited values from disk.
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


func _apply(config: ConfigFile) -> void:
    var fresh := ConfigFile.new()
    var err := fresh.load(FILE_PATH + "/config.ini")
    if err == OK:
        config = fresh

    demo_self_register = config.get_value("Bool", "demo_self_register", {"value": true})["value"]
    test_hotkey_keycode = int(config.get_value("Keycode", "test_hotkey", {"value": KEY_F11})["value"])

    var logger = _resolve_logger()
    if logger:
        logger.apply_from_config(config)


func _resolve_logger():
    var n = get_node_or_null("/root/RTVModItemRegistryLog")
    if n == null:
        n = get_tree().root.find_child("RTVModItemRegistryLog", true, false)
    return n
