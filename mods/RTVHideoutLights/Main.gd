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

	# Hand-authored wall sconce SKU.
	_register_lamp(
		lib,
		"rtvlights_lamp_cellar_wall",
		preload("res://mods/RTVHideoutLights/scenes/Lamp_Cellar_Ceiling_F.tscn"),
		load("res://mods/RTVHideoutLights/items/Lamp_Cellar_Ceiling_F.tres"),
		"Generalist",
	)
	# All other v1 SKUs are produced by tools/generate_lights_skus.py.
	# Edit the FIXTURES list there and re-run to add/remove/tweak.
	_register_lamp(
		lib,
		"rtvlights_lamp_grid_lit_ceiling",
		preload("res://mods/RTVHideoutLights/scenes/rtvlights_lamp_grid_lit_ceiling_F.tscn"),
		load("res://mods/RTVHideoutLights/items/rtvlights_lamp_grid_lit_ceiling_F.tres"),
		"Generalist",
	)
	_register_lamp(
		lib,
		"rtvlights_lamp_generic_lit_hp_ceiling",
		preload("res://mods/RTVHideoutLights/scenes/rtvlights_lamp_generic_lit_hp_ceiling_F.tscn"),
		load("res://mods/RTVHideoutLights/items/rtvlights_lamp_generic_lit_hp_ceiling_F.tres"),
		"Generalist",
	)
	_register_lamp(
		lib,
		"rtvlights_lamp_generic_lit_lp_ceiling",
		preload("res://mods/RTVHideoutLights/scenes/rtvlights_lamp_generic_lit_lp_ceiling_F.tscn"),
		load("res://mods/RTVHideoutLights/items/rtvlights_lamp_generic_lit_lp_ceiling_F.tres"),
		"Generalist",
	)
	_register_lamp(
		lib,
		"rtvlights_candle",
		preload("res://mods/RTVHideoutLights/scenes/rtvlights_candle_F.tscn"),
		load("res://mods/RTVHideoutLights/items/rtvlights_candle_F.tres"),
		"Generalist",
	)
	_register_lamp(
		lib,
		"rtvlights_lantern_kerosene",
		preload("res://mods/RTVHideoutLights/scenes/rtvlights_lantern_kerosene_F.tscn"),
		load("res://mods/RTVHideoutLights/items/rtvlights_lantern_kerosene_F.tres"),
		"Generalist",
	)
	_register_lamp(
		lib,
		"rtvlights_lamp_floor",
		preload("res://mods/RTVHideoutLights/scenes/rtvlights_lamp_floor_F.tscn"),
		load("res://mods/RTVHideoutLights/items/rtvlights_lamp_floor_F.tres"),
		"Generalist",
	)
	_register_lamp(
		lib,
		"rtvlights_sign_exit_lit",
		preload("res://mods/RTVHideoutLights/scenes/rtvlights_sign_exit_lit_F.tscn"),
		load("res://mods/RTVHideoutLights/items/rtvlights_sign_exit_lit_F.tres"),
		"Generalist",
	)
	_register_lamp(
		lib,
		"rtvlights_computer_lit",
		preload("res://mods/RTVHideoutLights/scenes/rtvlights_computer_lit_F.tscn"),
		load("res://mods/RTVHideoutLights/items/rtvlights_computer_lit_F.tres"),
		"Generalist",
	)

# Wires one fixture into Metro v3.x registries:
#   SCENES         — Database.get(id) resolves to the placeable scene
#   ITEMS          — registers the ItemData (auto-syncs itemData.file = id)
#   LOOT/LT_Master — appends to LT_Master, which is the source pool the
#                    vanilla Trader.FillTraderBucket() iterates over to
#                    decide what to stock. The game also filters
#                    type=="Furniture" out of loot-container spawns, so
#                    this only ever has trader effect for our fixtures —
#                    not actual loot drops.
#   TRADER_POOLS   — appends the item to each trader's supply pool
# The same `id` string keys SCENES/ITEMS, and itemData.file must match it
# because the placement and shelter-load paths both call Database.get(file).
#
# v1 stocks every fixture at the three currently-revealed traders so
# players see them everywhere they shop. Grandma is intentionally
# skipped — she's still story-hidden. We'll scale this back per-fixture
# in a later release based on user feedback.
const TRADERS := ["Generalist", "Gunsmith", "Doctor"]

func _register_lamp(lib, id: String, scene: PackedScene, data: Resource, _trader: String) -> void:
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
	for trader in TRADERS:
		if !lib.register(lib.Registry.TRADER_POOLS, id + "_" + trader.to_lower(), {
			"item": data,
			"trader": trader,
		}):
			_log("warn", "Metro rejected TRADER_POOLS for %s @ %s" % [id, trader])

	_log("debug", "Registered %s at all traders" % id)

func _log(lvl: String, msg: String) -> void:
	if _log_node == null or !is_instance_valid(_log_node):
		_log_node = get_node_or_null("/root/RTVHideoutLightsLog")
		if _log_node == null:
			_log_node = get_tree().root.find_child("RTVHideoutLightsLog", true, false)
	if _log_node:
		_log_node.call(lvl, msg)
	else:
		print("[RTVHideoutLights] [", lvl.to_upper(), "] ", msg)
