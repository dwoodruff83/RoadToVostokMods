#!/usr/bin/env python3
"""Compare a mod's live ModWorkshop body tabs to the local repo files.

The ModWorkshop edit form has two body tabs — Description (`desc`) and
Changelog (`changelog`) — that DO NOT auto-update when a new .vmz is
uploaded. Every release upload requires a manual paste into both tabs.
This script catches drift between local README/CHANGELOG and the live
MW page so we know whether a paste step is pending or has been done.

Usage:
    python check_mw_bodies.py <ModName>          # diff vs MW for one mod
    python check_mw_bodies.py --all              # iterate every published mod
    python check_mw_bodies.py <ModName> --paste  # print local README + CHANGELOG
                                                 # ready to copy into MW form
    python check_mw_bodies.py <ModName> --summary-only
                                                 # skip the unified diff dump

Mod folder must contain `.publish` (one-line ModWorkshop id) plus
`README.md` and `CHANGELOG.md`. Imports `_get` from modworkshop.py for
the API call.

Exit codes:
    0 = clean (everything in sync)
    2 = drift detected (some body differs from local)
    1 = error (mod folder missing, .publish missing, network failure)
"""

from __future__ import annotations

import argparse
import difflib
import sys
from pathlib import Path

# Re-use the API helper from modworkshop.py — same dir.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from modworkshop import _get  # noqa: E402

WORKSPACE = Path(__file__).resolve().parent.parent
MODS_DIR = WORKSPACE / "mods"


def discover_published_mods() -> list[tuple[str, int]]:
    """Walk mods/<Name>/.publish to find every published mod."""
    out: list[tuple[str, int]] = []
    if not MODS_DIR.is_dir():
        return out
    for mod_dir in sorted(MODS_DIR.iterdir()):
        publish_file = mod_dir / ".publish"
        if not publish_file.is_file():
            continue
        try:
            mod_id = int(publish_file.read_text(encoding="utf-8").strip())
        except (ValueError, OSError):
            continue
        out.append((mod_dir.name, mod_id))
    return out


def load_local(mod_name: str) -> tuple[str, str, int]:
    """Returns (readme_text, changelog_text, mod_id) for the mod folder."""
    mod_dir = MODS_DIR / mod_name
    if not mod_dir.is_dir():
        raise SystemExit(f"error: mod folder not found: {mod_dir}")
    publish = mod_dir / ".publish"
    if not publish.is_file():
        raise SystemExit(
            f"error: {mod_name}/.publish missing — mod isn't published yet, "
            f"nothing to diff against ModWorkshop."
        )
    try:
        mod_id = int(publish.read_text(encoding="utf-8").strip())
    except ValueError as e:
        raise SystemExit(f"error: {publish} doesn't contain a valid integer mod id: {e}")
    readme_path = mod_dir / "README.md"
    changelog_path = mod_dir / "CHANGELOG.md"
    if not readme_path.is_file():
        raise SystemExit(f"error: {readme_path} missing")
    if not changelog_path.is_file():
        raise SystemExit(f"error: {changelog_path} missing")
    return (
        readme_path.read_text(encoding="utf-8"),
        changelog_path.read_text(encoding="utf-8"),
        mod_id,
    )


def fetch_live(mod_id: int) -> tuple[str, str]:
    """Returns (live_desc, live_changelog) from the MW API."""
    m = _get(f"/mods/{mod_id}")
    return m.get("desc") or "", m.get("changelog") or ""


