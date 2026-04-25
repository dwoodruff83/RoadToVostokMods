extends Node

const MOD_ID := "PunisherGuarantee"
const MOD_NAME := "Punisher Guarantee"
const FILE_PATH := "user://MCM/PunisherGuarantee"

var enabled := true
var guarantee_event := true
var bypass_day_gate := true
var force_boss_mode := true
var hotkey_enabled := true
var hotkey_keycode: int = KEY_F10

var _mcm_helpers = null

func _ready() -> void:
    name = "PunisherGuaranteeConfig"

    _mcm_helpers = load("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")

    var config := ConfigFile.new()

    config.set_value("Category", "General", { "menu_pos": 1 })
    config.set_value("Category", "Hotkey",  { "menu_pos": 2 })

    config.set_value("Bool", "enabled", {
        "name" = "Enable Mod",
        "tooltip" = "Master toggle. Turn off and reload to disable all effects.",
        "default" = true,
        "value" = true,
        "category" = "General",
        "menu_pos" = 1,
    })

    config.set_value("Bool", "guarantee_event", {
        "name" = "Guarantee Event Fires",
        "tooltip" = "Bumps the Punisher event's possibility from 10 to 100 — fires every Area 05 entry.",
        "default" = true,
        "value" = true,
        "category" = "General",
        "menu_pos" = 2,
    })

    config.set_value("Bool", "bypass_day_gate", {
        "name" = "Bypass Day 5 Gate",
        "tooltip" = "Removes the requirement that you reach day 5 before the Punisher can show up.",
        "default" = true,
        "value" = true,
        "category" = "General",
        "menu_pos" = 3,
    })

    config.set_value("Bool", "force_boss_mode", {
        "name" = "Force Boss Mode on Van",
        "tooltip" = "Every Police van arrives in Boss mode (sirens). Otherwise it's a 50/50 coin flip.",
        "default" = true,
        "value" = true,
        "category" = "General",
        "menu_pos" = 4,
    })

    config.set_value("Bool", "hotkey_enabled", {
        "name" = "Enable Spawn Hotkey",
        "tooltip" = "Press the hotkey to spawn a Punisher near you, bypassing the van cutscene.",
        "default" = true,
        "value" = true,
        "category" = "Hotkey",
        "menu_pos" = 10,
    })

    config.set_value("Keycode", "hotkey_keycode", {
        "name" = "Spawn Hotkey",
        "tooltip" = "Key to press to spawn a Punisher at the player's location.",
        "default" = KEY_F10,
        "value" = KEY_F10,
        "category" = "Hotkey",
        "menu_pos" = 11,
    })

    var logger = _resolve_logger()
    if logger:
        logger.attach_to_mcm_config(config, "Logging", 20)

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
        "Force the Punisher boss to spawn. Changes take effect on next scene load.",
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

    enabled = config.get_value("Bool", "enabled", {"value": true})["value"]
    guarantee_event = config.get_value("Bool", "guarantee_event", {"value": true})["value"]
    bypass_day_gate = config.get_value("Bool", "bypass_day_gate", {"value": true})["value"]
    force_boss_mode = config.get_value("Bool", "force_boss_mode", {"value": true})["value"]
    hotkey_enabled = config.get_value("Bool", "hotkey_enabled", {"value": true})["value"]
    hotkey_keycode = int(config.get_value("Keycode", "hotkey_keycode", {"value": KEY_F10})["value"])

    var logger = _resolve_logger()
    if logger:
        logger.apply_from_config(config)

func _resolve_logger():
    var n = get_node_or_null("/root/PunisherGuaranteeLog")
    if n == null:
        n = get_tree().root.find_child("PunisherGuaranteeLog", true, false)
    return n
