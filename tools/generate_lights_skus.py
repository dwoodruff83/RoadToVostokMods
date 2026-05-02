#!/usr/bin/env python3
"""Generate all v1 RTVHideoutLights SKU wrapper files (.tscn, .tres, tetris).

For each fixture in FIXTURES, writes three files into the mod folder:
  scenes/<id>_F.tscn       — placeable scene with Furniture component
  items/<id>_F.tres        — ItemData
  scenes/<id>_<W>x<H>.tscn — tetris grid sprite scene

Re-runnable: overwrites existing files. Edit FIXTURES below to add/remove
or tweak SKUs, then re-run. The lone hand-authored Lamp_Cellar wall SKU
that exists pre-generator stays as-is (not in this list).

Per-fixture spec:
  id           : registry id ("rtvlights_X"); also used as filename stem
  name         : display name shown in trader and catalog
  mesh         : res:// path to .obj (the visual mesh)
  material     : res:// path to .tres (lit material variant for *_Lit fixtures)
  aabb         : (W, H, D) mesh-local bounding box dimensions in meters
  grid         : (W, H) tetris cells; PNG output is 128*W × 128*H
  mount        : "wall" / "ceiling" / "floor" — drives rotation + ray pattern
  value        : trader price (int)
  trader       : trader pool flag ("Generalist" by default)
  surface      : Surface.gd material name on the StaticBody3D ("Metal", "Wood", "Generic")
  light        : dict with light setup or None (Tier C fixtures get a custom one)
                 type     : "OmniLight3D" or "SpotLight3D"
                 color    : (r, g, b) or None for default white
                 energy   : float
                 range    : float (omni_range or spot_range)
                 angle    : float (spot_angle, only for SpotLight)
                 pos      : (x, y, z) light position in scene-local frame
                 down     : True if SpotLight should be aimed at -Y (rotated)
"""

from pathlib import Path

MOD_ROOT = Path(__file__).resolve().parent.parent / "mods" / "RTVHideoutLights"
SCENES_DIR = MOD_ROOT / "scenes"
ITEMS_DIR = MOD_ROOT / "items"
ICON_DIR_RES = "res://mods/RTVHideoutLights/assets/icons"

# Decompiled project root — used to resolve fixture mesh paths to absolute
# .obj file paths so we can compute real AABBs (not just sizes).
DECOMPILED_ROOT = Path(__file__).resolve().parent.parent / "reference" / "RTV_decompiled"


def parse_obj_aabb(res_path: str):
    """Read mesh vertex coords from an OBJ at a res:// path; return
    (xmin, xmax, ymin, ymax, zmin, zmax). Many fixtures have AABBs whose
    origin is NOT centered (Candle Y starts at 0, Lamp_Grid Y ends at 0,
    etc.) so we need the full extents, not just sizes, to position the
    Furniture component's rays/area/parenter/hint correctly."""
    if not res_path.startswith("res://"):
        raise ValueError(f"expected res:// path, got {res_path}")
    obj_file = DECOMPILED_ROOT / res_path[len("res://"):]
    xs, ys, zs = [], [], []
    with open(obj_file) as f:
        for line in f:
            if not line.startswith("v "):
                continue
            parts = line.split()
            if len(parts) < 4:
                continue
            try:
                xs.append(float(parts[1]))
                ys.append(float(parts[2]))
                zs.append(float(parts[3]))
            except ValueError:
                pass
    if not xs:
        raise RuntimeError(f"no vertices found in {obj_file}")
    return (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs))

