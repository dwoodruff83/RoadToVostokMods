#!/usr/bin/env python3
"""Analyze which mods in F:/RoadToVostokMods/mods may be affected by changes between
two snapshots of the RTV_history repo.

Usage:
    python analyze_mods.py --from <tag-or-ref> --to <tag-or-ref>
    python analyze_mods.py --from game-v0.1.0.0-build22286617 --to HEAD
    python analyze_mods.py --list-tags
    python analyze_mods.py --from <ref> --to <ref> --output report.html

For each mod in F:/RoadToVostokMods/mods/:
  1. Read mod.txt for autoloads.
  2. Scan mod's .gd scripts for take_over_path("res://...") calls.
  3. Map res:// paths to files in the history repo.
  4. Diff those files between <from> and <to>.
  5. Classify: 🟢 safe, 🟡 review (body-only changes), 🔴 broken (signature changed or file deleted).
"""

from __future__ import annotations

import argparse
import html
import io
import re
import subprocess
import sys

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")
from dataclasses import dataclass, field
from pathlib import Path

WORKSPACE = Path(r"F:\RoadToVostokMods")
MODS_DIR = WORKSPACE / "mods"
HISTORY_DIR = WORKSPACE / "reference" / "RTV_history"

TAKE_OVER_LITERAL_RE = re.compile(r'take_over_path\s*\(\s*["\']res://([^"\']+)["\']')
TAKE_OVER_IDENT_RE = re.compile(r'take_over_path\s*\(\s*([A-Z_][A-Z0-9_]*)\s*[,)]')
CONST_RES_RE = re.compile(r'^\s*const\s+([A-Z_][A-Z0-9_]*)\s*(?::\s*\w+\s*)?(?::=|=)\s*["\']res://([^"\']+)["\']', re.MULTILINE)
AUTOLOAD_RE = re.compile(r'^\s*([A-Za-z0-9_]+)\s*=\s*["\']res://([^"\']+)["\']', re.MULTILINE)
FUNC_SIG_RE = re.compile(r'^\s*func\s+([A-Za-z0-9_]+)\s*\(([^)]*)\)', re.MULTILINE)
CLASS_SIG_RE = re.compile(r'^\s*(class_name|extends)\s+.*$', re.MULTILINE)


@dataclass
class ChangedFile:
    path: str
    status: str  # "M", "A", "D", "R..."
    signature_changed: bool = False
    diff_summary: str = ""


@dataclass
class ModImpact:
    mod_id: str
    mod_dir: Path
    overrides: list[str] = field(default_factory=list)   # res:// paths
    autoloads: list[str] = field(default_factory=list)   # res:// paths
    touched: list[ChangedFile] = field(default_factory=list)

    @property
    def status(self) -> str:
        if not self.touched:
            return "safe"
        if any(cf.status == "D" or cf.signature_changed for cf in self.touched):
            return "broken"
        return "review"

    @property
    def status_icon(self) -> str:
        return {"safe": "🟢", "review": "🟡", "broken": "🔴"}[self.status]


def run_git(args: list[str], cwd: Path = HISTORY_DIR, check: bool = True) -> str:
    r = subprocess.run(["git", *args], cwd=cwd, check=check, text=True, capture_output=True)
    return r.stdout


def list_tags() -> list[str]:
    return [t for t in run_git(["tag", "--list", "--sort=creatordate"]).splitlines() if t]


def resolve_ref(ref: str) -> str:
    return run_git(["rev-parse", ref]).strip()


def changed_paths_between(from_ref: str, to_ref: str) -> dict[str, str]:
    """Return {path: status_letter} for files that changed between two refs."""
    out = run_git(["diff", "--name-status", f"{from_ref}..{to_ref}"])
    result = {}
    for line in out.splitlines():
        parts = line.split("\t", 2)
        if len(parts) < 2:
            continue
        status, path = parts[0], parts[-1]
        result[path.replace("\\", "/")] = status[0]  # M/A/D/R
    return result


def file_at_ref(ref: str, path: str) -> str | None:
    r = subprocess.run(
        ["git", "show", f"{ref}:{path}"],
        cwd=HISTORY_DIR, text=True, capture_output=True,
    )
    return r.stdout if r.returncode == 0 else None


