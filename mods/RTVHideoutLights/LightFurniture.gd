extends Furniture

# Furniture subclass for light fixtures. Two behaviours on top of vanilla
# Furniture:
#
# 1. Placement lifecycle — when the player picks the fixture up to move
#    it (StartMove) we force it OFF: call the toggle's Deactivate (or
#    Fire.Deactivate) so active=false AND hide every Light3D descendant
#    plus any "Bulb" decoration mesh so they don't leak light or show
#    inside the green placement hologram. The fixture stays off through
#    placement.
#
#    When the player commits placement (ResetMove) we route by spec:
#      - Switch-controlled fixtures (LightToggle.subscribe_to_switch=true,
#        the four ceiling/Cellar SKUs) re-run their switch subscription so
#        their state matches the shelter's vanilla Light_Switch.
#      - Manual fixtures (Floor Lamp, PC) stay off; player turns them on
#        with the Use action.
#      - Fire fixtures (Candle, Lantern) stay off; player ignites with Use.
#      - Always-on fixtures with no toggle (Exit Sign) restore preview
#        visibility so they re-light themselves.
#
#    The cancel-to-catalog path (Catalog -> owner.queue_free) needs no
#    handling — the whole scene is freed.
#
# 2. Surface-orientation gate — when `ceiling_only = true`, placement is
#    rejected if the center ray's hit surface normal points more "up" than
#    "down" (i.e. it's a floor, not a ceiling). Catches the common case of
#    a player aiming a ceiling fixture at a normal solid floor (e.g. cabin
#    floor): the lamp would otherwise clip into the floor because the mesh
#    hangs DOWN from the scene origin.
#
#    Edge case: floors with empty space below them (e.g. the attic's plank
#    floor) defeat this check — rays pass through the gaps and either miss
#    surfaces entirely or hit floor-undersides with flipped normals. The
#    failure mode is benign (lamp clips under floor but is still pickable),
#    so we accept it rather than chase the edge.

@export var ceiling_only := false

var _preview_hidden: Array[Node3D] = []

# Lazy collection: don't walk the tree during _ready (sibling-subtree
# ordering with the LightToggle script on the scene root made the array
# end up empty in some catalog-spawn paths, causing StartMove's hide call
# to no-op). Walk on first StartMove instead — by then the tree is fully
# constructed and Placer has just called us.
func _ensure_preview_hidden_collected() -> void:
    if !_preview_hidden.is_empty():
        return
    _collect_preview_hidden_into(_preview_hidden, owner)

func _collect_preview_hidden_into(out: Array[Node3D], node: Node) -> void:
    if node == null:
        return
    for child in node.get_children():
        if child is Light3D:
            out.append(child)
        elif child is Node3D and child.name == "Bulb":
            out.append(child)
        _collect_preview_hidden_into(out, child)

func StartMove() -> void:
    super()
    _ensure_preview_hidden_collected()
    # Only hide the preview-visible nodes (Light3D + Bulb). Don't call
    # Deactivate here — it would re-apply the swap material to swap_mesh,
    # overwriting the green hologram that vanilla super.StartMove() just
    # set on the same surface. The fixture LOOKS off during placement
    # because Light3D nodes are hidden; we'll commit the actual off-state
    # in ResetMove after super.ResetMove restores sourceMaterials.
    _set_preview_visible(false)

func ResetMove() -> void:
    super()
    var root = owner
    if root == null:
        _set_preview_visible(true)
        return

    # Force the fixture off after placement (1.1.0 behavior). super.ResetMove
    # just restored sourceMaterials including the LIT swap variant where
    # applicable, so we re-apply Deactivate to put the swap surface back to
    # the off material AND hide lights.
    #
    # An earlier 1.2.0 build tried to "restore from sidecar" here so that
    # picking up and re-placing a lit fixture preserved its state. That
    # caused two bugs: (1) on PC, the swap-mesh material and Light3D
    # visibility could desync because the deferred sidecar read in
    # LightToggle._ready raced the placement preview hide; (2) a sidecar
    # entry left behind by a previous fixture at the same position would
    # latch onto a freshly-placed different fixture. Simpler design wins:
    # every commit defaults to off, the sidecar entry gets overwritten with
    # false, and stale entries can't leak across fixtures.
    if root.has_method("Deactivate"):
        root.Deactivate()

    # Switch-controlled fixtures (Cellar, Industrial/Bright/Soft Fluo)
    # immediately re-sync to the shelter's vanilla Light_Switch via the
    # subscription path, which calls Activate or Deactivate to match.
    if "subscribe_to_switch" in root and root.subscribe_to_switch \
            and root.has_method("_try_subscribe_to_switch"):
        root._try_subscribe_to_switch()
        return

    # No toggle and no fire (Exit Sign): restore preview visibility so
    # the always-on light re-illuminates the scene.
    if "active" not in root:
        _set_preview_visible(true)

func _set_preview_visible(value: bool) -> void:
    for n in _preview_hidden:
        if is_instance_valid(n):
            n.visible = value

# Override vanilla CheckRays() — call super to do the standard collision
# check, then for ceiling-only fixtures additionally reject any surface
# whose normal points strongly upward (i.e. a floor). 0.5 threshold is
# ~60° off vertical — walls (n.y near 0) and ceilings (n.y near -1) pass;
# floors (n.y near +1) get rejected.
func CheckRays() -> void:
    super.CheckRays()
    if !raysValid or !ceiling_only:
        return
    var center_ray = rays.get_child(0)
    if center_ray and center_ray.is_colliding():
        var n: Vector3 = center_ray.get_collision_normal()
        if n.y > 0.5:
            raysValid = false
