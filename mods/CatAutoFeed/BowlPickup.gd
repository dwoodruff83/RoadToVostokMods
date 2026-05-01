extends Pickup

# Cat Food Bowl pickup — extends the vanilla Pickup so the RigidBody3D behaves
# like any other droppable item, while adding a content-management panel
# (BowlContentsPanel.gd) when the bowl is placed in the world with food.
#
# Storage model: bowl.slotData.storage is an Array[SlotData] where each entry
# represents one cat-edible food type (Cat_Food, Canned_Meat, Canned_Tuna,
# Perch) and its current count. Vanilla save/load already serializes
# slotData.storage on a Pickup, so contents persist through inventory ↔
# placed-in-shelter transitions for free.

const PANEL_SCRIPT_PATH := "res://mods/CatAutoFeed/BowlContentsPanel.gd"
const FOOD_NAMES := ["Cat_Food", "Canned_Meat", "Canned_Tuna", "Perch"]
const MAX_SERVINGS := 10

# Y of the bowl mesh's lowest point in RB-local space, captured during
# collision setup. Used by the clip-correction code to compute where the
# bowl's RB origin should sit so the visual bottom rests on the surface.
var _bowl_bottom_offset_y: float = 0.0

# Periodic clip check: every CLIP_CHECK_INTERVAL seconds, if the bowl is at
# rest, raycast down to verify it's not slowly sinking into a surface.
const CLIP_CHECK_INTERVAL := 0.5
var _clip_check_timer := 0.0

func _ready() -> void:
    # Heal save-data bowls written before the local_to_scene fix landed:
    # those bowls' SlotData was serialized while shared, so multiple bowls in
    # the same save can still point to the same SlotData object on load even
    # with the .tscn-side fix in place. Duplicate it here so each bowl ends
    # up with its own storage going forward. One-shot per bowl per save —
    # subsequent loads see resource_local_to_scene = true and skip.
    if slotData != null and not slotData.resource_local_to_scene:
        slotData = slotData.duplicate(true)
        slotData.resource_local_to_scene = true

    # Enable continuous collision detection so a fast-thrown bowl can't
    # tunnel through the table between physics ticks. Discrete CD samples
    # at fixed intervals and can miss overlaps when the bowl traverses
    # more than its own thickness in one step (which happens easily with
    # a player-tossed item).
    continuous_cd = true

    # Lock pitch/roll rotation. Works in tandem with the spawn-Y correction
    # below: when a bowl spawns slightly clipped, physics needs to resolve
    # the penetration. Without this lock, the solver applies both linear
    # AND angular forces, and the bowl can tip-and-wedge itself further
    # into the surface instead of climbing out. With rotation pinned to
    # yaw-only, the only resolution path is upward translation, which is
    # what we want. Mild loss of "throw it hard and watch it tumble"
    # realism is acceptable for a placeable item.
    axis_lock_angular_x = true
    axis_lock_angular_z = true

    var meshes := find_children("*", "MeshInstance3D", true, false)
    var mesh_inst: MeshInstance3D = meshes[0] if meshes.size() > 0 else null

    if mesh_inst and collision and mesh_inst.mesh:
        # Build a snug cylinder collision from the actual mesh AABB. The
        # .tscn-defined placeholder shape is a stand-in for editor preview;
        # the bowl's real shape is closer to a cylinder than a box, so a
        # cylinder hugs it more tightly while still being a simple primitive.
        _setup_cylinder_collision_from_aabb(mesh_inst)

    if mesh_inst:
        var base_mat := mesh_inst.get_active_material(0)
        if base_mat is StandardMaterial3D:
            var tinted: StandardMaterial3D = base_mat.duplicate()
            tinted.albedo_color = tinted.albedo_color.darkened(0.45)
            # Bypass mipmaps to suppress dark-seam artifacts that appear at
            # distance. The artifacts come from S3TC compression blocks baked
            # into the lower mip levels of the GLB's embedded texture — no
            # texture-filter setting (anisotropic, etc.) can mask them
            # because the dark pixels are in the mip data itself. Sampling
            # the full-resolution texture at all distances avoids the
            # compressed lower mips entirely. Trade-off: mild aliasing at
            # the bowl rim when viewed from a few metres. Bowl is small in
            # screen space at that range and the aliasing is barely visible.
            #
            # A cleaner future fix would be to re-import the GLB's embedded
            # texture as lossless (no S3TC), which preserves working
            # mipmaps. Tracked separately as a follow-up.
            tinted.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
            mesh_inst.material_override = tinted
        mesh_inst.visibility_range_end = 0
        _smooth_mesh_normals(mesh_inst)

    # Tiny invisible proxy MeshInstance3D for vanilla Placer's get_aabb()
    # call — without it, Placer would see the GLB's raw Sketchfab mesh
    # bounds (source units render as tens of metres in Godot), mis-position
    # the bowl on placement, and the resulting offset between visual and
    # collision causes the bowl to intermittently clip through surfaces.
    # Same proxy trick used by the RTV Wallets mod.
    var proxy := MeshInstance3D.new()
    proxy.name = "MeshProxy"
    var proxy_box := BoxMesh.new()
    proxy_box.size = Vector3(0.16, 0.07, 0.16)
    proxy.mesh = proxy_box
    proxy.visible = false
    add_child(proxy)
    mesh = proxy

    # After vanilla setup finishes, verify our spawn Y isn't below the
    # surface beneath us — vanilla Placer occasionally mis-positions the
    # bowl on fast upright placements, baking the bowl into the table.
    # Deferred so the bowl is fully in the scene tree when the raycast runs.
    call_deferred("_correct_spawn_position")

    super()
    _recompute_amount()

