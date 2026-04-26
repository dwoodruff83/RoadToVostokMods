# PunisherGuarantee — publish notes

> Notes for whichever session/agent picks up the ModWorkshop publish work for this mod.
> Captures positioning, metadata, and a TODO list for the upload form.

## Status

**Recommended sequence:** publish FIFTH (last) — only if at all. This mod is a small,
focused tweak that the author is unlikely to publish in the near term; this file exists
so the workflow is ready in case that changes. Lower priority than the four "core"
publishables (RTVModItemRegistry, RTVModLogger, CatAutoFeed, Wallet).

## TL;DR pitch

> Punisher boss every Area 05 entry, day one, full Boss mode. Plus a hotkey to spawn one
> on demand. For players who want the encounter without RNG-gating it behind a 10%
> roll × day-5 minimum × 50/50 boss-vs-patrol coin flip.

## Competitor landscape

There is no direct competitor on ModWorkshop currently. Adjacent mods exist that touch
police/AI behaviour, but none specifically remove the Punisher event's RNG gating. This
is a small enough niche that a competitor is unlikely to appear quickly.

Quick check before publishing: search ModWorkshop for "Punisher" and "Police" tags to
confirm the niche is still empty.

## Positioning

Lead with the player frustration, not the implementation:

> "Tired of grinding to day 5, then getting 10% roll after 10% roll, only for the police
> van that finally arrives to be a regular patrol? This mod removes all three RNG gates
> on the Punisher event. Every Area 05 entry from day 1 fires the event, and every van
> is in Boss mode. F10 also spawns one on demand for loadout testing."

**Strong differentiators:**
- Surgical: only touches `Scripts/Police.gd`. No item additions, no UI, no save changes.
- Configurable: each of the three gates is a separate MCM toggle, so players can keep
  some of the vanilla mystery (e.g. only remove the day gate but keep the 10% roll).
- Hotkey spawn for testing — useful for content creators recording loadouts/strats.

## Recommended ModWorkshop metadata

| Field | Value |
|---|---|
| **Category** | `Tweaks` or `Difficulty`-equivalent (check the dropdown when publishing) |
| **Tags** | `Difficulty`, `Tweak`, `Add-on (#13)` |
| **Dependencies** | `Metro Mod Loader (#55623)` required; `MCM (#53713)` recommended |
| **Repo URL** | (set when public) |
| **License** | MIT |

## Conflict callout

> "**Conflicts with any mod that also overrides `res://Scripts/Police.gd`.** Only one
> override can win; load order decides. If ye install another mod that touches police
> behaviour, expect either this mod or that one to silently lose."

## ModWorkshop description outline

Draft from `README.md` directly — it's already publish-shaped. Just remove the
"Source & Issues" section if the repo isn't public, and add the conflict callout above.

## TODO before publish

- [ ] Verify `mods/PunisherGuarantee/build.py` builds: `publish.bat PunisherGuarantee --no-open`
      (build.py now supports `--version X.Y.Z` and bundles README/CHANGELOG/LICENSE)
- [ ] Bump version to 1.0.0 if features are stable (currently 0.1.0)
- [ ] Capture screenshots: (a) Punisher van arriving on day 1, (b) F10 spawn firing,
      (c) the MCM page with the four toggle settings
- [ ] Test compatibility with any popular mod that touches `Scripts/Police.gd`
- [ ] Re-check ModWorkshop for any newly-published Punisher/Police tweak mods
- [ ] First publish via web form
- [ ] **Post-publish:** write assigned mod id into `mods/PunisherGuarantee/.publish` AND
      add `[updates]\nmodworkshop=<id>` to `mod.txt`, then rebuild + re-upload so the
      shipped `.vmz` is update-aware (see "Update flow" section below)

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

Loader endpoints (read-only, both on `api.modworkshop.net`):
- `POST /mods/versions` with `{"mod_ids":[...]}` for the diff check
- `GET /mods/<id>/download` to fetch the new file

No separate "submit" or external changelog log is required — the ModWorkshop page IS the
source of truth.

## References

- User-facing docs: [README.md](README.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Source: [Main.gd](Main.gd), [PoliceOverride.gd](PoliceOverride.gd)
- Workspace publish workflow: see `publish.bat` in workspace root
