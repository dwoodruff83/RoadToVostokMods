extends Node

const MOD_ID := "CatAutoFeed"
const MOD_NAME := "Cat Auto Feed"
const FILE_PATH := "user://MCM/CatAutoFeed"

var enabled := true
var feed_threshold := 25.0
var show_notification := true
var show_hunger_warning := true

var _mcm_helpers = null

func _ready() -> void:
    name = "CatAutoFeedConfig"

    _mcm_helpers = load("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")

    var config := ConfigFile.new()

    config.set_value("Category", "General", { "menu_pos": 1 })

    config.set_value("Bool", "enabled", {
        "name" = "Enable Auto-Feed",
        "tooltip" = "Automatically feed the cat from shelter storage when hunger is low.",
        "default" = true,
        "value" = true,
        "category" = "General",
        "menu_pos" = 1,
    })

    config.set_value("Float", "feed_threshold", {
        "name" = "Feed Threshold",
        "tooltip" = "Trigger auto-feed when cat hunger drops below this value. Clamped to 25-75 to prevent instant re-feeding.",
        "default" = 25.0,
        "value" = 25.0,
        "minRange" = 25.0,
        "maxRange" = 75.0,
        "category" = "General",
        "menu_pos" = 2,
    })

    config.set_value("Bool", "show_notification", {
        "name" = "Show Fed Notification",
        "tooltip" = "Show the green \"Cat Auto-Fed\" message when the cat is fed automatically.",
        "default" = true,
        "value" = true,
        "category" = "General",
        "menu_pos" = 3,
    })

    config.set_value("Bool", "show_hunger_warning", {
        "name" = "Show Hunger Warning",
        "tooltip" = "Show an orange warning when the cat drops below the feed threshold (once per hunger cycle).",
        "default" = true,
        "value" = true,
        "category" = "General",
        "menu_pos" = 4,
    })

    var logger_for_schema = get_node_or_null("/root/CatAutoFeedLog")
    if logger_for_schema == null:
        logger_for_schema = get_tree().root.find_child("CatAutoFeedLog", true, false)
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
        "Automatically feeds the cat from shelter storage anywhere on the map.",
        { "config.ini" = _apply }
    )

# Silent schema migration. Adds new keys from our in-memory schema, drops
# keys no longer in the schema, and preserves each setting's user-edited
# "value" from disk. Writes the merged result back to disk.
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
    # MCM sometimes passes a stale in-memory config to the callback — force
    # a fresh reload from disk so we always pick up the latest user values.
    var fresh := ConfigFile.new()
    var err := fresh.load(FILE_PATH + "/config.ini")
    if err == OK:
        config = fresh

    enabled = config.get_value("Bool", "enabled", {"value": true})["value"]
    feed_threshold = float(config.get_value("Float", "feed_threshold", {"value": 25.0})["value"])
    show_notification = config.get_value("Bool", "show_notification", {"value": true})["value"]
    show_hunger_warning = config.get_value("Bool", "show_hunger_warning", {"value": true})["value"]

    var logger = get_node_or_null("/root/CatAutoFeedLog")
    if logger == null:
        logger = get_tree().root.find_child("CatAutoFeedLog", true, false)
    print("[CatAutoFeed] Config._apply threshold=", feed_threshold, " enabled=", enabled, " show_notif=", show_notification, " show_warn=", show_hunger_warning, " logger=", logger)
    if logger:
        logger.apply_from_config(config)