def signatures_of(gd_source: str) -> set[tuple[str, str]]:
    """Extract a set of (func_name, arg_list) tuples — stable enough to detect
    signature changes without tripping on whitespace/comment edits."""
    sigs = set()
    for m in FUNC_SIG_RE.finditer(gd_source):
        name = m.group(1)
        args = re.sub(r"\s+", "", m.group(2))
        sigs.add(("func", name, args))
    for m in CLASS_SIG_RE.finditer(gd_source):
        sigs.add(("class", m.group(0).strip()))
    return sigs


def detect_signature_change(from_ref: str, to_ref: str, path: str) -> bool:
    old = file_at_ref(from_ref, path)
    new = file_at_ref(to_ref, path)
    if old is None or new is None:
        return True  # file appeared/disappeared — definitely breaking for overrides
    return signatures_of(old) != signatures_of(new)


def load_mods() -> list[ModImpact]:
    mods = []
    if not MODS_DIR.exists():
        return mods
    for mod_dir in sorted(MODS_DIR.iterdir()):
        if not mod_dir.is_dir():
            continue
        mod_txt = mod_dir / "mod.txt"
        if not mod_txt.exists():
            continue
        mod_id = mod_dir.name
        impact = ModImpact(mod_id=mod_id, mod_dir=mod_dir)

        try:
            txt = mod_txt.read_text(encoding="utf-8", errors="replace")
        except OSError:
            txt = ""
        for m in AUTOLOAD_RE.finditer(txt):
            impact.autoloads.append(m.group(2))

        for gd in mod_dir.rglob("*.gd"):
            try:
                src = gd.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            consts = {m.group(1): m.group(2) for m in CONST_RES_RE.finditer(src)}
            for m in TAKE_OVER_LITERAL_RE.finditer(src):
                path = m.group(1)
                if path not in impact.overrides:
                    impact.overrides.append(path)
            for m in TAKE_OVER_IDENT_RE.finditer(src):
                ident = m.group(1)
                if ident in consts:
                    path = consts[ident]
                    if path not in impact.overrides:
                        impact.overrides.append(path)

        mods.append(impact)
    return mods


def analyze(from_ref: str, to_ref: str) -> list[ModImpact]:
    mods = load_mods()
    changed = changed_paths_between(from_ref, to_ref)
    for impact in mods:
        for override in impact.overrides:
            if override in changed:
                status = changed[override]
                sig_changed = False
                if status != "D":
                    sig_changed = detect_signature_change(from_ref, to_ref, override)
                impact.touched.append(
                    ChangedFile(path=override, status=status, signature_changed=sig_changed)
                )
    return mods


def render_text(mods: list[ModImpact], from_ref: str, to_ref: str) -> str:
    lines = []
    lines.append(f"Mod impact: {from_ref}  →  {to_ref}")
    lines.append("=" * 72)
    buckets: dict[str, list[ModImpact]] = {"broken": [], "review": [], "safe": []}
    for m in mods:
        buckets[m.status].append(m)

    for bucket in ("broken", "review", "safe"):
        if not buckets[bucket]:
            continue
        lines.append(f"\n[{bucket.upper()}]")
        for m in buckets[bucket]:
            lines.append(f"  {m.status_icon} {m.mod_id}  (overrides: {len(m.overrides)})")
            for cf in m.touched:
                marker = "SIGNATURE CHANGED" if cf.signature_changed else ("DELETED" if cf.status == "D" else "body changed")
                lines.append(f"      - [{cf.status}] res://{cf.path}  ({marker})")
    if not any(buckets.values()):
        lines.append("\n(no mods found)")
    return "\n".join(lines) + "\n"


