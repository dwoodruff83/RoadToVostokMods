# RTV Hideout Lights — publish notes

Internal workspace doc. Not bundled in the .vmz.

## Status

**Current state:** v1.1.0 (about to publish). Live on ModWorkshop as id 56519. v1.0.1 (live) hardened the `[registry]` section to survive Metro v3.0.0 ConfigFile parsing. v1.1.0 ships placement-preview cleanup, "off-on-pickup, sync-to-switch-on-drop" lifecycle, and room-aware switch routing (subscribes to whichever switch's static lights are nearest, so multi-room shelters like the Cabin work correctly).

Nine placeable light fixtures, stocked by all three currently-revealed traders (Generalist, Gunsmith, Doctor). Grandma intentionally skipped (still story-hidden). Metro v3.0+ hard-required (uses `[registry]` API). MCM optional (only the Logger category attaches; mod has no settings of its own). All assets are vanilla `res://Assets/...` references; the mod ships zero mesh/texture data, only trader-catalog icons and a handful of `.tscn` / `.tres` wrappers + `.gd` scripts.

## TL;DR pitch

> Nine placeable light fixtures, stocked by every trader. Decorate your shelter with vanilla-quality lamps, lanterns, candles, fluorescents and an exit sign. Some toggle on/off via Use; ceiling fixtures wire into your shelter's existing wall switch.

**Niche:** Confirmed empty as of 2026-04-28 via `modworkshop.bat search` against game id 864 — zero competing placeable-lights mods. Re-verify before posting and update if anything shows up.

## ModWorkshop upload metadata

| Field | Value |
|---|---|
| **Category** | `Add-on` (check dropdown for a "Decor" / "Furniture" option if one exists) |
| **Tags** | `Quality of Life (#12)`, `Add-on (#13)` |
| **Dependencies** | **Metro Mod Loader (#55623) v3.0.0+ required** (uses `[registry]` API); MCM (#53713) optional (only attaches Logger category) |
| **License** | MIT (mod code) — vanilla game assets remain Road to Vostok Productions' property; see NOTICES.txt |
| **Description source** | Use README.md content directly. |
| **Screenshots** | TODO: capture before publishing — see "Screenshots to capture" below. |

## Screenshots (in `screenshots/`, ordered for MW)

- `01_overview.png` — hero: hideout with multiple fixtures placed and lit
- `02_mcm.png` — MCM page (Logger category only, since mod has no settings)
- `03_catalog.png` — trader catalog row of light icons
- `04_placement01.png` — wall placement preview (green hologram on rocky wall)
- `05_placement02.png` — ceiling placement preview (long fluorescent tube hologram)
- `06-interactions01.png` — lit lantern close-up (Fire integration)
- `07-interactions02.png` — Use prompt on a fixture in a dark room

## Conflict callout (include in description)

- **Other placeable-lights mods** (none known at v1.0.0 publish, but re-check). Likely fine alongside; collisions only matter if another mod also uses Metro registry IDs starting with `rtvlights_`.
- **Mods that override `res://Scripts/Switch.gd` differently** — wiring relies on Switch.gd's `targets: Array[Node3D]` field and `Activate()`/`Deactivate()` methods. A mod that swaps out Switch.gd would need to preserve that interface.
- **Uninstall warning** — placed fixtures vanish from saves on next load if the .vmz is removed (Godot can't resolve `res://mods/RTVHideoutLights/...` paths). Pick everything up before uninstalling.

## Per-release publish steps (recurring)

For every new version after 1.0.0:

- [x] Bump `mod.txt` version via `publish.bat <Mod> --version X.Y.Z --no-open` (also rebuilds + installs)
- [x] Update CHANGELOG with the new version's entry (placement at top)
- [x] Update README if user-facing behavior changed
- [ ] Commit + push, PR staging → main, squash-merge
- [ ] Tag `RTVHideoutLights-vX.Y.Z` against the merge commit on `main`
- [ ] Post-squash resync: force-reset `staging` to `origin/main`
- [ ] Bump workspace README releases-table row to new version
- [ ] On ModWorkshop edit page (`publish.bat RTVHideoutLights` opens it via `.publish`): drop new `.vmz`, click **Clear Primary Download** so Metro auto-update sees the new file, save

## References

- User-facing docs: [README.md](README.md)
- Asset attribution: [NOTICES.txt](NOTICES.txt)
- Original design doc: [docs/RTVHideoutLights_PLAN.md](../../docs/RTVHideoutLights_PLAN.md)
- Workspace publish workflow: `publish.bat` at workspace root
