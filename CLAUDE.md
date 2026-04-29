# CLAUDE.md — Road to Vostok Modding

## Conversational Tone

Adopt the persona of a medieval squire (Monty Python style) in conversational messages only. Do NOT use this tone in code, commits, docs, or GitHub communications.

## Project Overview

This is a modding workspace for **Road to Vostok**, a survival FPS built in Godot 4.6.1. We're learning Godot modding and building custom mods.

## Key Paths

| Path | Purpose |
|------|---------|
| `F:\RoadToVostokMods\` | This workspace root |
| `F:\RoadToVostokMods\reference\RTV_decompiled\Scripts\` | Decompiled game scripts (176 files, 30K lines) |
| `F:\RoadToVostokMods\reference\RTV_decompiled\project.godot` | Game project config |
| `F:\RoadToVostokMods\tools\GDRE_tools\gdre_tools.exe` | Godot RE Tools for decompiling |
| `F:\rtv-mod-impact-tracker\` | Standalone tool repo (MIT, private): snapshot.py + analyze_mods.py + changelog.py + fetch_version.py + deps_fetch.py + deps_diff.py + deps_audit.py + deps_changelog.py |
| `F:\RoadToVostokMods\mod_tracker.toml` | Config consumed by the tool (paths + Steam app id + `[[deps]]` upstreams) |
| `F:\RoadToVostokMods\manifests.json` | Steam manifest registry consumed by `fetch_version.py` |
| `F:\RoadToVostokMods\snapshot.bat` / `analyze_mods.bat` / `changelog.bat` / `fetch_version.bat` | Game-tracking wrappers (Steam-sourced) calling into the tool repo |
| `F:\RoadToVostokMods\deps_fetch.bat` / `deps_diff.bat` / `deps_audit.bat` / `deps_changelog.bat` | Dep-tracking wrappers (Metro Mod Loader + MCM upstreams declared in `[[deps]]`) |
| `F:\RoadToVostokMods\reference\MetroModLoader_source\` | Local mirror clone of Metro Mod Loader upstream (gitignored, regenerable via `deps_fetch sync`) |
| `F:\RoadToVostokMods\reference\MCM_source\` | Local mirror clone of MCM upstream (gitignored, regenerable via `deps_fetch sync`) |
| `F:\RoadToVostokMods\tools\GDRE_tools\` | GDRE Tools v2.5.0-beta.5 (decompiler) |
| `F:\RoadToVostokMods\tools\Godot\` | Godot Editor 4.6.2 (installed) |
| `F:\RoadToVostokMods\tools\DepotDownloader\` | Steam depot tool (for backfilling old game builds) |
| `F:\RoadToVostokMods\tools\save_backup.py` | Backup/restore RTV save files from `%APPDATA%\Road to Vostok\` |
| `F:\RoadToVostokMods\tools\sync_logger.py` | Sync canonical `shared/Logger.gd` into each mod, preserving identity values |
| `F:\RoadToVostokMods\tools\modworkshop.py` / `modworkshop.bat` | Read-only ModWorkshop API client (browse, search, info, files) |
| `F:\RoadToVostokMods\tools\godot_docs_mcp\` | MCP server exposing Godot 4.6 docs as query tools (search/class/method); reads from `reference/godot_docs/` |
| `F:\RoadToVostokMods\reference\godot_docs\` | Local shallow clone of godot-docs @ 4.6 branch (gitignored, regenerable via `download_godot_docs.bat`) |
| `F:\RoadToVostokMods\download_godot_docs.bat` | One-shot wrapper: shallow-clones godot-docs to `reference/godot_docs/`. Idempotent; `--refresh` to re-sync, `--branch X.Y` to pin a different version |
| `F:\RoadToVostokMods\.mcp.json` / `.vscode\mcp.json` | MCP server registrations (godotlens + godot-docs); both committed, no secrets |
| `F:\RoadToVostokMods\tools\publish.py` / `publish.bat` | One-shot build → install → open ModWorkshop edit/upload page |
| `F:\RoadToVostokMods\tools\scaffold_mod.py` / `scaffold.bat` | Scaffold a new mod folder with the workspace's standard layout (mod.txt + Logger.gd stub + Main.gd + config.gd + canonical build.py + README/CHANGELOG/LICENSE/PUBLISH_NOTES + screenshots/). Auto-syncs Logger.gd. Optional `--assets` (assets/ folder + NOTICES.txt + LICENSE carve-out for third-party assets) and `--items` (Metro v3.x `[registry]` opt-in in mod.txt + a Main.gd that registers items via `lib.register(lib.Registry.SCENES, ...)`) flags |
| `F:\RoadToVostokMods\mods\<ModName>\.publish` | Optional one-line file containing the ModWorkshop mod id; if present, `publish.bat` opens that mod's edit page |
| `F:\RoadToVostokMods\shared\Logger.gd` | Canonical reusable Logger source (synced into each mod) |
| `F:\RoadToVostokMods\mods\RTVModLogger\` | Standalone demo + reusable logging library mod (ships `Logger.gd` for other modders) |
| `F:\RoadToVostokMods\mods\RTVModLogger\LOGGER.md` | Full modder-facing reference for the logger (formerly in `shared/`) |
| `F:\RoadToVostokMods\docs\archive\RTVModItemRegistry\` | **RETIRED & ARCHIVED** 2026-04-27 — superseded by Metro v3.x's built-in `[registry]` API (verified working). Source kept for workspace history; not in publish set. Consumer mods migrated to `Engine.get_meta("RTVModLib").register(...)` |
| `F:\RoadToVostokMods\reference\RTV_history\` | Git repo of decompiled snapshots, one commit per game version |
| `F:\RoadToVostokMods\mods\` | Our mod projects |
| `F:\RoadToVostokMods\docs\archive\` | Historical workspace docs (design plans, retired test mod fixtures). Not bundled into any `.vmz` |
| `C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\` | Game install |
| `C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\mods\` | Installed mods (.vmz files) |
| `C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\override.cfg` | Godot autoload override — `[autoload_prepend] ModLoader="*res://modloader.gd"` so the loader runs before vanilla `Loader`/`Database`/`Simulation` autoloads (v3.1.1+) |
| `C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\modloader.gd` | Metro Mod Loader v3.1.1 (11843 lines, MD5 `f7ec2261d6cc629043b6db8bb4bc2794`) — mounts `.vmz` files before save scanning. Upgraded from v2.0.0 (was at `%APPDATA%\Road to Vostok\modloader.gd`, md5 `61bbf6edda9e23310cbe39cadb1ca5d3`) which had a save-load race |
| `%APPDATA%\Road to Vostok\mod_config.cfg` | Metro UI state (per-mod enabled/priority) |
| `%APPDATA%\Road to Vostok\modloader_conflicts.txt` | Metro's last-run conflict report |

## Modding Quick Reference

- Mods are `.vmz` files (renamed ZIPs) with a `mod.txt` metadata file
- Entry point scripts are autoloaded via `mod.txt` `[autoload]` section
- Override game scripts with `take_over_path()` (see Pattern 1 in README.md)
- MCM integration for in-game config (see Pattern 2 in README.md)
- Game state lives in `GameData.tres` (preload as `res://Resources/GameData.tres`)
- All game scripts are under `res://Scripts/` (176 files)