# fmt: off
FIXTURES = [
    {
        # Migrated from hand-authored on 2026-05-01. `id` matches the
        # existing scene/tres filenames (Lamp_Cellar_Ceiling_F.*) so player
        # saves that already reference these paths keep working. The `file`
        # field changes from "rtvlights_lamp_cellar_wall" to
        # "Lamp_Cellar_Ceiling" — verified harmless (file is only used for
        # item-identity comparisons like stacking / door keys / matches /
        # ammo type, none of which apply to furniture).
        "id": "Lamp_Cellar_Ceiling",
        "name": "Cellar Wall Light",
        "mesh": "res://Assets/Lamp_Cellar/Files/MS_Lamp_Cellar.obj",
        "material": "res://Assets/Lamp_Cellar/Files/MT_Lamp_Cellar_Lit.tres",
        "icon": "Icon_Lamp_Cellar_Lit.png",
        "aabb": (0.2, 0.4, 0.128),
        "grid": (2, 3),
        "mount": "wall",
        "value": 250,
        "trader": "Generalist",
        "surface": "Metal",
        # Vanilla Lamp_Cellar_Lit's OmniLight, 50cm out from the wall in
        # +Z (into the room). Warm bulb-color, 4m range. Defaults to
        # always-on like vanilla wall sconces.
        "light": {
            "type": "OmniLight3D", "color": (1.0, 0.941, 0.863),
            "energy": 1.0, "range": 4.0,
            "pos": (0, 0, 0.5), "down": False,
        },
        "toggle": {
            "label": "Cellar Wall Light",
            "interactable": False, "subscribe_to_switch": True, "force_on": True,
            "lights": ["Mesh/Light"],
            # Swap surface 0 between unlit (matte) and Lit (emissive) so the
            # mesh stops glowing when the light is off — vanilla Light.gd pattern.
            "material_swap": {
                "mesh": "Mesh", "surface_index": 0,
                "off_material": "res://Assets/Lamp_Cellar/Files/MT_Lamp_Cellar.tres",
                "on_material": "res://Assets/Lamp_Cellar/Files/MT_Lamp_Cellar_Lit.tres",
            },
        },
    },
    {
        "id": "rtvlights_lamp_grid_lit_ceiling",
        "name": "Industrial Fluorescent",
        "mesh": "res://Assets/Lamp_Grid/Files/MS_Lamp_Grid.obj",
        "material": "res://Assets/Lamp_Grid/Files/MT_Lamp_Grid_Lit.tres",
        "icon": "Icon_Lamp_Grid_Lit.png",
        "aabb": (0.4, 0.13, 0.4),
        "grid": (2, 2),
        "mount": "ceiling",
        "value": 450,
        "trader": "Generalist",
        "surface": "Metal",
        # Tight ray cluster so the 0.4m square fixture can mount on
        # narrow beams (~0.15m wide) without corner rays missing.
        "ray_spread": (0.06, 0.06),
        "light": {
            "type": "SpotLight3D", "color": (1.0, 0.94, 0.86),
            "energy": 2.0, "range": 8.0, "angle": 60.0,
            "pos": (0, -0.15, 0), "down": True,
        },
        # Switch-controlled (not player-interactable). Auto-subscribes
        # to the shelter's vanilla Light_Switch when placed.
        "toggle": {
            "label": "Industrial Fluorescent",
            "interactable": False, "subscribe_to_switch": True, "force_on": True,
            "lights": ["Mesh/Light"],
            "material_swap": {
                "mesh": "Mesh", "surface_index": 0,
                "off_material": "res://Assets/Lamp_Grid/Files/MT_Lamp_Grid.tres",
                "on_material": "res://Assets/Lamp_Grid/Files/MT_Lamp_Grid_Lit.tres",
            },
        },
    },
    {
        "id": "rtvlights_lamp_generic_lit_hp_ceiling",
        "name": "Bright Fluorescent",
        "mesh": "res://Assets/Lamp_Generic/Files/MS_Lamp_Generic.obj",
        "material": "res://Assets/Lamp_Generic/Files/MT_Lamp_Generic_Lit.tres",
        "icon": "Icon_Lamp_Generic_Lit_HP.png",
        "aabb": (1.6, 0.1, 0.2),
        "grid": (5, 2),
        "mount": "ceiling",
        "value": 600,
        "trader": "Generalist",
        "surface": "Metal",
        # Tight ray cluster (0.2m x 0.1m around center) instead of corners
        # at ±0.8m / ±0.1m. Lets the fixture mount on narrow beams (~0.2m
        # wide) in either orientation — along the beam OR perpendicular.
        "ray_spread": (0.1, 0.05),
        "light": {
            "type": "SpotLight3D", "color": None,
            "energy": 10.0, "range": 20.0, "angle": 60.0,
            "pos": (0, -0.1, 0), "down": True,
        },
        "toggle": {
            "label": "Bright Fluorescent",
            "interactable": False, "subscribe_to_switch": True, "force_on": True,
            "lights": ["Mesh/Light"],
            "material_swap": {
                "mesh": "Mesh", "surface_index": 0,
                "off_material": "res://Assets/Lamp_Generic/Files/MT_Lamp_Generic.tres",
                "on_material": "res://Assets/Lamp_Generic/Files/MT_Lamp_Generic_Lit.tres",
            },
        },
    },
    {
        "id": "rtvlights_lamp_generic_lit_lp_ceiling",
        "name": "Soft Fluorescent",
        "mesh": "res://Assets/Lamp_Generic/Files/MS_Lamp_Generic.obj",
        "material": "res://Assets/Lamp_Generic/Files/MT_Lamp_Generic_Lit.tres",
        "icon": "Icon_Lamp_Generic_Lit_LP.png",
        "aabb": (1.6, 0.1, 0.2),
        "grid": (5, 2),
        "mount": "ceiling",
        "value": 400,
        "trader": "Generalist",
        "surface": "Metal",
        # Tight ray cluster — same reasoning as HP variant. Lets the
        # fixture mount on narrow beams in either orientation.
        "ray_spread": (0.1, 0.05),
        # `fog: False` matches vanilla LP behavior — light still illuminates
        # surfaces but is invisible in volumetric fog (no god-ray cone).
        # Differentiates LP from HP visually beyond just brightness.
        "light": {
            "type": "SpotLight3D", "color": None,
            "energy": 5.0, "range": 10.0, "angle": 60.0,
            "pos": (0, -0.1, 0), "down": True, "fog": False,
        },
        "toggle": {
            "label": "Soft Fluorescent",
            "interactable": False, "subscribe_to_switch": True, "force_on": True,
            "lights": ["Mesh/Light"],
            "material_swap": {
                "mesh": "Mesh", "surface_index": 0,
                "off_material": "res://Assets/Lamp_Generic/Files/MT_Lamp_Generic.tres",
                "on_material": "res://Assets/Lamp_Generic/Files/MT_Lamp_Generic_Lit.tres",
            },
        },
    },
    {
        "id": "rtvlights_candle",
        "name": "Candle",
        "mesh": "res://Assets/Candle/Files/MS_Candle.obj",
        "material": "res://Assets/Candle/Files/MT_Candle.tres",
        "icon": "Icon_Candle.png",
        "aabb": (0.3, 0.104, 0.3),
        "grid": (2, 2),
        "mount": "floor",
        "value": 80,
        "trader": "Generalist",
        "surface": "Metal",
        # Vanilla Fire.gd integration — small flame on the wick, player
        # ignites/extinguishes via Use action. Values copied from vanilla
        # Candle.tscn so the lit visual matches what's in NPC houses.
        "fire": {
            "pos": (0, 0.1, 0), "flame_size": (0.05, 0.05),
            "flame_offset": (0, 0.015, 0), "particle_amount": 1,
            "particle_lifetime": 2.0,
            "light_color": (0.94, 0.78, 0.67), "light_energy": 0.25,
            "light_min_energy": 0.2, "light_max_energy": 0.4,
            "light_flicker_freq": 0.2, "light_range": 1.0,
        },
    },
    {
        "id": "rtvlights_lantern_kerosene",
        "name": "Kerosene Lantern",
        "mesh": "res://Assets/Lantern_Kerosene/Files/MS_Lantern_Kerosene_LOD0.obj",
        "material": "res://Assets/Lantern_Kerosene/Files/MT_Lantern_Kerosene.tres",
        # Surface 1 is the glass chimney. Without an explicit material it
        # renders as opaque white, hiding the flame inside. MT_Glass.tres
        # is the same translucent material vanilla Lantern.tscn uses.
        "surface_materials": [
            "res://Modular/Materials/MT_Glass.tres",
        ],
        "icon": "Icon_Lantern_Kerosene.png",
        "aabb": (0.2, 0.3, 0.2),
        "grid": (2, 3),
        "mount": "floor",
        "value": 200,
        "trader": "Generalist",
        "surface": "Metal",
        # Vanilla Lantern_Kerosene.tscn flame is at (0, 0.1, 0) — same
        # spot as the candle (the mesh origin sits at the lantern base
        # and the wick is ~10cm up where the metal cap meets the glass).
        # Earlier (0, 0.15, 0) put the flame INSIDE the metal base mesh
        # where it was invisible. local_coords=true (vanilla parity)
        # keeps the particle stuck to the lantern when it moves.
        "fire": {
            "pos": (0, 0.1, 0), "flame_size": (0.05, 0.05),
            "flame_offset": (0, 0.015, 0), "particle_amount": 1,
            "particle_lifetime": 2.0, "local_coords": True,
            "light_color": (0.94, 0.78, 0.67), "light_energy": 0.75,
            "light_min_energy": 0.5, "light_max_energy": 1.0,
            "light_flicker_freq": 0.2, "light_range": 4.0,
        },
    },
    {
        "id": "rtvlights_lamp_floor",
        "name": "Floor Lamp",
        "mesh": "res://Assets/Lamp_Floor/Files/MS_Lamp_Floor_LOD0.obj",
        # Vanilla material — Lamp_Floor's mesh has no glow vertex coloring,
        # so the Standard.gdshader's `glow` parameter has no visual effect
        # on the lampshade. Instead of trying to emit the shade itself, we
        # add a small emissive Bulb child mesh inside the shade (see "bulb"
        # below) to give the visual cue that the lamp is on.
        "material": "res://Assets/Lamp_Floor/Files/MT_Lamp_Floor.tres",
        "icon": "Icon_Lamp_Floor.png",
        "aabb": (0.4, 2.0, 0.4),
        "grid": (3, 6),
        "mount": "floor",
        "value": 350,
        "trader": "Generalist",
        "surface": "Wood",
        # Tier C: no embedded vanilla light, we add a downward SpotLight
        # inside the lampshade for the classic floor-lamp pool. Warmer
        # color (~3000K incandescent) so it reads as a soft household
        # lamp rather than a cold workshop fixture.
        "light": {
            "type": "SpotLight3D", "color": (1.0, 0.85, 0.65),
            "energy": 3.0, "range": 4.0, "angle": 50.0,
            "pos": (0, 1.7, 0), "down": True,
        },
        # Fill light pointing UP from below the shade opening into the
        # dome interior. Necessary because Standard.gdshader uses
        # max(NdotL, 0) which kills any light hitting back-faces of the
        # shade (point lights INSIDE the shade contribute zero diffuse
        # to the inside surface). An uplight at the opening's bottom
        # has its photons travelling up — same direction as the inside
        # surface's flipped back-face normal — so it actually lights
        # the dome interior visibly.
        "uplight": {
            "type": "SpotLight3D", "color": (1.0, 0.85, 0.65),
            "energy": 1.5, "range": 0.5, "angle": 90.0,
            # Position just below the bulb (which sits at y=1.7) but
            # still inside the shade — visible "source" of the dome
            # fill light reads as the bulb itself, not the open bottom.
            "pos": (0, 1.65, 0), "up": True,
        },
        # Visible "lit bulb" inside the shade — lampshade mesh itself
        # can't glow (no vertex-color setup in vanilla mesh), so we
        # inject a small emissive sphere where the bulb would sit.
        "bulb": {
            "color": (1.0, 0.85, 0.65), "energy": 2.0, "radius": 0.04,
            "pos": (0, 1.7, 0),
        },
        # Manual on/off toggle via Use action. Hides the SpotLight,
        # UpLight, and visible bulb sphere when off (placed instance
        # starts unlit by default; player flips it).
        "toggle": {
            "label": "Floor Lamp",
            "interactable": True,
            "lights": ["Mesh/Light", "Mesh/UpLight"],
            "lit_meshes": ["Mesh/Bulb"],
        },
    },
    {
        "id": "rtvlights_sign_exit_lit",
        "name": "Exit Sign",
        "mesh": "res://Assets/Sign_Exit/Files/MS_Sign_Exit.obj",
        "material": "res://Assets/Sign_Exit/Files/MT_Sign_Exit.tres",
        "icon": "Icon_Sign_Exit_Lit.png",
        "aabb": (0.6, 0.2, 0.12),
        "grid": (3, 2),
        "mount": "wall",
        "value": 280,
        "trader": "Generalist",
        "surface": "Generic",
        "light": {
            "type": "SpotLight3D", "color": (0.39, 1.0, 0.0),
            "energy": 1.0, "range": 2.0, "angle": 75.0,
            "pos": (0, 0, 0.5), "down": False,  # default forward (+Z, into room)
        },
    },
    {
        "id": "rtvlights_computer_lit",
        "name": "Vintage Desktop PC",
        "mesh": "res://Assets/Computer/Files/MS_Computer_LOD0.obj",
        "material": "res://Assets/Computer/Files/MT_Computer.tres",
        # Surface 1 of the Computer mesh is the monitor screen. Lit
        # version (cyan UI image) is the default; toggle below swaps to
        # the dark MT_Computer_Screen.tres when off.
        "surface_materials": [
            "res://Assets/Computer/Files/MT_Computer_Screen_Lit.tres",
        ],
        "icon": "Icon_Computer_Lit.png",
        "aabb": (0.84, 0.55, 0.52),
        "grid": (4, 4),
        "mount": "floor",
        "value": 400,
        "trader": "Generalist",
        "surface": "Generic",
        "light": {
            "type": "OmniLight3D", "color": (0.39, 0.78, 0.78),
            "energy": 0.5, "range": 3.0,
            "pos": (0, 0.4, 0.2), "down": False,
        },
        # Manual on/off via Use. Hides the soft cyan glow when off, plus
        # swaps the screen material from cyan UI to dark blank screen.
        "toggle": {
            "label": "PC",
            "interactable": True,
            "lights": ["Mesh/Light"],
            "material_swap": {
                "mesh": "Mesh",
                "surface_index": 1,
                "off_material": "res://Assets/Computer/Files/MT_Computer_Screen.tres",
                "on_material": "res://Assets/Computer/Files/MT_Computer_Screen_Lit.tres",
            },
        },
    },
]
# fmt: on


