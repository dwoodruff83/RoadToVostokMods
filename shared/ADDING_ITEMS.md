# Adding Custom Items to Road to Vostok

A complete guide to adding a new inventory-carryable, droppable, pickupable 3D
item to the game via a mod. Based on the Cat Food Bowl implementation in the
CatAutoFeed mod.

Covers: inventory registration, icon & 2D tetris sprite, 3D world scene with a
Sketchfab GLB, auto-generated collision, Godot import metadata packaging,
Database injection so drops/loot/traders can resolve the item, and testing via
save-file editing.

---

## Overview — the 6 files per item

For each item you want the game to accept, you need these files in your mod:

| File | Location | Purpose |
|---|---|---|
| `MyItem.tres` | mod root | **ItemData** — stats, name, size, rarity, loot flags, references the icon + tetris scene |
| `MyItem_NxM.tscn` | mod root | **Tetris/inventory sprite** — 2D scene shown in the inventory grid |
| `MyItem.tscn` | mod root | **World scene** — RigidBody3D with Pickup script, mesh, collision |
| `assets/icons/MyItem.png` | mod assets | Inventory icon, 128 px × each grid cell (see below) |
| `assets/models/MyItem.glb` | mod assets | 3D mesh (from Blender, Sketchfab, etc.) |
| `assets/icons/MyItem.png.import` + `.godot/imported/*` | generated | Godot's compiled texture metadata — **must ship in the VMZ** |

Plus one-time infrastructure shared by all your items:

- `BowlPickup.gd` (or generic `ModPickup.gd`) — extends `Pickup`, auto-generates collision from mesh
- `DatabaseInject.gd` — extends `Database.gd`, adds preload consts for every new item
- A `_inject_database()` call in your mod's `Main.gd._ready()`

---

## Step 1 — Icon (128 × N per grid cell)

RTV's inventory icons are **N × 128 pixels**, where N is the item's grid size.

| Item size | Icon resolution |
|---|---|
| 1×1 | 128 × 128 |
| 2×2 | 256 × 256 |
| 6×2 (rifle) | 768 × 256 |

Examples to match for style:
- `reference/RTV_decompiled/Items/Consumables/Cat_Food/Files/Icon_Cat_Food.png`
- `reference/RTV_decompiled/Assets/Cabinet_Medical/Files/Icon_Cabinet_Medical.png`

**Style conventions:**
- Photorealistic product shot, transparent background (PNG RGBA)
- Slight 3/4 angle for small items (cans); more top-down for flat items (bowls, plates)
- Item fills ~85% of the frame with a soft shadow beneath
- White / neutral studio HDRI lighting (no warm tint) — matches vanilla

### Rendering from a Blender scene

1. Import the GLB, delete the default cube
2. Use the default camera + delete the default light
3. World Properties → Surface → add Environment Texture → load a neutral studio HDRI (download free from polyhaven.com, 1K is plenty)
4. Set Strength to 0.3–0.5 for clean whites without blown-out highlights
5. Output Properties → Resolution 1024 × 1024, Format PNG, Color RGBA
6. Render Properties → Cycles, Sampling Max Samples 256, Denoise on
7. Render (F12), save as `MyItem_1024.png` (master)
8. Downscale to target resolution (128, 256, etc.) in Photopea: Image Size, Bicubic, save as `MyItem.png`
9. Keep the master (`*_1024.png`) in the mod's icons folder but exclude it from the VMZ (see build.py below)
10. Save the .blend outside the mod folder — `sources/MyItem/MyItem.blend` — so it never gets packed

---

## Step 2 — ItemData .tres

Text-editable resource defining how the item behaves in inventory, trader, and
loot pools. Reference: `reference/RTV_decompiled/Items/Consumables/Cat_Food/Cat_Food.tres`.

Example for a 2×2 item:

```
[gd_resource type="Resource" script_class="ItemData" format=3]

[ext_resource type="Texture2D" path="res://mods/MyMod/assets/icons/MyItem.png" id="1"]
[ext_resource type="Script" path="res://Scripts/ItemData.gd" id="2"]
[ext_resource type="PackedScene" path="res://mods/MyMod/MyItem_2x2.tscn" id="3"]

[resource]
script = ExtResource("2")
file = "MyItem"
name = "My Item"
inventory = "My Item"
rotated = "My Item"
equipment = "My Item"
display = "MyItem"
type = "Furniture"
weight = 0.5
value = 150
rarity = 1
icon = ExtResource("1")
tetris = ExtResource("3")
size = Vector2(2, 2)
civilian = true
```

**Field notes:**
- `file` — must match the const name you'll add to DatabaseInject.gd (see step 7)
- `type` — `"Furniture"`, `"Consumables"`, `"Valuable"`, `"Weapon"`, `"Ammo"`, `"Medical"`, `"Electronic"`, etc. Drives filtering and tooltips.
- `size` — must match the `_NxM.tscn` file name and icon dimensions
- `rarity` — 0=Common, 1=Rare, 2=Legendary, 3=Null (excluded from loot)
- `civilian` / `industrial` / `military` — loot table flags (which container types can spawn it)
- `generalist` / `doctor` / `gunsmith` / `grandma` — which traders stock it

---

## Step 3 — Tetris / inventory sprite scene

A 2D `Sprite2D` that renders the icon in the inventory grid. File name
**must** be `MyItem_{width}x{height}.tscn` matching `ItemData.size`.

```
[gd_scene format=3]

[ext_resource type="Material" path="res://UI/Effects/MT_Item.tres" id="1"]
[ext_resource type="Texture2D" path="res://mods/MyMod/assets/icons/MyItem.png" id="2"]

[node name="MyItem" type="Sprite2D"]
material = ExtResource("1")
position = Vector2(64, 64)
scale = Vector2(0.5, 0.5)
texture = ExtResource("2")
```

For a 2×2, `position = (64, 64)` centers the sprite in the 128×128 grid area. For a 1×1, use `position = (32, 32)`. For other sizes, center = `(width*32, height*32)`.

After creating, **open the file in the Godot editor and Ctrl+S** to let Godot add the `uid://` to each `ext_resource` line. Missing UIDs cause warnings but usually still work via text-path fallback.

---

## Step 4 — World scene (3D droppable form)

RigidBody3D with `Pickup.gd` script. Loader uses this scene when the item is
dropped, spawned as loot, or re-loaded from a shelter save.

Reference: `reference/RTV_decompiled/Items/Consumables/Cat_Food/Cat_Food.tscn`.

```
[gd_scene format=3]

[ext_resource type="Script" path="res://mods/MyMod/MyPickup.gd" id="1"]
[ext_resource type="PackedScene" path="res://mods/MyMod/assets/models/MyItem.glb" id="2"]
[ext_resource type="Resource" path="res://mods/MyMod/MyItem.tres" id="3"]
[ext_resource type="Script" path="res://Scripts/SlotData.gd" id="4"]
[ext_resource type="PhysicsMaterial" path="res://Items/Physics/Item_Physics.tres" id="5"]

[sub_resource type="Resource" id="Resource_slot"]
script = ExtResource("4")
itemData = ExtResource("3")

[sub_resource type="CylinderShape3D" id="CylinderShape3D_placeholder"]
radius = 0.08
height = 0.06

[node name="MyItem" type="RigidBody3D" node_paths=PackedStringArray("collision") groups=["Item"]]
collision_layer = 4
collision_mask = 29
physics_material_override = ExtResource("5")
script = ExtResource("1")
slotData = SubResource("Resource_slot")
collision = NodePath("Collision")

[node name="GLB" parent="." instance=ExtResource("2")]
transform = Transform3D(0.06, 0, 0, 0, 0.06, 0, 0, 0, 0.06, 0, 0.04, 0)

[node name="Collision" type="CollisionShape3D" parent="."]
shape = SubResource("CylinderShape3D_placeholder")
```

