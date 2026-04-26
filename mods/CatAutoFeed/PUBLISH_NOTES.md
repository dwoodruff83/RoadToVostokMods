# CatAutoFeed — publish notes

> Notes for whichever session/agent picks up the ModWorkshop publish work for this mod.
> Captures competitive analysis, positioning, and the metadata to put in the upload form.

## Status

**Recommended sequence:** publish THIRD, after RTVModItemRegistry and RTVModLogger are up.
This mod can declare both as soft dependencies and benefit from the goodwill.

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
- Bowl-management UI panel (theirs is just drop-on-floor)
- Bowl spawns in loot tables at Legendary rarity (~1 in 120 civilian containers)
- 6 MCM toggles (Put Food Out has 0)
- Works with all shelters (Cabin / Attic / Classroom / Tent / Bunker)
- Hunger and bowl-empty warnings (orange notifications)
- Opt-in shelter-fallback (cat raids cabinets/fridges if bowl is empty)

**Strong differentiators vs Immortal Cat:**
- Preserves the "you have to plan around the cat" tension
- Lorefriendly (food stays the limiting resource, the bowl is just better UX)

## Recommended ModWorkshop metadata

| Field | Value |
|---|---|
| **Category** | `Add-on` or `Animals/Pets`-equivalent (check the dropdown — Apartment Shelter uses `Shelters`) |
| **Tags** | `Quality of Life (#12)`, `Add-on (#13)` |
| **Dependencies** | `Metro Mod Loader (#55623)` required; `MCM (#53713)` recommended; **soft dep on RTVModItemRegistry once it's published** (declare optional) |
| **Repo URL** | (set when public) |
| **License** | MIT (mod code) + CC BY 4.0 attribution for the cat bowl model — see NOTICES.txt |

## Incompatibility callout (be explicit)

In the description, list these as known conflicts so users don't blame us:
- **Cat Food Shelter** (the compiled .gdc mod we have for reference) — can double-feed
- Any mod that overrides `res://Scripts/Cat.gd` or `res://Scripts/CatFeeder.gd` differently
- **Probably incompatible with Put Food Out** (both touch cat-feeding logic) — confirm by testing

## ModWorkshop description outline

```markdown
# Cat Auto Feed

> Automatically feeds your cat from a placed Cat Food Bowl from anywhere on the map.

No more returning to base every 40 minutes to drop a can of tuna in the feeder.

## What it adds

- **Cat Food Bowl** — a 2×2 placeable inventory item with a custom 3D model. Sellable,
  droppable, lootable. Holds up to 10 servings of cat-edible food (Cat Food, Canned Meat,
  Canned Tuna, Perch).
- **Bowl management UI** — middle-click a placed bowl to open a custom panel: two-column
  layout (bowl ↔ inventory), Take/Add buttons, capacity indicator, "Pick up bowl" button.
- **Spawns in legendary loot** — registered in the master loot table, ~1 in 120 civilian
  containers. Toggleable in MCM.
- **Auto-feed from anywhere** — when cat hunger drops below the threshold and you're
  outside the shelter, the cat eats one serving from its bowl.
- **Hunger and bowl-empty warnings** — on-screen notifications, once per hunger cycle.
- **Opt-in shelter fallback** — when off (default), cat eats only from the bowl. When on,
  it raids raw food in cabinets/fridges in its shelter.
- **Manual feeding preserved** — when you're inside the cat's shelter, the mod defers to
  the vanilla CatFeeder.
- **Shelter-agnostic** — works with Cabin, Attic, Classroom, Tent, and Bunker.

## Configuration (MCM)

Six toggles: Enable Auto-Feed, Feed Threshold, Show Fed Notification, Show Hunger Warning,
Allow Shelter Fallback, Bowl in Loot Tables. Plus the standard Logger category.

## Compatibility

- **Incompatible with** other cat-feeding mods (Cat Food Shelter, etc.) — remove them first
- **MCM is optional** — runs with sensible defaults if MCM is absent
- **Uninstalling drops bowls and contents.** Empty bowls before removing the .vmz to
  preserve food in saves.

## Why not Immortal Cat?

If you want zero cat-anxiety, install Immortal Cat. This mod is for players who want the
"manage your cat's food supply" mechanic to keep working — just without the back-to-base
pilgrimage every 40 minutes.

## Requires
- **Metro Mod Loader** (or any compatible .vmz loader)

## Recommended
- **Mod Configuration Menu (MCM)** — for in-game settings

## Optional
- **RTV Mod Item Registry** — if installed, the Cat Bowl is registered cooperatively;
  if absent, the mod falls back to direct in-place Database injection (works fine
  in single-mod setups).
```

## TODO before publish

- [ ] Verify `mods/CatAutoFeed/build.py` builds: `publish.bat CatAutoFeed --no-open`
- [ ] Bump version to 1.0.0 if features are stable
- [ ] **Test compatibility with Put Food Out** — install both, see what happens. Document
      the result (compatible / partial / hard conflict) in the ModWorkshop description.
- [ ] Capture screenshots: (a) Cat Food Bowl placed in shelter, (b) the bowl management
      UI panel open, (c) an "Cat ate from bowl" notification firing
- [ ] Update Main.gd to detect the registry and prefer it (`get_node_or_null("/root/ModItemRegistry")`)
      with fallback to current direct injection — only do this AFTER RTVModItemRegistry is
      published so users can install both
- [ ] Confirm NOTICES.txt is current with the cat bowl model attribution
- [ ] First publish via web form
- [ ] Write assigned mod id into `mods/CatAutoFeed/.publish`

## References

- User-facing docs: [README.md](README.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Asset attribution: [NOTICES.txt](NOTICES.txt)
- Source: [Main.gd](Main.gd), [BowlPickup.gd](BowlPickup.gd), [BowlContentsPanel.gd](BowlContentsPanel.gd)
- Closest competitor for comparison reading: https://modworkshop.net/mod/56098