def transform3d(*v):
    """Format Transform3D from 12 floats."""
    return "Transform3D(" + ", ".join(str(x) for x in v) + ")"


# Identity transform
T_IDENT = transform3d(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)


def light_node(light, name="Light"):
    """Render a Light3D node block."""
    if light is None:
        return ""
    pos = light["pos"]
    color = light.get("color")
    color_str = (
        f"\nlight_color = Color({color[0]}, {color[1]}, {color[2]}, 1)" if color else ""
    )
    # SpotLight3D defaults to shining in -Z. Re-orient by:
    #   "down": -90° X → basis (1,0,0, 0,0,1, 0,-1,0), photon -Y (down)
    #   "up":   +90° X → basis (1,0,0, 0,0,-1, 0,1,0), photon +Y (up)
    #   default: identity, photon -Z (forward)
    if light.get("down"):
        xform = transform3d(1, 0, 0, 0, 0, 1, 0, -1, 0, *pos)
    elif light.get("up"):
        xform = transform3d(1, 0, 0, 0, 0, -1, 0, 1, 0, *pos)
    else:
        xform = transform3d(1, 0, 0, 0, 1, 0, 0, 0, 1, *pos)
    extras = []
    extras.append(f"light_energy = {light['energy']}")
    extras.append("shadow_enabled = true")
    extras.append("distance_fade_enabled = true")
    # Volumetric fog interaction. Defaults to 1.0 (visible god-ray cone in
    # foggy/dusty scenes). Set fog: False on a light to make it invisible
    # in volumetric fog — matches vanilla's "low-power" fixtures (e.g.
    # Lamp_Generic_Lit_LP) that light surfaces without a visible beam.
    if light.get("fog") is False:
        extras.append("light_volumetric_fog_energy = 0.0")
    if light["type"] == "OmniLight3D":
        extras.append(f"omni_range = {light['range']}")
    elif light["type"] == "SpotLight3D":
        extras.append(f"spot_range = {light['range']}")
        extras.append(f"spot_angle = {light['angle']}")
    # Parent the light to Mesh (not scene root). For wall/floor fixtures
    # Mesh has identity transform so this is equivalent. For ceiling
    # fixtures Mesh has a -90° X rotation that makes the light's spec
    # position (in mesh-natural frame) and "down" rotation work uniformly:
    # light photon direction ends up world -Y (DOWN into the room) instead
    # of the world -Z (backward) we'd get with the rotations stacked
    # against the scene root's +90° X.
    return f"""
[node name="{name}" type="{light['type']}" parent="Mesh"]
transform = {xform}{color_str}
{chr(10).join(extras)}
"""


