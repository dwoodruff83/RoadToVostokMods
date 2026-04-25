extends Node

const MOD_ID := "Wallet"
const MOD_NAME := "Wallet"
const FILE_PATH := "user://MCM/Wallet"

const WALLETS := preload("res://mods/Wallet/wallets.gd")

var enabled := true
var notify_on_transfer := true
var tier_enabled: Dictionary = {}

var _mcm_helpers = null

func _ready() -> void:
    name = "WalletConfig"

    _mcm_helpers = load("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")

    var config := ConfigFile.new()

    config.set_value("Category", "General", { "menu_pos": 1 })
    config.set_value("Category", "Tiers",   { "menu_pos": 2 })

    config.set_value("Bool", "enabled", {
        "name" = "Enable Wallet",
        "tooltip" = "Master toggle for the Wallet mod.",
        "default" = true,
        "value" = true,
        "category" = "General",
        "menu_pos" = 1,
    })

    config.set_value("Bool", "notify_on_transfer", {
        "name" = "Notify On Transfer",
        "tooltip" = "Show an on-screen message when cash is moved to or from a wallet.",
        "default" = true,
        "value" = true,
        "category" = "General",
        "menu_pos" = 2,
    })

    var pos := 10
    for tier in WALLETS.TIERS:
        config.set_value("Bool", "tier_" + tier.id, {
            "name" = "Enable: " + tier.name,
            "tooltip" = "Register this wallet tier (capacity " + str(tier.capacity) + ").",
            "default" = true,
            "value" = true,
            "category" = "Tiers",
            "menu_pos" = pos,
        })
        pos += 1

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

    enabled = config.get_value("Bool", "enabled", {"value": true})["value"]
    notify_on_transfer = config.get_value("Bool", "notify_on_transfer", {"value": true})["value"]
    tier_enabled.clear()
    for tier in WALLETS.TIERS:
        var entry = config.get_value("Bool", "tier_" + tier.id, {"value": true})
        tier_enabled[tier.id] = bool(entry["value"])

    var logger = _resolve_logger()
    if logger:
        logger.apply_from_config(config)

func _resolve_logger():
    var n = get_node_or_null("/root/WalletLog")
    if n == null:
        n = get_tree().root.find_child("WalletLog", true, false)
    return n
