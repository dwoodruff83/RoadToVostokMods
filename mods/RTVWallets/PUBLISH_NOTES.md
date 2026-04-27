# RTV Wallets — publish notes

Internal workspace doc. Not bundled in the .vmz.

## Status

**Near-ready.** Trader Buy/Sell with cash is working — currently ironing out edge-case kinks before bumping to 1.0.0 and publishing. Headline feature is functional; the README's claims are accurate.

**Migrated to Metro v3.x registry (2026-04-26).** Database injection now goes through `Engine.get_meta("RTVModLib").register(SCENES, ...)` instead of the retired RTVModItemRegistry shim. Bumped to v0.3.0 for the migration.

## TL;DR pitch (when ready)

> Wallet & Cash, but as physical containers. Find a fat money case in a military crate instead of picking up 47 stacks of euros. Three tiers tied to loot rarity and trader unlocks.

**Direct competitor (heavy hitter):** [Wallet & Cash (#55951)](https://modworkshop.net/mod/55951) by domfrags — 6,026 DL, top-10 RTV mod. v2.9.1, mature, polished. Has a Signals API for mod devs, MCM support, reset-on-death toggle. **Trying to be a "better generalist" version is a losing fight.** Our angle has to be a different *aesthetic* — physical containers vs abstract balances — for a different player.

## Differentiator (when pitching)

- **Wallet IS a container item**, not a UI row in a Deal panel
- Three tiers with distinct 3D models, sizes, sale values
- Lootable, droppable, persists with cash through inventory ↔ world ↔ shelter
- Cash is a content of the wallet, not a separate inventory stack — fewer slots used

**Don't pitch as "better than Wallet & Cash."** Pitch as a different fantasy.

## ModWorkshop upload metadata (when ready)

| Field | Value |
|---|---|
| **Category** | `Fixes/Tweaks` (matches Wallet & Cash's choice) |
| **Tags** | `Quality of Life (#12)`, `Add-on (#13)`, `Lorefriendly (#3)` |
| **Dependencies** | **Metro Mod Loader (#55623) v3.0.0+ required** (uses Metro's `[registry]` API); MCM (#53713) recommended |
| **License** | MIT (mod code) + CC BY 4.0 attribution for three Sketchfab models — see NOTICES.txt |
| **Description source** | Use README.md content directly. |

## Incompatibility callout (include in description when published)

> **Incompatible with Wallet & Cash by domfrags.** Both mods rewire the trader Buy/Sell flow. Pick one or the other.

## Remaining TODO (publish blockers)

- [ ] Trader cash integration — wrap up edge-case fixes (working as of 2026-04-26; ironing kinks)
- [ ] Capture screenshots once trader work is fully settled: tiers in inventory, wallet at trader, money case in military crate
- [ ] Test side-by-side with Wallet & Cash (#55951) — document exact failure mode
- [ ] Bump to 1.0.0 + add 1.0.0 CHANGELOG entry
- [ ] First publish via ModWorkshop web form
- [ ] **Post-publish:** write assigned mod id into `mods/RTVWallets/.publish` AND add `[updates]\nmodworkshop=<id>` to `mod.txt`, then rebuild + re-upload so the shipped `.vmz` is update-aware
- [ ] Post-publish: comment on Wallet & Cash's mod page (friendly, link our mod, frame as "alternative aesthetic, not replacement")

## MCM settings reference (current)

Six user-visible: Enable Wallets (master), Notify On Transfer, Stash Report Hotkey (Keycode, default F9), Enable: Leather Wallet, Enable: Ammo Tin, Enable: Money Case. Plus the standard Logger category.

## References

- User-facing docs: [README.md](README.md)
- Asset attribution: [NOTICES.txt](NOTICES.txt)
- Workspace publish workflow: `publish.bat` at workspace root