def bulb_subresources(bulb):
    """Render SubResource blocks for a visible-bulb sphere + emissive material.

    Used by fixtures whose vanilla mesh has no glow vertex coloring (e.g.
    Lamp_Floor) — instead of fighting the shader we just inject a small
    emissive sphere where the bulb would sit. Material is StandardMaterial3D
    (not the custom Standard.gdshader) since we want guaranteed emission
    without depending on mesh-specific UV/color setup.
    """
    if bulb is None:
        return ""
    color = bulb.get("color", (1.0, 1.0, 1.0))
    energy = bulb.get("energy", 5.0)
    radius = bulb.get("radius", 0.04)
    return f"""
[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_bulb"]
albedo_color = Color({color[0]}, {color[1]}, {color[2]}, 1)
emission_enabled = true
emission = Color({color[0]}, {color[1]}, {color[2]}, 1)
emission_energy_multiplier = {energy}

[sub_resource type="SphereMesh" id="SphereMesh_bulb"]
material = SubResource("StandardMaterial3D_bulb")
radius = {radius}
height = {radius * 2}
radial_segments = 8
rings = 4
"""


def toggle_ext_resources(toggle, start_id):
    """ext_resources needed when a fixture has a LightToggle script.
    Returns (block_text, count). Always emits the script ext_resource;
    additionally emits material ext_resources if material_swap is set."""
    if toggle is None:
        return ("", 0)
    lines = [
        f'\n[ext_resource type="Script" path="res://mods/RTVHideoutLights/LightToggle.gd" id="{start_id}"]'
    ]
    count = 1
    swap = toggle.get("material_swap")
    if swap:
        lines.append(
            f'\n[ext_resource type="Material" path="{swap["off_material"]}" id="{start_id + 1}"]'
        )
        lines.append(
            f'\n[ext_resource type="Material" path="{swap["on_material"]}" id="{start_id + 2}"]'
        )
        count += 2
    return ("".join(lines), count)


def toggle_root_attrs(toggle, script_id, off_mat_id, on_mat_id):
    """Attributes appended to the scene root when LightToggle is used.
    Returns (header_extra, body_extra)."""
    if toggle is None:
        return ("", "")
    # node_paths declaration tells Godot which exported Node-typed fields
    # need NodePath → Node resolution at scene load (vanilla Switch.gd pattern).
    np_list = ["lights", "lit_meshes"]
    if toggle.get("material_swap"):
        np_list.append("swap_mesh")
    np_str = ", ".join(f'"{n}"' for n in np_list)
    header_extra = f' node_paths=PackedStringArray({np_str})'

    lights = toggle.get("lights", [])
    lit_meshes = toggle.get("lit_meshes", [])
    body_lines = [f'\nscript = ExtResource("{script_id}")']
    body_lines.append(f'\nlabel = "{toggle.get("label", "Light")}"')
    body_lines.append(f'\ninteractable = {str(toggle.get("interactable", True)).lower()}')
    body_lines.append(f'\nsubscribe_to_switch = {str(toggle.get("subscribe_to_switch", False)).lower()}')
    body_lines.append(f'\nforce_on = {str(toggle.get("force_on", False)).lower()}')
    if lights:
        np_array = ", ".join(f'NodePath("{p}")' for p in lights)
        body_lines.append(f'\nlights = [{np_array}]')
    if lit_meshes:
        np_array = ", ".join(f'NodePath("{p}")' for p in lit_meshes)
        body_lines.append(f'\nlit_meshes = [{np_array}]')
    swap = toggle.get("material_swap")
    if swap:
        body_lines.append(f'\nswap_mesh = NodePath("{swap["mesh"]}")')
        body_lines.append(f'\nswap_surface_index = {swap.get("surface_index", 0)}')
        body_lines.append(f'\nswap_off_material = ExtResource("{off_mat_id}")')
        body_lines.append(f'\nswap_on_material = ExtResource("{on_mat_id}")')
    return (header_extra, "".join(body_lines))


