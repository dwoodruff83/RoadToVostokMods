# PunisherGuarantee — publish notes

Internal workspace doc. Not bundled in the .vmz.

## Status

**HELD — local testing only, per current direction.** A small focused tweak that the author may or may not publish later. The workflow is documented here so it's ready to ship if that changes.

## TL;DR pitch (when ready)

> Punisher boss every Area 05 entry, day one, full Boss mode. Plus a hotkey to spawn one on demand. For players who want the encounter without RNG-gating it behind a 10% roll × day-5 minimum × 50/50 boss-vs-patrol coin flip.

**Competitor landscape:** no direct competitor on ModWorkshop. Re-check by searching "Punisher" / "Police" tags before publishing.

## Differentiator (when pitching)

- Surgical: only touches `Scripts/Police.gd`. No item additions, no UI, no save changes.
- Configurable: each gate is a separate MCM toggle — keep some vanilla mystery if desired.
- Hotkey spawn (default F10, configurable Keycode) for loadout testing.

## ModWorkshop upload metadata (when ready)

| Field | Value |
|---|---|
| **Category** | `Tweaks` or `Difficulty`-equivalent (check dropdown when publishing) |
| **Tags** | `Difficulty`, `Tweak`, `Add-on (#13)` |
| **Dependencies** | Metro Mod Loader (#55623) required; MCM (#53713) recommended |
| **License** | MIT |
| **Description source** | Use README.md content directly — append the conflict callout below. |

## Conflict callout (include in description)

> **Conflicts with any mod that also overrides `res://Scripts/Police.gd`.** Only one override can win; load order decides. If you install another mod that touches police behaviour, expect either this mod or that one to silently lose.

## Remaining TODO (publish blockers)

- [ ] Bump to 1.0.0 + add 1.0.0 CHANGELOG entry
- [ ] Capture screenshots: Punisher van arriving on day 1, F10 spawn firing, MCM page (six settings: four General toggles + two Hotkey settings)
- [ ] Re-check ModWorkshop for any newly-published Punisher/Police tweak mods
- [ ] Test compatibility with any popular mod that touches `Scripts/Police.gd`
- [ ] First publish via ModWorkshop web form
- [ ] **Post-publish:** write assigned mod id into `mods/PunisherGuarantee/.publish` AND add `[updates]\nmodworkshop=<id>` to `mod.txt`, then rebuild + re-upload so the shipped `.vmz` is update-aware

## References

- User-facing docs: [README.md](README.md)
- Workspace publish workflow: `publish.bat` at workspace root