## Tooling

- **GDRE Tools v2.5.0-beta.5** (installed at `tools/GDRE_tools/`): Decompile PCK, list files, create PCK
- **Godot Editor 4.6.2** (installed at `tools/Godot/`): Run/edit mods from source
- **DepotDownloader** (installed at `tools/DepotDownloader/`): Pull specific historical RTV builds from Steam (only needed for backfilling old snapshots)
- **rtv-mod-impact-tracker** (`F:\rtv-mod-impact-tracker\`): Standalone repo with eight scripts. Game-tracking (Steam-sourced): snapshot, analyze_mods, changelog, fetch_version. Dep-tracking (GitHub upstreams declared in `[[deps]]`): deps_fetch (sync mirror clones), deps_diff (file/signature diff between two upstream tags), deps_audit (flag mods whose call sites touch changed dep APIs), deps_changelog (Markdown release notes between dep tags). Driven from this workspace via `mod_tracker.toml` and eight `.bat` wrappers. See README.md "Version Tracking" section.
- **ModWorkshop CLI** (`tools/modworkshop.py` → `modworkshop.bat`): Read-only client for the public ModWorkshop API (https://api.modworkshop.net). Subcommands: `find-game`, `browse`, `top`, `search`, `info <mod_id>`, `files <mod_id>`. Defaults to RTV (game_id 864). Stdlib only. See README.md "ModWorkshop Browse & Publish" section.
- **Publish workflow** (`tools/publish.py` → `publish.bat`): Calls `mods/<ModName>/build.py --version X --install` then opens the browser to the mod's ModWorkshop edit page (if `mods/<ModName>/.publish` contains the integer mod id) or the generic upload page. The actual upload click stays manual — ModWorkshop's API is GET-only at the moment.
- **Mod scaffold** (`tools/scaffold_mod.py` → `scaffold.bat`): Generates a complete `mods/<MOD_ID>/` folder matching the workspace's standard layout. Drops mod.txt, Logger.gd stub, Main.gd, config.gd, the canonical build.py, README/CHANGELOG/LICENSE/PUBLISH_NOTES.md, and screenshots/README.md, then auto-runs `sync_logger.py` to fill in Logger.gd's body. Two opt-in flags: `--assets` (creates `assets/` folder + NOTICES.txt template + asset bundling in build.py + LICENSE carve-out paragraph for third-party assets) and `--items` (appends `[registry]` to mod.txt to opt into Metro Mod Loader v3.x's database wrapping + scaffolds a Main.gd that registers items via `Engine.get_meta("RTVModLib").register(lib.Registry.SCENES, ...)`; also bumps the PUBLISH_NOTES dependency line to require Metro v3.0.0+). Usage: `scaffold.bat "My New Mod"` or `scaffold.bat "My New Mod" --assets --items`.
- **Shared Logger** (`shared/Logger.gd` → synced into every mod via `tools/sync_logger.py`): Drop-in logging framework providing `debug/info/success/warn/error` (filterable, color-coded) plus `notify(msg, color)` (always-shows). Routes to game's `Loader.Message`. Demo + reuse package lives at `mods/RTVModLogger/`. See `mods/RTVModLogger/LOGGER.md` for the full API.
- **VS Code + Godot GDScript extension**: Recommended (not required) for syntax highlighting + autocomplete when editing `.gd` files. Connects to a running Godot Editor's language server (default port 6008).
- **MCP servers** (`.mcp.json` at workspace root, mirrored to `.vscode/mcp.json` for VS Code MCP-aware extensions):
  - `godotlens` — wraps Godot's built-in LSP via [godotlens-mcp](https://github.com/pzalutski-pixel/godotlens-mcp). Gives compiler-accurate `gdscript_definition` / `gdscript_references` / `gdscript_symbols` etc. across whatever project is loaded in the running Godot Editor. Best target: open `reference/RTV_decompiled/project.godot` so vanilla code is queryable.
  - `godot-docs` (`tools/godot_docs_mcp/server.py`) — exposes the Godot 4.6 documentation as queryable tools (`godot_search`, `godot_class`, `godot_method`). Reads from a local clone of [godotengine/godot-docs](https://github.com/godotengine/godot-docs) at `reference/godot_docs/` (gitignored); bootstrap with `download_godot_docs.bat`. Pinned to Godot 4.6 to match the game.

## Build & Test Workflow

1. Write mod scripts in `mods/<ModName>/`
2. Create `mod.txt` with metadata and autoload entries
3. Build & install with `publish.bat <ModName> --version X.Y.Z --no-open` (calls the mod's `build.py` which zips into `.vmz` and copies to game's `mods/` folder)
4. Launch game and test
5. To publish to ModWorkshop: `publish.bat <ModName> --version X.Y.Z` — opens the upload/edit page so the just-built `.vmz` can be dragged in

## Documentation

See [README.md](README.md) for comprehensive documentation including:
- Full game script catalog (all 176 scripts categorized)
- All 4 modding patterns with code examples
- mod.txt format specification
- Input action names
- Game architecture (autoloads, shader globals, node groups)
- GDRE Tools CLI usage