def fire_ext_resources(fire, start_id):
    """Render the ext_resources needed for a Fire.gd-controlled flame.
    Returns (block_text, lines_added). Caller appends block_text after the
    standard ext_resources and adjusts load_steps by lines_added."""
    if fire is None:
        return ("", 0)
    block = (
        f'\n[ext_resource type="Script" path="res://Scripts/Fire.gd" id="{start_id}"]'
        f'\n[ext_resource type="Material" path="res://Effects/Files/MT_Candle_Fire.tres" id="{start_id + 1}"]'
        f'\n[ext_resource type="Material" path="res://Effects/Emitters/Fire.tres" id="{start_id + 2}"]'
        f'\n[ext_resource type="Script" path="res://Scripts/Flicker.gd" id="{start_id + 3}"]'
    )
    return (block, 4)


def fire_quadmesh_subresource(fire):
    """QuadMesh sub_resource for the flame quad. Returns (text, count)."""
    if fire is None:
        return ("", 0)
    sx, sy = fire.get("flame_size", (0.05, 0.05))
    ox, oy, oz = fire.get("flame_offset", (0, 0.015, 0))
    return (
        f'\n[sub_resource type="QuadMesh" id="QuadMesh_flame"]'
        f'\nsize = Vector2({sx}, {sy})'
        f'\ncenter_offset = Vector3({ox}, {oy}, {oz})\n',
        1,
    )


def fire_root_script_attrs(fire, script_id):
    """Attributes to add to the scene root node header + body when fire is
    enabled. Returns (header_extra, body_extra). Caller adds these to the
    scene root's node line and the lines immediately following."""
    if fire is None:
        return ("", "")
    header_extra = ' node_paths=PackedStringArray("effect", "light")'
    body_extra = (
        f'\nscript = ExtResource("{script_id}")'
        f'\neffect = NodePath("VFX")'
        f'\nlight = NodePath("VFX/Light")'
    )
    return (header_extra, body_extra)


def fire_vfx_node_block(fire, fire_mat_id, fire_emit_id, flicker_script_id):
    """Render the VFX (GPUParticles3D) + Light (OmniLight3D) sibling block
    that Fire.gd toggles via Activate()/Deactivate()."""
    if fire is None:
        return ""
    px, py, pz = fire["pos"]
    color = fire.get("light_color", (0.94, 0.78, 0.67))
    energy = fire.get("light_energy", 0.25)
    min_energy = fire.get("light_min_energy", 0.2)
    max_energy = fire.get("light_max_energy", 0.4)
    freq = fire.get("light_flicker_freq", 0.2)
    rng = fire.get("light_range", 1.0)
    amount = fire.get("particle_amount", 1)
    lifetime = fire.get("particle_lifetime", 2.0)
    local_coords_line = "\nlocal_coords = true" if fire.get("local_coords") else ""
    return f"""
[node name="VFX" type="GPUParticles3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {px}, {py}, {pz})
visible = false
material_override = ExtResource("{fire_mat_id}")
cast_shadow = 0
amount = {amount}
lifetime = {lifetime}
fixed_fps = 60{local_coords_line}
transform_align = 1
process_material = ExtResource("{fire_emit_id}")
draw_pass_1 = SubResource("QuadMesh_flame")

[node name="Light" type="OmniLight3D" parent="VFX"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)
light_color = Color({color[0]}, {color[1]}, {color[2]}, 1)
light_energy = {energy}
shadow_enabled = true
distance_fade_enabled = true
distance_fade_shadow = 20.0
omni_range = {rng}
script = ExtResource("{flicker_script_id}")
maxEnergy = {max_energy}
minEnergy = {min_energy}
frequency = {freq}
"""


def bulb_node(bulb, name="Bulb"):
    """Render the Bulb MeshInstance3D node parented to Mesh, plus an
    optional short-range OmniLight3D child to actually light the inside
    of the shade (the StandardMaterial3D's emission is just a visual on
    the sphere itself — it doesn't cast light onto other surfaces).
    """
    if bulb is None:
        return ""
    pos = bulb["pos"]
    color = bulb.get("color", (1.0, 1.0, 1.0))
    glow_range = bulb.get("glow_light_range", 0.0)
    glow_energy = bulb.get("glow_light_energy", 0.0)

    base = f"""
[node name="{name}" type="MeshInstance3D" parent="Mesh"]
transform = {transform3d(1, 0, 0, 0, 1, 0, 0, 0, 1, *pos)}
mesh = SubResource("SphereMesh_bulb")
cast_shadow = 0
"""
    if glow_range > 0 and glow_energy > 0:
        base += f"""
[node name="GlowLight" type="OmniLight3D" parent="{name}"]
light_color = Color({color[0]}, {color[1]}, {color[2]}, 1)
light_energy = {glow_energy}
shadow_enabled = false
omni_range = {glow_range}
"""
    return base


