extends Node

const MOD_ID := "RTVHideoutLights"
const MOD_NAME := "RTV Hideout Lights"
const FILE_PATH := "user://MCM/RTVHideoutLights"

var _mcm_helpers = null

func _ready() -> void:
	name = "RTVHideoutLightsConfig"

	_mcm_helpers = load("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")

	var config := ConfigFile.new()

	# v1 has no mod-specific MCM settings — fixtures are placed via the
	# vanilla decor mode and toggled in-world. Logger category is always
	# attached so users can adjust log verbosity / output sinks.
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
		"Placeable hideout lights, stocked by every trader",
		{ "config.ini" = _apply }
	)

# Silent schema migration — see mods/RTVModLogger/LOGGER.md "Handling schema changes".
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

	var logger = _resolve_logger()
	if logger:
		logger.apply_from_config(config)

func _resolve_logger():
	var n = get_node_or_null("/root/RTVHideoutLightsLog")
	if n == null:
		n = get_tree().root.find_child("RTVHideoutLightsLog", true, false)
	return n
