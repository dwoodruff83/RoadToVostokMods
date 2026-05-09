# Changelog

All notable changes to the RTV Hideout Lights mod are documented here. Dates are
YYYY-MM-DD.

## 1.2.0 — 2026-05-09

- **All toggleable fixtures now persist their on/off state across shelter reloads (#47).** Floor Lamp, Vintage Desktop PC, fluorescents, Computer_Lit, **Candle, and Kerosene Lantern** were previously always off after leaving and returning to a shelter, even if you'd lit them. Now their lit state survives between shelter visits, scoped per-fixture-instance so multiple lamps in the same shelter each remember their own state independently. Exit Sign is excluded — it's always-on decorative (matches real emergency-exit lighting) and never had a toggle to begin with.
  - Mechanism: a sidecar config file at `user://rtvlights_state.cfg` keyed by `shelter_<name>` section, `<file_id>_<x>_<y>_<z>` entry. Position rounded to 1cm.
  - **Phase 1** covered LightToggle-based fixtures (Lamp / PC / fluorescents / Computer / Sign).
  - **Phase 2** added Fire-based fixtures (Candle, Kerosene Lantern) via a small `FireStatePersist` observer node attached as a child of each Fire-rooted scene root. The observer polls the parent's `active` flag once per frame and mirrors transitions into the same sidecar. No `take_over_path` on vanilla `Fire.gd`, so vanilla world candles / lanterns / fire pits / barrels are unaffected and keep their existing ~2% spawn-lit behavior.
  - Switch-controlled fixtures (Cellar Wall Light, Industrial / Bright / Soft Fluorescent) already persisted via vanilla switch state in 1.1.0; they continue to do so. The new sidecar tracks them too as redundant insurance, no behavior change for the player.
  - **Placement always defaults to off**, matching 1.1.0 behavior. Picking up a fixture and replacing it (anywhere) resets to off; you re-toggle from there. Persistence kicks in for fixtures that stay put between shelter visits — the common case.
- No save format changes (the sidecar is additive, not part of any vanilla save); existing 1.1.0 saves carry forward. The sidecar is created on first toggle.

## 1.1.0 — 2026-05-04

Placement and switch-routing overhaul. No save format changes; existing saves carry forward.

- **Placement preview now works on every fixture.** Earlier versions left the lit lamp/screen visible inside the green hologram and skipped the hologram material on switch-controlled fixtures. The new lifecycle hides Light3D / emissive Bulb meshes during preview without mutating toggle state, and only commits the off-state after placement so the hologram renders cleanly.
- **Pickup resets to off; placement syncs to the room switch.** Picking up any fixture turns it off for the move (clean preview, predictable state). When you commit placement: switch-controlled fixtures (Cellar Wall Light, all Fluorescents) immediately match the nearest room switch's on/off state. Manual fixtures (Floor Lamp, PC, Candle, Lantern) stay off so the player turns them on with Use.
- **Smart room-aware switch routing.** Multi-switch shelters like the Cabin have one switch per room. Placed fixtures now subscribe to the switch whose existing static lights are nearest, NOT just whichever switch enumerates first. Re-placing a fixture in a different room drops the old subscription and joins the new one, so a fixture is only ever wired to one switch. The "nearest static light" heuristic can occasionally mis-assign on edge cases (a fixture placed in a doorway between two rooms, or two switches whose lights are nearly equidistant); pick up and re-place to nudge it.
- **Interaction collider now covers the full fixture height.** The box collider was centered at scene origin instead of the AABB center, which on tall fixtures like the Floor Lamp meant the upper half (lampshade) was outside the interaction volume. Aiming at the lampshade now triggers the Use prompt.
- **Hardened against catalog-pickup crash.** When a placed switch-controlled fixture was picked back up to the catalog, the switch's `targets` array kept the freed reference. The next switch toggle called `Deactivate()` on a dead object and crashed the game. LightToggle now removes itself from the switch on `_exit_tree`, and Activate/Deactivate use `is_instance_valid()` checks so stale node references no-op instead of crashing.

## 1.0.1 — 2026-05-02

- **Fix: registration silently fails on Metro Mod Loader v3.0.0.** The mod's `[registry]` section in `mod.txt` was a bare header with no body. Godot's `ConfigFile` parser drops empty sections, so on Metro v3.0.0 (which lacks the workaround that v3.0.1 added) the section was dropped and the registry opt-in was never seen. Database wasn't rewritten, all 9 SCENES registrations returned false with "Metro rejected SCENES for ...", items weren't in `Database`, and traders had nothing to stock. Fix: added `opt_in = true` under `[registry]` so the section parses on every Metro version.
- No code or save format changes; existing saves carry forward.
- Reported via ModWorkshop comments on mod 56519 (officialkuutti, bcav712).

## 1.0.0 — 2026-05-01

First public release. Nine placeable light fixtures, stocked by all three currently-revealed traders (Generalist, Gunsmith, Doctor):

- **Candle** (2x2 floor) and **Kerosene Lantern** (2x3 floor) — vanilla `Fire.gd` integration; ignite/extinguish via Use action.
- **Floor Lamp** (3x6 floor) — warm 50° spotlight inside a fabric shade, plus an emissive bulb sphere visible through the shade opening. Use to toggle. Includes an upward-pointing fill light so the dome interior reads as lit (vanilla shader doesn't light back-faces from inside).
- **Vintage Desktop PC** (4x4 floor) — soft cyan glow + animated lit-screen UI when on; matte dark screen when off. Use to toggle.
- **Exit Sign** (3x2 wall) — green-glow sconce, always on.
- **Cellar Wall Light** (2x3 wall) — warm bare bulb behind a metal cage. Wired to shelter switch.
- **Industrial Fluorescent** (2x2 ceiling) — square ceiling panel, neutral white. Wired to shelter switch.
- **Bright Fluorescent** (5x2 ceiling) and **Soft Fluorescent** (5x2 ceiling) — long fluorescent tubes; the soft variant has lower energy and skips volumetric fog (no visible god-ray cone). Both wired to shelter switch.

Switch integration: ceiling and Cellar fixtures auto-subscribe to any node in the `Switch` group within the placement scene tree, so they react to the shelter's existing wall switch (Cabin, Bunker, Classroom). Subscription appends to the switch's `targets` array — no conflict with vanilla lights.

Material swap on toggle: when off, the lampshade material switches from the emissive `_Lit` variant to the matte default — same pattern vanilla `Light.gd` uses, so the fixture body doesn't keep glowing while the Light3D is hidden.

Placement constraints: ceiling fixtures reject floor placement (surface normal check) so they don't clip into solid floors. Ray clusters are tightened on long fluorescents so they can mount across narrow rafter beams in either orientation.

Built on Metro Mod Loader v3.0.0+ (uses `[registry]` API). Ships zero new asset data — every mesh, texture, and material is loaded from the vanilla game install at runtime.