def render_tscn(spec):
    """Generate the placeable _F.tscn for a fixture."""
    fid = spec["id"]
    name_caps = "".join(part.capitalize() for part in fid.replace("rtvlights_", "").split("_")) + "_F"
    mesh = spec["mesh"]
    material = spec["material"]
    icon_path = f"res://mods/RTVHideoutLights/assets/icons/{spec['icon']}"
    tres_path = f"res://mods/RTVHideoutLights/items/{fid}_F.tres"
    surface = spec["surface"]
    aabb = spec["aabb"]
    mount = spec["mount"]

    # Read the actual mesh AABB extents (not just sizes) so we can position
    # rays/area/parenter/hint at the real AABB center. Most game meshes have
    # off-origin AABBs — Candle starts at Y=0 (origin at base), Lamp_Grid
    # ends at Y=0 (origin at top), Sign_Exit starts at Z=0 (origin at back).
    # Using (0,0,0) as center caused fixtures to float off surfaces by
    # several cm — much worse for tall lamps (Lamp_Floor floated 1m).
    xmin, xmax, ymin, ymax, zmin, zmax = parse_obj_aabb(spec["mesh"])

    # Transform mesh-local AABB into scene-local AABB based on mount.
    # For ceiling, mesh rotates -90° X: mesh +Y -> scene -Z, mesh +Z -> scene +Y.
    # That maps mesh axis ranges to scene axis ranges:
    #   scene X range = mesh X range (unchanged)
    #   scene Y range = mesh Z range
    #   scene Z range = -mesh Y range (sign-flipped)
    if mount == "ceiling":
        s_xmin, s_xmax = xmin, xmax
        s_ymin, s_ymax = zmin, zmax
        s_zmin, s_zmax = -ymax, -ymin
    else:
        s_xmin, s_xmax = xmin, xmax
        s_ymin, s_ymax = ymin, ymax
        s_zmin, s_zmax = zmin, zmax

    sw = s_xmax - s_xmin
    sh = s_ymax - s_ymin
    sd = s_zmax - s_zmin
    cx = (s_xmin + s_xmax) / 2.0
    cy = (s_ymin + s_ymax) / 2.0
    cz = (s_zmin + s_zmax) / 2.0

    collider_size = (sw, sh, sd)
    area_size = (max(sw - 0.05, 0.01), max(sh - 0.05, 0.01), max(sd - 0.05, 0.01))
    parenter_size = (sw + 0.05, sh + 0.05, sd + 0.05)

    # Ray positions are RELATIVE to the rays node, which sits at the scene-
    # local AABB center (cx, cy, cz). Per Furniture.gd's ExecuteInitialize
    # formula, ray child positions are computed from sizes only — those are
    # offsets from the rays node. The shape positions and rays.position
    # below absorb the AABB center offset.
    if mount == "floor":
        # Hint plane lays flat on top surface; size is X and Z extents
        hint_size = (sw, sd)
        # Floor element: rays shoot down (-Y), positioned at top face corners
        ray_target = "Vector3(0, -0.2, 0)"
        # Per Furniture wallElement=false formula:
        # center = aabb.size/2 - (sx/2, sy, sz/2) = (0, -sy/2, 0)
        ray_center = (0, -sh / 2, 0)
        ray_topLeft = (sw / 2, -sh / 2, sd / 2)
        ray_topRight = (-sw / 2, -sh / 2, sd / 2)
        ray_bottomLeft = (sw / 2, -sh / 2, -sd / 2)
        ray_bottomRight = (-sw / 2, -sh / 2, -sd / 2)
        wall_element = "false"
        # Hint: no extra rotation, lies on XZ plane natively
        hint_xform = transform3d(1, 0, 0, 0, 1, 0, 0, 0, 1, cx, cy, cz)
    else:
        # Wall and ceiling both use wallElement=true with rays targeting -Z.
        # Default ray spread = AABB corners (sw/2, sh/2). For long fixtures
        # (e.g. 1.6m fluorescents), the corners reach ±0.8m and miss any
        # narrow surface like a beam (~0.15m), forcing placement onto the
        # ceiling above. Override with `ray_spread: (X, Y)` in the spec to
        # cluster the rays tighter so cross-beam mounting works.
        rsx, rsy = spec.get("ray_spread", (sw / 2, sh / 2))
        ray_target = "Vector3(0, 0, -0.2)"
        ray_center = (0, 0, -sd / 2)
        ray_topLeft = (-rsx, rsy, -sd / 2)
        ray_topRight = (rsx, rsy, -sd / 2)
        ray_bottomLeft = (rsx, -rsy, -sd / 2)
        ray_bottomRight = (-rsx, -rsy, -sd / 2)
        wall_element = "true"
        # Hint plane: rotate 90° X to lie flat against the wall/ceiling.
        # Position carries the scene-local X and Y center components but
        # zeros Z (matches the original ExecuteInitialize behavior:
        # `hint.position.z = mesh.position.z` where mesh is at origin).
        hint_xform = transform3d(1, 0, 0, 0, 0, -1, 0, 1, 0, cx, cy, 0)
        hint_size = (sw, sh)

    # Mount-specific scene root and mesh transforms
    if mount == "ceiling":
        root_xform = transform3d(1, 0, 0, 0, 0, -1, 0, 1, 0, 0, 0, 0)  # +90° X
        mesh_xform = transform3d(1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0)  # -90° X
    else:
        root_xform = T_IDENT
        mesh_xform = T_IDENT

    # ceiling_only = true on the Furniture node tells LightFurniture's
    # CheckRays() override to reject placement on floors. Works correctly
    # for solid floors (e.g. cabin); the attic plank-floor edge case isn't
    # caught (rays slip through gaps) but the failure mode is benign.
    ceiling_only_line = "\nceiling_only = true" if mount == "ceiling" else ""

    # Light node block (or empty for fixtures with no light)
    light_block = light_node(spec.get("light"))

    # Optional secondary light, typically used as a fill-light for fixtures
    # where the primary "down" light leaves the shade interior dark. The
    # Floor Lamp uses an uplight just below the shade opening to brighten
    # the inside of the dome (since the bulb's own emissive material can
    # only make the bulb visible, not light the shade fabric).
    uplight_block = light_node(spec.get("uplight"), name="UpLight")

    # Bulb sub_resources + node block (Floor Lamp etc. — fixtures whose mesh
    # has no vertex-color glow setup, so we add a visible emissive sphere
    # inside the shade as the "lit bulb"). load_steps grows by 2 if present.
    bulb = spec.get("bulb")
    bulb_sub_block = bulb_subresources(bulb)
    bulb_node_block = bulb_node(bulb)
    load_steps = 11 + (2 if bulb else 0)

    # Fire integration (Candle, Lantern, future fire barrel etc). Wires up
    # vanilla Fire.gd on the scene root + a VFX particle node + a flickering
    # OmniLight inside it. Player can ignite/extinguish via the standard
    # interact action. Default is unlit (well, 2% chance lit per Fire.gd's
    # _ready — vanilla quirk we accept). Adds 4 ext_resources + 1
    # sub_resource (QuadMesh).
    fire = spec.get("fire")
    fire_ext_block, fire_ext_count = fire_ext_resources(fire, start_id=20)
    fire_quad_block, fire_quad_count = fire_quadmesh_subresource(fire)
    fire_root_header_attrs, fire_root_body_attrs = fire_root_script_attrs(fire, script_id=20)
    fire_vfx_block = fire_vfx_node_block(fire, fire_mat_id=21, fire_emit_id=22, flicker_script_id=23)
    load_steps += fire_ext_count + fire_quad_count

    # LightToggle integration (Floor Lamp, PC, ceiling fixtures). Adds an
    # on/off toggle script to the scene root that supports both player Use
    # interaction (when interactable=true) and vanilla Switch.gd target
    # invocation. Mutually exclusive with `fire` (both want the scene root
    # script slot). ext_resource id 30 onward to avoid clashing with fire's 20-23.
    toggle = spec.get("toggle")
    toggle_ext_block, toggle_ext_count = toggle_ext_resources(toggle, start_id=30)
    toggle_root_header_attrs, toggle_root_body_attrs = toggle_root_attrs(
        toggle, script_id=30, off_mat_id=31, on_mat_id=32,
    )
    load_steps += toggle_ext_count

    # Combined script slot on the scene root (only one allowed). Fire wins
    # if both are set; sanity-check at spec time.
    if fire and toggle:
        raise SystemExit(f"{spec['id']}: 'fire' and 'toggle' both set — "
                         "they share the scene-root script slot")
    root_header_attrs = fire_root_header_attrs + toggle_root_header_attrs
    root_body_attrs = fire_root_body_attrs + toggle_root_body_attrs

    # Body groups depend on whether anything wants the player's Use action.
    # Fire fixtures and toggle.interactable fixtures both need "Interactable".
    needs_interactable = bool(fire) or (toggle and toggle.get("interactable", True))
    body_groups = '["Furniture", "Interactable"]' if needs_interactable else '["Furniture"]'

    # Multi-surface materials: some vanilla meshes have multiple surfaces
    # (e.g. Computer = body + screen). The default `material` field applies
    # one material to surface 0; `surface_materials` applies a list to
    # consecutive surface indices. Vanilla Computer_Lit.tscn pattern:
    #   surface 0 = MT_Computer.tres        (body)
    #   surface 1 = MT_Computer_Screen_Lit.tres  (lit screen, cyan UI)
    extra_surface_materials = spec.get("surface_materials", [])
    if extra_surface_materials:
        extra_ext_lines = []
        surface_override_lines = [f'surface_material_override/0 = ExtResource("2")']
        for idx, path in enumerate(extra_surface_materials, start=1):
            ext_id = 10 + idx  # ids 11, 12, ... avoid clashing with 1-7
            extra_ext_lines.append(f'[ext_resource type="Material" path="{path}" id="{ext_id}"]')
            surface_override_lines.append(f'surface_material_override/{idx} = ExtResource("{ext_id}")')
        extra_ext_block = "\n" + "\n".join(extra_ext_lines)
        mesh_surface_overrides = "\n".join(surface_override_lines)
        load_steps += len(extra_surface_materials)
    else:
        extra_ext_block = ""
        mesh_surface_overrides = 'surface_material_override/0 = ExtResource("2")'

    return f"""; Auto-generated by tools/generate_lights_skus.py — DO NOT HAND-EDIT.
; Edit the FIXTURES list in that script and re-run.
[gd_scene load_steps={load_steps} format=3]

[ext_resource type="ArrayMesh" path="{mesh}" id="1"]
[ext_resource type="Material" path="{material}" id="2"]
[ext_resource type="Script" path="res://Scripts/Surface.gd" id="3"]
[ext_resource type="Script" path="res://mods/RTVHideoutLights/LightFurniture.gd" id="4"]
[ext_resource type="Resource" path="{tres_path}" id="5"]
[ext_resource type="Texture2D" path="res://UI/Sprites/Icon_Object.png" id="6"]
[ext_resource type="Material" path="res://Modular/Materials/MT_Hint.tres" id="7"]{extra_ext_block}{fire_ext_block}{toggle_ext_block}

[sub_resource type="BoxShape3D" id="BoxShape3D_collider"]
size = Vector3({collider_size[0]}, {collider_size[1]}, {collider_size[2]})

[sub_resource type="BoxShape3D" id="BoxShape3D_area"]
size = Vector3({area_size[0]}, {area_size[1]}, {area_size[2]})

[sub_resource type="BoxShape3D" id="BoxShape3D_parenter"]
size = Vector3({parenter_size[0]}, {parenter_size[1]}, {parenter_size[2]})

[sub_resource type="PlaneMesh" id="PlaneMesh_hint"]
material = ExtResource("7")
size = Vector2({hint_size[0]}, {hint_size[1]})
{bulb_sub_block}{fire_quad_block}

[node name="{name_caps}" type="Node3D"{root_header_attrs}]{root_body_attrs}
transform = {root_xform}

[node name="Mesh" type="MeshInstance3D" parent="."]
transform = {mesh_xform}
cast_shadow = 0
mesh = ExtResource("1")
{mesh_surface_overrides}

[node name="Collider_R" type="MeshInstance3D" parent="."]
transform = {mesh_xform}
layers = 0
mesh = ExtResource("1")

[node name="StaticBody3D" type="StaticBody3D" parent="Collider_R" groups={body_groups}]
collision_layer = 16
script = ExtResource("3")
surface = "{surface}"

[node name="CollisionShape3D" type="CollisionShape3D" parent="Collider_R/StaticBody3D"]
shape = SubResource("BoxShape3D_collider")
{light_block}{uplight_block}{bulb_node_block}{fire_vfx_block}
[node name="Furniture" type="Node3D" parent="." node_paths=PackedStringArray("mesh", "colliderR")]
script = ExtResource("4")
itemData = ExtResource("5")
mesh = NodePath("../Mesh")
colliderR = NodePath("../Collider_R")
wallElement = {wall_element}{ceiling_only_line}

[node name="Indicator" type="Sprite3D" parent="Furniture"]
modulate = Color(0, 1, 0, 0.25098)
pixel_size = 0.0005
billboard = 1
double_sided = false
no_depth_test = true
render_priority = 1
texture = ExtResource("6")

[node name="Area" type="Area3D" parent="Furniture"]
collision_mask = 8255

[node name="CollisionShape3D" type="CollisionShape3D" parent="Furniture/Area"]
transform = {transform3d(1, 0, 0, 0, 1, 0, 0, 0, 1, cx, cy, cz)}
shape = SubResource("BoxShape3D_area")

[node name="Parenter" type="Area3D" parent="Furniture"]
collision_layer = 0
collision_mask = 4

[node name="CollisionShape3D" type="CollisionShape3D" parent="Furniture/Parenter"]
transform = {transform3d(1, 0, 0, 0, 1, 0, 0, 0, 1, cx, cy, cz)}
shape = SubResource("BoxShape3D_parenter")

[node name="Rays" type="Node3D" parent="Furniture"]
transform = {transform3d(1, 0, 0, 0, 1, 0, 0, 0, 1, cx, cy, cz)}

[node name="Ray_01" type="RayCast3D" parent="Furniture/Rays"]
transform = {transform3d(1, 0, 0, 0, 1, 0, 0, 0, 1, *ray_center)}
target_position = {ray_target}

[node name="Ray_02" type="RayCast3D" parent="Furniture/Rays"]
transform = {transform3d(1, 0, 0, 0, 1, 0, 0, 0, 1, *ray_topLeft)}
target_position = {ray_target}

[node name="Ray_03" type="RayCast3D" parent="Furniture/Rays"]
transform = {transform3d(1, 0, 0, 0, 1, 0, 0, 0, 1, *ray_topRight)}
target_position = {ray_target}

[node name="Ray_04" type="RayCast3D" parent="Furniture/Rays"]
transform = {transform3d(1, 0, 0, 0, 1, 0, 0, 0, 1, *ray_bottomLeft)}
target_position = {ray_target}

[node name="Ray_05" type="RayCast3D" parent="Furniture/Rays"]
transform = {transform3d(1, 0, 0, 0, 1, 0, 0, 0, 1, *ray_bottomRight)}
target_position = {ray_target}

[node name="Hint" type="MeshInstance3D" parent="Furniture"]
transform = {hint_xform}
mesh = SubResource("PlaneMesh_hint")
"""


