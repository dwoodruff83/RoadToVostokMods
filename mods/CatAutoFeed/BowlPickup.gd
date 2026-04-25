extends Pickup

# Cat Food Bowl pickup — extends the vanilla Pickup so the RigidBody3D behaves
# like any other droppable item. Auto-wires the `mesh` reference AND generates
# a convex collision shape from the actual mesh geometry, so the bowl's
# physics volume matches its visual shape regardless of the GLB's internal
# transforms / origin quirks.

func _ready() -> void:
    var mesh_inst: MeshInstance3D = null
    if mesh != null:
        mesh_inst = mesh
    else:
        var meshes := find_children("*", "MeshInstance3D", true, false)
        if meshes.size() > 0:
            mesh_inst = meshes[0]
            mesh = mesh_inst

    if mesh_inst and collision and mesh_inst.mesh:
        # Hand-tuned primitives beat auto-generated convex hulls for dropped
        # items in RTV — vanilla uses simple BoxShape3D for every consumable.
        # Compute the mesh's AABB and build a box that exactly encloses it.
        _setup_box_collision_from_aabb(mesh_inst)

    # Tone down the GLB's bright white material so the bowl fits RTV's
    # darker, desaturated environment.
    if mesh_inst:
        var base_mat := mesh_inst.get_active_material(0)
        if base_mat is StandardMaterial3D:
            var tinted: StandardMaterial3D = base_mat.duplicate()
            tinted.albedo_color = tinted.albedo_color.darkened(0.45)
            mesh_inst.material_override = tinted
        mesh_inst.visibility_range_end = 0
        _smooth_mesh_normals(mesh_inst)
    super()

# Sketchfab GLBs often ship with per-face (flat) normals, causing dark polygon
# edges to show up as shading artifacts. Rebuild the surface with smooth
# vertex-averaged normals so the bowl looks continuous.
func _setup_box_collision_from_aabb(mi: MeshInstance3D) -> void:
    if mi.mesh == null or collision == null:
        return
    # AABB is in mesh-local space; transform it into RigidBody-local space.
    var local_aabb: AABB = mi.mesh.get_aabb()
    var mesh_to_rb: Transform3D = global_transform.affine_inverse() * mi.global_transform
    var rb_aabb: AABB = mesh_to_rb * local_aabb

    var box := BoxShape3D.new()
    # Clamp to a minimum size so any zero-thickness AABB axis doesn't produce
    # a degenerate box.
    box.size = Vector3(max(rb_aabb.size.x, 0.01), max(rb_aabb.size.y, 0.01), max(rb_aabb.size.z, 0.01))
    collision.shape = box
    collision.position = rb_aabb.get_center()
    collision.rotation = Vector3.ZERO
    collision.scale = Vector3.ONE

func _smooth_mesh_normals(mi: MeshInstance3D) -> void:
    var old_mesh := mi.mesh
    if old_mesh == null:
        return
    var new_mesh := ArrayMesh.new()
    for surface_idx in range(old_mesh.get_surface_count()):
        var st := SurfaceTool.new()
        st.create_from(old_mesh, surface_idx)
        st.generate_normals()
        st.generate_tangents()
        st.commit(new_mesh)
        var mat := old_mesh.surface_get_material(surface_idx)
        if mat:
            new_mesh.surface_set_material(surface_idx, mat)
    mi.mesh = new_mesh
