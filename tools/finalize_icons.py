#!/usr/bin/env python3
"""Finalize an icon-render pass for any mod that uses the
decompiled-project + junction workflow.

After running an icon renderer scene (e.g. `_dev_icon_renderer.tscn`)
inside Godot Editor on the decompiled project, the new PNGs sit at
`mods/<MOD>/assets/icons/` but Godot doesn't always regenerate the
compiled `.ctex` files reliably on the editor's own auto-scan. This
script:

  1. Forces a headless re-import on the decompiled project so
     `.png.import` sidecars and `.godot/imported/*.ctex` files are
     regenerated from the new source PNGs.
  2. Syncs the freshly-regenerated `.ctex` + `.md5` files from the
     decompiled project's cache into the mod's own
     `mods/<MOD>/.godot/imported/` cache (the build script bundles
     this into the .vmz; the decompiled cache isn't bundled).
  3. Runs `publish.bat <MOD> --no-open` to rebuild the .vmz with the
     matched cache + new PNGs and install it to the game folder.

After this, fully exit and re-launch Road to Vostok so Metro re-mounts
the new .vmz. Save reload alone won't pick up new mod content.

Discovery:
- Icons are auto-discovered by scanning `mods/<MOD>/assets/icons/*.png`,
  so any new icon PNGs added to the renderer will be synced without
  needing to update this script.
- Only mods that use the decompiled-project junction workflow benefit
  from this script. Mods built without that workflow handle their
  imports differently and don't need this dance.

Usage:
    python tools/finalize_icons.py <ModName>
    finalize_icons.bat <ModName>

Examples:
    finalize_icons.bat RTVHideoutLights
    finalize_icons.bat CatAutoFeed
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parent.parent
DECOMPILED = WORKSPACE / "reference" / "RTV_decompiled"
DECOMPILED_CACHE = DECOMPILED / ".godot" / "imported"
GODOT = WORKSPACE / "tools" / "Godot" / "Godot_v4.6.2-stable_win64_console.exe"
PUBLISH_BAT = WORKSPACE / "publish.bat"


def step1_reimport() -> None:
    """Run Godot headless on the decompiled project to force re-import
    of any source asset whose timestamp is newer than its .png.import
    sidecar (which is the case after the icon renderer overwrites the
    PNGs)."""
    print("[finalize_icons] Step 1: forcing Godot re-import...")
    if not GODOT.exists():
        raise SystemExit(f"Godot binary not found: {GODOT}")
    if not DECOMPILED.is_dir():
        raise SystemExit(f"Decompiled project not found: {DECOMPILED}")
    cmd = [
        str(GODOT), "--headless", "--quit", "--editor",
        "--path", str(DECOMPILED),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    if "Icon_" in result.stdout:
        for line in result.stdout.splitlines():
            if "Icon_" in line and "reimport" in line.lower():
                print(f"  {line.strip()}")
    print("  re-import done")


def step2_sync_cache(mod_name: str) -> None:
    """Copy the freshly-regenerated .ctex + .md5 files for the mod's
    icons from the decompiled project's import cache into the mod's
    own cache. Auto-discovers which icons to sync by scanning the
    mod's icons folder."""
    print(f"[finalize_icons] Step 2: syncing .ctex cache for {mod_name}...")
    mod_dir = WORKSPACE / "mods" / mod_name
    icons_dir = mod_dir / "assets" / "icons"
    mod_cache = mod_dir / ".godot" / "imported"
    if not icons_dir.is_dir():
        raise SystemExit(f"No icons folder at {icons_dir} — nothing to sync")
    mod_cache.mkdir(parents=True, exist_ok=True)
    icon_stems = sorted({p.stem for p in icons_dir.glob("*.png")})
    if not icon_stems:
        print(f"  no PNGs found in {icons_dir}")
        return
    # Wipe old icon ctex/md5 from mod cache so we don't end up with
    # orphans pointing to obsolete hashes.
    wiped = 0
    for old in mod_cache.iterdir():
        if old.is_file() and any(old.name.startswith(s + ".png-") for s in icon_stems):
            old.unlink()
            wiped += 1
    copied = 0
    missing: list[str] = []
    for stem in icon_stems:
        srcs = list(DECOMPILED_CACHE.glob(f"{stem}.png-*"))
        if not srcs:
            missing.append(stem)
            continue
        for src in srcs:
            shutil.copy2(src, mod_cache / src.name)
            copied += 1
    print(f"  wiped {wiped}, copied {copied} files into mod cache")
    if missing:
        print(f"  WARNING: no cache entries found in decompiled "
              f"project for: {', '.join(missing)}")


def step3_build_vmz(mod_name: str) -> None:
    """Run publish.bat to rebuild the .vmz and install it to the game
    folder. Uses --no-open so the browser doesn't pop up."""
    print(f"[finalize_icons] Step 3: building {mod_name}.vmz...")
    if not PUBLISH_BAT.exists():
        raise SystemExit(f"publish.bat not found: {PUBLISH_BAT}")
    result = subprocess.run(
        [str(PUBLISH_BAT), mod_name, "--no-open"],
        cwd=str(WORKSPACE),
        capture_output=True,
        text=True,
        timeout=120,
        shell=True,
    )
    print(result.stdout.strip())
    if result.returncode != 0:
        print(result.stderr.strip(), file=sys.stderr)
        raise SystemExit(f"publish.bat failed with code {result.returncode}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Finalize an icon-render pass: force Godot re-import, "
                    "sync ctex cache to the mod, build + install .vmz."
    )
    parser.add_argument(
        "mod_name",
        help="Mod folder name under mods/ (e.g. RTVHideoutLights)",
    )
    args = parser.parse_args()

    if not (WORKSPACE / "mods" / args.mod_name).is_dir():
        raise SystemExit(f"Mod folder not found: mods/{args.mod_name}")

    step1_reimport()
    step2_sync_cache(args.mod_name)
    step3_build_vmz(args.mod_name)
    print()
    print("[finalize_icons] DONE.")
    print("    Now FULLY exit Road to Vostok (close to desktop) and")
    print("    re-launch — Metro re-mounts .vmz on game launch only.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
