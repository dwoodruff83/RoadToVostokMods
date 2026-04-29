# RTV Hideout Lights — Mod Plan

Status: **Planning complete, implementation not started.** Last updated 2026-04-28.

## Concept

Extract the light fixtures that already exist baked into Road to Vostok's
world (lamps, sconces, ceiling pendants, candles, braziers — none of
which are placeable furniture in vanilla) and turn them into placeable
hideout furniture. Sold by the Generalist trader, placed via the
existing decor/furniture mode, persisted in the shelter save like any
other furniture.

The mod ships zero new mesh or texture data — it references the game's
existing assets directly. Final `.vmz` size estimated ~310 KB.

---

## 1. Market research (ModWorkshop)

Confirmed via `modworkshop.bat search` against game id 864 on
2026-04-28. Zero competing mods in this niche.

| Search term | Result count | Relevance |
|---|---|---|
| `light` | 5 | All flashlight tweaks / loot highlighters. Zero placeable lights. |
| `lamp` | 0 | — |
| `lighting` | 1 | Outdated weather/sun mod. Not fixtures. |

Closest existing furniture-adjacent mods (none compete):

- LanaOnTheRhoades **Crafting Expansion** (recipes, not placeables)
- Improvise **Shelter Terminal** (UI, not placeables)

Lane is wide open.

---

## 2. Asset inventory — fixtures available in-game

All paths are under `F:\RoadToVostokMods\reference\RTV_decompiled\`.

Each `Assets/<Name>/` folder ships:
- `<Name>.tscn` and/or `<Name>_Lit.tscn` — the scene
- `Files/MS_<Name>.obj` — the mesh (Wavefront OBJ)
- `Files/MT_<Name>.tres` and `MT_<Name>_Lit.tres` — materials (default + lit emissive variant)
- `Files/TX_<Name>_AL.png` — albedo texture
- Sometimes `Files/MS_<Name>_Collider.obj` — separate collision mesh

**Critical: all assets stay at `res://Assets/<Name>/...`. Our mod's
`_F.tscn` files reference those paths directly. We do not bundle a
single byte of mesh, texture, or material — the player already has
them on disk via the game install.**

### Tier A — Lit, ready to ship (4 fixtures, embedded light)

| Fixture | Light type | Notes |
|---|---|---|
| `Lamp_Cellar_Lit` | OmniLight, warm | Bare bulb hanging from cord |
| `Lamp_Grid_Lit` | SpotLight 60°, warm | Industrial fluorescent panel; uses `Light.gd` toggle |
| `Lamp_Generic_Lit_HP` | SpotLight 60°, e=10 | Bright wall bracket; always-on |
| `Lamp_Generic_Lit_LP` | SpotLight 60°, e=5, no fog | Soft wall bracket; uses `Light.gd` toggle |

Light parameters (inherited from vanilla scenes):
- `shadow_enabled = true` universally
- `shadow_normal_bias = 2.0` on SpotLights (no shadow acne)
- `distance_fade_enabled = true` on bracket variants
- Warm color palette: `Color(0.94, 0.90, 0.86)` to `Color(0.94, 0.78, 0.67)`

### Tier B — Flame fixtures, self-animating (4 fixtures)

Embedded `OmniLight3D` extended by `Flicker.gd`:

```gdscript
# Scripts/Flicker.gd — full source
extends OmniLight3D
@export var maxEnergy = 1.0
@export var minEnergy = 1.0
@export var frequency = 0.1
@export var multiplier = 1.0
# ...lerps light_energy to randf_range(minEnergy, maxEnergy) every `frequency` sec
```

| Fixture | Color | Energy | Vibe |
|---|---|---|---|
| `Candle` | Warm cream `Color(0.941, 0.784, 0.667)` | 0.25 (flickers 0.2-0.4) | Tabletop ambient |
| `Lantern_Kerosene` | Warm cream | 0.75 (flickers 0.5-1.0) | Portable / hangable |
| `Firepot` | Orange `Color(1, 0.686, 0.392)` | 1.3 | Floor brazier |
| `Barrel_Metal_Fire` | Orange | 1.35 | Trash-fire barrel |

### Tier C — Prop-only, we add the light ourselves (5+ fixtures)

Mesh exists but no embedded light node. We attach an `OmniLight` or
`SpotLight` ourselves in our `_F.tscn` wrapper.

- `Lamp_Rail` — wall rail lamp (small)
- `Lamp_Rail_Tall` — wall rail lamp (tall)
- `Lamp_Floor` — standing floor lamp
- `Lamp_Round` — round pendant
- `Sauna_Lamp` — wooden sauna fixture
- `Stadium_Light` — large outdoor floodlight

### Tier D — Pole lights (5 fixtures, outdoor)

Same drill as Tier C. Tall outdoor pieces. Best for hideouts with
outdoor footprints.

- `Pole_Light_Concrete`
- `Pole_Light_Metal`
- `Pole_Light_Metal_Double`
- `Pole_Light_Metal_Guard`
- `Pole_Light_Wood`

### Bonus — non-lamp lit assets

Surfaced by grepping for `OmniLight3D|SpotLight3D` in `Assets/`:

- `Sign_Exit_Lit` — green EXIT sign with embedded light
- `Computer_Lit` — CRT monitor with screen glow
- `Light_Switch` — wall switch model (could be paired with toggleable lamps)

### Recommended v1 scope

**Tier A + Tier B = 8 fixtures.** Tier C/D land in v1.1. Bonuses are
flavor pickups for v1.2 if we want.

---

## 3. Bundling strategy

### The big unlock

Every asset we want already exists in the game's PCK at known `res://`
paths. Our mod's `_F.tscn` wrapper references them by absolute path:

