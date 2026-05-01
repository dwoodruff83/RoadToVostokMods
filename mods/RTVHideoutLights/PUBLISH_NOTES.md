# RTV Hideout Lights — publish notes

> Notes for whichever session/agent picks up the ModWorkshop publish work for this mod.
> Captures positioning, metadata, and a TODO list for the upload form.

## Status

**Recommended sequence:** TODO — slot this mod into the publish queue when it's ready.

## TL;DR pitch

> Placeable hideout lights, sold by the Generalist

## Competitor landscape

TODO: search ModWorkshop for adjacent mods. Use `modworkshop.bat search <keyword>`.
Document any direct competitors and how this mod differs.

## Positioning

TODO: one paragraph on the angle to lead with on the mod page.

## Recommended ModWorkshop metadata

| Field | Value |
|---|---|
| **Category** | TODO (check the dropdown) |
| **Tags** | `Add-on (#13)` plus any specific to your mod |
| **Dependencies** | **`Metro Mod Loader (#55623)` v3.0.0+ required** (uses Metro's `[registry]` API); `MCM (#53713)` recommended |
| **Repo URL** | (set when public) |
| **License** | MIT |

## Conflict callout

TODO: any incompatibilities to flag explicitly in the description so users don't blame this mod.

## ModWorkshop description outline

Draft from `README.md` — it's already publish-shaped. Adjust per the positioning above.

## TODO before publish

- [ ] Verify `mods/RTVHideoutLights/build.py` builds: `publish.bat RTVHideoutLights --no-open`
- [ ] Bump version to 1.0.0 if features are stable (currently 0.1.0)
- [ ] Capture screenshots (see `screenshots/README.md` for the naming convention)
- [ ] Test on a clean profile with only this mod installed
- [ ] First publish via web form
- [ ] **Post-publish:** write assigned mod id into `mods/RTVHideoutLights/.publish` AND
      add `[updates]\nmodworkshop=<id>` to `mod.txt`, then rebuild + re-upload
      so the shipped `.vmz` is update-aware (see "Update flow" section below)

## Update flow (Metro Mod Loader)

Metro Mod Loader has a built-in **Updates** tab that auto-checks ModWorkshop and offers a
one-click Download button per mod. To opt in, `mod.txt` must include both:

```
[mod]
version="1.0.0"

[updates]
modworkshop=<mod_id>
```

Then on each release:

1. Bump `version=` (or pass `--version X.Y.Z` to `publish.bat`)
2. Build the new `.vmz`
3. **Upload to the existing ModWorkshop mod page (replace the file, do NOT create a new mod)**
4. Users hit Check on the loader's Updates tab → see "update: vX.Y.Z" → click Download

No separate "submit" or external changelog log is required — the ModWorkshop page IS the
source of truth.

## References

- User-facing docs: [README.md](README.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Source: [Main.gd](Main.gd)
- Workspace publish workflow: see `publish.bat` in workspace root