# Always open the management panel on interact. The panel handles add/remove
# and exposes a "Pick up bowl" button (enabled only when empty) — needed even
# for an empty bowl, otherwise the player has no way to ever fill one.
func Interact() -> void:
    _open_panel()

# Direct pickup that bypasses the panel-opening Interact() override. Called
# by BowlContentsPanel's "Pick up bowl" button — invoking Interact() there
# would just re-open the panel. Logic mirrors vanilla Pickup.Interact().
func do_pickup() -> void:
    if interface == null:
        return
    if interface.AutoStack(slotData, interface.inventoryGrid):
        interface.UpdateStats(false)
        PlayPickup()
        queue_free()
    elif interface.Create(slotData, interface.inventoryGrid, false):
        interface.UpdateStats(false)
        PlayPickup()
        queue_free()
    else:
        interface.PlayError()

# Surface contents + capacity in the look-at tooltip so the player can tell
# at a glance how full the bowl is before opening the panel.
func UpdateTooltip() -> void:
    var item_name: String = String(slotData.itemData.name)
    var n: int = total_servings()
    if n > 0:
        gameData.tooltip = "%s (%d/%d)" % [item_name, n, MAX_SERVINGS]
    else:
        gameData.tooltip = item_name

# --- Storage helpers (used by BowlContentsPanel and the cat-feed loop) ---

func is_empty() -> bool:
    return total_servings() == 0

func is_full() -> bool:
    return total_servings() >= MAX_SERVINGS

func capacity() -> int:
    return MAX_SERVINGS

func total_servings() -> int:
    if slotData == null:
        return 0
    var total := 0
    for sd in slotData.storage:
        if sd != null:
            total += int(sd.amount)
    return total

# Returns Array of {item_data, amount} dicts for non-empty entries, sorted by
# the FOOD_NAMES priority order so the cat eats Cat_Food before Perch.
func contents_breakdown() -> Array:
    var out: Array = []
    if slotData == null:
        return out
    for fname in FOOD_NAMES:
        for sd in slotData.storage:
            if sd != null and sd.itemData != null and sd.amount > 0 and String(sd.itemData.file) == fname:
                out.append({"item_data": sd.itemData, "amount": int(sd.amount)})
                break
    return out

