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
        _setup_box_collision_from_aabb(mesh_inst)

    if mesh_inst:
        var base_mat := mesh_inst.get_active_material(0)
        if base_mat is StandardMaterial3D:
            var tinted: StandardMaterial3D = base_mat.duplicate()
            tinted.albedo_color = tinted.albedo_color.darkened(0.45)
            mesh_inst.material_override = tinted
        mesh_inst.visibility_range_end = 0
        _smooth_mesh_normals(mesh_inst)
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

# --- Mesh / collision setup (unchanged from previous revision) ---

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