def render_tres(spec):
    """Generate the ItemData _F.tres for a fixture.

    v1 stocks every fixture at the three currently-revealed traders
    (Generalist, Gunsmith, Doctor) so players see them everywhere they
    shop. Grandma is intentionally skipped — she's still story-hidden.
    We'll scale this back per-fixture in a later release based on user
    feedback. The spec's `trader` field is currently inert; kept for
    forward compatibility when we re-introduce per-fixture targeting.
    """
    fid = spec["id"]
    name = spec["name"]
    grid = spec["grid"]
    icon_path = f"res://mods/RTVHideoutLights/assets/icons/{spec['icon']}"
    tetris_name = f"{fid}_{grid[0]}x{grid[1]}.tscn"
    tetris_path = f"res://mods/RTVHideoutLights/scenes/{tetris_name}"

    return f"""; Auto-generated by tools/generate_lights_skus.py — DO NOT HAND-EDIT.
[gd_resource type="Resource" script_class="ItemData" load_steps=4 format=3]

[ext_resource type="Script" path="res://Scripts/ItemData.gd" id="1"]
[ext_resource type="Texture2D" path="{icon_path}" id="2"]
[ext_resource type="PackedScene" path="{tetris_path}" id="3"]

[resource]
script = ExtResource("1")
file = "{fid}"
name = "{name}"
inventory = "{name}"
display = "{name}"
type = "Furniture"
weight = 0.5
value = {spec['value']}
rarity = 4
icon = ExtResource("2")
tetris = ExtResource("3")
size = Vector2({grid[0]}, {grid[1]})
generalist = true
gunsmith = true
doctor = true
"""