**Key bits:**
- Root is a `RigidBody3D` in group `"Item"` — this group is what `Loader.SaveShelter` iterates to persist items
- `collision_layer = 4, collision_mask = 29` — matches the vanilla item physics mask
- `physics_material_override` — reuse the game's Item_Physics.tres for consistent friction/bounce
- `slotData` — inline SubResource pointing at your ItemData
- `GLB` child instances the .glb directly. `transform`'s scale (0.06 here) controls item world size — tune until it looks right next to vanilla items.
- Placeholder cylinder collision — the Pickup script will replace it with an auto-generated one at runtime (step 5)

---

## Step 5 — Pickup wrapper with auto-collision

Sketchfab GLBs often have baked-in transforms (multi-layer rotate + scale
stacks) that make hand-authored collision shapes finicky. This wrapper script
generates a convex hull from the mesh at runtime, guaranteeing the physics
volume matches the visible mesh.

```gdscript
extends Pickup

# Auto-wires Pickup.mesh to the GLB's MeshInstance3D and generates a convex
# collision hull from the mesh geometry. Saves hand-tuning shape positions.

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
        # clean=true, simplify=false — keep every hull vertex so the shape
        # fully envelops the mesh (no clipping through floors/tables).
        var convex := mesh_inst.mesh.create_convex_shape(true, false)
        if convex:
            collision.shape = convex
            collision.global_transform = mesh_inst.global_transform
    super()
```

**Why not a MeshLibrary or trimesh collision?** `ConcavePolygonShape3D` would match the bowl interior precisely but only works for static bodies — RTV items are RigidBody3D (dynamic). Convex is the only option that produces a dynamic body with geometry-matching collision.

**Convex means solid hull** — if your item's hollow interior matters (e.g. stacking items *inside* a bowl with physics), you'll need multiple separate ConvexPolygonShape3D children (rim + walls + base as separate shapes). For decor/display items, a single convex envelope is fine.

---

## Step 6 — Database injection

`Interface.Drop()`, `Loader.LoadShelter()`, `Spawner`, `Trader`, and anything
else that needs to spawn items in the world calls `Database.get(file_name)`.
`Database` is a vanilla autoload with a long list of `const` preloads —
`const Cat_Food = preload("res://Items/Consumables/Cat_Food/Cat_Food.tscn")`.
Your new items aren't in that list, so the game doesn't know how to spawn them.

**The symptom:** dropped item disappears. Log shows
`File not found: <ItemData.name>`.

> **Recommended (Metro Mod Loader v3.0+):** declare `[registry]` in your
> `mod.txt` and call `Engine.get_meta("RTVModLib").register(lib.Registry.SCENES, "MyItem", preload(...))`.
> Metro wraps `Database.gd` once at loader startup before any user mod runs,
> so multiple item-adding mods coexist without clobbering each other. See
> Metro's [Registry docs](https://github.com/ametrocavich/vostok-mod-loader/blob/development/docs/wiki/Registry.md)
> and CatAutoFeed / RTVWallets for working examples.
>
> The `take_over_path` + `DatabaseInject.gd` pattern below still works for
> single-mod setups but is the legacy approach — last loader wins, breaking
> when multiple item-adding mods are installed together.

### The fix (legacy, single-mod setups)

Create `DatabaseInject.gd` in your mod that extends `Database.gd` and adds
consts for every item:

```gdscript
extends "res://Scripts/Database.gd"

const MyItem = preload("res://mods/MyMod/MyItem.tscn")
const MyOtherItem = preload("res://mods/MyMod/MyOtherItem.tscn")
```

In your mod's `Main.gd._ready()`:

```gdscript
func _ready() -> void:
    name = "MyMod"
    _inject_database()

func _inject_database() -> void:
    var inject = load("res://mods/MyMod/DatabaseInject.gd")
    if inject == null:
        push_error("MyMod: could not load DatabaseInject.gd")
        return
    inject.reload()
    inject.take_over_path("res://Scripts/Database.gd")

    # take_over_path only affects future load() calls — the already-running
    # Database autoload keeps its original script. Swap our extended script
    # onto the live instance so Database.get("MyItem") resolves immediately.
    var db = get_node_or_null("/root/Database")
    if db == null:
        db = get_tree().root.find_child("Database", true, false)
    if db:
        db.set_script(inject)
```

