#!/usr/bin/env python3
"""Package the RTVModLogger demo mod into a .vmz archive.

Usage:
    python build.py                 # builds RTVModLogger.vmz next to this script
    python build.py --install       # also copies to the game's mods/ folder
    python build.py --version 1.1.0 # bump mod.txt version before building
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
import zipfile
from pathlib import Path

MOD_ID = "RTVModLogger"
ROOT_FILES = ["mod.txt", "README.md", "CHANGELOG.md", "LOGGER.md", "LICENSE"]
MOD_FILES = ["Main.gd", "config.gd", "Logger.gd"]
GAME_MODS_DIR = Path(r"C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\mods")
VERSION_RE = re.compile(r'^(version\s*=\s*)"([^"]+)"', re.MULTILINE)


def bump_version(mod_txt: Path, new_version: str) -> str:
    text = mod_txt.read_text()
    match = VERSION_RE.search(text)
    if not match:
        raise SystemExit(f"version= line not found in {mod_txt}")
    old_version = match.group(2)
    if old_version == new_version:
        print(f"Version already {new_version}, no change")
        return old_version
    new_text = VERSION_RE.sub(rf'\g<1>"{new_version}"', text)
    mod_txt.write_text(new_text)
    print(f"Bumped version: {old_version} -> {new_version}")
    return old_version


def current_version(mod_txt: Path) -> str:
    match = VERSION_RE.search(mod_txt.read_text())
    return match.group(2) if match else "?"


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
        for f in ROOT_FILES:
            path = src_dir / f
            if path.exists():
                z.write(path, arcname=f)
        for f in MOD_FILES:
            z.write(src_dir / f, arcname=f"mods/{MOD_ID}/{f}")

    print(f"Built {out_path} v{current_version(mod_txt)} ({out_path.stat().st_size} bytes)")


def install(vmz: Path) -> None:
    if not GAME_MODS_DIR.exists():
        raise SystemExit(f"game mods dir not found: {GAME_MODS_DIR}")
    dest = GAME_MODS_DIR / vmz.name
    shutil.copy2(vmz, dest)
    print(f"Installed to {dest}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--install", action="store_true", help="Copy the .vmz into the game's mods folder")
    parser.add_argument("--version", help="Bump mod.txt to this version before building (e.g. 1.1.0)")
    args = parser.parse_args()

    src = Path(__file__).resolve().parent
    out = src / f"{MOD_ID}.vmz"

    if args.version:
        bump_version(src / "mod.txt", args.version)

    build(src, out)
    if args.install:
        install(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
