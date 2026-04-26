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
| `F:\rtv-mod-impact-tracker\` | Standalone tool repo (MIT, private): snapshot.py + analyze_mods.py + changelog.py + fetch_version.py |
| `F:\RoadToVostokMods\mod_tracker.toml` | Config consumed by the tool (paths + Steam app id) |
| `F:\RoadToVostokMods\manifests.json` | Steam manifest registry consumed by `fetch_version.py` |
| `F:\RoadToVostokMods\snapshot.bat` / `analyze_mods.bat` / `changelog.bat` / `fetch_version.bat` | Wrappers calling into the tool repo |
| `F:\RoadToVostokMods\tools\GDRE_tools\` | GDRE Tools v2.5.0-beta.5 (decompiler) |
| `F:\RoadToVostokMods\tools\Godot\` | Godot Editor 4.6.2 (installed) |
| `F:\RoadToVostokMods\tools\DepotDownloader\` | Steam depot tool (for backfilling old game builds) |
| `F:\RoadToVostokMods\tools\save_backup.py` | Backup/restore RTV save files from `%APPDATA%\Road to Vostok\` |
| `F:\RoadToVostokMods\tools\sync_logger.py` | Sync canonical `shared/Logger.gd` into each mod, preserving identity values |
| `F:\RoadToVostokMods\tools\modworkshop.py` / `modworkshop.bat` | Read-only ModWorkshop API client (browse, search, info, files) |
| `F:\RoadToVostokMods\tools\publish.py` / `publish.bat` | One-shot build → install → open ModWorkshop edit/upload page |
| `F:\RoadToVostokMods\mods\<ModName>\.publish` | Optional one-line file containing the ModWorkshop mod id; if present, `publish.bat` opens that mod's edit page |
| `F:\RoadToVostokMods\shared\Logger.gd` | Canonical reusable Logger source (synced into each mod) |
| `F:\RoadToVostokMods\mods\RTVModLogger\` | Standalone demo + reusable logging library mod (ships `Logger.gd` for other modders) |
| `F:\RoadToVostokMods\mods\RTVModLogger\LOGGER.md` | Full modder-facing reference for the logger (formerly in `shared/`) |
| `F:\RoadToVostokMods\reference\RTV_history\` | Git repo of decompiled snapshots, one commit per game version |
| `F:\RoadToVostokMods\mods\` | Our mod projects |
| `C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\` | Game install |
| `C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\mods\` | Installed mods (.vmz files) |
| `C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\override.cfg` | Godot autoload override — points at `user://modloader.gd` (Metro Mod Loader v2.0.0 install) |
| `%APPDATA%\Road to Vostok\modloader.gd` | Metro Mod Loader v2.0.0 (1699 lines, MD5 `61bbf6edda9e23310cbe39cadb1ca5d3`) — the loader script that mounts our `.vmz` files at game start |
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
- **rtv-mod-impact-tracker** (`F:\rtv-mod-impact-tracker\`): Standalone repo with four scripts (snapshot, analyze_mods, changelog, fetch_version). Driven from this workspace via `mod_tracker.toml` and four `.bat` wrappers. See README.md "Version Tracking" section.
- **ModWorkshop CLI** (`tools/modworkshop.py` → `modworkshop.bat`): Read-only client for the public ModWorkshop API (https://api.modworkshop.net). Subcommands: `find-game`, `browse`, `top`, `search`, `info <mod_id>`, `files <mod_id>`. Defaults to RTV (game_id 864). Stdlib only. See README.md "ModWorkshop Browse & Publish" section.
- **Publish workflow** (`tools/publish.py` → `publish.bat`): Calls `mods/<ModName>/build.py --version X --install` then opens the browser to the mod's ModWorkshop edit page (if `mods/<ModName>/.publish` contains the integer mod id) or the generic upload page. The actual upload click stays manual — ModWorkshop's API is GET-only at the moment.
- **Shared Logger** (`shared/Logger.gd` → synced into every mod via `tools/sync_logger.py`): Drop-in logging framework providing `debug/info/success/warn/error` (filterable, color-coded) plus `notify(msg, color)` (always-shows). Routes to game's `Loader.Message`. Demo + reuse package lives at `mods/RTVModLogger/`. See `mods/RTVModLogger/LOGGER.md` for the full API.
- **VS Code + Godot GDScript extension**: Recommended (not required) for syntax highlighting + autocomplete when editing `.gd` files. Connects to a running Godot Editor's language server (default port 6008).

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
