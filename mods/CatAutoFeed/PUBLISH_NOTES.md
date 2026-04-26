# CatAutoFeed — publish notes

> Notes for whichever session/agent picks up the ModWorkshop publish work for this mod.
> Captures competitive analysis, positioning, and the metadata to put in the upload form.

## Status

**Recommended sequence:** publish THIRD, after RTVModItemRegistry and RTVModLogger are up.
This mod can declare both as soft dependencies and benefit from the goodwill.

**Position as a 1.0.0 release.** Lots of features stacked since 0.3.0 was tagged
(registry integration, Logger 6/6 API coverage, defensive review-pass fixes,
clean boot, full docs). Bump `mod.txt` from `0.3.0 → 1.0.0` and add a 1.0.0
entry to CHANGELOG.md before uploading. The first impression is the catalog
listing, so don't ship a "0.x" with this much content.

## TL;DR pitch

> The middle ground between Immortal Cat (too easy) and vanilla (too punishing).
> A real auto-feeder you build into your base — placeable bowl, lootable, manageable.

## Competitor landscape

**Closest direct competitor (by mechanic):**

| Mod | Author | DL | Approach |
|---|---|---|---|
| [Put Food Out (56098)](https://modworkshop.net/mod/56098) | Improvise | 370 | Drop cat food anywhere in shelter, cat eats one per day. v0.0.2. Author admits "Likely incompatible with any cat mods except Pet Semetary." |

**Adjacent (different angles on the same player frustration):**

| Mod | Author | DL | Approach |
|---|---|---|---|
| [Immortal Cat (55927)](https://modworkshop.net/mod/55927) | PoshIndie | **1,987** | Cat just doesn't starve. Most popular. Hard difficulty bypass. |
| [80 hour cat (56024)](https://modworkshop.net/mod/56024) | ivy melinda | 717 | Multiplies starvation timer 7×. Pure tweak. |
| [Pet Semetary (56065)](https://modworkshop.net/mod/56065) | Improvise | 59 | Resurrection. Complementary, not competing. |

**Insight:** the Immortal Cat audience (~2k players) wants the cat-anxiety problem solved,
not removed. Many of them likely feel guilty cheesing it. That's our pitch target.

## Positioning

Lead with what differentiates the mechanic, then the polish.

> "Don't make your cat immortal — make a real cat-feeder. Place a 2×2 Cat Food Bowl in
> your shelter, fill it with food (canned meat, tuna, perch, cat food), and your cat
> eats from it on its own when you're away. Bowls spawn in legendary loot, can be sold
> at traders, and persist with their contents across save/reload. Survival tension stays
> intact — you still have to find or buy food and remember to refill the bowl. But you
> don't lose your cat because you got pinned down at Bunker for an extra hour."

**Strong differentiators vs Put Food Out:**
- Custom 2×2 placeable Cat Food Bowl with custom 3D model (Put Food Out has zero new items)
- Bowl-management UI panel — vanilla theme, item icons, hover effects, capacity indicator that turns amber at full (theirs is just drop-on-floor)
- Bowl is **Legendary rarity (purple badge), 750 € sale value, type Misc** — sellable at traders, spawns in civilian loot at ~1 in 120 containers, world tooltip shows `Cat Food Bowl (5/10)` while filled
- 6 MCM toggles (Put Food Out has 0)
- Works with all shelters (Cabin / Attic / Classroom / Tent / Bunker)
- Hunger and bowl-empty warnings (throttled to once per hunger cycle)
- Opt-in shelter-fallback (cat raids cabinets/fridges if bowl is empty)

**Strong differentiators vs Immortal Cat:**
- Preserves the "you have to plan around the cat" tension
- Lorefriendly (food stays the limiting resource, the bowl is just better UX)

## Recommended ModWorkshop metadata

| Field | Value |
|---|---|
| **Category** | `Add-on` or `Animals/Pets`-equivalent (check the dropdown — Apartment Shelter uses `Shelters`) |
| **Tags** | `Quality of Life (#12)`, `Add-on (#13)` |
| **Dependencies** | A VostokMods-compatible loader required (Metro Mod Loader #55623 is the most popular); `MCM (#53713)` recommended; **soft dep on RTVModItemRegistry** — declare optional, but recommended for clean coexistence with other Database-extending mods (the mod falls back to legacy direct injection when absent) |
| **Repo URL** | (set when public) |
| **License** | MIT (mod code) + CC BY 4.0 attribution for the cat bowl model — see NOTICES.txt |

## Incompatibility callout (be explicit)

In the description, list these as known conflicts so users don't blame us:
- **Cat Food Shelter** (the compiled .gdc mod we have for reference) — can double-feed
- Any mod that overrides `res://Scripts/Cat.gd` or `res://Scripts/CatFeeder.gd` differently
- **Probably incompatible with Put Food Out** (both touch cat-feeding logic) — confirm by testing

## ModWorkshop description outline

```markdown
# Cat Auto Feed 1.0.0

> Automatically feeds your cat from a placed Cat Food Bowl from anywhere on the map.

No more returning to base every 40 minutes to drop a can of tuna in the feeder.

## What it adds

- **Cat Food Bowl** — a 2×2 placeable inventory item with a custom 3D model.
  **Legendary rarity (purple badge), 750 € sale value.** Sellable at traders,
  droppable, lootable. Holds up to 10 servings of cat-edible food (Cat Food,
  Canned Meat, Canned Tuna, Perch). World tooltip shows `Cat Food Bowl (5/10)`
  while filled so you can see the level at a glance.
- **Bowl management UI** — middle-click a placed bowl to open a custom panel
  with the vanilla theme, item icon thumbnails, hover effects, two columns
  (bowl ↔ inventory), Take/Add buttons, a capacity indicator that turns amber
  when full, and a "Pick up bowl" button (enabled only when empty).
- **Spawns in legendary loot** — registered in the master loot table, ~1 in
  120 civilian containers. Toggleable in MCM.
- **Auto-feed from anywhere** — when cat hunger drops below the threshold and
  you're outside the shelter, the cat eats one serving from its bowl.
- **Hunger and bowl-empty warnings** — on-screen notifications, throttled to
  once per hunger cycle.
- **Opt-in shelter fallback** — when off (default), cat eats only from the
  bowl. When on, it raids raw food in cabinets/fridges in its shelter.
- **Manual feeding preserved** — when you're inside the cat's shelter, the
  mod defers to the vanilla CatFeeder.
- **Shelter-agnostic** — works with Cabin, Attic, Classroom, Tent, and Bunker.

## Configuration (MCM)

Six toggles: Enable Auto-Feed, Feed Threshold, Show Fed Notification, Show
Hunger Warning, Allow Shelter Fallback, Bowl in Loot Tables. Plus the
standard Logger category (level / file / overlay).

## Compatibility

- **Incompatible with** other cat-feeding mods (Cat Food Shelter, etc.) —
  remove them first to avoid double-feeding.
- **MCM is optional** — runs with sensible defaults if MCM is absent.
- **Uninstalling drops bowls and contents.** Empty bowls before removing the
  .vmz to preserve food in your saves.

## Why not Immortal Cat?

If you want zero cat-anxiety, install Immortal Cat. This mod is for players
who want the "manage your cat's food supply" mechanic to keep working — just
without the back-to-base pilgrimage every 40 minutes.

## Requires
- A **VostokMods-compatible loader** — [Metro Mod Loader](https://modworkshop.net/mod/55623)
  is the most popular; any .vmz-aware loader should work.

## Recommended
- **[Mod Configuration Menu (MCM)](https://modworkshop.net/mod/53713)** — for
  in-game settings. The mod runs without it but you can't tweak toggles.
- **[RTV Mod Item Registry](https://modworkshop.net/mod/PENDING)** — coordinates
  with other Database-extending mods (e.g. Wallet) so they coexist cleanly.
  Without it, the mod falls back to legacy direct injection (works fine in
  single-mod setups; conflicts with siblings if multiple Database-extenders
  are installed).
```

## TODO before publish

- [x] ~~Verify `mods/CatAutoFeed/build.py` builds: `publish.bat CatAutoFeed --no-open`~~
      Built and installed many times during development.
- [x] ~~Update Main.gd to detect the registry and prefer it~~ Done in commit `1154e1c` —
      `_inject_database` now does `get_node_or_null("/root/ModItemRegistry")` (with
      `find_child` fallback for the cross-mod-autoload lookup) and falls back to
      legacy direct injection only when the registry isn't installed.
- [x] ~~Confirm NOTICES.txt is current with the cat bowl model attribution~~ CC BY 4.0
      attribution to Justyna.sliwinska for the cat bowl Sketchfab model is in place.
- [ ] **Bump `mod.txt` version 0.3.0 → 1.0.0** and add a 1.0.0 entry to `CHANGELOG.md`
      summarizing the full feature set (bowl item + bowl-only mode + loot integration +
      registry support + Logger 6/6 + defensive review-pass fixes).
- [ ] **Test compatibility with Put Food Out (#56098)** — install both, see what happens.
      Document the result (compatible / partial / hard conflict) in the ModWorkshop
      description. If hard-conflict, list it under "Known incompatibilities".
- [ ] Capture screenshots:
      (a) Cat Food Bowl placed in shelter,
      (b) the bowl management UI panel open with both columns populated,
      (c) the "Cat ate from bowl" notification firing in-game,
      (d) the bowl appearing in trader supply (proves Misc / Legendary tier displays
          correctly with the purple rarity badge).
- [ ] First publish via the ModWorkshop web form.
- [ ] Write the assigned mod id into `mods/CatAutoFeed/.publish` so future
      `publish.bat` runs open the right edit page.
- [ ] Once **RTVModItemRegistry** is also published, replace the `PENDING` placeholder
      in the description's Recommended section with the assigned mod id link.

## References

- User-facing docs: [README.md](README.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Asset attribution: [NOTICES.txt](NOTICES.txt)
- Source: [Main.gd](Main.gd), [BowlPickup.gd](BowlPickup.gd), [BowlContentsPanel.gd](BowlContentsPanel.gd)
- Closest competitor for comparison reading: https://modworkshop.net/mod/56098
