# RTVModLogger — publish notes

Internal workspace doc. Not bundled in the .vmz.

## Status

**Publish position:** FIRST among the day-one releases. RTVModItemRegistry was retired (Metro v3.x's built-in registry replaces it natively), so RTVModLogger is now the lead publish, followed by CatAutoFeed.

**Pre-publish state:** v1.0.0 frozen. Welcome notify defaults OFF. Build packaging includes README/CHANGELOG/LOGGER.md/LICENSE in the .vmz.

**Differentiator from Metro v3.x's Developer Mode:** Metro's checkbox enables loader-internal `[ModLoader][Debug]` logs. RTVModLogger is a library other mods consume to expose *their* internals, with per-mod files, MCM toggles per consumer, and in-game overlay routing through `Loader.Message`. Different layer of the stack — they're complementary, not competing.

## TL;DR pitch

> A drop-in logging library for Road to Vostok mods. Six levels, three output targets (console / file / in-game overlay), MCM integration in one call, per-mod isolation so multiple consumers don't conflict.

**Closest competitor:** [Debug API (#56067)](https://modworkshop.net/mod/56067) by ScriptExec — 3 levels, console-only, no MCM, no file output, no overlay. 12 downloads at the time of survey. Niche is wide open.

## ModWorkshop upload metadata

| Field | Value |
|---|---|
| **Category** | Libraries (sibling to Debug API #56067, Weapon Rig API #56146, Cassette Framework #56206) |
| **Tags** | `Add-on (#13)` |
| **Dependencies** | `Metro Mod Loader (#55623)` required; `MCM (#53713)` optional |
| **License** | MIT |
| **Description source** | Use README.md content directly — no separate copy needed. |
| **Screenshots** | `screenshots/01-overview.png` (hero — six levels stacked), `02-mcm.png` (config page), `03-test-actions.png` (dropdown), `04-logging-levels.png` (MCM logging category). |

## Remaining TODO

- [ ] First publish via ModWorkshop web form
- [ ] **Post-publish:** write assigned mod id into `mods/RTVModLogger/.publish` AND add `[updates]\nmodworkshop=<id>` to `mod.txt`, then rebuild + re-upload so the shipped `.vmz` is update-aware (Metro Mod Loader auto-update support)

## References

- Public modder reference: [LOGGER.md](LOGGER.md)
- User-facing docs: [README.md](README.md)
- Workspace publish workflow: `publish.bat` at workspace root