def render_tetris(spec):
    """Generate the tetris grid sprite scene for a fixture."""
    fid = spec["id"]
    grid = spec["grid"]
    icon_path = f"res://mods/RTVHideoutLights/assets/icons/{spec['icon']}"
    # Position is the center of the grid in 64px-cell pixel coords.
    # 1 cell = 64px → grid (W, H) total = (W*64, H*64); center = (W*32, H*32).
    px, py = grid[0] * 32, grid[1] * 32
    sprite_name = fid.replace("rtvlights_", "").replace("_", " ").title().replace(" ", "_")

    return f"""; Auto-generated by tools/generate_lights_skus.py — DO NOT HAND-EDIT.
[gd_scene load_steps=3 format=3]

[ext_resource type="Material" path="res://UI/Effects/MT_Item.tres" id="1"]
[ext_resource type="Texture2D" path="{icon_path}" id="2"]

[node name="{sprite_name}" type="Sprite2D"]
material = ExtResource("1")
position = Vector2({px}, {py})
scale = Vector2(0.5, 0.5)
texture = ExtResource("2")
"""


def main():
    SCENES_DIR.mkdir(parents=True, exist_ok=True)
    ITEMS_DIR.mkdir(parents=True, exist_ok=True)
    written = 0
    for spec in FIXTURES:
        fid = spec["id"]
        grid = spec["grid"]

        tscn_path = SCENES_DIR / f"{fid}_F.tscn"
        tscn_path.write_text(render_tscn(spec), encoding="utf-8")
        written += 1

        tres_path = ITEMS_DIR / f"{fid}_F.tres"
        tres_path.write_text(render_tres(spec), encoding="utf-8")
        written += 1

        tetris_name = f"{fid}_{grid[0]}x{grid[1]}.tscn"
        tetris_path = SCENES_DIR / tetris_name
        tetris_path.write_text(render_tetris(spec), encoding="utf-8")
        written += 1

        print(f"  {fid}: {tscn_path.name}, {tres_path.name}, {tetris_path.name}")

    print(f"\nGenerated {written} files for {len(FIXTURES)} fixtures.")


if __name__ == "__main__":
    main()