# Add one unit of item_data to the bowl. Returns true if accepted; false if
# rejected because the food isn't on the whitelist or the bowl is full.
# Items are matched by the `file` string rather than Resource identity, since
# the same logical item (e.g. Cat_Food.tres) can load as distinct Resource
# instances across save/load, mod injection, and database lookups.
func add_food(item_data) -> bool:
    if slotData == null or item_data == null:
        return false
    var key := String(item_data.file)
    if not (key in FOOD_NAMES):
        return false
    if is_full():
        return false
    for sd in slotData.storage:
        if sd != null and sd.itemData != null and String(sd.itemData.file) == key:
            sd.amount = int(sd.amount) + 1
            _recompute_amount()
            return true
    var new_slot := SlotData.new()
    new_slot.itemData = item_data
    new_slot.amount = 1
    slotData.storage.append(new_slot)
    _recompute_amount()
    return true

# Remove one unit of item_data and return a fresh SlotData ready to be added
# back to the player's inventory grid (or null if not present). For
# non-stackable consumables (Cat_Food, Perch, etc.) we mirror vanilla and
# leave the new slot's amount at 0; only stackable items carry a count.
func take_food(item_data) -> SlotData:
    if slotData == null or item_data == null:
        return null
    var key := String(item_data.file)
    for i in range(slotData.storage.size()):
        var sd: SlotData = slotData.storage[i]
        if sd != null and sd.itemData != null and String(sd.itemData.file) == key and sd.amount > 0:
            var taken := SlotData.new()
            taken.itemData = sd.itemData
            taken.amount = 1 if bool(sd.itemData.stackable) else 0
            sd.amount = int(sd.amount) - 1
            if sd.amount <= 0:
                slotData.storage.remove_at(i)
            _recompute_amount()
            return taken
    return null

# slotData.amount drives the inventory badge ("x3"). Keep it in sync with the
# total of all stored entries so the count is accurate when carrying a bowl.
func _recompute_amount() -> void:
    if slotData != null:
        slotData.amount = total_servings()

func _correct_spawn_position() -> void:
    var lift := _compute_lift_to_clear_surface()
    if lift > 0.0:
        global_position.y += lift

# Periodic clip correction. Same raycast as the spawn check, but runs while
# the bowl is at rest — if vanilla physics has let the bowl drift slowly
# into a surface (residual penetration that the solver can't fully resolve
# tick-by-tick), lift it back out and zero linear velocity so it stays put.
func _physics_process(delta: float) -> void:
    _clip_check_timer -= delta
    if _clip_check_timer > 0.0:
        return
    _clip_check_timer = CLIP_CHECK_INTERVAL
    # Skip during placement and inventory-held states. Vanilla Pickup uses
    # three states (see Pickup.gd):
    #   - Freeze(): freeze=true, mode=STATIC — bowl is parked / pre-placement
    #   - Kinematic(): freeze=false, mode=KINEMATIC — placement preview, the
    #     player is positioning via aim/scroll/middle-click
    #   - Unfreeze(): freeze=false, mode=STATIC — physics-active or settled
    # We only want to clip-correct in the Unfreeze state. Running the raycast
    # during placement would snap the bowl to whatever surface is beneath
    # the current aim point, ignoring where the player intends to place it.
    if freeze or freeze_mode == FREEZE_MODE_KINEMATIC:
        return
    # Only correct while at rest — a bowl mid-flight is legitimately moving
    # through space and shouldn't be teleported.
    if linear_velocity.length_squared() > 0.0025:  # > 5cm/s
        return
    var lift := _compute_lift_to_clear_surface()
    if lift > 0.0:
        global_position.y += lift
        linear_velocity = Vector3.ZERO

