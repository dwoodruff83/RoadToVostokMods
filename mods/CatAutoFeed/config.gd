extends Node

const MOD_ID := "CatAutoFeed"
const MOD_NAME := "Cat Auto Feed"
const FILE_PATH := "user://MCM/CatAutoFeed"

var enabled := true
var feed_threshold := 25.0
var show_notification := true
var show_hunger_warning := true
var allow_shelter_fallback := false
var bowl_in_loot := true
var bowl_at_gunsmith := false
var cat_company_buff := true

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

    config.set_value("Bool", "allow_shelter_fallback", {
        "name" = "Allow Shelter Fallback",
        "tooltip" = "When OFF (default), the cat ONLY eats from the Cat Food Bowl — you must keep it filled. When ON, the cat will also raid raw food on the floor or inside cabinets/fridges in the cat's shelter if the bowl is empty.",
        "default" = false,
        "value" = false,
        "category" = "General",
        "menu_pos" = 5,
    })

    config.set_value("Bool", "bowl_in_loot", {
        "name" = "Bowl in Loot Tables",
        "tooltip" = "When ON (default), Cat Food Bowl is added to the master loot table so it can spawn in civilian containers (rarity Legendary, ~1 in 120 containers). Turn off if you want the bowl as a trader-only or unfindable item. Reload the game for changes to take effect.",
        "default" = true,
        "value" = true,
        "category" = "General",
        "menu_pos" = 6,
    })

    config.set_value("Bool", "bowl_at_gunsmith", {
        "name" = "Bowl at Gunsmith",
        "tooltip" = "When ON, the Gunsmith trader stocks Cat Food Bowl in his random supply. The Gunsmith only unlocks at day 10 in vanilla, so this is a late-game purchase path for players who haven't found a bowl in loot. Default OFF — bowls remain loot-only by default. Reload the game after toggling for the change to take effect.",
        "default" = false,
        "value" = false,
        "category" = "General",
        "menu_pos" = 7,
    })

    config.set_value("Bool", "cat_company_buff", {
        "name" = "Cat Company Mental Buff",
        "tooltip" = "When ON (default), being in the same shelter as your cat slowly raises mental, the same way sitting near a fire does. Requires the cat to be alive and rescued. Vanilla shelter doesn't normally restore mental — this is the cat's contribution.",
        "default" = true,
        "value" = true,
        "category" = "General",
        "menu_pos" = 8,
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
    allow_shelter_fallback = config.get_value("Bool", "allow_shelter_fallback", {"value": false})["value"]
    bowl_in_loot = config.get_value("Bool", "bowl_in_loot", {"value": true})["value"]
    bowl_at_gunsmith = config.get_value("Bool", "bowl_at_gunsmith", {"value": false})["value"]
    cat_company_buff = config.get_value("Bool", "cat_company_buff", {"value": true})["value"]

    var logger = get_node_or_null("/root/CatAutoFeedLog")
    if logger == null:
        logger = get_tree().root.find_child("CatAutoFeedLog", true, false)
    if logger:
        logger.debug("Config applied: threshold=%d enabled=%s show_notif=%s show_warn=%s" % [int(feed_threshold), enabled, show_notification, show_hunger_warning])
        logger.apply_from_config(config)
