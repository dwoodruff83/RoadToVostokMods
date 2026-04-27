# Contributing — RoadToVostokMods workspace

This is a monorepo of Road to Vostok mods plus shared workspace tooling. If you're a mod author looking to fork a single mod, the README at the root of each `mods/<ModName>/` directory has user-facing docs; this file covers the workspace-level conventions.

## Branch flow

```
feature/<short-name>   work branches
        |
        v
     staging            integration branch (where everything lands first)
        |
        v
       main             stable, only updated via PR from staging
```

- Open all PRs against **`staging`** by default
- `main` is protected. PRs into `main` are only accepted from `staging` (enforced by `.github/workflows/enforce-main-source.yml` and branch protection rules)
- Force pushes and branch deletions are disabled on both `main` and `staging`

## Versioning and release tags

The workspace is a monorepo, so tags carry a mod-id prefix to disambiguate releases across mods. The shape is:

```
<ModId>-v<X.Y.Z>
```

Examples:

```
RTVModLogger-v1.0.0
CatAutoFeed-v1.1.0
RTVWallets-v1.0.0
```

Tag at the moment ye cut a `.vmz` for ModWorkshop. The tagged commit becomes the canonical "what was in this published build" — `git checkout <tag>` reproduces exactly what shipped.

The standalone tracker repo at https://github.com/dwoodruff83/rtv-mod-impact-tracker uses plain semver tags (`v1.0.0`, `v1.1.0`, etc.) since it's a single tool, not a monorepo.

### Bumping a mod's version

1. Update the mod's `mod.txt` `version=` field
2. Add a CHANGELOG entry under `mods/<ModId>/CHANGELOG.md`
3. Build + publish via `publish.bat <ModName> --version X.Y.Z`
4. Tag: `git tag -a <ModId>-v<X.Y.Z> -m "<ModId> v<X.Y.Z> — short release note"`
5. Push: `git push origin <ModId>-v<X.Y.Z>`

## Workspace conventions

- **GDScript**: 4-space indentation (mixed-tab/space breaks Godot compile)
- **Logger sync**: each mod ships its own `Logger.gd` synced from `shared/Logger.gd` via `tools/sync_logger.py`. Identity values (mod_id, autoload name, log filename) are preserved per mod
- **Mod scaffolding**: use `tools/scaffold_mod.py` (or `scaffold.bat`) for new mods to get the standard layout
- **Build / install / publish**: `publish.bat <ModName> --version X.Y.Z` builds the `.vmz`, installs to the game's mods folder, and (with `.publish` containing the ModWorkshop id) opens the edit page

## Tooling

See [README.md](README.md) for the full tooling table. Key entries:

- `tools/save_backup.py` — backup/restore RTV save files
- `tools/sync_logger.py` — sync canonical Logger.gd into each mod
- `tools/publish.py` — build → install → open ModWorkshop edit page
- `tools/scaffold_mod.py` — scaffold a new mod folder
- The eight `.bat` wrappers at the workspace root (snapshot/analyze_mods/changelog/fetch_version/deps_*) call into the [rtv-mod-impact-tracker](https://github.com/dwoodruff83/rtv-mod-impact-tracker) tool

## Reporting issues

Open an issue against the specific mod (mention `mods/<ModId>/`) with:
- What ye ran
- What ye expected
- What actually happened (errors, missing items, save corruption, etc.)
- The mod version (in `mod.txt`) and the game version

For game-developer concerns: the workspace ships modder content built on a decompile we keep local. If anything looks off, open an issue and the maintainer will work with you.