```gdresource
[gd_scene load_steps=4 format=3]

# These resolve against the GAME's filesystem at runtime.
[ext_resource type="ArrayMesh" path="res://Assets/Lamp_Cellar/Files/MS_Lamp_Cellar.obj" id="1"]
[ext_resource type="Material" path="res://Assets/Lamp_Cellar/Files/MT_Lamp_Cellar_Lit.tres" id="2"]
[ext_resource type="Script" path="res://Scripts/Furniture.gd" id="3"]

[node name="Lamp_Cellar_Ceiling_F" type="Node3D"]
  [node name="Mesh" type="MeshInstance3D"]
    mesh = ExtResource("1")
    material_override = ExtResource("2")
  [node name="OmniLight3D" type="OmniLight3D"]
    light_color = Color(1, 0.941, 0.863)
    omni_range = 4.0
    shadow_enabled = true
  [node name="Furniture" type="Node3D"]
    script = ExtResource("3")
    # ...indicator, area, parenter, rays, hint
```

### Final mod footprint

| Component | Per SKU | × 11 SKUs | Notes |
|---|---|---|---|
| `_F.tscn` | ~3 KB | ~33 KB | Just the node graph |
| `_F.tres` (ItemData) | ~1 KB | ~11 KB | Pricing, flags, icon ref |
| Tetris grid scene | ~1 KB | ~11 KB | Inventory grid sprite |
| Trader icon PNG (256×256) | ~30 KB | ~330 KB | The only original art we ship |
| Main.gd + Logger.gd + docs | one-time | ~30 KB | |
| **Total `.vmz`** | | **~415 KB** | vs ~50+ MB if shipping meshes |

11 SKUs because some fixtures get multiple mount-orientation variants
(see §7 Placement and §8 Mount Matrix).

### Future-proofing for free

If RTV updates a lamp's texture or material, our furniture inherits the
new look automatically — we point at the live game asset, not a frozen
copy. This is also exactly how vanilla `Furniture` scenes like
`Bed_Civilian_F.tscn` reference their meshes.

### What we do need to ship

**Trader icons.** The 8 fixtures don't have icons because they were
never trader items. We render them ourselves in Godot Editor (Phase 1).
Save at `res://mods/RTVHideoutLights/icons/Icon_*.png`. Existing
furniture icons in `Assets/<Name>/Files/Icon_<Name>.png` are typically
~512×512 PNGs — we'll match that convention, possibly downscaled to
256×256 for inventory grid.

---

## 4. System integration — end-to-end pipeline

The pipeline is **one string** — `itemData.file` — used by every system:

```
ItemData.file = "rtvlights_lamp_cellar"
        │
        ├─→ trader: LT_Master.items[…] flagged generalist=true
        │   └─→ purchase → SlotData{itemData} → catalogGrid
        │       (because Interface.gd:1311 routes type=="Furniture" here)
        │
        └─→ placement: Database.get("rtvlights_lamp_cellar").instantiate()
            └─→ Furniture node, snap, place
                └─→ save: FurnitureSave{file:"rtvlights_lamp_cellar", pos, rot}
                    └─→ load: Database.get("rtvlights_lamp_cellar").instantiate()
                        (same exact call, Loader.gd:817)
```

**Same key, every step. No item-id ↔ furniture-id seam to bridge.**

### Key code references

| File | Lines | What it does |
|---|---|---|
| `reference/RTV_decompiled/Scripts/Database.gd` | 249-289 | Furniture `const` preloads (the lookup table) |
| `reference/RTV_decompiled/Scripts/Trader.gd` | 9 | `LT_Master.tres` reference |
| `reference/RTV_decompiled/Scripts/Trader.gd` | 125-148 | `FillTraderBucket` / `CreateSupply` |
| `reference/RTV_decompiled/Scripts/Interface.gd` | 1311-1314 | Furniture-type purchase routes to catalogGrid |
| `reference/RTV_decompiled/Scripts/Interface.gd` | 1716 | `Database.get(file).instantiate()` for placement |
| `reference/RTV_decompiled/Scripts/Interface.gd` | 2278-2328 | `ContextPlace` (right-click "Place" from catalog) |
| `reference/RTV_decompiled/Scripts/Loader.gd` | 696-785 | `SaveShelter` — serializes furniture |
| `reference/RTV_decompiled/Scripts/Loader.gd` | 815-831 | `LoadShelter` — restores furniture from save |
| `reference/RTV_decompiled/Scripts/Furniture.gd` | (all) | Placement component (rays, snap, area check) |
| `reference/RTV_decompiled/Scripts/Placer.gd` | (all) | Decor + non-decor placement input loop |
| `reference/RTV_decompiled/Scripts/Light.gd` | (all 16 lines) | Vanilla on/off toggle + material swap |
| `reference/RTV_decompiled/Scripts/Flicker.gd` | (all 23 lines) | Self-animating flame light |
| `reference/RTV_decompiled/Scripts/ItemData.gd` | (all) | The shared schema |

### `ItemData` schema

Required fields for our furniture items:

| Field | Type | Value for our lamps |
|---|---|---|
| `file` | String | `"rtvlights_<id>"` (must match registry id, must be the `Database` lookup key) |
| `name` | String | Display + save identity (e.g., `"Cellar Bulb (Ceiling)"`) |
| `inventory` | String | Short label in catalog UI |
| `display` | String | Trader display label |
| `type` | String | Must be `"Furniture"` to route to catalogGrid post-purchase |
| `icon` | Texture2D | Our 256×256 trader icon |
| `tetris` | PackedScene | 2D inventory grid sprite |
| `size` | Vector2 | Inventory grid footprint (e.g., 2×2, 3×3) |
| `orientation` | float | Default Y rotation offset (degrees) |
| `wallOffset` | float | Z-depth snap offset for wall-mount items |
| `weight` | float | Pickup weight |
| `value` | int | Trader price (see §10) |
| `rarity` | int | 4 for furniture (matches Dartboard) |
| `generalist` | bool | `true` to land in Generalist's pool |