**Both steps matter:**
- `take_over_path` — future loads (scripts that reload `Database.gd`) get your version
- `set_script` — the live autoload node picks up your consts immediately

### Conflict note (multiple mods injecting)

If two mods both call `take_over_path` on Database, the last one wins and the
first mod's items silently stop working. Mods that do this need to chain:
each mod's `DatabaseInject.gd` should extend the *previous* injector if
another exists. For now, there's no standard convention — document any
item injection in your mod README so users don't install conflicting mods.

---

## Step 7 — build.py packaging

The VMZ must contain:
- `mod.txt` at root
- `mods/MyMod/*.gd`, `*.tres`, `*.tscn` at their paths
- `mods/MyMod/assets/**/*.png`, `*.glb`
- `mods/MyMod/assets/**/*.png.import` and `*.glb.import` — Godot import directives
- `.godot/imported/**/*.ctex`, `*.md5`, `*.scn` — pre-compiled textures and meshes

The `.import` files and `.godot/imported/` files are generated by opening the
mod folder inside a Godot editor project (use the decompiled RTV project as a
workbench: `reference/RTV_decompiled/project.godot`). Godot auto-creates them
when you click each asset in the FileSystem dock.

**Copy them back to your workspace mod** before building:

```bash
cp reference/RTV_decompiled/mods/MyMod/assets/icons/*.import mods/MyMod/assets/icons/
cp reference/RTV_decompiled/mods/MyMod/assets/models/*.import mods/MyMod/assets/models/
mkdir -p mods/MyMod/.godot/imported
cp reference/RTV_decompiled/.godot/imported/MyItem* mods/MyMod/.godot/imported/
```

### build.py skeleton

Here's the packaging logic — adapt to your mod:

```python
MOD_ID = "MyMod"
ROOT_FILES = ["mod.txt", "README.md", "CHANGELOG.md", "NOTICES.txt", "LOGGER.md"]
MOD_FILES = [
    "Main.gd", "config.gd", "Logger.gd",
    "MyPickup.gd", "DatabaseInject.gd",
    "MyItem.tres", "MyItem_2x2.tscn", "MyItem.tscn",
]
ASSET_DIRS = ["assets"]

with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as z:
    for f in ROOT_FILES:
        if (src_dir / f).exists():
            z.write(src_dir / f, arcname=f)
    for f in MOD_FILES:
        z.write(src_dir / f, arcname=f"mods/{MOD_ID}/{f}")
    for asset_dir in ASSET_DIRS:
        for path in sorted((src_dir / asset_dir).rglob("*")):
            if not path.is_file(): continue
            if path.name.startswith("."): continue
            if "_1024" in path.name or "_master" in path.name: continue  # skip render masters
            if path.suffix.lower() in {".blend", ".blend1", ".psd", ".xcf"}: continue
            rel = path.relative_to(src_dir)
            z.write(path, arcname=f"mods/{MOD_ID}/{rel.as_posix()}")
    # Include .godot/imported/ — critical for PNG → Texture2D resolution at runtime
    godot_imported = src_dir / ".godot" / "imported"
    if godot_imported.is_dir():
        for path in sorted(godot_imported.rglob("*")):
            if not path.is_file(): continue
            rel = path.relative_to(src_dir)
            z.write(path, arcname=rel.as_posix())
```

---

## Step 8 — Testing via save-file injection

For rapid iteration, skip the trader/loot-table wiring and drop items straight
into the player's inventory by editing `%APPDATA%\Road to Vostok\Character.tres`
(with the game closed).

Three edits:

**1.** Add an ext_resource before the `CharacterSave.gd` script line:

