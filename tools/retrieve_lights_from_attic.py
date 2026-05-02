#!/usr/bin/env python3
"""Move all RTVHideoutLights fixtures from Attic.tres back into the
Character.tres catalog. Useful when stuck in unreachable spots.

Strategy:
  1. Find ext_resource ids in Attic.tres whose path starts with our mod
     prefix.
  2. Find sub_resource (FurnitureSave) blocks whose itemData references
     one of those ext_resource ids.
  3. Strip those sub_resource blocks from Attic.tres and remove their
     SubResource() references from the furnitures array.
  4. Inject one SlotData per stripped fixture into Character.tres
     catalog (using new ext_resource + sub_resource ids).

Backups go to *.tres.bak.preFurnRetrieve before any writes.
"""

import re
import shutil
from pathlib import Path

ROAMING = Path.home() / "AppData" / "Roaming" / "Road to Vostok"
ATTIC = ROAMING / "Attic.tres"
CHARACTER = ROAMING / "Character.tres"
MOD_PREFIX = "res://mods/RTVHideoutLights/"


def main():
    # --- Backup ---
    shutil.copy2(ATTIC, ATTIC.with_suffix(".tres.bak.preFurnRetrieve"))
    shutil.copy2(CHARACTER, CHARACTER.with_suffix(".tres.bak.preFurnRetrieve"))
    print("Backups: Attic.tres.bak.preFurnRetrieve, Character.tres.bak.preFurnRetrieve")

    attic = ATTIC.read_text(encoding="utf-8")

    # --- Find our ext_resource ids ---
    our_ext_ids = set()
    ext_id_to_path = {}
    for m in re.finditer(
        r'^\[ext_resource[^]]*path="(res://mods/RTVHideoutLights/items/[^"]+)"[^]]*id="(\d+)"',
        attic, re.MULTILINE,
    ):
        path, ext_id = m.group(1), m.group(2)
        our_ext_ids.add(ext_id)
        ext_id_to_path[ext_id] = path
    print(f"Found {len(our_ext_ids)} of our ext_resources in Attic")

    # --- Walk sub_resources line-by-line; identify ones referencing our items ---
    lines = attic.split("\n")
    blocks_to_strip = []  # list of (start_line, end_line_exclusive, sub_id, ext_id)
    i = 0
    while i < len(lines):
        m = re.match(r'\[sub_resource type="Resource" id="([^"]+)"\]', lines[i])
        if not m:
            i += 1
            continue
        sub_id = m.group(1)
        # Find end of block: next line starting with `[` (no leading whitespace)
        j = i + 1
        while j < len(lines) and not lines[j].startswith("["):
            j += 1
        # Check if any line in this block has `itemData = ExtResource("<our id>")`
        block_text = "\n".join(lines[i:j])
        item_match = re.search(r'itemData\s*=\s*ExtResource\("(\d+)"\)', block_text)
        if item_match and item_match.group(1) in our_ext_ids:
            blocks_to_strip.append((i, j, sub_id, item_match.group(1)))
        i = j

    print(f"Found {len(blocks_to_strip)} sub_resource blocks to move:")
    for _, _, sub_id, ext_id in blocks_to_strip:
        print(f"  {sub_id} -> {ext_id_to_path[ext_id]}")

    if not blocks_to_strip:
        print("Nothing to move. Done.")
        return

    # --- Build new Attic.tres without the stripped blocks ---
    # Reverse-iterate so line indices stay valid as we delete.
    sub_ids_removed = [sub_id for _, _, sub_id, _ in blocks_to_strip]
    fixture_paths = [ext_id_to_path[ext_id] for _, _, _, ext_id in blocks_to_strip]

    new_lines = list(lines)
    for start, end, _, _ in sorted(blocks_to_strip, key=lambda x: -x[0]):
        # Remove block lines, plus one trailing blank line if present (to keep
        # the file's blank-line separation between blocks consistent).
        del_end = end
        if del_end < len(new_lines) and new_lines[del_end] == "":
            del_end += 1
        del new_lines[start:del_end]
    attic_new = "\n".join(new_lines)

    # Drop SubResource refs from the furnitures = ... array line.
    for sub_id in sub_ids_removed:
        for variant in [f', SubResource("{sub_id}")', f'SubResource("{sub_id}"), ',
                        f'SubResource("{sub_id}")']:
            if variant in attic_new:
                attic_new = attic_new.replace(variant, "", 1)
                break

    ATTIC.write_text(attic_new, encoding="utf-8")
    print(f"Attic.tres: stripped {len(blocks_to_strip)} fixtures + array refs")

    # --- Add fixtures back to Character.tres catalog ---
    char = CHARACTER.read_text(encoding="utf-8")

    # Find next ext_resource id
    existing_ids = [int(m) for m in re.findall(r'^\[ext_resource[^\]]*id="(\d+)"', char, re.MULTILINE)]
    next_id = max(existing_ids) + 1

    # Skip paths already referenced (idempotent re-run)
    new_entries = []
    for path in fixture_paths:
        if f'path="{path}"' in char:
            print(f"  catalog already has: {path}")
            continue
        # Make a unique sub_id from the path's filename stem
        stem = path.rsplit("/", 1)[-1].replace(".tres", "")
        # Sanitize for sub_resource id (safe characters only)
        sub_id = "Resource_retrieved_" + re.sub(r"[^A-Za-z0-9_]", "_", stem).lower()[:40]
        # Ensure unique against any existing sub_resource ids in the file
        suffix = 0
        base_sub_id = sub_id
        while f'id="{sub_id}"' in char:
            suffix += 1
            sub_id = f"{base_sub_id}_{suffix}"
        new_entries.append((path, sub_id, next_id))
        next_id += 1

    if not new_entries:
        print("Character.tres: nothing new to add (all paths already present)")
        return

    # Lay out grid positions in a row at Y=128 (below the existing Y=0 row from
    # the catalog inject). 128px per row, 64px per cell horizontally — this
    # gives every fixture its own slot regardless of size; if they overlap the
    # UI handles it.
    layout_x = 0
    ext_lines = []
    sub_lines = []
    sub_refs = []
    for path, sub_id, ext_id in new_entries:
        ext_lines.append(f'[ext_resource type="Resource" path="{path}" id="{ext_id}"]')
        sub_lines.append(_make_sub_resource(sub_id, ext_id, (layout_x, 128)))
        sub_refs.append(f'SubResource("{sub_id}")')
        layout_x += 192  # generous spacing so even 5x2 fixtures don't overlap

    # Insert ext_resources after the last existing one
    last_ext = list(re.finditer(r'^\[ext_resource[^\]]*\][^\n]*\n', char, re.MULTILINE))[-1]
    char = char[:last_ext.end()] + "\n".join(ext_lines) + "\n" + char[last_ext.end():]

    # Insert sub_resources just before [resource]
    res_idx = char.index("\n[resource]\n")
    char = char[:res_idx + 1] + "\n".join(sub_lines) + "\n" + char[res_idx + 1:]

    # Append to catalog array
    catalog_pat = re.compile(r'^(catalog = Array\[ExtResource\("1"\)\]\()(\[[^\]]*\])(\))', re.MULTILINE)
    m = catalog_pat.search(char)
    if not m:
        raise SystemExit("catalog array not found")
    existing_refs = m.group(2).strip("[]").strip()
    if existing_refs:
        new_refs = "[" + existing_refs + ", " + ", ".join(sub_refs) + "]"
    else:
        new_refs = "[" + ", ".join(sub_refs) + "]"
    char = catalog_pat.sub(lambda mm: f"{mm.group(1)}{new_refs}{mm.group(3)}", char)

    CHARACTER.write_text(char, encoding="utf-8")
    print(f"Character.tres: added {len(new_entries)} SKUs into catalog at Y=128 row")


def _make_sub_resource(sub_id, ext_id, grid_pos):
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
