# RTVModItemRegistry — publish notes

> Notes for whichever session/agent picks up the ModWorkshop publish work for this mod.
> Captures competitive analysis, positioning, and the metadata to put in the upload form.

## Status

**Recommended sequence:** publish FIRST among our four mods. Other mods (CatAutoFeed, Wallet)
should declare a soft dependency on this one once it's live, so it benefits from being up
before they go up.

## TL;DR pitch

> Lets multiple mods add new items to the vanilla `Database` without clobbering each other.
> If you've ever had two item-adding mods crash when loaded together, this is why.

## Competitor landscape

**There is no direct competitor.** No mod on ModWorkshop currently does Database/item
registry coordination for Road to Vostok. The closest analogues are framework-pattern
mods for *other* engine subsystems:

| Mod | Author | DL | What it covers |
|---|---|---|---|
| [Weapon Rig API (56146)](https://modworkshop.net/mod/56146) | ScriptExec | 102 | Extending `WeaponRig` |
| [Cassette Framework (56206)](https://modworkshop.net/mod/56206) | Ryujiro | 96 | Custom in-game music |
| [Camo Framework (56117)](https://modworkshop.net/mod/56117) | Your401kplan | 122 | Camo values on clothing |
| [SimpleHUD UI Framework (56307)](https://modworkshop.net/mod/56307) | Tewq | 170 | Customizable HUD |

**Strongest validation of the problem:** [ItemSpawner Compatibility Edition (55672)](https://modworkshop.net/mod/55672)
by metro (1,722 DL) is a rebuild of Ryhon's Item Spawner that *exists specifically to fix
crashes* caused by mods that add items not matching the vanilla schema. Our registry
prevents the upstream cause of those crashes. That's the elevator pitch to other framework
authors.

## Positioning

Lead with the problem, not the implementation:

> "If you've ever had two item-adding mods crash when loaded together — that's because both
> tried to override `Scripts/Database.gd` and the second one wins. This mod solves it once
> and exposes a `register()` API that consumer mods call instead."

Pitch directly to:
- Authors of existing item-adding mods (in DMs or mod comments) — invite them to integrate
- metro — whose ItemSpawner Compatibility Edition exists because of this exact problem
- New modders just starting on RTV — be the documented "right way" to add items

## Recommended ModWorkshop metadata

| Field | Value |
|---|---|
| **Category** | `Libraries (#?)` — sibling to Debug API, Weapon Rig API, Cassette Framework |
| **Tags** | `Add-on (#13)` |
| **Dependencies** | `Metro Mod Loader (#55623)` — required. **No** dep on MCM (we work without it). |
| **Repo URL** | (set when public) |
| **License** | MIT |

**Why so few tags:** "Library" / "Modding Tools" / "Framework" don't exist as tags on ModWorkshop;
`Add-on` is the closest fit for a coordination shim. Lean on the description text to convey
"this is a developer-facing library" — see the long-description outline below.

## ModWorkshop description outline

```markdown
# RTV Mod Item Registry

> Lets multiple mods add new items to the vanilla Database without clobbering each other.

**For mod developers**, not players directly. If you don't run any mod that depends on it,
this mod does nothing.

## The problem

Vanilla items in Road to Vostok are registered as `const` entries on `Database.gd` and
resolved via `Database.get(name)`. When a mod wants to add a new item, it has to call
`take_over_path("res://Scripts/Database.gd")` and `set_script(...)` on the live Database
autoload. **The last mod to load wins** — every earlier item-adding mod gets clobbered.

This is why mod packs that combine multiple item-adding mods often crash.

## The fix

This mod runs *before* consumer mods (`priority=-50`) and takes over the Database script
**once**. It then exposes a single API that consumer mods call cooperatively:

    var registry = get_node_or_null("/root/ModItemRegistry")
    if registry:
        registry.register("My_Item", preload("res://mods/MyMod/My_Item.tscn"))

## Compatibility

- Works with any mod that calls `register()` instead of doing its own injection.
- Conflicts with mods that still do their own `take_over_path` on `Database.gd`. Order
  determines who wins.
- Soft dependency: consumer mods can detect the registry's absence and fall back to
  legacy in-place injection for single-mod setups.

## Requires
- **Metro Mod Loader** (or any compatible .vmz loader)

## Optional
- **Mod Configuration Menu (MCM)** — for tweaking the registry's diagnostic logging
```

Link to `REGISTRY.md` (the integration guide) prominently.

## TODO before publish

- [x] Verify `mods/RTVModItemRegistry/build.py` builds cleanly — built at 10058 bytes
- [x] Confirm `REGISTRY.md` exists and the integration guide is up to date — updated for new API (overwrite/force, deferred queue, collision policy)
- [x] Bump version to 1.0.0 — done
- [x] Audit-driven hardening (from three pre-publish audit agents):
  - [x] Reject-by-default for collisions: `register(name, scene, overwrite=true)` to opt in
  - [x] Reject-by-default for vanilla const shadowing: `register(name, scene, false, force=true)` to opt in
  - [x] Deferred-register queue for consumer mods at priority < -50
  - [x] `registered_items()` typed as `Array[String]` matching docs
  - [x] DatabaseInject routes warns through registry's logger via `set_log_callback`
  - [x] Wallet checks register() return values + falls back on rejection
- [x] Test stub mods generated:
  - `mods/RegistryTest/` — auto-runs 6 safe API tests on game start (clean register, collision reject/accept, vanilla shadow reject, empty/null rejection); F8 re-runs
  - `mods/RegistryTest_Hostile/` — destructive sibling that fights the registry; install separately to verify behavior under attack
  - `mods/RegistryTest_Early/` — priority=-100 mod that calls register() before registry's _ready; verifies deferred queue
- [ ] **Test #1 (must-pass before 1.0.0 public)**: install RegistryTest alongside RTVModItemRegistry on a clean save. Expected: 6/6 PASS notification on game start, F8 re-runs cleanly.
- [ ] **Test #2 (must-pass before 1.0.0 public)**: install RegistryTest_Early alongside RTVModItemRegistry. Expected: green "Early item resolves post-flush: True" notification.
- [ ] **Test #3 (must-pass before 1.0.0 public)**: install RegistryTest_Hostile + RTVModItemRegistry + CatAutoFeed. Expected: hostile script clobbers /root/Database; observe whether CatAutoFeed's bowl still resolves and what console warnings fire. **Document the failure mode for the README** if the registry can't survive — this is the limitation to communicate to other modders.
- [ ] **Test #4 (must-pass before 1.0.0 public)**: save a game with a registered item in inventory; quit; restart; load the save. Expected: item still resolves via Database.get(). If not, document that registry items are session-scoped and consumer mods must re-register on every game start (which they already do via _ready).
- [ ] First publish via web form (API write not yet enabled)
- [ ] **Post-publish:** write assigned mod id into `mods/RTVModItemRegistry/.publish` AND
      add `[updates]\nmodworkshop=<id>` to `mod.txt`, then rebuild + re-upload so the
      shipped `.vmz` is update-aware (see "Update flow" section at the end of this file)
- [ ] After publish: update CatAutoFeed and Wallet ModWorkshop descriptions to declare the registry as a soft dependency
- [ ] After publish: send the outreach DMs below (post-publish so the URL works)

## Outreach DM drafts (post-publish)

Drafted by Haiku 4.5 on 2026-04-25. Edit lightly before sending — particularly insert the ModWorkshop URL once it's assigned.

### DM 1 — to `domfrags`

> Hey, I've been following your work on Wallet & Cash and XP & Skills — both are hitting real quality benchmarks on the workshop, and the download counts reflect that. I'm impressed.
>
> I've been wrestling with the same problem you probably have: when multiple mods add custom items to the game, they all end up calling take_over_path on Database.gd, and last-loader-wins means users see crashes or missing items when they try to run both. It's a friction point in the ecosystem.
>
> I've spent some time building a coordination library called RTVModItemRegistry — essentially a soft-dependency shim that sits at priority -50, takes over Database.gd once, and exposes a simple register() API. If your mods call into it instead of doing their own injection, they coexist without conflicts. And it's completely optional; single-mod setups keep working through a fallback path.
>
> I'm prepping it for ModWorkshop publication (URL forthcoming) and thought it'd be worth reaching out since your item-adding mods would benefit from it. No pressure on refactoring — just wanted you to know it exists and is available if you decide it's useful.
>
> Would be happy to walk you through the integration API if you want to check it out. Either way, respect for what you're building.

### DM 2 — to `metro`

> Hey. I've been watching ItemSpawner Compatibility Edition and recognizing the exact problem you built it to solve — mod-stacking breakage when multiple items mods run together. You clearly understand the ecosystem friction there.
>
> I've been building something complementary: RTVModItemRegistry, a coordination library that runs at priority -50 and acts as a single point of item registration. Instead of each item mod doing take_over_path(Database.gd), they call a register() method on a central node. Multiple mods coexist, conflicts vanish, and it's completely soft-dependent (legacy single-mod setups still work through fallback injection).
>
> The reason I'm reaching out: you've already invested thought into this problem space, and I'd value your technical feedback on whether this is the right shape for a solution, or whether there's an alignment opportunity if you think your approach and mine should converge. You might even see ways to leverage it in ItemSpawner Compat itself, though that's not the ask.
>
> I'm publishing to ModWorkshop soon (URL forthcoming). Would be interested in your take — whether it's "this solves something I've been thinking about too" or "you're missing X consideration," both are useful. And if you want to review the implementation or brainstorm next steps, I'm all in.

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

- Source: [Main.gd](Main.gd), [DatabaseInject.gd](DatabaseInject.gd)
- Integration guide: [REGISTRY.md](REGISTRY.md)
- User-facing docs: [README.md](README.md)
- Workspace publish workflow: see `publish.bat` in workspace root
