#!/usr/bin/env python3
"""Capture a snapshot of the current Road to Vostok decompiled scripts into the
RTV_history git repo, tagged with the game version + Steam build id.

Usage:
    python snapshot.py                     # uses defaults, auto-detects version
    python snapshot.py --label 0.1.0.0     # override version label
    python snapshot.py --dry-run           # print what would happen, do nothing
    python snapshot.py --init              # initialize RTV_history repo if missing

Detects:
    - Game version from RTV_decompiled/project.godot (config/version=...)
    - Steam build id from appmanifest_1963610.acf

Excludes from snapshot:
    - mods/ subfolder (user mods, not game content)
    - gdre_export.log
    - .godot/ cache
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

WORKSPACE = Path(r"F:\RoadToVostokMods")
SOURCE_DIR = WORKSPACE / "reference" / "RTV_decompiled"
HISTORY_DIR = WORKSPACE / "reference" / "RTV_history"
APPMANIFEST = Path(r"C:\Program Files (x86)\Steam\steamapps\appmanifest_1963610.acf")

EXCLUDE_TOPLEVEL = {"mods", ".godot", "gdre_export.log"}


def detect_version(project_godot: Path) -> str | None:
    if not project_godot.exists():
        return None
    text = project_godot.read_text(encoding="utf-8", errors="replace")
    m = re.search(r'^\s*config/version\s*=\s*"([^"]+)"', text, re.MULTILINE)
    return m.group(1) if m else None


def detect_buildid(appmanifest: Path) -> str | None:
    if not appmanifest.exists():
        return None
    text = appmanifest.read_text(encoding="utf-8", errors="replace")
    m = re.search(r'"buildid"\s+"(\d+)"', text)
    return m.group(1) if m else None


def run_git(args: list[str], cwd: Path, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", *args], cwd=cwd, check=check, text=True, capture_output=True
    )


def init_repo(history_dir: Path) -> None:
    history_dir.mkdir(parents=True, exist_ok=True)
    if (history_dir / ".git").exists():
        print(f"[skip] repo already initialized at {history_dir}")
        return
    run_git(["init", "-b", "main"], cwd=history_dir)
    gitignore = history_dir / ".gitignore"
    gitignore.write_text(
        "# snapshot exclusions (also enforced by snapshot.py)\n"
        ".godot/\n"
        "gdre_export.log\n"
        "mods/\n",
        encoding="utf-8",
    )
    readme = history_dir / "README.md"
    readme.write_text(
        "# RTV_history\n\n"
        "Versioned snapshots of decompiled Road to Vostok scripts, one commit per game patch.\n\n"
        "Managed by `tools/version_tracker/snapshot.py`. Do not edit by hand.\n\n"
        "Tags use the pattern `game-v<version>-build<buildid>`.\n",
        encoding="utf-8",
    )
    run_git(["add", ".gitignore", "README.md"], cwd=history_dir)
    run_git(
        ["commit", "-m", "Initialize RTV_history repo"],
        cwd=history_dir,
    )
    print(f"[init] created {history_dir} as a git repo")


def sync(source: Path, dest: Path, exclude: set[str], dry_run: bool) -> None:
    if not source.exists():
        raise SystemExit(f"source dir missing: {source}")

    existing_top = {p.name for p in dest.iterdir() if p.name != ".git" and p.name != "README.md"}
    incoming_top = {p.name for p in source.iterdir() if p.name not in exclude}

    to_remove = existing_top - incoming_top - {".gitignore"}
    for name in sorted(to_remove):
        target = dest / name
        print(f"[delete] {target}")
        if not dry_run:
            if target.is_dir():
                shutil.rmtree(target)
            else:
                target.unlink()

    for name in sorted(incoming_top):
        src = source / name
        dst = dest / name
        print(f"[copy]   {name}")
        if dry_run:
            continue
        if src.is_dir():
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(src, dst)
        else:
            shutil.copy2(src, dst)


def commit_and_tag(
    history_dir: Path,
    version: str,
    buildid: str | None,
    message: str | None,
    dry_run: bool,
) -> str | None:
    status = run_git(["status", "--porcelain"], cwd=history_dir, check=True).stdout
    if not status.strip():
        print("[skip] no changes to commit — snapshot is identical to HEAD")
        return None

    if buildid:
        tag = f"game-v{version}-build{buildid}"
    else:
        tag = f"game-v{version}"

    if not message:
        iso = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
        buildpart = f", build {buildid}" if buildid else ""
        message = f"Game v{version}{buildpart} (captured {iso})"

    print(f"[commit] {message}")
    print(f"[tag]    {tag}")
    if dry_run:
        return tag

    run_git(["add", "-A"], cwd=history_dir)
    run_git(["commit", "-m", message], cwd=history_dir)

    existing_tags = run_git(["tag", "--list", tag], cwd=history_dir).stdout.strip()
    if existing_tags:
        print(f"[warn] tag {tag} already exists — not re-tagging (rename or delete first)")
    else:
        run_git(["tag", tag], cwd=history_dir)
    return tag


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--source", type=Path, default=SOURCE_DIR, help=f"source decompile dir (default: {SOURCE_DIR})")
    p.add_argument("--history", type=Path, default=HISTORY_DIR, help=f"history repo dir (default: {HISTORY_DIR})")
    p.add_argument("--label", help="override auto-detected version label")
    p.add_argument("--build", help="override auto-detected build id (use when appmanifest has drifted past the decompiled version)")
    p.add_argument("--message", help="override commit message")
    p.add_argument("--dry-run", action="store_true", help="print planned actions without writing")
    p.add_argument("--init", action="store_true", help="initialize history repo if missing")
    return p.parse_args()


def main() -> int:
    args = parse_args()

    if args.init or not (args.history / ".git").exists():
        if not args.dry_run:
            init_repo(args.history)
        else:
            print(f"[dry-run] would init repo at {args.history}")
            if not (args.history / ".git").exists():
                print("[dry-run] repo doesn't exist yet — aborting further actions")
                return 0

    version = args.label or detect_version(args.source / "project.godot")
    if not version:
        raise SystemExit("could not detect version — pass --label to override")
    buildid = args.build or detect_buildid(APPMANIFEST)

    project_version = detect_version(args.source / "project.godot")
    if args.label and project_version and project_version != args.label and not args.build:
        print(
            f"[warn] --label {args.label!r} doesn't match project.godot ({project_version!r}); "
            f"appmanifest buildid {buildid} probably doesn't apply — pass --build explicitly"
        )

    print(f"version: {version}")
    print(f"buildid: {buildid or '(not found)'}")
    print(f"source:  {args.source}")
    print(f"history: {args.history}")
    print()

    sync(args.source, args.history, EXCLUDE_TOPLEVEL, args.dry_run)
    tag = commit_and_tag(args.history, version, buildid, args.message, args.dry_run)

    if tag and not args.dry_run:
        print(f"\n[done] snapshot committed and tagged as {tag}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
