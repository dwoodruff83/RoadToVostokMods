# CatAutoFeed — publish notes

Internal workspace doc. Not bundled in the .vmz.

## Status

**Publish position:** SECOND, after RTVModLogger. RTVModItemRegistry was retired (Metro v3.x's built-in registry replaces it natively); we now use Metro's `lib.register(SCENES, ...)` and `lib.register(LOOT, ...)` directly via the `[registry]` opt-in in mod.txt.

**Pre-publish state:** v1.1.0 frozen. Eight MCM toggles. Metro v3.0+ hard-required (uses Metro's registry API). Logger 6/6 API coverage. Cat bowl has Sketchfab CC BY 4.0 attribution in NOTICES.txt.

## TL;DR pitch

> The middle ground between Immortal Cat (too easy) and vanilla (too punishing). A real auto-feeder you build into your base — placeable bowl, lootable, manageable.

**Closest competitor:** [Put Food Out (#56098)](https://modworkshop.net/mod/56098) by Improvise — drop cat food anywhere in shelter, cat eats one per day. v0.0.2, 370 DL. The author admits "Likely incompatible with any cat mods except Pet Semetary." Our angle: real bowl item, MCM toggles, shelter-agnostic, trader-aware.

**Adjacent (not direct competitors):** [Immortal Cat (#55927)](https://modworkshop.net/mod/55927) (1,987 DL — cat doesn't starve), [80 hour cat (#56024)](https://modworkshop.net/mod/56024) (multiplies starvation 7×). Pitch target: the Immortal Cat audience that wants the cat-anxiety problem solved, not removed.

## ModWorkshop upload metadata

| Field | Value |
|---|---|
| **Category** | `Add-on` or animals/pets-equivalent (check dropdown options) |
| **Tags** | `Quality of Life (#12)`, `Add-on (#13)` |
| **Dependencies** | **Metro Mod Loader (#55623) v3.0.0+ required** (uses Metro's `[registry]` API); MCM (#53713) recommended |
| **License** | MIT (mod code) + CC BY 4.0 attribution for cat bowl model — see NOTICES.txt |
| **Description source** | Use README.md content directly. |
| **Screenshots** | `screenshots/01_overview.png` (hero — bowl in inventory), `02_mcm.png` (9 MCM toggles), `03_cat_bowl.png` (bowl in world). |

## Incompatibility callout (include in description)

- **Cat Food Shelter** (compiled .gdc reference mod) — can double-feed; remove first
- Any mod overriding `res://Scripts/Cat.gd` or `res://Scripts/CatFeeder.gd` differently
- **Probably incompatible with Put Food Out (#56098)** — both touch cat-feeding; test before claiming compatibility either way

## Remaining TODO

- [ ] **Test compatibility with Put Food Out (#56098)** — install both, document result; list as known-incompat in description if hard conflict
- [ ] Optional: capture a 4th screenshot of the bowl in trader supply (purple Legendary badge) — strong differentiator vs Put Food Out, but the 3 existing shots are sufficient to ship
- [x] First publish via ModWorkshop web form (mod id 56407)
- [x] **Post-publish:** mod id `56407` written to `mods/CatAutoFeed/.publish`; `[updates] modworkshop=56407` added to `mod.txt`

## References

- User-facing docs: [README.md](README.md)
- Asset attribution: [NOTICES.txt](NOTICES.txt)
- Workspace publish workflow: `publish.bat` at workspace root
