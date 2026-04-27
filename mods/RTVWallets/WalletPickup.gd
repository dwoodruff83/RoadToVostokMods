extends Pickup

# Wallet pickup — auto-sizes an axis-aligned BoxShape3D to wrap the visible
# GLB mesh, positioned at the mesh's AABB centre in RigidBody-local space.
# Physics solver then rests the box on surfaces correctly regardless of
# where the GLB's origin is in the model.
#
# A tiny invisible proxy MeshInstance3D is used for Placer's get_aabb()
# call so it doesn't see the raw Sketchfab mesh bounds (tens of metres).

func _ready() -> void:
    var meshes := find_children("*", "MeshInstance3D", true, false)
    if collision and meshes.size() > 0:
        _setup_box_collision_from_combined_aabb(meshes)

    # Sketchfab Euro50 GLB has emissive PBR baked in — looks like a glowing
    # beacon in RTV's dim shelter/loot lighting. Override the materials with
    # dimmed copies (emission off, albedo × 0.5) so cash blends in like loot.
    if _is_cash():
        _dim_meshes(meshes)

    var proxy := MeshInstance3D.new()
    proxy.name = "MeshProxy"
    var proxy_box := BoxMesh.new()
    proxy_box.size = Vector3(0.1, 0.05, 0.1)
    proxy.mesh = proxy_box
    proxy.visible = false
    add_child(proxy)
    mesh = proxy

    super()

func _is_cash() -> bool:
    return slotData != null and slotData.itemData != null \
        and String(slotData.itemData.file) == "Cash"

func _dim_meshes(meshes: Array) -> void:
    for node in meshes:
        var mi := node as MeshInstance3D
        if mi == null or mi.mesh == null:
            continue
        for i in mi.mesh.get_surface_count():
            var src := mi.get_active_material(i)
            if src == null:
                continue
            var dim := src.duplicate()
            if dim is StandardMaterial3D:
                var sm := dim as StandardMaterial3D
                sm.emission_enabled = false
                var a := sm.albedo_color
                sm.albedo_color = Color(a.r * 0.5, a.g * 0.5, a.b * 0.5, a.a)
            mi.set_surface_override_material(i, dim)

# Merges AABBs of every MeshInstance3D under this pickup — many GLBs
# (e.g. wallets) have multiple mesh parts (body + button), and using only
# the first one leaves the rest uncollided and clipping through surfaces.
func _setup_box_collision_from_combined_aabb(meshes: Array) -> void:
    if collision == null:
        return
    var combined: AABB = AABB()
    var have_any := false
    for node in meshes:
        var mi := node as MeshInstance3D
        if mi == null or mi.mesh == null:
            continue
        var local_aabb: AABB = mi.mesh.get_aabb()
        var mesh_to_rb: Transform3D = global_transform.affine_inverse() * mi.global_transform
        var rb_aabb: AABB = mesh_to_rb * local_aabb
        if !have_any:
            combined = rb_aabb
            have_any = true
        else:
            combined = combined.merge(rb_aabb)
    if !have_any:
        return

    var box := BoxShape3D.new()
    box.size = Vector3(max(combined.size.x, 0.01), max(combined.size.y, 0.01), max(combined.size.z, 0.01))
    collision.shape = box
    collision.position = combined.get_center()
    collision.rotation = Vector3.ZERO
    collision.scale = Vector3.ONE