```
[ext_resource type="Resource" path="res://mods/MyMod/MyItem.tres" id="31"]
[ext_resource type="Script" path="res://Scripts/CharacterSave.gd" id="30"]
```

(Pick an id number higher than existing ones — doesn't matter if out of order, the game renumbers on re-save.)

**2.** Add a sub_resource (SlotData) just before `[resource]`:

```
[sub_resource type="Resource" id="Resource_myitem1"]
script = ExtResource("1")
itemData = ExtResource("31")
nested = Array[ExtResource("3")]([])
storage = Array[ExtResource("1")]([])
condition = 100
amount = 0
position = 0
mode = 1
zoom = 1
chamber = false
casing = false
state = ""
gridPosition = Vector2(0, 128)
gridRotated = false
slot = ""
```

Pick an empty `gridPosition` by checking existing SubResources — 64 pixels per grid cell, rows usually `y=0, 64, 128, 192`. Placing a 2×2 item at `(0, 128)` occupies cells y=128–256 in the 2×2 footprint.

**3.** Append the SubResource to the inventory array:

```
inventory = Array[ExtResource("1")]([SubResource("Resource_xxx"), ..., SubResource("Resource_myitem1")])
```

Launch the game — the item should appear in your inventory. Drop it to test
the world scene + pickup. If the save fails to load or the item disappears on
drop, check the log (`%APPDATA%\Road to Vostok\logs\godot.log`) for specific
error lines.

---

## Troubleshooting

### `ERROR: Cannot open file 'res://mods/MyMod/MyItem.tres'`
VMZ doesn't contain `MyItem.tres`. Check `MOD_FILES` in `build.py`.

### `ERROR: No loader found for resource: ...png (expected type: Texture2D)`
`.import` file or `.godot/imported/*.ctex` is missing from the VMZ. Copy them
from the decompiled workbench and ensure `build.py` packs them.

### `File not found: <item display name>` on drop (item disappears)
`Database.get("MyItem")` returned null. Either:
- `_inject_database()` didn't run (check for the startup log message)
- Item isn't in `DatabaseInject.gd` (add `const MyItem = preload(...)`)
- Live autoload's script wasn't swapped (verify `set_script` call on `/root/Database`)

### Item sinks into the floor / table
Placeholder collision is too shallow or offset. Use the auto-convex wrapper
(step 5) and ensure GLB instance has a reasonable scale. If still clipping,
check the log for script errors — `create_convex_shape` returns null if the
mesh doesn't have valid vertex data.

### Item too big / too small
Adjust the GLB's transform scale in the world scene. Sketchfab imports are
typically huge; 0.06–0.1 is a good starting range for consumer-sized items.

### `Parse Error: [ext_resource] referenced non-existent resource at: ...tres`
Path typo, or the file isn't in the VMZ. Confirm paths match VMZ contents.

### Save fails to load after inventory edit
Usually a missing resource reference in `Character.tres`. Revert your edit
(or restore from `save_backups/`) and re-add with more care. Ensure the
ext_resource id you reference from the sub_resource matches the declared id.

---

## Iteration rhythm

1. Edit source files in `mods/MyMod/`
2. `python build.py --install` — rebuilds VMZ and copies to the game's mods folder
3. If icon/scene content changed — reopen the file in Godot editor + Ctrl+S so it regenerates import metadata; copy `.import` files back
4. Launch game, test
5. Check `%APPDATA%\Road to Vostok\logs\godot.log` for errors (filter by your mod's log prefix via the logger)
6. Repeat

Keep a **save backup** workflow (see `tools/save_backup.py`) so mistakes during
testing don't cost you a real run.

---

## Reference implementations

- **CatAutoFeed / Cat Food Bowl** — single 2×2 decor/storage item, uses the full pattern above
- **RTV Wallets / Wallet + Ammo Tin + Money Case** — multiple item variants sharing a tier schema

## License note

When shipping items that use third-party models (Sketchfab, etc.), include a
`NOTICES.txt` with the CC attribution lines and ship it in your VMZ root. See
CatAutoFeed's `NOTICES.txt` for an example.
