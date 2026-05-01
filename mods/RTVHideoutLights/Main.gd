extends Node

# Paths to .tres ItemData resources for any loot-table integration you do.
const ITEM_PATHS := [
	# "res://mods/RTVHideoutLights/MyItem.tres",
]

var _log_node: Node = null

func _ready() -> void:
	name = "RTVHideoutLights"
	_log("debug", "RTV Hideout Lights mod loaded")
	_register_with_metro()

# Registers each item scene as a SCENES entry via Metro's registry API.
# Metro v3.x wraps Database.gd at loader startup when [registry] is declared
# in mod.txt, so Database.get("<name>") resolves to the registered scene.
# Requires Metro Mod Loader v3.0.0 or later — without it, items will not
# resolve and the mod will warn at startup.
func _register_with_metro() -> void:
	var lib = Engine.get_meta("RTVModLib") if Engine.has_meta("RTVModLib") else null
	if lib == null:
		_log("error", "Metro Mod Loader not detected — items will not be registered. Install Metro v3.x or newer.")
		return
	await lib.frameworks_ready

	_register_lamp(
		lib,
		"rtvlights_lamp_cellar_ceiling",
		preload("res://mods/RTVHideoutLights/scenes/Lamp_Cellar_Ceiling_F.tscn"),
		load("res://mods/RTVHideoutLights/items/Lamp_Cellar_Ceiling_F.tres"),
		"Generalist",
	)

# Wires one fixture into the four registries Metro v3.x exposes:
#   SCENES         — Database.get(id) resolves to the placeable scene
#   ITEMS          — registers the ItemData (auto-syncs itemData.file = id)
#   LOOT           — appends the item into LT_Master so traders can stock it
#   TRADER_POOLS   — flips the trader-flag (e.g. item.generalist = true)
# The same `id` string keys SCENES/ITEMS, and itemData.file must match it
# because the placement and shelter-load paths both call Database.get(file).
func _register_lamp(lib, id: String, scene: PackedScene, data: Resource, trader: String) -> void:
	if data == null:
		_log("error", "ItemData failed to load for %s" % id)
		return

	if !lib.register(lib.Registry.SCENES, id, scene):
		_log("warn", "Metro rejected SCENES for %s" % id)
		return
	if !lib.register(lib.Registry.ITEMS, id, data):
		_log("warn", "Metro rejected ITEMS for %s" % id)
		return
	if !lib.register(lib.Registry.LOOT, id + "_in_master", {
		"item": data,
		"table": "LT_Master",
	}):
		_log("warn", "Metro rejected LOOT for %s" % id)
		return
	if !lib.register(lib.Registry.TRADER_POOLS, id + "_" + trader.to_lower(), {
		"item": data,
		"trader": trader,
	}):
		_log("warn", "Metro rejected TRADER_POOLS for %s" % id)
		return

	_log("debug", "Registered %s in %s pool" % [id, trader])

func _log(lvl: String, msg: String) -> void:
	if _log_node == null or !is_instance_valid(_log_node):
		_log_node = get_node_or_null("/root/RTVHideoutLightsLog")
		if _log_node == null:
			_log_node = get_tree().root.find_child("RTVHideoutLightsLog", true, false)
	if _log_node:
		_log_node.call(lvl, msg)
	else:
		print("[RTVHideoutLights] [", lvl.to_upper(), "] ", msg)
