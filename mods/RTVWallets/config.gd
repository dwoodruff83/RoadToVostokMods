extends Node

const MOD_ID := "RTVWallets"
const MOD_NAME := "RTV Wallets"
const FILE_PATH := "user://MCM/RTVWallets"

var stash_report_keycode := KEY_F9

var _mcm_helpers = null

func _ready() -> void:
    name = "RTVWalletsConfig"

    _mcm_helpers = load("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")

    var config := ConfigFile.new()

    config.set_value("Category", "General", { "menu_pos": 1 })

    config.set_value("Keycode", "stash_report_hotkey", {
        "name" = "Stash Report Hotkey",
        "tooltip" = "Press this key in-game to log every wallet you're carrying with its balance — useful when you've split cash across tiers and want a quick total.",
        "default" = KEY_F9,
        "default_type" = "Key",
        "value" = KEY_F9,
        "type" = "Key",
        "category" = "General",
        "menu_pos" = 1,
    })

    var logger = _resolve_logger()
    if logger:
        logger.attach_to_mcm_config(config, "Logging", 100)

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
        "Lootable, tradeable wallets that hold cash like a magazine holds rounds.",
        { "config.ini" = _apply }
    )

# Silent schema migration — see shared/LOGGER.md "Handling schema changes".
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

    stash_report_keycode = int(config.get_value("Keycode", "stash_report_hotkey", {"value": KEY_F9})["value"])

    var logger = _resolve_logger()
    if logger:
        logger.apply_from_config(config)

func _resolve_logger():
    var n = get_node_or_null("/root/RTVWalletsLog")
    if n == null:
        n = get_tree().root.find_child("RTVWalletsLog", true, false)
    return n
