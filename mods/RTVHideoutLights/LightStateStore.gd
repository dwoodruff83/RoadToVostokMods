class_name LightStateStore
extends RefCounted

# Sidecar persistence for placed-fixture lit state.
#
# Vanilla shelter saves serialize FurnitureSave (position, rotation, scale,
# itemData, storage), but NOT arbitrary script-level state like
# `LightToggle.active`. So a Floor Lamp the player turned on always loads
# back as off. This file plugs that hole by mirroring each manual fixture's
# active flag into a separate ConfigFile keyed by shelter + fixture file
# id + world position.
#
# All methods are static — no autoload needed. The ConfigFile is lazily
# loaded on first access and cached in a static var, so per-shelter visits
# pay one disk read followed by in-memory writes (each `set_value` triggers
# a save() so a crash mid-toggle still preserves the most recent state).
#
# Issue #47.

const PATH := "user://rtvlights_state.cfg"

# Single-instance ConfigFile cache. Lazily initialised on first call;
# survives full mod reload because static state is bound to the script
# resource, not a node instance.
static var _cache: ConfigFile = null

static func _config() -> ConfigFile:
	if _cache != null:
		return _cache
	_cache = ConfigFile.new()
	# `load` returns ERR_FILE_NOT_FOUND on first run; that's expected and
	# leaves the ConfigFile empty. We don't surface the error.
	_cache.load(PATH)
	return _cache

# Persist the lit state of a single fixture. Section is per-shelter so a
# bunker's Floor Lamp doesn't collide with a cabin's at the same x/y/z.
# Position is rounded to 2dp (1cm) to immunize the key against float drift
# when the player picks up and re-places at "the same spot".
static func save_state(shelter: String, file_id: String, position: Vector3, active: bool) -> void:
	if shelter.is_empty() or file_id.is_empty():
		return
	var cfg := _config()
	cfg.set_value(_section(shelter), _make_key(file_id, position), active)
	cfg.save(PATH)

# Returns saved state, or `default` if no entry exists for this fixture.
static func load_state(shelter: String, file_id: String, position: Vector3, default: bool = false) -> bool:
	if shelter.is_empty() or file_id.is_empty():
		return default
	var cfg := _config()
	return bool(cfg.get_value(_section(shelter), _make_key(file_id, position), default))

# True iff a sidecar entry exists for this fixture (regardless of value).
# Lets callers tell "no entry, use default" apart from "entry says false".
static func has_state(shelter: String, file_id: String, position: Vector3) -> bool:
	if shelter.is_empty() or file_id.is_empty():
		return false
	return _config().has_section_key(_section(shelter), _make_key(file_id, position))

static func _section(shelter: String) -> String:
	return "shelter_" + shelter

static func _make_key(file_id: String, pos: Vector3) -> String:
	return "%s_%.2f_%.2f_%.2f" % [file_id.to_lower(), pos.x, pos.y, pos.z]
