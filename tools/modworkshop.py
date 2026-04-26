#!/usr/bin/env python3
"""ModWorkshop API client (read-only).

Browse and inspect mods on https://modworkshop.net via the public API at
https://api.modworkshop.net. Defaults to the Road to Vostok game section
(game_id 864).

Usage:
    python modworkshop.py find-game <query>
    python modworkshop.py browse [--sort latest|popular|downloads|likes|created] [--limit N]
    python modworkshop.py search <query> [--limit N]
    python modworkshop.py info <mod_id>
    python modworkshop.py files <mod_id>
    python modworkshop.py top [--limit N]                # alias for browse --sort downloads

Add --game <id> to any subcommand to target a different game section.
"""

from __future__ import annotations

import argparse
import json
import sys
import textwrap
import urllib.parse
import urllib.request
from typing import Any

API_BASE = "https://api.modworkshop.net"
RTV_GAME_ID = 864
USER_AGENT = "RoadToVostokMods-modworkshop-cli/1.0 (+https://github.com/)"


def _get(path: str, params: dict[str, Any] | None = None) -> Any:
    url = f"{API_BASE}{path}"
    if params:
        clean = {k: v for k, v in params.items() if v is not None}
        if clean:
            url = f"{url}?{urllib.parse.urlencode(clean, doseq=True)}"
    req = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def _truncate(s: str | None, n: int) -> str:
    if not s:
        return ""
    s = s.replace("\n", " ").replace("\r", " ").strip()
    return s if len(s) <= n else s[: n - 3] + "..."


def _print_table(rows: list[list[str]], headers: list[str]) -> None:
    if not rows:
        print("(no results)")
        return
    cols = list(zip(headers, *rows))
    widths = [max(len(str(c)) for c in col) for col in cols]
    fmt = "  ".join(f"{{:<{w}}}" for w in widths)
    print(fmt.format(*headers))
    print(fmt.format(*("-" * w for w in widths)))
    for row in rows:
        print(fmt.format(*row))


def _mod_row(m: dict) -> list[str]:
    return [
        str(m.get("id", "?")),
        _truncate(m.get("name", ""), 40),
        str(m.get("version") or "-"),
        str(m.get("downloads", "?")),
        str(m.get("likes", "?")),
        _truncate((m.get("user") or {}).get("name") or f"user#{m.get('user_id','?')}", 20),
        (m.get("updated_at") or "")[:10],
    ]


_MOD_HEADERS = ["id", "name", "version", "DLs", "likes", "author", "updated"]


def cmd_find_game(args: argparse.Namespace) -> int:
    data = _get("/games", {"query": args.query, "limit": args.limit})
    rows = [
        [str(g["id"]), _truncate(g["name"], 40), str(g.get("mods_count", "?")), g.get("short_name", "")]
        for g in data.get("data", [])
    ]
    _print_table(rows, ["id", "name", "mods", "short_name"])
    return 0


def cmd_browse(args: argparse.Namespace) -> int:
    if args.sort == "popular":
        data = _get(f"/games/{args.game}/popular-and-latest")
        mods = data.get("popular", [])[: args.limit]
    elif args.sort == "latest":
        data = _get(f"/games/{args.game}/popular-and-latest")
        mods = data.get("latest", [])[: args.limit]
    else:
        data = _get(f"/games/{args.game}/mods", {"limit": args.limit, "sort": args.sort, "order": "desc"})
        mods = data.get("data", [])
    _print_table([_mod_row(m) for m in mods], _MOD_HEADERS)
    return 0


def cmd_search(args: argparse.Namespace) -> int:
    data = _get(f"/games/{args.game}/mods", {"query": args.query, "limit": args.limit})
    _print_table([_mod_row(m) for m in data.get("data", [])], _MOD_HEADERS)
    return 0


