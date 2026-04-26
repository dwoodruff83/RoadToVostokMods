extends Node

# MCM-driven config for the RTVModLogger demo. Demonstrates the canonical
# integration pattern: user settings + delegated logger settings + schema-
# preserving migration.

const MOD_ID := "RTVModLogger"
const MOD_NAME := "RTV Mod Logger"
const FILE_PATH := "user://MCM/RTVModLogger"

# Demo settings exposed to the user.
var welcome_on_start := true
var test_hotkey_keycode := KEY_F12
var test_action := "Test All"

const TEST_ACTIONS := [
    "Test All",
    "Test Debug",
    "Test Info",
    "Test Success",
    "Test Warn",
    "Test Error",
    "Test Notify",
]

var _mcm_helpers = null

func _ready() -> void:
    name = "RTVModLoggerConfig"

    _mcm_helpers = load("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")

    var config := ConfigFile.new()

    config.set_value("Category", "Demo", { "menu_pos": 1 })

    config.set_value("Bool", "welcome_on_start", {
        "name" = "Welcome on Game Start",
        "tooltip" = "Show a one-time notification when the mod loads, reminding you of the test hotkey.",
        "default" = true,
        "value" = true,
        "category" = "Demo",
        "menu_pos" = 1,
    })

    config.set_value("Keycode", "test_hotkey", {
        "name" = "Test Hotkey",
        "tooltip" = "Press this key in-game to fire the configured test action.",
        "default" = KEY_F12,
        "default_type" = "Key",
        "value" = KEY_F12,
        "type" = "Key",
        "category" = "Demo",
        "menu_pos" = 2,
    })

    config.set_value("Dropdown", "test_action", {
        "name" = "Test Action",
        "tooltip" = "What pressing the Test Hotkey should fire. \"Test All\" runs every level + a notify in sequence.",
        "default" = 0,
        "value" = 0,
        "options" = TEST_ACTIONS,
        "category" = "Demo",
        "menu_pos" = 3,
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
        "Demo + reusable logging library for RTV mods. Press the test hotkey in-game to see each log level.",
        { "config.ini" = _apply }
    )

func _resolve_logger() -> Node:
    var n = get_node_or_null("/root/RTVModLoggerLog")
    if n == null:
        n = get_tree().root.find_child("RTVModLoggerLog", true, false)
    return n

# Silent schema migration. Adds new keys, drops removed keys, preserves user
# values from disk. See LOGGER.md for the full pattern.
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
    # MCM occasionally passes a stale in-memory config — reload from disk.
    var fresh := ConfigFile.new()
    if fresh.load(FILE_PATH + "/config.ini") == OK:
        config = fresh

    welcome_on_start = bool(config.get_value("Bool", "welcome_on_start", {"value": true})["value"])
    test_hotkey_keycode = int(config.get_value("Keycode", "test_hotkey", {"value": KEY_F12})["value"])

    var idx: int = int(config.get_value("Dropdown", "test_action", {"value": 0})["value"])
    if idx < 0 or idx >= TEST_ACTIONS.size():
        idx = 0
    test_action = TEST_ACTIONS[idx]

    var logger = _resolve_logger()
    if logger:
        logger.apply_from_config(config)
