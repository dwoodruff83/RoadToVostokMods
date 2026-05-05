# Changelog

All notable changes to the RTV Hideout Lights mod are documented here. Dates are
YYYY-MM-DD.

## 1.0.1 — 2026-05-02

- **Fix: registration silently fails on Metro Mod Loader v3.0.0.**
  The mod's `[registry]` section in `mod.txt` was a bare header with no
  body. Godot's `ConfigFile` parser drops empty sections, so on Metro
  v3.0.0 (which lacks the workaround that v3.0.1 added) the section was
  dropped and `_any_mod_declared_registry` stayed false. The Database.gd
  rewriter never fired, `_rtv_mod_scenes` was missing on the Database
  autoload, and all 9 SCENES registrations returned false with the
  warning "Metro rejected SCENES for ...". Downstream effects: items
  weren't in `Database`, the Generalist trader had nothing to stock, and
  placement didn't work. Fix is one line: added `opt_in = true` under
  `[registry]` so the section parses on every Metro version.
- No code changes; no save format changes; existing saves carry forward.
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
