#!/usr/bin/env python3
"""Mod publish workflow: build -> install -> open ModWorkshop.

Drives a mod's existing build.py to produce a .vmz, copies it into the
game's mods/ folder, then opens the ModWorkshop edit page (or the generic
upload page for a brand-new mod) so the .vmz can be uploaded by hand.

The actual upload step still requires a browser click — ModWorkshop's
public API is GET-only at the moment.

Usage:
    python publish.py <ModName> [--version X.Y.Z] [--no-install] [--no-open] [--dry-run]

Per-mod ModWorkshop id is read from `mods/<ModName>/.publish` (a single
line: the integer mod id). If absent, the upload page is opened instead.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import webbrowser
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
MODS_DIR = WORKSPACE_ROOT / "mods"
UPLOAD_URL = "https://modworkshop.net/upload"
EDIT_URL_TEMPLATE = "https://modworkshop.net/mod/{mod_id}/edit"


def _read_publish_id(mod_dir: Path) -> int | None:
    f = mod_dir / ".publish"
    if not f.exists():
        return None
    text = f.read_text().strip()
    if not text:
        return None
    try:
        return int(text.splitlines()[0].strip())
    except ValueError:
        print(f"warning: {f} did not contain an integer mod id; ignoring", file=sys.stderr)
        return None


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("mod_name", help="Mod folder name under mods/ (e.g. CatAutoFeed)")
    p.add_argument("--version", help="Bump mod.txt to this version before building")
    p.add_argument("--no-install", action="store_true", help="Skip copying the .vmz to the game's mods/ folder")
    p.add_argument("--no-open", action="store_true", help="Skip opening the browser at the end")
    p.add_argument("--dry-run", action="store_true", help="Print what would be done, do nothing")
    args = p.parse_args()

    mod_dir = MODS_DIR / args.mod_name
    build_script = mod_dir / "build.py"
    if not build_script.exists():
        print(f"error: {build_script} not found", file=sys.stderr)
        return 2

    cmd = [sys.executable, str(build_script)]
    if args.version:
        cmd += ["--version", args.version]
    if not args.no_install:
        cmd.append("--install")

    print(f"=> {' '.join(cmd)}")
    if args.dry_run:
        print("(dry-run, not executing)")
    else:
        result = subprocess.run(cmd, cwd=mod_dir)
        if result.returncode != 0:
            print(f"build failed (exit {result.returncode})", file=sys.stderr)
            return result.returncode

    if args.no_open:
        return 0

    mod_id = _read_publish_id(mod_dir)
    if mod_id:
        url = EDIT_URL_TEMPLATE.format(mod_id=mod_id)
        print(f"=> opening edit page for mod {mod_id}: {url}")
    else:
        url = UPLOAD_URL
        print(f"=> no .publish file in {mod_dir}; opening upload page: {url}")
        print(f"   (after first publish, write the mod id into {mod_dir / '.publish'} to open edit page next time)")

    if not args.dry_run:
        webbrowser.open(url)
    return 0


if __name__ == "__main__":
    sys.exit(main())
