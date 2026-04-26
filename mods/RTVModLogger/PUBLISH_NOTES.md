# RTVModLogger — publish notes

> Notes for whichever session/agent picks up the ModWorkshop publish work for this mod.
> Captures competitive analysis, positioning, and the metadata to put in the upload form.

## Status

**Recommended sequence:** publish SECOND, after RTVModItemRegistry. Same target audience
(mod developers + ecosystem early adopters); benefits from going up shortly after the
registry so the "tools by us" cluster lands together.

## TL;DR pitch

> A drop-in logging library for Road to Vostok mods. Six levels, three output targets
> (console / file / in-game overlay), MCM integration in one call, and per-mod isolation
> so multiple consumers don't step on each other.

## Competitor landscape

**One direct competitor, anemic:**

| Mod | Author | DL | What it does |
|---|---|---|---|
| [Debug API (56067)](https://modworkshop.net/mod/56067) | ScriptExec | **12** | 3 levels (log/warn/error), console-only, no MCM, no file, no overlay |

Adjacent mods that share the "debug" word but solve different problems:

| Mod | Author | DL | What it actually is |
|---|---|---|---|
| [Debug menu (55974)](https://modworkshop.net/mod/55974) | woovie | 314 | God mode / cheats UI |
| [Debug Mode (56289)](https://modworkshop.net/mod/56289) | Tewq | 43 | God mode, noclip, spawn UI, teleport |
| [RTV Tool Kit (56362)](https://modworkshop.net/mod/56362) | RealEstonia | 17 | Broader toolkit, unclear scope |

**Read on Debug API:** released ~mid-April, still 12 downloads. Either no one has discovered
it, or it's too thin to be worth installing. Either way the niche is wide open.

## Positioning

Direct, not coy. Debug API is `print()` with timestamps. We're a full logging library.

> "Six levels (debug / info / success / warn / error + always-shows `notify`). Three output
> targets, each toggleable in MCM (console, file, in-game overlay routed through the
> vanilla `Loader.Message` system). MCM integration helper adds Level/File/Overlay controls
> to your mod's existing config page in one call. Schema-preserving migration so adding new
> settings between versions doesn't lose user values. Each consumer mod gets its own
> identity, log file, and MCM page — no conflicts."

Demo mod ships in the same .vmz so people can see what each level looks like in-game
before integrating. **Lead with the demo screenshot/gif** — Debug API has no equivalent.

## Recommended ModWorkshop metadata

| Field | Value |
|---|---|
| **Category** | `Libraries (#?)` — same as Debug API, Weapon Rig API, Cassette Framework |
| **Tags** | `Add-on (#13)` |
| **Dependencies** | `Metro Mod Loader (#55623)` required; **MCM (#53713) optional** |
| **Repo URL** | (set when public) |
| **License** | MIT (embed Logger.gd freely) |

**On tags:** no "Library" / "Framework" / "Modding Tools" tag exists in active use on
ModWorkshop. Closest fit is `Add-on`. Make the developer-targeting clear in the description
opening rather than via tags.

## ModWorkshop description outline

```markdown
# RTV Mod Logger

> A drop-in logging library for Road to Vostok mods. One file, no dependencies on other libraries.

**For mod developers**, not players directly. The mod ships a small demo so you can see
what each log level looks like in-game.

## Six log levels

- `debug` (gray) - filterable
- `info` (white)
- `success` (green)
- `warn` (orange)
- `error` (red)
- `notify(msg, color)` - always shows, regardless of filters

## Three output targets

Each toggleable in MCM:

- **Console** - standard print
- **File** - `user://MCM/<mod_id>/<filename>.log`, rotates between sessions
- **In-game overlay** - routed through the vanilla `Loader.Message` system

## MCM integration in one call

    logger.register_mcm_category(config)

That's it. Adds Level / File / Overlay dropdowns to your mod's existing MCM page.

## Coexistence

Each mod that uses the library has its own identity, log file, and MCM page. They don't
conflict. Two consumer mods both depending on the logger? Fine.

## Schema-preserving migration

Add a new setting in v1.1 of your mod, your users keep their v1.0 values. See LOGGER.md
for the pattern.

## For modders: integrating

1. Copy `Logger.gd` into your mod folder
2. Edit three identity vars in `_init()`
3. Autoload it first in mod.txt
4. Use it: `_log.success("Mod activated")`, `_log.notify("Boss spawned!", Color.RED)`

Full reference: see LOGGER.md inside the mod's folder.

## Requires
- **Metro Mod Loader** (or any compatible .vmz loader)

## Optional
- **Mod Configuration Menu (MCM)** — for in-game settings (Level / File / Overlay toggles)
```

## TODO before publish

- [x] Verify `mods/RTVModLogger/build.py` builds: `publish.bat RTVModLogger --no-open`
      — build.py now supports `--version X.Y.Z` and bundles README/CHANGELOG/LOGGER/LICENSE
- [x] Confirm `LOGGER.md` is current — this is the public reference modders will follow
- [x] Capture an in-game screenshot or short gif showing the demo (Test All cycling through
      the levels with notifications in the corner) — `screenshots/01-overview.png` shows
      all six levels stacked with self-documenting strings; `02-mcm.png` shows the MCM page
- [x] Bump version to 1.0.0 (signals "stable API, embed it freely")
- [ ] Test on a clean profile: install standalone, press Test Hotkey (F12), confirm all six
      level outputs render correctly
- [ ] Test as a dependency: install + a consumer mod (e.g. CatAutoFeed) that uses the
      logger; confirm both MCM pages appear and don't conflict
- [ ] First publish via web form
- [ ] **Post-publish:** write assigned mod id into `mods/RTVModLogger/.publish` AND add
      `[updates]\nmodworkshop=<id>` to `mod.txt`, then rebuild + re-upload so the shipped
      `.vmz` is update-aware (see "Update flow" section below)
- [ ] Once supported, point CatAutoFeed and Wallet to declare this as an *optional*
      dependency (they each ship their own copy of Logger.gd, but reference is friendly)

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
source of truth. The version in `mod.txt` inside the new `.vmz` is what drives the diff.

## References

- Public reference: [LOGGER.md](LOGGER.md)
- User-facing docs: [README.md](README.md)
- Source: [Main.gd](Main.gd), [Logger.gd](Logger.gd), [config.gd](config.gd)
- Closest competitor for comparison reading: https://modworkshop.net/mod/56067
