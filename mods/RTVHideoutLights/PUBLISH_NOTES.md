# RTV Hideout Lights — publish notes

Internal workspace doc. Not bundled in the .vmz.

## Status

**Pre-publish state:** v1.0.0. Nine placeable light fixtures, stocked by all three currently-revealed traders (Generalist, Gunsmith, Doctor). Grandma intentionally skipped (still story-hidden). Metro v3.0+ hard-required (uses `[registry]` API). MCM optional (only the Logger category attaches; mod has no settings of its own). All assets are vanilla `res://Assets/...` references — the mod ships zero mesh/texture data, only trader-catalog icons and a handful of `.tscn` / `.tres` wrappers + `.gd` scripts.

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

## Screenshots to capture

Aim for 4-5 hero shots:

1. **Trader catalog** — Generalist supply page showing the row of light icons.
2. **Hideout interior, lights on** — wide shot of a shelter with several fixtures placed and lit (cabin attic with the bright fluorescent + cellar wall sconce works well).
3. **Same scene, switch off** — same angle, vanilla light switch flipped, all wired fixtures dark. Demonstrates switch integration.
4. **PC + Floor Lamp close-ups** — show the cyan-lit monitor and the warm bulb glow inside the floor-lamp shade.
5. *(optional)* **Candle + Lantern lit in the dark** — shows the ignite/extinguish behavior and warm flicker light.

## Conflict callout (include in description)

- **Other placeable-lights mods** (none known at v1.0.0 publish, but re-check). Likely fine alongside; collisions only matter if another mod also uses Metro registry IDs starting with `rtvlights_`.
- **Mods that override `res://Scripts/Switch.gd` differently** — wiring relies on Switch.gd's `targets: Array[Node3D]` field and `Activate()`/`Deactivate()` methods. A mod that swaps out Switch.gd would need to preserve that interface.
- **Uninstall warning** — placed fixtures vanish from saves on next load if the .vmz is removed (Godot can't resolve `res://mods/RTVHideoutLights/...` paths). Pick everything up before uninstalling.

## TODO before publish

- [ ] Re-run `modworkshop.bat search lamp` / `light` / `placeable` to confirm no new direct competitors appeared since 2026-04-28
- [ ] Capture the screenshot set above (save under `screenshots/`, naming convention: `01_trader.png`, `02_hideout_lit.png`, etc.)
- [ ] Final test on a clean profile with only Metro + this mod installed
- [ ] First publish via ModWorkshop web form
- [ ] **Post-publish:** write assigned mod id into `mods/RTVHideoutLights/.publish` AND add `[updates]\nmodworkshop=<id>` to `mod.txt`, then rebuild + re-upload so the shipped `.vmz` is update-aware (per workspace memory: also click **Clear Primary Download** on every file swap or Metro auto-update breaks)

## References

- User-facing docs: [README.md](README.md)
- Asset attribution: [NOTICES.txt](NOTICES.txt)
- Original design doc: [docs/RTVHideoutLights_PLAN.md](../../docs/RTVHideoutLights_PLAN.md)
- Workspace publish workflow: `publish.bat` at workspace root
