#!/usr/bin/env python3
"""One-shot Character.tres injector for testing all RTVHideoutLights SKUs.

Adds one of each fixture into the player's catalog grid by appending
ext_resources, sub_resources (SlotData wrappers), and updating the
catalog array. Re-runnable: detects existing entries and skips them.

USAGE:
  python tools/inject_lights_catalog.py

Prereq: back up Character.tres first (the script does NOT back it up).
"""

import re
from pathlib import Path

CHARACTER_TRES = Path.home() / "AppData" / "Roaming" / "Road to Vostok" / "Character.tres"

# (resource_path, sub_resource_id, gridPosition)
# Layout: single row Y=0, items packed left-to-right by width.
SKUS = [
    ("res://mods/RTVHideoutLights/items/Lamp_Cellar_Ceiling_F.tres",                  "Resource_rtvcellarwall",  (0, 0)),
    ("res://mods/RTVHideoutLights/items/rtvlights_candle_F.tres",                     "Resource_rtvcandle",      (64, 0)),
    ("res://mods/RTVHideoutLights/items/rtvlights_lantern_kerosene_F.tres",           "Resource_rtvlantern",     (192, 0)),
    ("res://mods/RTVHideoutLights/items/rtvlights_sign_exit_lit_F.tres",              "Resource_rtvsignexit",    (320, 0)),
    ("res://mods/RTVHideoutLights/items/rtvlights_lamp_grid_lit_ceiling_F.tres",      "Resource_rtvgrid",        (512, 0)),
    ("res://mods/RTVHideoutLights/items/rtvlights_lamp_generic_lit_hp_ceiling_F.tres","Resource_rtvgenerichp",   (704, 0)),
    ("res://mods/RTVHideoutLights/items/rtvlights_lamp_generic_lit_lp_ceiling_F.tres","Resource_rtvgenericlp",   (1024, 0)),
    ("res://mods/RTVHideoutLights/items/rtvlights_lamp_floor_F.tres",                 "Resource_rtvfloor",       (1344, 0)),
    ("res://mods/RTVHideoutLights/items/rtvlights_computer_lit_F.tres",               "Resource_rtvcomputer",    (1472, 0)),
]


def main():
    text = CHARACTER_TRES.read_text(encoding="utf-8")

    # Find the highest existing ext_resource id; new ones get sequential ids
    # starting from max+1. The CharacterSave script ext_resource (last one)
    # also has a numeric id we keep in place; new data resources go after it.
    existing_ext_ids = [int(m) for m in re.findall(r'^\[ext_resource[^\]]*id="(\d+)"', text, re.MULTILINE)]
    next_id = max(existing_ext_ids) + 1
    print(f"Highest existing ext_resource id: {max(existing_ext_ids)}; new ids start at {next_id}")

    # Skip SKUs whose resource path is already in the file (idempotent re-run).
    new_entries = []
    for path, sub_id, grid_pos in SKUS:
        if f'path="{path}"' in text:
            print(f"  SKIP (already present): {path}")
            continue
        new_entries.append((path, sub_id, grid_pos, next_id))
        next_id += 1

    if not new_entries:
        print("Nothing new to inject. Done.")
        return

    # Build the ext_resource block to append to the existing ext_resource list.
    # Insert just before the [sub_resource ... or [resource] block, whichever
    # comes first. Easiest: insert right after the LAST [ext_resource line.
    ext_lines = []
    sub_lines = []
    sub_ref_strs = []
    for path, sub_id, grid_pos, ext_id in new_entries:
        ext_lines.append(f'[ext_resource type="Resource" path="{path}" id="{ext_id}"]')
        sub_lines.append(_make_sub_resource(sub_id, ext_id, grid_pos))
        sub_ref_strs.append(f'SubResource("{sub_id}")')

    # Find the position to insert the new ext_resources (after the last one).
    # We'll do it by splitting text on the last "[ext_resource" occurrence's line.
    last_ext_match = list(re.finditer(r'^\[ext_resource[^\]]*\][^\n]*\n', text, re.MULTILINE))[-1]
    insert_pos = last_ext_match.end()
    text = text[:insert_pos] + "\n".join(ext_lines) + "\n" + text[insert_pos:]

    # Insert sub_resources just before the [resource] line.
    resource_block_idx = text.index("\n[resource]\n")
    text = text[:resource_block_idx + 1] + "\n".join(sub_lines) + "\n" + text[resource_block_idx + 1:]

    # Update the catalog array. Pattern: catalog = Array[ExtResource("1")]([...])
    # Append our new SubResource refs into the array.
    catalog_pattern = re.compile(r'^(catalog = Array\[ExtResource\("1"\)\]\()(\[[^\]]*\])(\))', re.MULTILINE)
    m = catalog_pattern.search(text)
    if not m:
        raise SystemExit("Could not find 'catalog = Array[...]' line in Character.tres")
    existing_refs = m.group(2).strip("[]").strip()
    if existing_refs:
        new_refs_str = "[" + existing_refs + ", " + ", ".join(sub_ref_strs) + "]"
    else:
        new_refs_str = "[" + ", ".join(sub_ref_strs) + "]"
    text = catalog_pattern.sub(lambda mm: f"{mm.group(1)}{new_refs_str}{mm.group(3)}", text)

    CHARACTER_TRES.write_text(text, encoding="utf-8")
    print(f"\nInjected {len(new_entries)} new SKUs into catalog.")
    for path, sub_id, grid_pos, ext_id in new_entries:
        print(f"  ext={ext_id}  sub={sub_id}  pos={grid_pos}  {path}")


def _make_sub_resource(sub_id: str, ext_id: int, grid_pos):
    return f"""[sub_resource type="Resource" id="{sub_id}"]
script = ExtResource("1")
itemData = ExtResource("{ext_id}")
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
gridPosition = Vector2({grid_pos[0]}, {grid_pos[1]})
gridRotated = false
slot = ""
"""


if __name__ == "__main__":
    main()