def cmd_info(args: argparse.Namespace) -> int:
    m = _get(f"/mods/{args.mod_id}")
    user = (m.get("user") or {}).get("name") or f"user#{m.get('user_id','?')}"
    cat = m.get("category") or {}
    tags = ", ".join(f"{t.get('name')} (#{t.get('id')})" for t in (m.get("tags") or []))
    fields = [
        ("id", m.get("id")),
        ("name", m.get("name")),
        ("author", user),
        ("version", m.get("version") or "-"),
        ("downloads", m.get("downloads")),
        ("likes", m.get("likes")),
        ("views", m.get("views")),
        ("category", f"{cat.get('name')} (#{cat.get('id')})" if cat.get("name") else "-"),
        ("tags", tags or "-"),
        ("game", (m.get("game") or {}).get("name")),
        ("visibility", m.get("visibility")),
        ("approved", m.get("approved")),
        ("files", m.get("files_count")),
        ("created", (m.get("created_at") or "")[:10]),
        ("updated", (m.get("updated_at") or "")[:10]),
        ("repo", m.get("repo_url") or "-"),
        ("url", f"https://modworkshop.net/mod/{m.get('id')}"),
    ]
    width = max(len(k) for k, _ in fields)
    for k, v in fields:
        print(f"{k:<{width}}  {v}")

    deps = m.get("dependencies") or []
    print()
    print(f"dependencies ({len(deps)}):")
    if not deps:
        print("  (none declared)")
    else:
        for d in deps:
            req = "optional" if d.get("optional") else "required"
            if d.get("dependable_type") == "mod":
                dep_mod = d.get("mod") or {}
                dep_id = dep_mod.get("id") or d.get("mod_id")
                name = dep_mod.get("name") or f"mod#{dep_id}"
                url = f"https://modworkshop.net/mod/{dep_id}" if dep_id else "(no id)"
                print(f"  [{req}] {name}  ->  {url}")
            else:
                # offsite link
                name = d.get("name") or "(unnamed)"
                url = d.get("url") or "(no url)"
                print(f"  [{req}] {name}  ->  {url}  (offsite)")

    short = m.get("short_desc")
    if short:
        print()
        print("short_desc:")
        print(textwrap.indent(textwrap.fill(short, 100), "  "))
    return 0


def cmd_files(args: argparse.Namespace) -> int:
    data = _get(f"/mods/{args.mod_id}/files")
    rows = []
    for f in data.get("data", []):
        size_kb = f.get("size", 0) // 1024
        rows.append([
            str(f.get("id", "?")),
            _truncate(f.get("name", ""), 30),
            str(f.get("version") or "-"),
            f.get("type", ""),
            f"{size_kb} KB",
            str(f.get("downloads", "?")),
            (f.get("created_at") or "")[:10],
        ])
    _print_table(rows, ["file_id", "name", "version", "type", "size", "DLs", "uploaded"])
    return 0


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    p = argparse.ArgumentParser(description="ModWorkshop API client (read-only)")
    p.add_argument("--game", type=int, default=RTV_GAME_ID, help=f"Game id (default {RTV_GAME_ID} = Road to Vostok)")
    sub = p.add_subparsers(dest="command", required=True)

    sp = sub.add_parser("find-game", help="Search for a game by name to discover its game_id")
    sp.add_argument("query")
    sp.add_argument("--limit", type=int, default=20)
    sp.set_defaults(func=cmd_find_game)

    sp = sub.add_parser("browse", help="List mods for the configured game")
    sp.add_argument("--sort", choices=["latest", "popular", "downloads", "likes", "created"], default="latest")
    sp.add_argument("--limit", type=int, default=20)
    sp.set_defaults(func=cmd_browse)

    sp = sub.add_parser("top", help="Top mods by downloads (alias of browse --sort downloads)")
    sp.add_argument("--limit", type=int, default=20)
    sp.set_defaults(func=lambda a: cmd_browse(argparse.Namespace(game=a.game, sort="downloads", limit=a.limit)))

    sp = sub.add_parser("search", help="Search mods in the configured game")
    sp.add_argument("query")
    sp.add_argument("--limit", type=int, default=20)
    sp.set_defaults(func=cmd_search)

    sp = sub.add_parser("info", help="Show full info for a single mod")
    sp.add_argument("mod_id", type=int)
    sp.set_defaults(func=cmd_info)

    sp = sub.add_parser("files", help="List files (versions) for a mod")
    sp.add_argument("mod_id", type=int)
    sp.set_defaults(func=cmd_files)

    args = p.parse_args()
    try:
        return args.func(args)
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code}: {e.reason}", file=sys.stderr)
        return 1
    except urllib.error.URLError as e:
        print(f"Network error: {e.reason}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
