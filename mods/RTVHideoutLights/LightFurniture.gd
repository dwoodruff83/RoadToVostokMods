extends Furniture

# Furniture subclass for light fixtures. Adds placement-preview light
# suppression: when the player picks up the lamp to move it (StartMove),
# every Light3D descendant of the scene root is hidden so the unplaced
# lamp doesn't bleed light into the room. Restored on ResetMove. The
# cancel-to-catalog path (Catalog -> owner.queue_free) needs no handling
# since the whole scene is freed.

var _placement_lights: Array[Light3D] = []

func _ready() -> void:
    super()
    if Engine.is_editor_hint():
        return
    _placement_lights.clear()
    _collect_lights_into(_placement_lights, owner)

func _collect_lights_into(out: Array[Light3D], node: Node) -> void:
    if node == null:
        return
    for child in node.get_children():
        if child is Light3D:
            out.append(child)
        _collect_lights_into(out, child)

func StartMove() -> void:
    super()
    _set_lights_visible(false)

func ResetMove() -> void:
    super()
    _set_lights_visible(true)

func _set_lights_visible(value: bool) -> void:
    for light in _placement_lights:
        if is_instance_valid(light):
            light.visible = value
