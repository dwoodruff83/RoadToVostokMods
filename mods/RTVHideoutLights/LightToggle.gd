extends Node3D

# Generic on/off toggle for placed light fixtures. Three behavior surfaces:
#
#   1. Player Use action — vanilla Interactor walks up from the focused
#      "Interactable"-group body and calls Interact() on this script.
#      Used by fixtures with `interactable = true` in the generator spec
#      (Floor Lamp, Vintage Desktop PC).
#
#   2. Vanilla Switch.gd target — Switch.gd iterates its `targets` array
#      and calls .Activate()/.Deactivate() on each. We're switch-target
#      compatible because we expose those exact methods.
#
#   3. Auto-subscribe — when `subscribe_to_switch = true`, after a brief
#      delay walks the active scene tree for a node in the "Switch" group
#      and appends self to its targets array. Lets ceiling fixtures the
#      player places into a shelter automatically hook into that
#      shelter's Light_Switch.
#
# Toggle effects (any combination, configured per-fixture by generator):
#   - Toggle visibility on a list of lights / meshes (off = hidden)
#   - Swap a mesh's surface_material_override between an off and on material
#     (used for the PC's screen: dark when off, cyan UI when on)
#
# Mesh nodes whose names appear in `preview_hidden_extra` are also hidden
# during placement preview by LightFurniture (so the bulb / lit screen
# don't show up inside the green hologram). That's handled in
# LightFurniture.gd by checking node names.

# Exports use Node3D / MeshInstance3D (not NodePath) so Godot's standard
# node_paths=PackedStringArray(...) tscn relocation mechanism resolves the
# paths into actual node refs at scene load. Vanilla Switch.gd uses the
# same pattern (Array[Node3D] for `targets`). Using Array[NodePath] here
# silently fails — the array is left empty at runtime even though the tscn
# declares NodePath literals.
@export_group("Targets")
@export var lights: Array[Node3D] = []
@export var lit_meshes: Array[Node3D] = []

# Optional: swap a material on a mesh surface when toggling. Used for two
# distinct cases:
#   - PC: surface 1 (the monitor) swaps cyan UI ↔ dark blank screen
#   - Ceiling fixtures: surface 0 (the lampshade) swaps emissive Lit
#     material ↔ matte unlit material, so the fixture body doesn't
#     keep glowing when the Light3D is hidden (vanilla Light.gd pattern)
@export_group("Material swap (optional)")
@export var swap_mesh: MeshInstance3D
@export var swap_surface_index: int = 0
@export var swap_off_material: Material
@export var swap_on_material: Material

@export_group("Behavior")
@export var label: String = "Light"
@export var interactable: bool = true
@export var subscribe_to_switch: bool = false
@export var force_on: bool = false

var active: bool = false
var gameData = preload("res://Resources/GameData.tres")

# Cached ref to the switch we subscribed to so _exit_tree can deregister
# in O(1). If the player picks the fixture back up to the catalog, our
# scene root gets queue_freed — without this cleanup, the switch's
# targets array would hold a dead reference and the next toggle would
# crash the game on dead.Deactivate().
var _subscribed_switch: Node = null

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    # Set initial state. Default is off; force_on flips that.
    if force_on:
        Activate()
    else:
        Deactivate()
    # Subscribe to shelter Switch if enabled. Brief delay so the shelter
    # scene's switch is fully initialized before we touch its array.
    if subscribe_to_switch:
        await get_tree().create_timer(0.5, false).timeout
        _try_subscribe_to_switch()

func Interact() -> void:
    # Only fire on Use action when interactable; otherwise the Switch is
    # the only one allowed to call Activate/Deactivate on us.
    if not interactable:
        return
    if active:
        Deactivate()
    else:
        Activate()

func Activate() -> void:
    active = true
    for n in lights:
        if is_instance_valid(n):
            n.visible = true
    for n in lit_meshes:
        if is_instance_valid(n):
            n.visible = true
    if is_instance_valid(swap_mesh) and swap_on_material:
        swap_mesh.set_surface_override_material(swap_surface_index, swap_on_material)

