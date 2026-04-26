#!/usr/bin/env python3
"""Package the RegistryTest_Hostile mod into a .vmz archive."""

from __future__ import annotations

import argparse
import shutil
import sys
import zipfile
from pathlib import Path

MOD_ID = "RegistryTest_Hostile"
MOD_FILES = ["Main.gd", "HostileInject.gd"]
GAME_MODS_DIR = Path(r"C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\mods")


def build(src_dir: Path, out_path: Path) -> None:
    mod_txt = src_dir / "mod.txt"
    if not mod_txt.exists():
        raise SystemExit(f"mod.txt not found at {mod_txt}")
    for f in MOD_FILES:
        if not (src_dir / f).exists():
            raise SystemExit(f"missing source file: {src_dir / f}")
    if out_path.exists():
        out_path.unlink()
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as z:
        z.write(mod_txt, arcname="mod.txt")
        for f in MOD_FILES:
            z.write(src_dir / f, arcname=f"mods/{MOD_ID}/{f}")
    print(f"Built {out_path} ({out_path.stat().st_size} bytes)")


def install(vmz: Path) -> None:
    if not GAME_MODS_DIR.exists():
        raise SystemExit(f"game mods dir not found: {GAME_MODS_DIR}")
    dest = GAME_MODS_DIR / vmz.name
    shutil.copy2(vmz, dest)
    print(f"Installed to {dest}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--install", action="store_true")
    args = parser.parse_args()
    src = Path(__file__).resolve().parent
    out = src / f"{MOD_ID}.vmz"
    build(src, out)
    if args.install:
        install(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