def render_html(mods: list[ModImpact], from_ref: str, to_ref: str) -> str:
    def esc(s: str) -> str:
        return html.escape(s)

    rows = []
    for bucket, title in [("broken", "Broken"), ("review", "Review needed"), ("safe", "Safe")]:
        in_bucket = [m for m in mods if m.status == bucket]
        if not in_bucket:
            continue
        rows.append(f'<h2 class="{bucket}">{title} ({len(in_bucket)})</h2>')
        for m in in_bucket:
            rows.append(f'<div class="mod {bucket}">')
            rows.append(f'<h3>{m.status_icon} {esc(m.mod_id)}</h3>')
            rows.append(f'<div class="meta">overrides: {len(m.overrides)} &nbsp; autoloads: {len(m.autoloads)}</div>')
            if m.touched:
                rows.append("<ul>")
                for cf in m.touched:
                    cls = "sig" if cf.signature_changed else ("del" if cf.status == "D" else "body")
                    tag = "signature changed" if cf.signature_changed else ("deleted" if cf.status == "D" else "body changed")
                    rows.append(f'<li class="{cls}"><code>res://{esc(cf.path)}</code> <span class="tag">[{cf.status}] {tag}</span></li>')
                rows.append("</ul>")
            rows.append("</div>")

    style = """
    body { font: 14px/1.5 -apple-system, system-ui, sans-serif; max-width: 920px; margin: 2rem auto; padding: 0 1rem; color: #222; }
    h1 { margin-bottom: 0.25rem; }
    .subtitle { color: #666; margin-bottom: 2rem; font-size: 13px; }
    h2 { margin-top: 2rem; padding-bottom: 0.25rem; border-bottom: 1px solid #ddd; }
    h2.broken { color: #b91c1c; } h2.review { color: #a16207; } h2.safe { color: #15803d; }
    .mod { border-left: 4px solid #ccc; padding: 0.5rem 1rem; margin: 0.75rem 0; background: #fafafa; }
    .mod.broken { border-color: #ef4444; } .mod.review { border-color: #eab308; } .mod.safe { border-color: #22c55e; }
    .mod h3 { margin: 0; font-size: 15px; }
    .meta { color: #666; font-size: 12px; margin-top: 0.25rem; }
    ul { margin: 0.5rem 0 0 0; padding-left: 1.25rem; }
    li { margin: 0.15rem 0; }
    li.sig { color: #b91c1c; font-weight: 500; }
    li.del { color: #b91c1c; }
    li.body { color: #666; }
    code { background: #eee; padding: 1px 4px; border-radius: 3px; font-size: 12px; }
    .tag { color: #888; font-size: 11px; text-transform: uppercase; letter-spacing: 0.5px; }
    """
    return f"""<!doctype html>
<html><head><meta charset="utf-8"><title>Mod impact report</title><style>{style}</style></head>
<body>
<h1>Mod impact report</h1>
<div class="subtitle">from <code>{esc(from_ref)}</code> &nbsp;→&nbsp; to <code>{esc(to_ref)}</code></div>
{''.join(rows) if rows else '<p>(no mods found)</p>'}
</body></html>
"""


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--from", dest="from_ref", help="from-ref (tag, branch, or commit)")
    p.add_argument("--to", dest="to_ref", default="HEAD", help="to-ref (default: HEAD)")
    p.add_argument("--list-tags", action="store_true", help="list known snapshot tags and exit")
    p.add_argument("--output", type=Path, help="also write HTML report to this path")
    return p.parse_args()


def main() -> int:
    args = parse_args()

    if not HISTORY_DIR.exists():
        raise SystemExit(f"history repo missing at {HISTORY_DIR} — run snapshot.py first")

    if args.list_tags:
        for t in list_tags():
            print(t)
        return 0

    if not args.from_ref:
        tags = list_tags()
        if len(tags) < 1:
            raise SystemExit("no snapshots tagged yet — pass --from explicitly")
        if len(tags) == 1:
            raise SystemExit(
                f"only one snapshot exists ({tags[0]}) — nothing to diff against yet.\n"
                "After the next game patch, re-run snapshot.py and then re-run this."
            )
        args.from_ref = tags[-2]
        if args.to_ref == "HEAD":
            args.to_ref = tags[-1]

    from_sha = resolve_ref(args.from_ref)
    to_sha = resolve_ref(args.to_ref)
    if from_sha == to_sha:
        print(f"(no changes — {args.from_ref} and {args.to_ref} point to the same commit)")
        return 0

    mods = analyze(args.from_ref, args.to_ref)
    print(render_text(mods, args.from_ref, args.to_ref))

    if args.output:
        args.output.write_text(render_html(mods, args.from_ref, args.to_ref), encoding="utf-8")
        print(f"[html] wrote {args.output}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
