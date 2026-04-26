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

- [ ] Verify `mods/RTVModItemRegistry/build.py` builds cleanly: `publish.bat RTVModItemRegistry --no-open`
- [ ] Confirm `REGISTRY.md` exists and the integration guide is up to date
- [ ] Bump version to 1.0.0 if not already (signals "ready for adoption" to other authors)
- [ ] Test on a clean save: install registry alone, then install CatAutoFeed *configured to
      use the registry*, confirm CatAutoFeed's bowl still loots/places/persists
- [ ] First publish via web form (API write not yet enabled)
- [ ] After publish: write the assigned mod id into `mods/RTVModItemRegistry/.publish` so
      future `publish.bat` runs open the edit page
- [ ] Update CatAutoFeed and Wallet to declare the registry as a soft dependency in their
      ModWorkshop descriptions and (once supported) structured deps

## References

- Source: [Main.gd](Main.gd), [DatabaseInject.gd](DatabaseInject.gd)
- Integration guide: [REGISTRY.md](REGISTRY.md)
- User-facing docs: [README.md](README.md)
- Workspace publish workflow: see `publish.bat` in workspace root
