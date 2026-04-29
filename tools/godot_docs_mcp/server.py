# /// script
# requires-python = ">=3.10"
# dependencies = ["mcp>=1.0"]
# ///
"""MCP server exposing the Godot 4.x documentation as queryable tools.

Reads from a local clone of godotengine/godot-docs at
``reference/godot_docs/`` (relative to the workspace root, two levels up
from this file). Run ``download_godot_docs.bat`` first to populate it.

Tools:
    godot_search(query, limit=10)            - full-text search across all .rst files
    godot_class(name)                        - return a class reference page (RST)
    godot_method(class_name, method_name)    - extract one method's section
"""

from __future__ import annotations

import re
from pathlib import Path

from mcp.server.fastmcp import FastMCP

DOCS_ROOT = Path(__file__).resolve().parent.parent.parent / "reference" / "godot_docs"
CLASSES_DIR = DOCS_ROOT / "classes"

MISSING_DOCS_HINT = (
    f"Godot docs not found at {DOCS_ROOT}.\n"
    "Run ``download_godot_docs.bat`` (or "
    "``python tools/godot_docs_mcp/download_docs.py``) from the workspace "
    "root to populate it."
)

mcp = FastMCP("godot-docs")


def _ensure_docs() -> str | None:
    """Return an error string if the docs clone is absent, else None."""
    if not DOCS_ROOT.exists():
        return MISSING_DOCS_HINT
    return None


@mcp.tool()
def godot_search(query: str, limit: int = 10) -> str:
    """Full-text search across all Godot doc pages (case-insensitive).

    Searches class references, tutorials, and getting-started docs. Results
    are ordered with class references first, then tutorials. Each hit shows
    the relative path, line number, and a trimmed context snippet.

    Args:
        query: literal text to search for.
        limit: maximum number of hits to return (default 10).
    """
    if err := _ensure_docs():
        return err

    pattern = re.compile(re.escape(query), re.IGNORECASE)
    class_hits: list[str] = []
    other_hits: list[str] = []

    for rst in DOCS_ROOT.rglob("*.rst"):
        # Skip the auto-generated stuff that just points elsewhere
        if rst.name in ("404.rst",):
            continue
        try:
            text = rst.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for line_no, line in enumerate(text.splitlines(), 1):
            if pattern.search(line):
                rel = rst.relative_to(DOCS_ROOT).as_posix()
                snippet = line.strip()
                if len(snippet) > 200:
                    snippet = snippet[:197] + "..."
                entry = f"{rel}:{line_no}: {snippet}"
                bucket = class_hits if rel.startswith("classes/") else other_hits
                bucket.append(entry)
                if len(class_hits) + len(other_hits) >= limit * 4:
                    break
        if len(class_hits) + len(other_hits) >= limit * 4:
            break

    combined = (class_hits + other_hits)[:limit]
    if not combined:
        return f"No results for '{query}'."
    header = f"Top {len(combined)} hit(s) for '{query}':"
    return header + "\n" + "\n".join(combined)


@mcp.tool()
def godot_class(name: str) -> str:
    """Return the full class reference page for a Godot class as RST source.

    Args:
        name: class name (case-insensitive, e.g. 'ResourceLoader',
            'HTTPRequest', 'PackedScene').
    """
    if err := _ensure_docs():
        return err

    fname = f"class_{name.lower()}.rst"
    path = CLASSES_DIR / fname
    if not path.exists():
        return (
            f"Class '{name}' not found (looked for {fname} in {CLASSES_DIR}).\n"
            "Use godot_search to find the right class name."
        )
    return path.read_text(encoding="utf-8", errors="ignore")


@mcp.tool()
def godot_method(class_name: str, method_name: str) -> str:
    """Extract a single method's section from a Godot class reference.

    Returns the method's anchor block, which typically includes the
    signature line plus its description, until the next method/property/
    signal/constant anchor.

    Args:
        class_name: class name (case-insensitive, e.g. 'ResourceLoader').
        method_name: method name (case-insensitive, e.g. 'load').
    """
    if err := _ensure_docs():
        return err

    fname = f"class_{class_name.lower()}.rst"
    path = CLASSES_DIR / fname
    if not path.exists():
        return f"Class '{class_name}' not found (looked for {fname})."

    text = path.read_text(encoding="utf-8", errors="ignore")
    anchor_pat = re.compile(
        rf"^\.\. _class_{re.escape(class_name)}_method_{re.escape(method_name)}:\s*$",
        re.IGNORECASE | re.MULTILINE,
    )
    m = anchor_pat.search(text)
    if not m:
        return (
            f"Method '{class_name}.{method_name}' not found in {fname}. "
            "Use godot_class to see all methods, or godot_search for fuzzy lookup."
        )

    start = m.start()
    next_anchor = re.search(
        r"^\.\. _class_\w+_(?:method|property|signal|constant|annotation|theme_item)_\w+:\s*$",
        text[m.end():],
        re.MULTILINE,
    )
    end = m.end() + next_anchor.start() if next_anchor else len(text)
    return text[start:end].rstrip()


if __name__ == "__main__":
    mcp.run()
