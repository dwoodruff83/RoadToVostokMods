# godot_docs_mcp

Local MCP server that exposes the **Godot 4.x documentation** as
queryable tools. Useful for AI agents writing GDScript against a specific
Godot version, since signatures, properties, and methods drift between
versions.

This workspace targets **Godot 4.6** (the version Road to Vostok ships
with). The server reads from a local clone of
[godotengine/godot-docs](https://github.com/godotengine/godot-docs)
pinned to the `4.6` branch.

## Tools

| Tool | Purpose |
|------|---------|
| `godot_search(query, limit=10)` | Full-text search across class refs + tutorials. Class-reference hits are returned first. |
| `godot_class(name)` | Fetch a class reference page (e.g. `ResourceLoader`, `HTTPRequest`) as raw RST. |
| `godot_method(class_name, method_name)` | Extract a single method's section from a class reference. |

## Setup (first-time, per machine)

The docs are not committed — they're ~440 MB of RST source pulled fresh
from upstream and gitignored under `reference/godot_docs/`. Bootstrap
with:

```cmd
download_godot_docs.bat
```

(or, cross-platform, `python tools/godot_docs_mcp/download_docs.py`)

This shallow-clones godotengine/godot-docs at the `4.6` branch into
`reference/godot_docs/`. Re-run with `--refresh` to pick up upstream
fixes:

```cmd
download_godot_docs.bat --refresh
```

To pin a different Godot version, pass `--branch`:

```cmd
download_godot_docs.bat --branch 4.7
```

(Update the `DEFAULT_BRANCH` constant in `download_docs.py` when the
game upgrades.)

## Wiring it into Claude Code / VS Code

Add the entry to `.mcp.json` (Claude Code) or `.vscode/mcp.json`
(VS Code MCP-aware extensions). The server runs as a single-file
script via `uv run`, with `mcp` resolved from PEP 723 inline metadata
— no virtualenv required:

```json
{
  "mcpServers": {
    "godot-docs": {
      "type": "stdio",
      "command": "C:\\Users\\<you>\\.local\\bin\\uv.exe",
      "args": ["run", "f:/RoadToVostokMods/tools/godot_docs_mcp/server.py"]
    }
  }
}
```

(See the workspace's `.mcp.json` for the canonical entry.)

## Requirements

- **git** on PATH (for the doc download)
- **[uv](https://docs.astral.sh/uv/)** on PATH (`uv` resolves the `mcp`
  dependency declared inline in `server.py`)
- **Python 3.10+** (uv will fetch one if missing)

## Updating to a new Godot version

1. Edit `DEFAULT_BRANCH` in `download_docs.py`
2. Delete `reference/godot_docs/` (or run with the new `--branch`
   pointing at a fresh `--dest`)
3. Re-run `download_godot_docs.bat`

Document the bump in `CLAUDE.md` so the workspace's "currently targeting
Godot X.Y" status stays accurate.

## Future ideas

- `godot_with_rtv_usages(symbol)` — combine docs lookup with grep over
  `reference/RTV_decompiled/Scripts/` to show how the game itself uses
  the API.
- Pre-built search index for the rare slow query (currently a linear
  scan over RST files, which is fine for ~440 MB on local disk).
- HTML→Markdown rendering for cleaner output (currently returns raw RST,
  which is readable but verbose).