# Cast a short vertical ray from just above the bowl down past where the
# bowl is sitting; if we find a static surface, return the upward distance
# the RB origin needs to move so the bowl's visual bottom is at-or-above
# the surface (with a 2mm safety margin). Returns 0 if no correction needed.
func _compute_lift_to_clear_surface() -> float:
    if not is_inside_tree():
        return 0.0
    var space := get_world_3d().direct_space_state
    if space == null:
        return 0.0
    var origin := global_position
    var query := PhysicsRayQueryParameters3D.create(
        origin + Vector3(0, 0.5, 0),
        origin + Vector3(0, -0.5, 0)
    )
    query.exclude = [self.get_rid()]
    var result := space.intersect_ray(query)
    if result.is_empty():
        return 0.0
    var surface_y: float = result.position.y
    # Reject hits that are obviously too far above the bowl. The ray starts
    # 0.5m above origin to handle the "buried in surface" case, but if there
    # is a shelf or other surface within that 0.5m above the bowl the ray
    # finds it first and lifts the bowl onto it. A buried bowl's surface
    # sits at most a few cm above its origin (bowls are ~7cm tall); anything
    # farther is a different surface we don't want to teleport onto.
    if surface_y - origin.y > 0.10:
        return 0.0
    # Bowl visual bottom in world space = rb_origin.y + _bowl_bottom_offset_y.
    # For the bowl to rest on the surface, rb_origin.y should equal
    # surface_y - _bowl_bottom_offset_y. Add 2mm so the bowl is just above.
    var desired_y := surface_y - _bowl_bottom_offset_y + 0.002
    var lift := max(0.0, desired_y - origin.y)
    # Skip sub-5mm corrections — the physics solver self-resolves shallow
    # penetration tick-by-tick, and our half-second lift fights the solver
    # when the bowl is touching another item that nudges it microscopically
    # each tick (visible as a perceptible bump every 0.5s). Real clip-throughs
    # that need our help (the case 1.1.4 originally addressed) are cm-scale.
    if lift < 0.005:
        return 0.0
    return lift

func _open_panel() -> void:
    var panel_script = load(PANEL_SCRIPT_PATH)
    if panel_script == null:
        push_error("[BowlPickup] Could not load BowlContentsPanel.gd")
        return
    # Mount through a high-layer CanvasLayer at the scene root rather than as a
    # child of /root/Map/Core/UI/Interface — Interface toggles `visible=false`
    # during gameplay (it only shows when inventory is open), and Godot
    # propagates that to children, hiding our panel.
    var root = get_tree().current_scene
    if root == null:
        push_warning("[BowlPickup] no current_scene; cannot open panel")
        return
    var canvas := CanvasLayer.new()
    canvas.name = "BowlContentsPanelLayer"
    canvas.layer = 100
    root.add_child(canvas)
    var panel = panel_script.new()
    canvas.add_child(panel)
    panel.open(self)

# --- Mesh / collision setup ---

func _setup_cylinder_collision_from_aabb(mi: MeshInstance3D) -> void:
    if mi.mesh == null or collision == null:
        return
    # AABB is in mesh-local space; transform it into RigidBody-local space.
    var local_aabb: AABB = mi.mesh.get_aabb()
    var mesh_to_rb: Transform3D = global_transform.affine_inverse() * mi.global_transform
    var rb_aabb: AABB = mesh_to_rb * local_aabb

    var cylinder := CylinderShape3D.new()
    # Radius wraps the larger of X/Z half-extents with a small margin so the
    # cylinder slightly overhangs the bowl rim — gives physics resolution
    # some breathing room without looking obviously oversized.
    cylinder.radius = max(max(rb_aabb.size.x, rb_aabb.size.z) * 0.5 * 1.05, 0.01)
    # Height matches full Y extent of the mesh, also with a touch of margin.
    cylinder.height = max(rb_aabb.size.y * 1.05, 0.01)
    collision.shape = cylinder
    collision.position = rb_aabb.get_center()
    collision.rotation = Vector3.ZERO
    collision.scale = Vector3.ONE
    # Cache the AABB's lowest point so _correct_spawn_position() knows
    # where the bowl's visual bottom sits relative to its RB origin.
    _bowl_bottom_offset_y = rb_aabb.position.y

# Sketchfab GLBs often ship with per-face (flat) normals, causing dark polygon
# edges to show up as shading artifacts. Rebuild the surface with smooth
# vertex-averaged normals so the bowl looks continuous.
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