def _diff(label: str, local: str, live: str) -> tuple[str, list[str]]:
    """Returns (status_line, diff_lines). Diff is empty if in-sync.

    Normalizes both sides before comparing:
      - rstrip trailing whitespace/newlines (MW strips these on save; local
        files keep a final newline per editor convention — the difference
        is benign and would otherwise be a constant false-positive)
      - normalize CRLF -> LF (a Windows-checkout local file shouldn't show
        as drifted vs an LF-stored MW body)
    """
    norm_local = local.replace("\r\n", "\n").rstrip()
    norm_live = live.replace("\r\n", "\n").rstrip()
    if norm_local == norm_live:
        return ("IN-SYNC", [])
    local_lines = norm_local.splitlines(keepends=True)
    live_lines = norm_live.splitlines(keepends=True)
    diff = list(difflib.unified_diff(
        live_lines, local_lines,
        fromfile=f"MW {label}",
        tofile=f"local {label}",
        n=2,
    ))
    additions = sum(1 for ln in diff if ln.startswith("+") and not ln.startswith("+++"))
    deletions = sum(1 for ln in diff if ln.startswith("-") and not ln.startswith("---"))
    return (f"DRIFT (+{additions} / -{deletions})", diff)


def check_one(mod_name: str, show_diff: bool = True) -> int:
    readme, changelog, mod_id = load_local(mod_name)
    live_desc, live_changelog = fetch_live(mod_id)

    desc_status, desc_diff = _diff("README", readme, live_desc)
    cl_status, cl_diff = _diff("CHANGELOG", changelog, live_changelog)

    print(f"\n=== {mod_name} (MW id {mod_id}) ===")
    print(f"  desc tab:      {desc_status}")
    print(f"  changelog tab: {cl_status}")

    if show_diff:
        if desc_diff:
            print("\n--- desc tab diff (MW -> local) ---")
            sys.stdout.write("".join(desc_diff))
            if not desc_diff[-1].endswith("\n"):
                print()
        if cl_diff:
            print("\n--- changelog tab diff (MW -> local) ---")
            sys.stdout.write("".join(cl_diff))
            if not cl_diff[-1].endswith("\n"):
                print()

    return 0 if (not desc_diff and not cl_diff) else 2


def cmd_paste(mod_name: str) -> int:
    """Print local README + CHANGELOG for copy-paste into the MW form."""
    readme, changelog, mod_id = load_local(mod_name)
    print(f"=== {mod_name} (MW id {mod_id}) ===")
    print(f"Edit page: https://modworkshop.net/mod/{mod_id}/edit\n")
    print("=" * 78)
    print("Description tab — paste this entire block:")
    print("=" * 78)
    print(readme)
    if not readme.endswith("\n"):
        print()
    print("=" * 78)
    print("Changelog tab — paste this entire block:")
    print("=" * 78)
    print(changelog)
    if not changelog.endswith("\n"):
        print()
    return 0


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    p = argparse.ArgumentParser(
        description="Compare a mod's live ModWorkshop description + changelog "
                    "tabs to the local README.md and CHANGELOG.md files.",
    )
    p.add_argument("mod_name", nargs="?", help="Mod folder name (e.g. CatAutoFeed). Omit with --all.")
    p.add_argument("--all", action="store_true", help="Iterate every published mod (those with .publish files).")
    p.add_argument("--paste", action="store_true", help="Print local README + CHANGELOG ready to paste into the MW edit form.")
    p.add_argument("--summary-only", action="store_true", help="Skip the full unified diff; just print the status lines.")
    args = p.parse_args()

    if args.paste:
        if not args.mod_name:
            p.error("--paste requires <mod_name>")
        if args.all:
            p.error("--paste and --all are mutually exclusive")
        return cmd_paste(args.mod_name)

    if args.all:
        mods = discover_published_mods()
        if not mods:
            print("No published mods found (no mods/*/.publish files).")
            return 0
        worst_rc = 0
        for name, _ in mods:
            rc = check_one(name, show_diff=not args.summary_only)
            if rc > worst_rc:
                worst_rc = rc
        return worst_rc

    if not args.mod_name:
        p.error("specify <mod_name> or --all")
    return check_one(args.mod_name, show_diff=not args.summary_only)


if __name__ == "__main__":
    sys.exit(main())
