#!/usr/bin/env python3
"""Sync Logger.gd from shared/ canonical source to every mod that uses it.

Each mod has its own Logger.gd with identity (mod_id, mod_display_name,
log_filename) set in _init(). This script replaces the rest of each mod's
Logger.gd with the canonical content from shared/Logger.gd while preserving
those three identity values.

Usage:
    python tools/sync_logger.py                # sync all mods
    python tools/sync_logger.py RTVWallets     # sync one mod
    python tools/sync_logger.py --check        # dry run, show what would change
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SHARED_LOGGER = REPO_ROOT / "shared" / "Logger.gd"
MODS_DIR = REPO_ROOT / "mods"

INIT_RE = re.compile(
    r"func _init\(\)\s*->\s*void:\s*\n"
    r"((?:[ \t]+.*\n)+)",
    re.MULTILINE,
)

IDENTITY_KEYS = ["mod_id", "mod_display_name", "log_filename"]


def extract_identity(content: str) -> dict[str, str]:
    """Extract identity assignments from _init() in a Logger.gd."""
    match = INIT_RE.search(content)
    if not match:
        return {}
    init_body = match.group(1)
    identity: dict[str, str] = {}
    for key in IDENTITY_KEYS:
        m = re.search(rf'{key}\s*=\s*"([^"]*)"', init_body)
        if m:
            identity[key] = m.group(1)
    return identity


def render_init_block(identity: dict[str, str]) -> str:
    lines = ["func _init() -> void:"]
    for key in IDENTITY_KEYS:
        value = identity.get(key, key.upper())
        lines.append(f'    {key} = "{value}"')
    return "\n".join(lines) + "\n"


def apply_identity(template_content: str, identity: dict[str, str]) -> str:
    """Replace the _init() block in template with the mod's identity."""
    new_init = render_init_block(identity)
    return INIT_RE.sub(new_init, template_content, count=1)


def sync_one(mod_dir: Path, template_content: str, check_only: bool) -> str:
    logger_path = mod_dir / "Logger.gd"
    if not logger_path.exists():
        return f"[skip] {mod_dir.name}: no Logger.gd"

    current = logger_path.read_text(encoding="utf-8")
    identity = extract_identity(current)
    if not identity:
        return f"[warn] {mod_dir.name}: could not extract identity — leaving untouched"

    new_content = apply_identity(template_content, identity)
    if new_content == current:
        return f"[unchanged] {mod_dir.name} ({identity.get('mod_id', '?')})"

    if check_only:
        return f"[would-update] {mod_dir.name} ({identity.get('mod_id', '?')})"

    logger_path.write_text(new_content, encoding="utf-8")
    return f"[updated]   {mod_dir.name} ({identity.get('mod_id', '?')})"


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("mod", nargs="?", help="Sync only this mod (default: all mods)")
    parser.add_argument("--check", action="store_true", help="Dry run — report but do not write")
    args = parser.parse_args()

    if not SHARED_LOGGER.exists():
        sys.exit(f"Canonical Logger.gd not found at {SHARED_LOGGER}")
    template = SHARED_LOGGER.read_text(encoding="utf-8")

    if args.mod:
        mod_dir = MODS_DIR / args.mod
        if not mod_dir.is_dir():
            sys.exit(f"Mod folder not found: {mod_dir}")
        print(sync_one(mod_dir, template, args.check))
        return 0

    if not MODS_DIR.is_dir():
        sys.exit(f"Mods dir not found: {MODS_DIR}")
    for mod_dir in sorted(MODS_DIR.iterdir()):
        if mod_dir.is_dir():
            print(sync_one(mod_dir, template, args.check))
    return 0


if __name__ == "__main__":
    sys.exit(main())