func Deactivate() -> void:
    active = false
    for n in lights:
        if is_instance_valid(n):
            n.visible = false
    for n in lit_meshes:
        if is_instance_valid(n):
            n.visible = false
    if is_instance_valid(swap_mesh) and swap_off_material:
        swap_mesh.set_surface_override_material(swap_surface_index, swap_off_material)

func UpdateTooltip() -> void:
    if not interactable:
        return
    gameData.tooltip = "%s [%s]" % [label, "Turn Off" if active else "Turn On"]

func _try_subscribe_to_switch() -> void:
    # Find the NEAREST node in the "Switch" group (by world distance to
    # this fixture) and append self to its targets array. Multi-switch
    # shelters like the Cabin have one switch per room — picking the
    # closest one means a placed fixture joins the room's switch instead
    # of always grabbing whichever switch enumerates first.
    #
    # Then sync our visible state to the switch's current state —
    # necessary on save load: the switch persists its `active` flag
    # across saves, but our `force_on=true` _ready leaves the light on
    # regardless. Without the else-Deactivate branch the player would
    # see lights-on / switch-off after every load until they manually
    # toggle the switch.
    #
    # Skip while the fixture is in placement preview (Furniture.isMoving).
    # The initial _ready 0.5s timer would otherwise fire mid-placement and
    # call Activate, overwriting the hologram material set by
    # Furniture.StartMove(). LightFurniture.ResetMove() re-invokes us once
    # placement is committed, so the subscription still happens — just
    # after the fixture has landed.
    var furniture = get_node_or_null("Furniture")
    if furniture and "isMoving" in furniture and furniture.isMoving:
        return

    # Drop any prior subscription so a re-placement (move from one room
    # to another) doesn't end up controlled by both rooms' switches.
    if is_instance_valid(_subscribed_switch):
        if "targets" in _subscribed_switch and _subscribed_switch.targets is Array:
            _subscribed_switch.targets.erase(self)
        _subscribed_switch = null

    # Pick the switch whose existing targets are nearest to us, NOT just
    # the nearest switch by straight-line distance. Vanilla shelters
    # (multi-room ones like the Cabin) put each switch's controlled
    # lights in that switch's room. So "nearest target distance"
    # functionally answers "which room am I in" — without needing to do
    # actual navmesh pathfinding or raycast wall-checking. A switch that's
    # physically close but mounted on a shared wall (so its lights are in
    # the OTHER room) won't win over a switch whose lights are in our room.
    #
    # Fallback: if a switch has no targets yet, score it by its own
    # position. This happens for shelters with one switch per room and
    # we're the first fixture being added.
    var switches = get_tree().get_nodes_in_group("Switch")
    var nearest: Node3D = null
    var nearest_dist_sq := INF
    for node in switches:
        if not ("targets" in node):
            continue
        if not (node.targets is Array):
            continue
        if not (node is Node3D):
            continue
        var switch_score := INF
        for target in node.targets:
            if target == self:
                continue
            if not is_instance_valid(target) or not (target is Node3D):
                continue
            var td := global_position.distance_squared_to(target.global_position)
            if td < switch_score:
                switch_score = td
        if switch_score == INF:
            # Switch has no valid targets to anchor by — use its own position.
            switch_score = global_position.distance_squared_to(node.global_position)
        if switch_score < nearest_dist_sq:
            nearest_dist_sq = switch_score
            nearest = node

    if nearest == null:
        return

    nearest.targets.append(self)
    _subscribed_switch = nearest
    if "active" in nearest:
        if nearest.active:
            Activate()
        else:
            Deactivate()

# Remove ourselves from the switch's targets array when leaving the tree
# (e.g. picked up back to catalog → owner.queue_free → all children exit
# the tree). Without this, the switch would call .Deactivate() on a
# dangling reference next toggle and the game crashes.
func _exit_tree() -> void:
    if not is_instance_valid(_subscribed_switch):
        return
    if "targets" in _subscribed_switch and _subscribed_switch.targets is Array:
        _subscribed_switch.targets.erase(self)
    _subscribed_switch = null
