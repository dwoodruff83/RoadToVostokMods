# RTV Wallets — publish notes

Internal workspace doc. Not bundled in the .vmz.

## Status

**Current state: v1.0.1 (live on ModWorkshop as id 56408).** Trader Sell-for-€ flow matches vanilla barter (drain → spill → overflow drops via our `Drop()` override). Cash drag-overlay shows €, drops are clean maxAmount chunks, materials dimmed so cash doesn't glow in dim lighting. MCM trimmed to working settings only. README and CHANGELOG match shipping behavior.

**Migrated to Metro v3.x registry (2026-04-26).** Database injection goes through `Engine.get_meta("RTVModLib").register(SCENES, ...)` instead of the retired RTVModItemRegistry shim.

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

## Remaining TODO

Done before 1.0.0:
- [x] Trader cash integration polished (Sell-for-€ button, drain-first, vanilla-barter parity)
- [x] Screenshots captured (overview, MCM, sell_for_cash, buy, loading, unloading)
- [x] Bump to 1.0.0 + 1.0.0 CHANGELOG entry

Manual / post-publish:
- [x] First publish via ModWorkshop web form (mod id 56408)
- [x] **Post-publish:** mod id `56408` written to `mods/RTVWallets/.publish`; `[updates] modworkshop=56408` added to `mod.txt`
- [ ] Test side-by-side with Wallet & Cash (#55951) — document exact failure mode
- [ ] Comment on Wallet & Cash's mod page (friendly, link our mod, frame as "alternative aesthetic, not replacement")

## MCM settings reference (current)

One user-visible setting: **Stash Report Hotkey** (Keycode, default F9). Plus the standard Logger category (Log Level / Log to File / Log to Overlay). Earlier non-functional toggles (master "Enable Wallets", "Notify On Transfer", per-tier enables) removed for 1.0.0 — they never gated runtime code.

## References

- User-facing docs: [README.md](README.md)
- Asset attribution: [NOTICES.txt](NOTICES.txt)
- Workspace publish workflow: `publish.bat` at workspace root
