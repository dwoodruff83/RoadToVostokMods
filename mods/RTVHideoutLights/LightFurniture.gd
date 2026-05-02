extends Furniture

# Furniture subclass for light fixtures. Two behaviours on top of vanilla
# Furniture:
#
# 1. Placement-preview suppression — when the player picks the lamp up to
#    move it (StartMove), every Light3D descendant AND any "Bulb" decoration
#    mesh is hidden so the unplaced lamp doesn't bleed light into the room
#    or show a bright emissive sphere inside the green placement hologram.
#    Restored on ResetMove. The cancel-to-catalog path
#    (Catalog -> owner.queue_free) needs no handling — the whole scene is
#    freed.
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

func _ready() -> void:
    super()
    if Engine.is_editor_hint():
        return
    _preview_hidden.clear()
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
    _set_preview_visible(false)

func ResetMove() -> void:
    super()
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
