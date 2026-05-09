extends Node

# Phase 2 of #47: persist on/off state for Fire-rooted catalog fixtures
# (Candle, Kerosene Lantern). Vanilla `Fire.gd` doesn't expose a hook we
# can latch into the way LightToggle does, so this script attaches as a
# child of the Fire-rooted scene root and observes the parent's `active`
# field by polling. On transitions it mirrors the value into
# LightStateStore (the same sidecar #47 phase 1 introduced for
# LightToggle fixtures).
#
# Why a child observer rather than `take_over_path` on Fire.gd:
#   - Scoped: only fixtures in OUR scenes get the observer. Vanilla world
#     candles / lanterns / fire pits / barrels keep their existing 2%
#     spawn-lit behaviour and are unaffected.
#   - Mod-coexistence safe: another mod overriding Fire.gd via
#     take_over_path won't collide with us.
#   - One ConfigFile write per ignite/extinguish; polling is just a bool
#     compare per frame, trivially cheap.

const LightStateStoreScript = preload("res://mods/RTVHideoutLights/LightStateStore.gd")

# Cached parent + Furniture sibling. Resolved in _ready and held for the
# lifetime of the node.
var _fire_root: Node3D = null
var _furniture: Node = null

# Last observed active state. _process flips when `_fire_root.active`
# transitions and writes the new value to LightStateStore.
var _last_active: bool = false

# Mirrors LightToggle's _initialized: prevents the initial restore pass
# from triggering a same-value persist write back, and gates `_process`
# until `_restore_state_from_sidecar` has run.
var _initialized: bool = false

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    _fire_root = get_parent() as Node3D
    if _fire_root == null:
        return
    _furniture = _fire_root.get_node_or_null("Furniture")
    # Two timing concerns to clear before we can restore:
    #
    # 1. LoadShelter assigns global_position AFTER the add_child that
    #    triggers _ready, so reading global_position immediately would
    #    look up the sidecar at (0,0,0) and miss.
    #
    # 2. Vanilla Fire.gd._ready does its own `await get_tree().create_timer(0.1)`
    #    before forcing `active = false` + Deactivate() on the 98% non-lit
    #    branch of its 2% spawn-lit roll. If we restore inside that 100ms
    #    window, vanilla clobbers us when it resumes.
    #
    # A 0.25s wait covers both: LoadShelter has long since assigned the
    # saved position (it's a synchronous loop), and Fire's 0.1s timer plus
    # the random-roll branch has fully completed. Then we override.
    await get_tree().create_timer(0.25, false).timeout
    _restore_state_from_sidecar()

func _restore_state_from_sidecar() -> void:
    if _fire_root == null or not is_instance_valid(_fire_root) or not ("active" in _fire_root):
        _initialized = true
        return
    # Skip during placement preview: the player is dragging the fixture
    # around, position is mid-flux, and LightFurniture.ResetMove will
    # deterministically force it off after commit anyway. Restoring now
    # would just flicker.
    if _furniture and "isMoving" in _furniture and _furniture.isMoving:
        _initialized = true
        _last_active = bool(_fire_root.active)
        return
    var shelter := _resolve_shelter_name()
    var file_id := _resolve_file_id()
    if shelter.is_empty() or file_id.is_empty():
        _initialized = true
        _last_active = bool(_fire_root.active)
        return
    if LightStateStoreScript.has_state(shelter, file_id, _fire_root.global_position):
        var saved: bool = LightStateStoreScript.load_state(shelter, file_id, _fire_root.global_position)
        if saved and not bool(_fire_root.active):
            # Re-ignite. Vanilla Fire.Interact sets `active = true` AFTER
            # calling Activate; we replicate that ordering so the data
            # stays consistent with vanilla expectations.
            _fire_root.Activate()
            _fire_root.active = true
        elif not saved and bool(_fire_root.active):
            _fire_root.Deactivate()
            _fire_root.active = false
    _last_active = bool(_fire_root.active)
    _initialized = true

func _process(_delta: float) -> void:
    if not _initialized:
        return
    if _fire_root == null or not is_instance_valid(_fire_root):
        return
    if not ("active" in _fire_root):
        return
    var current: bool = bool(_fire_root.active)
    if current == _last_active:
        return
    _last_active = current
    _persist_state(current)

func _persist_state(state: bool) -> void:
    var shelter := _resolve_shelter_name()
    var file_id := _resolve_file_id()
    if shelter.is_empty() or file_id.is_empty():
        return
    LightStateStoreScript.save_state(shelter, file_id, _fire_root.global_position, state)

func _resolve_shelter_name() -> String:
    var scene = get_tree().current_scene
    if scene == null:
        return ""
    var map_node = scene.get_node_or_null("/root/Map")
    if map_node == null:
        return ""
    var m = map_node.get("mapName")
    return String(m) if m != null else ""

# The Furniture sibling carries the catalog ItemData resource — `file` is
# the stable per-SKU id (`rtvlights_candle`, `rtvlights_lantern_kerosene`)
# that the same fixture uses across save/load.
func _resolve_file_id() -> String:
    if _furniture == null or not ("itemData" in _furniture):
        return ""
    var item_data = _furniture.itemData
    if item_data == null or not ("file" in item_data):
        return ""
    return String(item_data.file)
