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
| `F:\RoadToVostokMods\mods\` | Our mod projects |
| `C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\` | Game install |
| `C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\mods\` | Installed mods (.vmz files) |

## Modding Quick Reference

- Mods are `.vmz` files (renamed ZIPs) with a `mod.txt` metadata file
- Entry point scripts are autoloaded via `mod.txt` `[autoload]` section
- Override game scripts with `take_over_path()` (see Pattern 1 in README.md)
- MCM integration for in-game config (see Pattern 2 in README.md)
- Game state lives in `GameData.tres` (preload as `res://Resources/GameData.tres`)
- All game scripts are under `res://Scripts/` (176 files)

## Tooling

- **GDRE Tools** (installed): Decompile PCK, list files, create PCK
- **Godot Editor 4.6.x**: NOT YET INSTALLED — needed before we can build/test mods
- **VS Code + GDScript extension**: NOT YET INSTALLED — recommended for editing

## Build & Test Workflow

1. Write mod scripts in `mods/<ModName>/`
2. Create `mod.txt` with metadata and autoload entries
3. ZIP the mod folder contents into `<ModName>.vmz`
4. Copy `.vmz` to game's `mods/` folder
5. Launch game and test

## Documentation

See [README.md](README.md) for comprehensive documentation including:
- Full game script catalog (all 176 scripts categorized)
- All 4 modding patterns with code examples
- mod.txt format specification
- Input action names
- Game architecture (autoloads, shader globals, node groups)
- GDRE Tools CLI usage
