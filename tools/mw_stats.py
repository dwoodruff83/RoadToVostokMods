#!/usr/bin/env python3
"""ModWorkshop stats snapshot + history logger.

Prints a current-stats table for monitored mods, computes deltas vs the
previous CSV row (so you can see what's grown since last check), and
appends a fresh timestamped row per mod to a CSV history. Also detects
new comments since last run and shows them inline.

Configuration
-------------
- Workspace mods are auto-discovered from `mods/<X>/.publish` files
  (single-line integer mod id, written by publish.py / .publish convention).
- External mods (e.g. the standalone tracker repo) are listed in
  EXTERNAL_MODS at the top of this file. Edit to add more.

Usage
-----
    python tools/mw_stats.py            # snapshot + delta + CSV append
    python tools/mw_stats.py --no-csv   # snapshot + delta, no CSV write
    python tools/mw_stats.py --comments # also show ALL comments, not just new
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
MODS_DIR = WORKSPACE_ROOT / "mods"
DEFAULT_CSV_PATH = WORKSPACE_ROOT / "tools" / "mw_stats.csv"
DEFAULT_STATE_PATH = WORKSPACE_ROOT / "tools" / "mw_stats_state.json"

# Mods NOT in this workspace's mods/ folder but worth monitoring.
# Format: list of (mod_id, display_name) tuples.
EXTERNAL_MODS: list[tuple[int, str]] = [
    (56405, "RTV Mod Impact Tracker"),
]

API_BASE = "https://api.modworkshop.net"
HTTP_TIMEOUT = 15


# ---------- API helpers ----------


def fetch_json(url: str) -> dict:
    req = urllib.request.Request(url, headers={"Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as r:
        return json.loads(r.read())


def fetch_mod(mod_id: int) -> dict:
    return fetch_json(f"{API_BASE}/mods/{mod_id}")


def fetch_comments(mod_id: int) -> dict:
    return fetch_json(f"{API_BASE}/mods/{mod_id}/comments")


# ---------- mod discovery ----------


def discover_workspace_mods() -> list[tuple[int, str]]:
    out: list[tuple[int, str]] = []
    if not MODS_DIR.exists():
        return out
    for d in sorted(MODS_DIR.iterdir()):
        if not d.is_dir():
            continue
        publish = d / ".publish"
        if not publish.exists():
            continue
        try:
            mod_id = int(publish.read_text().strip().splitlines()[0])
        except (ValueError, IndexError):
            print(f"warning: {publish} did not contain an integer mod id; skipping", file=sys.stderr)
            continue
        out.append((mod_id, d.name))
    return out


# ---------- state (last-seen comment id per mod) ----------


def load_state(path: Path) -> dict[str, int]:
    if not path.exists():
        return {}
    try:
        return {k: int(v) for k, v in json.loads(path.read_text()).items()}
    except (ValueError, json.JSONDecodeError):
        return {}


def save_state(path: Path, state: dict[str, int]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2, sort_keys=True))


# ---------- CSV history ----------


CSV_FIELDS = ["timestamp", "mod_id", "name", "version", "views", "downloads", "likes", "comments"]


def append_csv(path: Path, snapshots: list[dict]) -> None:
    write_header = not path.exists()
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        if write_header:
            w.writerow(CSV_FIELDS)
        for s in snapshots:
            w.writerow([s[k] for k in CSV_FIELDS])


def load_previous_snapshot(path: Path) -> dict[int, dict]:
    """Return the most recent CSV row per mod_id (for delta computation)."""
    if not path.exists():
        return {}
    rows_by_id: dict[int, dict] = {}
    with path.open("r", newline="", encoding="utf-8") as f:
        for row in csv.DictReader(f):
            try:
                mid = int(row["mod_id"])
            except (KeyError, ValueError):
                continue
            rows_by_id[mid] = row
    return rows_by_id


# ---------- rendering ----------


def fmt_delta(current: int, previous: str | None) -> str:
    if previous is None:
        return ""
    try:
        d = current - int(previous)
    except (TypeError, ValueError):
        return ""
    if d == 0:
        return ""
    return f"(+{d})" if d > 0 else f"({d})"


def render_table(snapshots: list[dict], previous: dict[int, dict]) -> str:
    headers = ["ID", "Name", "Version", "Views", "DL", "Likes", "Cmts"]
    rows: list[list[str]] = []
    for s in snapshots:
        prev = previous.get(s["mod_id"], {})
        rows.append([
            str(s["mod_id"]),
            s["name"],
            str(s["version"]),
            f"{s['views']} {fmt_delta(s['views'], prev.get('views'))}".strip(),
            f"{s['downloads']} {fmt_delta(s['downloads'], prev.get('downloads'))}".strip(),
            f"{s['likes']} {fmt_delta(s['likes'], prev.get('likes'))}".strip(),
            f"{s['comments']} {fmt_delta(s['comments'], prev.get('comments'))}".strip(),
        ])
    widths = [max(len(r[i]) for r in [headers] + rows) for i in range(len(headers))]
    sep = "-+-".join("-" * w for w in widths)
    out = [" | ".join(h.ljust(widths[i]) for i, h in enumerate(headers)), sep]
    for r in rows:
        out.append(" | ".join(r[i].ljust(widths[i]) for i in range(len(headers))))
    return "\n".join(out)


# ---------- main ----------


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("--no-csv", action="store_true", help="Don't append a row to the CSV history")
    p.add_argument("--csv-path", type=Path, default=DEFAULT_CSV_PATH,
                   help=f"CSV history path (default: {DEFAULT_CSV_PATH})")
    p.add_argument("--state-path", type=Path, default=DEFAULT_STATE_PATH,
                   help=f"State file for comment-id tracking (default: {DEFAULT_STATE_PATH})")
    p.add_argument("--comments", action="store_true",
                   help="Show all comments, not just new ones since last run")
    return p.parse_args()


def main() -> int:
    args = parse_args()
    mods = discover_workspace_mods() + EXTERNAL_MODS
    if not mods:
        print("(no mods to monitor — add .publish files to mods/<X>/ or edit EXTERNAL_MODS)")
        return 1

    state = load_state(args.state_path)
    previous = load_previous_snapshot(args.csv_path)
    timestamp = datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")

    snapshots: list[dict] = []
    new_comments_by_mod: dict[int, list[dict]] = {}
    seen_ids: set[int] = set()

    for mod_id, fallback_name in sorted(mods, key=lambda x: x[0]):
        if mod_id in seen_ids:
            continue
        seen_ids.add(mod_id)
        try:
            info = fetch_mod(mod_id)
        except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError) as e:
            print(f"warning: could not fetch mod {mod_id} ({fallback_name}): {e}", file=sys.stderr)
            continue

        try:
            comments_resp = fetch_comments(mod_id)
        except (urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError) as e:
            print(f"warning: could not fetch comments for mod {mod_id}: {e}", file=sys.stderr)
            comments_resp = {"data": [], "meta": {"total": 0}}

        comment_total = comments_resp.get("meta", {}).get("total", 0)
        comments = comments_resp.get("data", []) or []

        snapshots.append({
            "timestamp": timestamp,
            "mod_id": info.get("id", mod_id),
            "name": info.get("name", fallback_name),
            "version": info.get("version") or "-",
            "views": info.get("views", 0),
            "downloads": info.get("downloads", 0),
            "likes": info.get("likes", 0),
            "comments": comment_total,
        })

        # Comment ids are integers; track the max we've seen to detect new ones next run.
        last_seen_id = state.get(str(mod_id), 0)
        if args.comments:
            visible = list(comments)
        else:
            visible = [c for c in comments if int(c.get("id", 0)) > last_seen_id]
        if visible:
            new_comments_by_mod[mod_id] = visible
        if comments:
            state[str(mod_id)] = max(int(c.get("id", 0)) for c in comments)

    if not snapshots:
        print("(no successful API responses)")
        return 1

    print(f"ModWorkshop stats - {timestamp}")
    print()
    print(render_table(snapshots, previous))

    if new_comments_by_mod:
        print()
        header = "All comments:" if args.comments else "New comments since last run:"
        print(header)
        for mod_id, comments in new_comments_by_mod.items():
            mod_name = next((s["name"] for s in snapshots if s["mod_id"] == mod_id), str(mod_id))
            for c in comments:
                user_field = c.get("user")
                user = user_field.get("name", "?") if isinstance(user_field, dict) else "?"
                created = c.get("created_at", "?")
                body = (c.get("body") or "").strip()
                print()
                print(f"  [{mod_name} ({mod_id})] {user} @ {created}")
                for line in body.splitlines() or [""]:
                    print(f"    {line}")

    if not args.no_csv:
        append_csv(args.csv_path, snapshots)
        print()
        print(f"[csv] appended {len(snapshots)} rows to {args.csv_path}")
    save_state(args.state_path, state)
    return 0


if __name__ == "__main__":
    sys.exit(main())
