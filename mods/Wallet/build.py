#!/usr/bin/env python3
"""Package the Wallet mod into a .vmz archive.

Usage:
    python build.py                 # builds Wallet.vmz next to this script
    python build.py --install       # also copies to the game's mods/ folder
    python build.py --version 0.2.0 # bump mod.txt version before building
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
import zipfile
from pathlib import Path

MOD_ID = "Wallet"
ROOT_FILES = ["mod.txt", "README.md", "CHANGELOG.md", "NOTICES.txt"]
MOD_FILES = [
    "Main.gd",
    "config.gd",
    "wallets.gd",
    "ItemOverride.gd",
    "Logger.gd",
    "WalletPickup.gd",
    "DatabaseInject.gd",
    "Wallet.tres",
    "Wallet_1x1.tscn",
    "Wallet.tscn",
    "Ammo_Tin.tres",
    "Ammo_Tin_2x2.tscn",
    "Ammo_Tin.tscn",
    "Money_Case.tres",
    "Money_Case_3x2.tscn",
    "Money_Case.tscn",
]
ASSET_DIRS = ["assets"]
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
        for asset_dir in ASSET_DIRS:
            asset_root = src_dir / asset_dir
            if not asset_root.is_dir():
                continue
            for path in sorted(asset_root.rglob("*")):
                if not path.is_file():
                    continue
                if path.name.startswith("."):
                    continue
                if "_1024" in path.name or "_1536x1024" in path.name or "_master" in path.name:
                    continue
                if path.suffix.lower() in {".blend", ".blend1", ".psd", ".xcf"}:
                    continue
                rel = path.relative_to(src_dir)
                z.write(path, arcname=f"mods/{MOD_ID}/{rel.as_posix()}")

        godot_imported = src_dir / ".godot" / "imported"
        if godot_imported.is_dir():
            for path in sorted(godot_imported.rglob("*")):
                if not path.is_file():
                    continue
                rel = path.relative_to(src_dir)
                z.write(path, arcname=rel.as_posix())

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
    parser.add_argument("--version", help="Bump mod.txt to this version before building (e.g. 0.2.0)")
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
