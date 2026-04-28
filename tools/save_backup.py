#!/usr/bin/env python3
"""Backup and restore Road to Vostok save files.

Source: %APPDATA%\\Road to Vostok\\
Destination: F:\\RoadToVostokMods\\save_backups\\<name>\\

Backs up .tres save files, the MCM/ directory, and mod_config.cfg.
Skips regenerable cache directories (shader_cache, vmz_mount_cache, vulkan, logs).

Usage:
    python save_backup.py backup [--label LABEL]   # snapshot current saves
    python save_backup.py list                     # show existing backups
    python save_backup.py restore <name>           # restore (use 'latest' for most recent)
    python save_backup.py delete <name>            # remove a backup
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
from datetime import datetime
from pathlib import Path

SAVE_DIR = Path(os.environ["APPDATA"]) / "Road to Vostok"
BACKUP_ROOT = Path(__file__).resolve().parent.parent / "save_backups"

INCLUDE_FILES_GLOB = ["*.tres", "mod_config.cfg"]
INCLUDE_DIRS = ["MCM"]


def timestamp() -> str:
    return datetime.now().strftime("%Y-%m-%d_%H-%M-%S")


def list_backup_items(src: Path) -> tuple[list[Path], list[Path]]:
    """Return (files, dirs) to include in a backup."""
    files: list[Path] = []
    for pattern in INCLUDE_FILES_GLOB:
        files.extend(sorted(src.glob(pattern)))
    dirs = [src / d for d in INCLUDE_DIRS if (src / d).is_dir()]
    return files, dirs


def do_backup(label: str | None = None, dest_override: Path | None = None) -> Path:
    if not SAVE_DIR.exists():
        sys.exit(f"Save folder not found: {SAVE_DIR}")

    if dest_override is not None:
        dest = dest_override
    else:
        name = timestamp() + (f"-{label}" if label else "")
        dest = BACKUP_ROOT / name

    if dest.exists():
        sys.exit(f"Backup already exists: {dest}")

    dest.mkdir(parents=True)
    files, dirs = list_backup_items(SAVE_DIR)

    if not files and not dirs:
        dest.rmdir()
        sys.exit(f"No save files found in {SAVE_DIR}")

    for f in files:
        shutil.copy2(f, dest / f.name)
    for d in dirs:
        shutil.copytree(d, dest / d.name)

    total_bytes = sum(p.stat().st_size for p in dest.rglob("*") if p.is_file())
    print(f"Backed up to {dest}")
    print(f"  {len(files)} files, {len(dirs)} dirs, {total_bytes / 1024:.1f} KB")
    return dest


def do_list() -> int:
    if not BACKUP_ROOT.exists():
        print("No backups yet.")
        return 0
    entries = sorted([p for p in BACKUP_ROOT.iterdir() if p.is_dir()])
    if not entries:
        print("No backups yet.")
        return 0
    print(f"Backups in {BACKUP_ROOT}:")
    for p in entries:
        size = sum(f.stat().st_size for f in p.rglob("*") if f.is_file())
        print(f"  {p.name}  ({size / 1024:.1f} KB)")
    return 0


def resolve_backup(name: str) -> Path:
    if not BACKUP_ROOT.exists():
        sys.exit(f"No backups directory: {BACKUP_ROOT}")

    if name == "latest":
        # Exclude pre-restore-* snapshots: those are auto-created safety nets
        # written by do_restore() before clobbering the live save folder, not
        # user-intended backups. They also break a pure name sort (the prefix
        # sorts after plain "2026-..." timestamps in ASCII), so without this
        # filter "latest" would pick the most recent pre-restore over the
        # most recent real backup. Still resolvable by explicit name.
        entries = sorted(
            p for p in BACKUP_ROOT.iterdir()
            if p.is_dir() and not p.name.startswith("pre-restore-")
        )
        if not entries:
            sys.exit("No backups to restore.")
        return entries[-1]

    candidate = BACKUP_ROOT / name
    if candidate.is_dir():
        return candidate
    sys.exit(f"Backup not found: {candidate}")


def clear_save_targets() -> None:
    """Remove the files/dirs we manage from the save folder."""
    files, dirs = list_backup_items(SAVE_DIR)
    for f in files:
        f.unlink()
    for d in dirs:
        shutil.rmtree(d)


def do_restore(name: str, yes: bool = False) -> int:
    src = resolve_backup(name)

    print(f"About to restore from: {src}")
    print(f"             into:     {SAVE_DIR}")
    print("Current save state will be snapshotted first to a 'pre-restore' backup.")
    if not yes:
        resp = input("Proceed? [y/N]: ").strip().lower()
        if resp not in ("y", "yes"):
            print("Aborted.")
            return 1

    if SAVE_DIR.exists():
        pre_name = f"pre-restore-{timestamp()}"
        try:
            do_backup(dest_override=BACKUP_ROOT / pre_name)
        except SystemExit as e:
            if str(e).startswith("No save files"):
                print("(No existing saves to snapshot — skipping pre-restore.)")
            else:
                raise

        clear_save_targets()
    else:
        SAVE_DIR.mkdir(parents=True)

    for entry in src.iterdir():
        target = SAVE_DIR / entry.name
        if entry.is_dir():
            shutil.copytree(entry, target)
        else:
            shutil.copy2(entry, target)

    print(f"Restored {name} into {SAVE_DIR}")
    return 0


def do_delete(name: str, yes: bool = False) -> int:
    if name == "latest":
        sys.exit("Refusing to delete 'latest' — name it explicitly.")
    target = BACKUP_ROOT / name
    if not target.is_dir():
        sys.exit(f"Backup not found: {target}")
    if not yes:
        resp = input(f"Delete {target}? [y/N]: ").strip().lower()
        if resp not in ("y", "yes"):
            print("Aborted.")
            return 1
    shutil.rmtree(target)
    print(f"Deleted {target}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_backup = sub.add_parser("backup", help="Snapshot current save files")
    p_backup.add_argument("--label", help="Optional label appended to the backup name")

    sub.add_parser("list", help="List existing backups")

    p_restore = sub.add_parser("restore", help="Restore a backup")
    p_restore.add_argument("name", help="Backup folder name, or 'latest'")
    p_restore.add_argument("-y", "--yes", action="store_true", help="Skip confirmation")

    p_delete = sub.add_parser("delete", help="Delete a backup")
    p_delete.add_argument("name", help="Backup folder name")
    p_delete.add_argument("-y", "--yes", action="store_true", help="Skip confirmation")

    args = parser.parse_args()

    if args.cmd == "backup":
        do_backup(args.label)
        return 0
    if args.cmd == "list":
        return do_list()
    if args.cmd == "restore":
        return do_restore(args.name, args.yes)
    if args.cmd == "delete":
        return do_delete(args.name, args.yes)
    return 1


if __name__ == "__main__":
    sys.exit(main())
