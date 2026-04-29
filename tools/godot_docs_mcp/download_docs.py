"""Download or update the Godot documentation source for use by the
godot_docs_mcp server.

Performs a shallow, single-branch git clone of godotengine/godot-docs at the
configured branch into ``reference/godot_docs/`` (gitignored). On subsequent
runs, re-syncs the existing clone instead of re-cloning.

Usage:
    python download_docs.py                  # uses default branch
    python download_docs.py --branch 4.7     # pin to a different version
    python download_docs.py --refresh        # force-resync to latest of branch

The default branch should match the Godot Editor / decompiled-game version this
workspace targets. Update ``DEFAULT_BRANCH`` below when the game upgrades.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

DEFAULT_BRANCH = "4.6"
REPO_URL = "https://github.com/godotengine/godot-docs.git"

# Resolve workspace root from this file's location:
#   tools/godot_docs_mcp/download_docs.py  →  workspace root is two levels up.
WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_DEST = WORKSPACE_ROOT / "reference" / "godot_docs"


def run(cmd: list[str], *, cwd: Path | None = None) -> None:
    print(f"  $ {' '.join(cmd)}")
    subprocess.run(cmd, cwd=cwd, check=True)


def clone(dest: Path, branch: str) -> None:
    print(f"Cloning godot-docs @ {branch} into {dest} ...")
    dest.parent.mkdir(parents=True, exist_ok=True)
    run([
        "git", "clone",
        "--depth", "1",
        "--branch", branch,
        "--single-branch",
        REPO_URL,
        str(dest),
    ])


def refresh(dest: Path, branch: str) -> None:
    print(f"Refreshing godot-docs @ {branch} in {dest} ...")
    run(["git", "fetch", "--depth", "1", "origin", branch], cwd=dest)
    run(["git", "reset", "--hard", f"origin/{branch}"], cwd=dest)


def existing_branch(dest: Path) -> str | None:
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=dest,
            text=True,
        ).strip()
        return out or None
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def main() -> int:
    parser = argparse.ArgumentParser(description="Fetch Godot docs source for godot_docs_mcp.")
    parser.add_argument(
        "--branch",
        default=DEFAULT_BRANCH,
        help=f"godot-docs branch to clone (default: {DEFAULT_BRANCH})",
    )
    parser.add_argument(
        "--dest",
        type=Path,
        default=DEFAULT_DEST,
        help=f"destination directory (default: {DEFAULT_DEST})",
    )
    parser.add_argument(
        "--refresh",
        action="store_true",
        help="re-sync an existing clone to the latest of its branch",
    )
    args = parser.parse_args()

    dest: Path = args.dest

    if not dest.exists():
        clone(dest, args.branch)
        print(f"Done. Clone size: see ``du -sh {dest}``.")
        return 0

    current = existing_branch(dest)
    if current is None:
        print(f"WARNING: {dest} exists but is not a git repo. Aborting.", file=sys.stderr)
        print("Move it aside and re-run, or delete it to allow a fresh clone.", file=sys.stderr)
        return 1

    if current != args.branch:
        print(
            f"WARNING: existing clone is on branch '{current}', not '{args.branch}'.",
            file=sys.stderr,
        )
        print(
            "Delete the directory to switch branches, or use --branch to match.",
            file=sys.stderr,
        )
        return 1

    if args.refresh:
        refresh(dest, args.branch)
        print("Done.")
    else:
        print(f"Already cloned at {dest} (branch {current}). Use --refresh to update.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