### Save schema (existing, no changes needed)

`FurnitureSave.gd`:

```
name: String              # e.g., "Cellar Bulb (Ceiling)"
itemData: ItemData        # full Resource ref (Godot caches by path)
position: Vector3
rotation: Vector3
scale: Vector3
storage: Array[SlotData]  # for containers; empty for lamps
gridPosition: Vector2     # tetris position in catalog
gridRotated: bool
```

Saved into `user://<ShelterName>.tres` (e.g., `user://Cabin.tres`)
under `shelter.furnitures: Array[FurnitureSave]`.

### Save compatibility on uninstall

If the player uninstalls our mod, `LoadShelter` calls
`Database.get("rtvlights_lamp_cellar")` → returns null → prints
`"File missing: ..."` and skips that lamp. **Save is not corrupted.**
Other furniture (vanilla or other mods) loads fine. Standard mod
compatibility behavior.

---

## 5. Metro Mod Loader v3.x — registry integration (🟢 GREEN)

**Verified by reading the Metro source at
`reference/MetroModLoader_source/src/registry/`** — no `take_over_path()`
required. Pure registry path.

### Opt-in (mod.txt)

```ini
[registry]
```

Empty section is enough. Triggers the rewriter to inject
`_rtv_mod_scenes`, `_rtv_override_scenes`, and a custom `_get()` into
`Database.gd` at build time. Without this section, registrations
silently no-op (and the loader fails *loud* with a clear message —
[scenes.gd:30](../reference/MetroModLoader_source/src/registry/scenes.gd#L30)).

Our `scaffold.bat --items` flag already adds this section.

### Four registries we use

| Registry | Purpose | API source |
|---|---|---|
| `SCENES` | Make `Database.get("rtvlights_lamp_cellar")` resolve to our `_F.tscn` | `src/registry/scenes.gd` |
| `ITEMS` | Register our `ItemData` resource; auto-syncs `itemData.file` to id | `src/registry/items.gd` |
| `LOOT` | Append our item into `LT_Master.items` so trader bucket sees it | `src/registry/loot.gd` |
| `TRADER_POOLS` | Flip `item.generalist = true` so it lands in Generalist's stock | `src/registry/traders.gd` |

### Minimum viable Main.gd (4 calls per fixture)

```gdscript
extends Node

func _ready() -> void:
    var lib = Engine.get_meta("RTVModLib")
    await lib.frameworks_ready

    _register_lamp(
        "rtvlights_lamp_cellar_ceiling",
        preload("res://mods/RTVHideoutLights/scenes/Lamp_Cellar_Ceiling_F.tscn"),
        preload("res://mods/RTVHideoutLights/items/Lamp_Cellar_Ceiling_F.tres"),
        "Generalist",
    )
    # ...repeat for each fixture × mount variant

func _register_lamp(id: String, scene: PackedScene, data: ItemData, trader: String) -> void:
    var lib = Engine.get_meta("RTVModLib")
    lib.register(lib.Registry.SCENES,        id, scene)
    lib.register(lib.Registry.ITEMS,         id, data)
    lib.register(lib.Registry.LOOT,          id + "_in_master",
                 {"item": data, "table": "LT_Master"})
    lib.register(lib.Registry.TRADER_POOLS,  id + "_" + trader.to_lower(),
                 {"item": data, "trader": trader})
```

### Critical id-matching constraint

The registry id MUST match between SCENES and ITEMS, AND must equal
`itemData.file`. The Metro registry auto-syncs `data.file = id` at
register time ([items.gd:35-36](../reference/MetroModLoader_source/src/registry/items.gd#L35-L36)),
but we should set `file = "rtvlights_..."` in the `.tres` for clarity.

This is because the placement/load path calls `Database.get(itemData.file)`,
and we registered the SCENE under that same id.

### Timing constraint

Register during mod's `_ready()`. Trader.gd's `_ready()` caches its
bucket from `LT_Master.items` and never re-reads. Mod autoloads load
*before* the first scene, so registering in our mod's `_ready()` is
early enough. `await lib.frameworks_ready` before the first register
call to be safe.

### Conflict semantics

- `register` on a colliding id fails (no silent overwrite). Our
  `rtvlights_` prefix means we won't collide with vanilla.
- Two mods registering different ids into LT_Master both succeed
  (additive append).
- `register('trader_pools', ...)` is idempotent on the bool flag (true OR true = true).

---

## 6. Light behavior — when does it shine?

### Layer 1: lights cannot exist before placement (automatic)

Inventory items are not scene instances — they're `SlotData` resources.
The 3D scene (and the Light3D node inside) only gets instantiated when
the player drags from catalog → world (`Database.get(file).instantiate()`).
Picking up calls `queue_free()` and the light is gone.

So **the light literally cannot illuminate from inside your inventory
or catalog.** No ghost lights in the backpack.

### Layer 2: in-world toggle (optional, per-fixture)

Vanilla `Light.gd` is trivially small (16 lines):

```gdscript
extends Node3D
@export var light: Light3D
@export var mesh: MeshInstance3D
@export var defaultMaterial: Material
@export var litMaterial: Material

func Activate():
    light.show()
    mesh.set_surface_override_material(0, litMaterial)

func Deactivate():
    light.hide()
    mesh.set_surface_override_material(0, defaultMaterial)
```

It also swaps the mesh material — that's how `Lamp_Generic` becomes
`Lamp_Generic_Lit` visually (lit material has emissive glow, default
doesn't). All four Tier A fixtures already ship matched
default+lit material pairs, so we get this for free.

### Three modes we can offer

| Mode | Behavior | Implementation |
|---|---|---|
| Always on | Lights up the moment scene spawns | Default — do nothing |
| Off-during-placement, on-after-confirm | No flickering during ghost preview | Hook `Furniture.StartMove()` → `Deactivate()`, post-`ResetMove()` → `Activate()` |
| Click to toggle | Player interacts with placed lamp to turn it on/off | Add `Interactor` area + bind `Activate`/`Deactivate` |

**v1 recommendation:** ship "always on" as default + "click to toggle"
on the four Tier A lamps that already have lit/unlit material pairs.
Flame fixtures (Tier B) stay always-on (you don't toggle a candle).
Total extra implementation: ~1 hour.

---

## 7. Placement system mechanics — the real story

### `wallElement` controls ray direction, not surface type

From `Furniture.gd:163-173`:

```gdscript
if wallElement:
    for ray in rays.get_children():
        ray.target_position = Vector3(0, 0, -0.2)   # rays point INTO back of item (-Z)
else:
    for ray in rays.get_children():
        ray.target_position = Vector3(0, -0.2, 0)   # rays point DOWN (-Y)
```

Five rays at center + 4 corners. **All 5 must hit something** or
`CanPlace()` returns false (the green-dashed `Hint` plane hides).

### Surface support matrix

| Surface | Floor-element (`wallElement=false`) | Wall-element (`wallElement=true`) |
|---|---|---|
| Floor | ✅ Native | ❌ |
| Tabletop / shelf top | ✅ (any horizontal surface that fits 5-ray footprint) | ❌ |
| Top of placed furniture | ✅ | ❌ |
| Vertical wall | ❌ | ✅ Native |
| Ceiling | ❌ | ⚠️ Position works, rotation does NOT auto-flip |
| Angled / sloped | ⚠️ Snaps upright (no surface alignment) | ⚠️ Position projects, rotation only handles horizontal facing |

### Rotation math is the hard constraint

From `Placer.gd:178`:

```gdscript
var targetRotationRad = atan2(hitNormal.x, hitNormal.z)
placable.global_rotation.y = lerp_angle(placable.global_rotation.y, targetRotationRad + angle, ...)
```

Only **Y rotation** ever changes during decor placement. atan2 only
considers normal X and Z.

- Wall normal `(1,0,0)` → 90° rotation (faces away from wall) ✅
- Ceiling normal `(0,-1,0)` → atan2(0,0) = 0° (no flip) ❌
- Floor normal `(0,1,0)` → 0° (irrelevant; floor mode uses different code path)

And `Furniture.gd:302-305` confirms it:
```gdscript
if wallElement:
    owner.global_rotation_degrees.y = snappedf(owner.global_rotation_degrees.y, 90.0)
else:
    owner.global_rotation_degrees.y = snappedf(owner.global_rotation_degrees.y, 15.0)
```

**X and Z rotations are never touched in decor mode.** Wall items snap
to 90° steps on Y; floor items snap to 15° on Y. No native upside-down
flip exists.

### Why the cat bowl couldn't be flipped

Cat bowl is in the `"Item"` group (not `"Furniture"`), so it uses the
non-decor placement path at `Placer.gd:144-152`:

```gdscript
if orientationMode == 1:    # upright
elif orientationMode == 2:  # tilt -90° on X
elif orientationMode == 3:  # tilt -90° on Z (middle-click cycles)
```

Three pre-defined orientations. Still no 180° flip. Same fundamental
limit as decor mode — Phocas just didn't build "upside down" as a
gesture.

### The pre-baked-orientation trick (ceiling mounting)

The placement system can't *rotate* a lamp upside down at runtime, but
we can **ship the lamp scene with the geometry already inverted** so
its "back" face is the top of the cord. When the player aims at a
ceiling with `wallElement=true`:

1. Back rays shoot up, hit ceiling ✅
2. Magnet projects position onto ceiling plane, offsets `-0.05m` Y
   (away from normal = downward into room) ✅
   (math at `Placer.gd:177`)
3. Y rotation snap stays at 0° ✅ (no rotation around vertical for hanging lamp)
4. **X/Z rotation is preserved from the scene file** — we set them at
   scene-author time so the bulb visually hangs down

So we ship one scene per intended mount orientation, no engine changes.
Costs ~3 KB per extra scene file plus an extra ItemData/icon — basically
free.

### What the Hint indicator does on a ceiling

`Furniture.ExecuteInitialize()` rotates the Hint plane 90° on X for
wall-elements so it lies flat against the surface plane. On a ceiling,
that same 90° rotation puts the dashed plane flat against the ceiling
facing down at the player. **Exactly the right visual** — green dashes
on the ceiling showing where the lamp will attach. Free for us.

### What we genuinely lose without engine modifications

1. **Continuous tilt** (e.g., desk lamp angled to spotlight a table) — we get one fixed angle per scene, no in-game tilt
2. **Place under shelves** as a primary mode (`Parenter` area picks up nearby items but tucking-under isn't a placement gesture)
3. **180° flips at runtime** — same constraint as cat bowl

All three are workable via pre-baked variants.

### Validation (godotlens MCP, 2026-04-29)

Cross-checked the `wallElement` analysis with godotlens
`gdscript_references` (the LSP, not text-search) to confirm we have
complete coverage of every branch point. Project-wide references for
`Furniture.wallElement` (zero-based; +1 for editor lines):

| File | LSP line | Editor line | What it does |
|---|---|---|---|
| `Scripts/Furniture.gd` | 18 | 19 | Declaration (`@export var wallElement = false`) |
| `Scripts/Furniture.gd` | 132 | 133 | `ExecuteInitialize` — Hint mesh orientation branch |
| `Scripts/Furniture.gd` | 155 | 156 | `ExecuteInitialize` — ray-position branch (the one that sets `target_position` to `(0,0,-0.2)` vs `(0,-0.2,0)`) |
| `Scripts/Furniture.gd` | 301 | 302 | `ResetMove` — Y-rotation snap step (90° vs 15°) |
| `Scripts/Furniture.gd` | 320 | 321 | `HintPosition` — Hint Y-rotation snap |
| `Scripts/Placer.gd` | 173 | 174 | Magnet code — surface-normal projection branch |

Six references, zero hidden code paths. The §7 placement analysis is
complete — no engine surprises waiting to bite us in Phase 2.

### Future v2: engine-patch route

If we ever want surface-normal-aligned rotation (proper sloped surface
mounting, true ceiling flip, etc.), we'd `take_over_path()` on
`Furniture.gd` and `Placer.gd` to extend the rotation math from
"Y-axis only" to a full Quaternion alignment from the surface normal.
**Park this as v2+** — risky for compat, overkill for v1.

---

## 8. Mount matrix per fixture (v1)

| Fixture | Floor-stand | Wall-bracket | Ceiling-hang | Total SKUs |
|---|---|---|---|---|
| `Lamp_Cellar_Lit` | ❌ | ✅ | ✅ | 2 |
| `Lamp_Grid_Lit` | ❌ | ❌ | ✅ | 1 |
| `Lamp_Generic_Lit_HP` | ❌ | ✅ | ❌ | 1 |
| `Lamp_Generic_Lit_LP` | ❌ | ✅ | ❌ | 1 |
| `Candle` | ✅ | ❌ | ❌ | 1 |
| `Lantern_Kerosene` | ✅ | ❌ | ✅ | 2 |
| `Firepot` | ✅ | ❌ | ❌ | 1 |
| `Barrel_Metal_Fire` | ✅ | ❌ | ❌ | 1 |
| **Total v1** | | | | **10 SKUs** |

(Earlier doc said 11; recount = 10. Lantern_Kerosene gets ceiling
variant because both forms are historically accurate.)

### Surface coverage in practice

With this catalog the player can fully decorate:

- **Ceiling**: cellar bulb pendant, fluorescent panel, hanging lantern
- **Walls**: bracket lamps (HP/LP), wall-bracket cellar bulb
- **Floor**: floor brazier, fire barrel, kerosene lantern
- **Tabletops**: candles, lanterns (floor-element variants land on any
  horizontal surface with all 5 rays hitting — confirmed via `CheckRays`)
- **Shelves**: same as tabletops (candles, lanterns)

Footprint examples:
- Candle: ~0.1×0.1m → fits a nightstand
- Floor lamp: ~0.5m base → won't fit small tables (realistic)

---

## 9. Phased implementation plan

### Phase 0: Validate Metro registry hooks ✅ DONE

Verdict: 🟢 GREEN. Metro v3.x has first-class registries for SCENES,
ITEMS, LOOT, TRADER_POOLS. No `take_over_path()` required. Documented
in §5 above.

### Phase 1: Render trader icons (3–5 hours)

- Open Godot Editor at `tools/Godot/`
- Build a "icon renderer" `@tool` scene: orthographic camera, neutral
  backdrop (dark grey or black), 3-point light setup
- For each of 10 SKUs: instance the `_Lit.tscn`, snap to camera, render
  at 256×256, save to `mods/RTVHideoutLights/icons/Icon_<id>.png`
- Could be batch-automated with one tool script that iterates a list
- **Output**: 10 icon PNGs

### Phase 2: Author `_F.tscn` wrappers (5–10 hours)

For each SKU, mirror the Dartboard template
(`reference/RTV_decompiled/Assets/Dartboard/Dartboard_F.tscn`):

- Root `Node3D` named `<id>_F`
- `Mesh: MeshInstance3D` referencing the game's `MS_<Name>.obj`
- `Collider_R: MeshInstance3D` with `StaticBody3D` child in group `"Furniture"`
- `Furniture: Node3D` with `Furniture.gd` script, configured `itemData`,
  `wallElement`, `mesh`, `colliderR`
- `Indicator: Sprite3D` (green tint, billboard, no depth test)
- `Area: Area3D` for overlap check
- `Parenter: Area3D` for nearby pickup parenting
- `Rays: Node3D` with 5× `RayCast3D` at center + 4 corners
- `Hint: MeshInstance3D` with `PlaneMesh` + `MT_Hint.tres` material
- For ceiling variants: pre-rotate the Mesh node 180° on X so it hangs
  down when scene snaps to ceiling normal

Add Light3D nodes for Tier C/D fixtures (those without embedded lights).
Tier A/B inherit lights from referenced game scene where possible.

**Output**: 10 `_F.tscn` files, ~3 KB each

### Phase 3: ItemData `.tres` per SKU (1–2 hours)

For each SKU, mirror `Assets/Dartboard/Dartboard_F.tres`:

```gdresource
[gd_resource type="Resource" script_class="ItemData"]
[ext_resource type="Script" path="res://Scripts/ItemData.gd" id="1"]
[ext_resource type="Texture2D" path="res://mods/RTVHideoutLights/icons/Icon_Lamp_Cellar_Ceiling.png" id="2"]
[ext_resource type="PackedScene" path="res://mods/RTVHideoutLights/scenes/Lamp_Cellar_Ceiling_3x3.tscn" id="3"]

[resource]
script = ExtResource("1")
file = "rtvlights_lamp_cellar_ceiling"
name = "Cellar Bulb (Ceiling)"
type = "Furniture"
value = 200
rarity = 4
size = Vector2(2, 2)
generalist = true
icon = ExtResource("2")
tetris = ExtResource("3")
```

**Output**: 10 `_F.tres` files + 10 tetris-grid scenes (~1 KB each)

### Phase 4: Mod scaffold + Main.gd (1–2 hours)

```bash
scaffold.bat "RTVHideoutLights" --items
```

Then write Main.gd with the 40 registry calls (4 per SKU × 10). Use the
helper function from §5.

**Output**: complete mod skeleton + Main.gd registration

### Phase 5: Playtest + polish (3–5 hours)

- Buy each variant from Generalist
- Place in shelter (test floor, wall, ceiling, tabletop coverage)
- Save, quit, reload — verify lights persist correctly
- Performance: count active shadow-casting lights in dense decoration
- Verify uninstall path (remove .vmz, load save, confirm "File missing"
  warnings without corruption)
- Edge cases: try to place on transitions, sloped surfaces, into walls

### Total v1 estimate: 13–24 hours

(Up from the original 10–20h estimate after adding ceiling-mount variants
and the mount-orientation pre-bake work.)

---

## 10. Pricing tiers

Based on Dartboard reference (`value = 350` for a decorative wall
furniture, no functional benefit). Lights are arguably more useful
(actually illuminate dark hideouts), so price slightly higher.

| Fixture | Suggested value | Rationale |
|---|---|---|
| Candle | 80 | Cheap, finite vibe |
| Lantern_Kerosene | 200 | Bigger, brighter |
| Lamp_Cellar_Lit | 250 | Functional bulb |
| Lamp_Generic_Lit_LP | 350 | Wall fixture, soft |
| Lamp_Generic_Lit_HP | 500 | Brightest indoor light |
| Lamp_Grid_Lit | 450 | Industrial fluorescent |
| Firepot | 280 | Decorative fire |
| Barrel_Metal_Fire | 200 | Trash-fire vibe |

Currency in RTV is unitless `value` integers. There's no named currency
(rubles/cash); items are bartered by total value comparison. Trader
applies `tax` markup on player's request pile (`Interface.gd:1253`).

---

## 11. Risks and open questions

### Performance

Each lit fixture has `shadow_enabled = true`. **6+ shadow-casting
lights in a small shelter could hurt framerate on weaker GPUs.**

Godot's `Light3D` ships four perf knobs that map cleanly to our
fixture tiers (surfaced via godot-docs MCP, 2026-04-29):

| Property | Type | Default | What it does |
|---|---|---|---|
| `distance_fade_shadow` | float | `50.0` | Distance at which shadows cut off. Set lower than `distance_fade_begin + length` to drop shadow rendering before the light itself culls — *"shadow rendering is often more expensive than light rendering itself"* (Godot docs). |
| `shadow_caster_mask` | int (bitmask) | `4294967295` (all layers) | Which physics layers cast shadows from this light. Restrict to the main world geometry layer to skip casting from small props, NPCs, etc. |
| `light_cull_mask` | int (bitmask) | `4294967295` (all layers) | Which physics layers receive light from this fixture. Useful to keep our placed lamps from leaking onto unrelated objects. |
| `editor_only` | bool | `false` | Disables the light at runtime. Not relevant for our shipping fixtures, but useful for asset-author preview lights. |

Plus one already-set vanilla flag worth keeping:

- `distance_fade_enabled = true` on all our `_F.tscn` lights (Tier A wall brackets already use this; copy the convention to ceiling and floor variants).

#### Recommended perf profile per fixture tier

These are starting values for the `_F.tscn` Light3D nodes. Tune in
playtest if needed.

| Tier | Example fixtures | `shadow_enabled` | `distance_fade_begin` | `distance_fade_length` | `distance_fade_shadow` | Notes |
|---|---|---|---|---|---|---|
| **A — bright accent** | `Lamp_Generic_Lit_HP`, `Lamp_Grid_Lit` | `true` | 30 | 10 | 20 | Shadows cut at 20m, light at 40m. Worth the cost — these are "hero" lights. |
| **A — soft / pendant** | `Lamp_Generic_Lit_LP`, `Lamp_Cellar_Lit` (both wall and ceiling) | `true` | 25 | 10 | 15 | Closer fade — most placements are interior, no need to render at 40m. |
| **B — candle** | `Candle` | `false` | 8 | 4 | n/a | Tiny radius (0.25e). Skip shadows entirely — visual cost negligible. Saves dozens of shadow-map slots when player decorates with many candles. |
| **B — lantern / brazier** | `Lantern_Kerosene`, `Firepot`, `Barrel_Metal_Fire` | `true` | 15 | 8 | 10 | Mid-range flame light. Shadows on (atmospheric), but cull early. |

Other mitigations:

- **Recommend LP variant as bulk light, HP as accent** (mod README)
- **MCM toggle "Disable shadows on placed lights"** (v1.1) → flip
  `shadow_enabled = false` across all our fixtures at runtime via
  `get_tree().get_nodes_in_group("rtvlights")` walk
- **MCM toggle "Cap shadow-casting lights to N nearest"** (v1.2) →
  per-frame distance sort + flip the bottom N's `shadow_enabled` off.
  Heavy hammer; only ship if v1 perf complaints surface.
- Monitor in playtest with frame-time HUD; adjust per-tier defaults
  before publish.

### Light cull distance

Vanilla bracket variants have `distance_fade_enabled = true`. We should
preserve that on our wraps so distant placed lights don't render their
full shadow cascade.

### Save migration on uninstall

If player uninstalls and loads a save with our furniture: `Database.get`
returns null, `LoadShelter` prints `"File missing: rtvlights_..."` and
skips. **Save not corrupted, but lamps are gone.** Re-installing
restores them. Standard mod behavior, document in README.

### Save migration on update

If we change a fixture's `file` string between mod versions, old saves'
references break (same as uninstall). **Treat the `file` string as a
public API — never rename after release.** If we need to change a
fixture, ship a new SKU and deprecate the old one (keep registering
both for one release cycle).

### Ceiling mount ergonomics

The pre-baked-orientation trick puts the cord/mesh visually pointing
down when the player aims at a ceiling. **But the player has to look
UP** to engage placement (because the floating-target position needs
to be near the ceiling for back-rays to hit it). UX may feel awkward.

Test in playtest. If awkward, consider:
- Shipping a third variant: "ceiling pendant from floor view" — a tall
  pole + light at top that floor-mounts but visually looks like it
  hangs from the ceiling (cheat the perspective)
- Or eat the awkward camera angle as a one-time placement cost

### Wall-mount for cellar bulb

Tier A `Lamp_Cellar_Lit` ships as a hanging bulb. The "wall-mount"
variant requires us to model the bracket geometry (or just ship it
slightly differently positioned so the cord meets the wall). Might not
look great. **Consider dropping this variant in v1 if it's ugly.**

### Trader stock churn

`Trader.CreateSupply()` picks 40 random items from the trader bucket
each restock cycle. If we add 10 items to Generalist's pool, our
fixtures may not always appear in stock — they're competing with
vanilla items for slots. **Player may need to wait for a restock.**

Acceptable. Document in README ("light fixtures may take a restock or
two to appear at the trader").

### MCM integration (deferred)

v1 doesn't need MCM. v1.1 could add:
- "Shadow quality" toggle (full / off)
- "Lights always on" vs "click to toggle" preference
- Per-fixture enable/disable

---

## 12. File touch list (v1)

### New files (in our mod)

```
mods/RTVHideoutLights/
├── mod.txt                          # [info], [autoload], [registry]
├── Main.gd                          # Registry calls
├── Logger.gd                        # Synced from shared/Logger.gd
├── icons/
│   ├── Icon_Candle.png
│   ├── Icon_Lantern_Kerosene_Floor.png
│   ├── Icon_Lantern_Kerosene_Ceiling.png
│   ├── Icon_Lamp_Cellar_Wall.png
│   ├── Icon_Lamp_Cellar_Ceiling.png
│   ├── Icon_Lamp_Generic_Lit_HP_Wall.png
│   ├── Icon_Lamp_Generic_Lit_LP_Wall.png
│   ├── Icon_Lamp_Grid_Lit_Ceiling.png
│   ├── Icon_Firepot_Floor.png
│   └── Icon_Barrel_Metal_Fire_Floor.png
├── scenes/
│   ├── Candle_F.tscn                # floor (table) variant
│   ├── Lantern_Kerosene_Floor_F.tscn
│   ├── Lantern_Kerosene_Ceiling_F.tscn  # pre-baked inverted
│   ├── Lamp_Cellar_Wall_F.tscn
│   ├── Lamp_Cellar_Ceiling_F.tscn
│   ├── Lamp_Generic_Lit_HP_Wall_F.tscn
│   ├── Lamp_Generic_Lit_LP_Wall_F.tscn
│   ├── Lamp_Grid_Lit_Ceiling_F.tscn
│   ├── Firepot_Floor_F.tscn
│   ├── Barrel_Metal_Fire_Floor_F.tscn
│   └── *_NxM.tscn                   # tetris grid scenes (10 files)
├── items/
│   └── *_F.tres                     # 10 ItemData files
├── README.md
├── CHANGELOG.md
├── LICENSE
├── NOTICES.txt
├── PUBLISH_NOTES.md
├── build.py                         # canonical scaffold version
└── screenshots/
    └── README.md
```

### Files we read (game) — never modify

- `res://Assets/<Name>/Files/MS_<Name>.obj` — referenced as `ext_resource`
- `res://Assets/<Name>/Files/MT_<Name>.tres` and `MT_<Name>_Lit.tres`
- `res://Assets/<Name>/Files/TX_<Name>_AL.png`
- `res://Assets/<Name>/<Name>.tscn` and `<Name>_Lit.tscn` (reference, not include)
- `res://Scripts/Furniture.gd`, `Light.gd`, `Flicker.gd`, `Surface.gd`, `ItemData.gd`
- `res://Modular/Materials/MT_Furniture.tres`, `MT_Hint.tres`
- `res://Loot/LT_Master.tres` (mutated via Metro registry, not directly)

---

## 13. v1 SKU manifest (final)

| Registry id | Name | Mount | Mesh source | Light | Tetris size | Value |
|---|---|---|---|---|---|---|
| `rtvlights_candle` | Candle | Floor (table) | `Assets/Candle/Files/MS_Candle.obj` | OmniLight + Flicker (warm 0.25e) | 1×1 | 80 |
| `rtvlights_lantern_kerosene_floor` | Kerosene Lantern (Floor) | Floor | `Assets/Lantern_Kerosene/Files/MS_Lantern_Kerosene.obj` | OmniLight + Flicker (warm 0.75e) | 2×2 | 200 |
| `rtvlights_lantern_kerosene_ceiling` | Kerosene Lantern (Ceiling) | Ceiling | same, inverted | same | 2×2 | 200 |
| `rtvlights_lamp_cellar_wall` | Cellar Bulb (Wall) | Wall | `Assets/Lamp_Cellar/Files/MS_Lamp_Cellar.obj` | OmniLight (warm 1.0e, range 4) | 2×2 | 250 |
| `rtvlights_lamp_cellar_ceiling` | Cellar Bulb (Ceiling) | Ceiling | same | same | 2×2 | 250 |
| `rtvlights_lamp_generic_lit_lp_wall` | Soft Wall Lamp | Wall | `Assets/Lamp_Generic/Files/MS_Lamp_Generic.obj` (lit material) | SpotLight 60°, e=5, fog off | 2×3 | 350 |
| `rtvlights_lamp_generic_lit_hp_wall` | Bright Wall Lamp | Wall | same | SpotLight 60°, e=10 | 2×3 | 500 |
| `rtvlights_lamp_grid_lit_ceiling` | Industrial Fluorescent | Ceiling | `Assets/Lamp_Grid/Files/MS_Lamp_Grid.obj` | SpotLight 60° (warm 2.0e) | 3×3 | 450 |
| `rtvlights_firepot_floor` | Firepot | Floor | `Assets/Firepot/Files/MS_Firepot.obj` | OmniLight + Flicker (orange 1.3e) | 2×2 | 280 |
| `rtvlights_barrel_metal_fire_floor` | Burning Barrel | Floor | `Assets/Barrel_Metal/Files/MS_Barrel_Metal.obj` | OmniLight + Flicker (orange 1.35e) | 2×2 | 200 |

All `type = "Furniture"`, all `rarity = 4`, all `generalist = true`.

---

## 14. Reference index

### Decompiled game source

Root: `F:\RoadToVostokMods\reference\RTV_decompiled\`

Most-referenced files for this mod:

- `Scripts/Database.gd` — autoload, scene const map
- `Scripts/Trader.gd` — trader stock generation
- `Scripts/Interface.gd` — purchase routing, catalog UI
- `Scripts/Loader.gd` — shelter save/load
- `Scripts/Furniture.gd` — placement component
- `Scripts/Placer.gd` — placement input loop
- `Scripts/Light.gd` — on/off toggle (16 lines)
- `Scripts/Flicker.gd` — flame animation (23 lines)
- `Scripts/ItemData.gd` — shared item schema
- `Resources/GameData.tres` — global game state
- `Loot/LT_Master.tres` — master loot table
- `Assets/Dartboard/Dartboard_F.tscn` — template for our `_F.tscn`
- `Assets/Dartboard/Dartboard_F.tres` — template for our `_F.tres`

### Metro Mod Loader source

Root: `F:\RoadToVostokMods\reference\MetroModLoader_source\`

- `docs/wiki/Registry.md` — full registry API documentation
- `src/registry.gd` — public verb dispatcher
- `src/registry/scenes.gd` — SCENES handler (Database injection)
- `src/registry/items.gd` — ITEMS handler (ItemData lookup)
- `src/registry/loot.gd` — LOOT handler (LT_Master.items append)
- `src/registry/traders.gd` — TRADER_POOLS handler (boolean flag flip)

### Existing workspace tooling we'll use

- `scaffold.bat "RTVHideoutLights" --items` — generates mod skeleton
- `tools/scaffold_mod.py` — the generator
- `tools/sync_logger.py` — auto-runs from scaffold, copies Logger.gd
- `publish.bat <mod> --version X.Y.Z` — build → install → ModWorkshop
- `tools/Godot/` — installed Godot Editor 4.6.2 for icon rendering
- `modworkshop.bat search <term>` — for ongoing market scans

### ModWorkshop competitive scan (2026-04-28)

Searched: `light`, `lamp`, `lighting`. Closest results:
- 56422 LootLight (loot UI, not lights)
- 50817 Configurable Flashlight Drain (flashlight, not fixtures)
- 50808 [Outdated] Better Light and Weather (atmosphere, not fixtures)

**Zero placeable-light competitors.** Re-scan before publish.

---

## 15. Open design decisions

These are choices to make before authoring starts:

1. **Click-to-toggle on Tier A lamps?** → Recommended yes (~1h extra)
2. **MCM at v1?** → No, defer to v1.1
3. **Ship Lamp_Cellar wall variant?** → Test ergonomics first; may drop
4. **Tier C/D in v1.1 or v2?** → v1.1 once v1 is stable
5. **Bonus assets (Sign_Exit_Lit, Computer_Lit) — v1.2?** → Yes, flavor pickups
6. **Engine patch for surface-normal rotation — v2?** → Park as wishlist
7. **Shadow quality MCM toggle?** → Add in v1.1 if perf complaints surface

---

## 16. Next session pickup

If a fresh Claude session inherits this plan (e.g. with new MCP servers
that change capabilities), the first three things to do:

1. **Re-scan ModWorkshop** — `modworkshop.bat search lamp` etc. — confirm
   the niche is still open. (Document in §1 if status changes.)
2. **Verify Metro registry source still matches §5** — read
   `reference/MetroModLoader_source/docs/wiki/Registry.md` and
   `src/registry/{scenes,items,loot,traders}.gd`. If the API has
   evolved, update §5.
3. **Verify decompiled game source still matches §4 line refs** — RTV
   game updates may shift line numbers in `Database.gd`, `Furniture.gd`,
   `Placer.gd`. Re-grep for the patterns rather than trusting line numbers.

Then proceed to Phase 1 (icon rendering) per §9.

---

*Plan authored 2026-04-28 across multiple research agents. Implementation deferred pending MCP server work in another session.*
