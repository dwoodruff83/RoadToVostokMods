# RTV Wallets

> Lootable, tradeable wallets that hold cash like a magazine holds rounds.

Find a wallet on a bandit, keep your euros in it, spend at traders. Die with it and it's lost — cash doesn't persist through death, only what's in the wallet on your body. Three tiers scale with risk and loot location.

---

## ⚠ Incompatibility

**Incompatible with [Wallet & Cash](https://modworkshop.net/mod/55951) by domfrags.** Both mods rewire the trader Buy/Sell flow. Pick one or the other — running both will fight over the same overrides and break the trade UI.

This mod is a **different aesthetic**, not a replacement: cash and wallets are *physical inventory items* you can see, drop, and lose, rather than abstract balances on a Deal panel. If you prefer the abstract version, Wallet & Cash is the right pick.

---

## Tiers

| Tier | Capacity | Rarity | Where it spawns |
|---|---|---|---|
| **Leather Wallet** | 1,000 € | Common | Civilian / industrial loot — sold by Doctor |
| **Ammo Tin** | 5,000 € | Rare | Industrial / military loot — sold by Gunsmith |
| **Money Case** | 10,000 € | Legendary | Military crates only — not sold by any trader |

## Features

- **Wallet-as-magazine model.** Each wallet instance has its own cash balance, shown as an ammo-style count on the inventory icon. Drag a Cash stack onto a wallet to load it (instant, no slow Progress animation), right-click → unload to empty it back into stacks.
- **Trader integration.** A "Sell for €" button appears on the Deal panel whenever you've selected items to offer with nothing requested in return — converts the offer into Cash stacks in your inventory. Behaves like vanilla barter: sold items vacate their cells first, payment fills the freed slots, any overflow drops at your feet.
- **Lootable cash.** Cash itself spawns in containers as 1×1 stacks (1–500 €). Wallets and ammo tins spawn as physical pickups in their respective loot zones.
- **Persists with cash.** Wallets are regular inventory items — they drop on death, can be stashed in your shelter, given to other containers. The cash stays inside through every transition.

## Requirements

- **[Metro Mod Loader](https://modworkshop.net/mod/55623) v3.0.0 or later** — required. Uses Metro's `[registry]` API to add wallet items to the game's database without `take_over_path` collisions.
- **[Mod Configuration Menu (MCM)](https://modworkshop.net/mod/53713)** — optional. Only used to rebind the Stash Report hotkey (default F9, prints every wallet you're carrying + balance to the log/overlay).

## Compatibility

- ✅ **Coexists with other registry-using mods** (e.g. CatAutoFeed, etc.). No Database.gd takeover.
- ❌ **Wallet & Cash** by domfrags — see incompatibility callout above.
- ⚠ **Uninstalling strips wallets from saves.** Save files reference wallet items via `res://mods/RTVWallets/<Tier>.tres`. Removing the `.vmz` causes the game to silently drop wallets (and any cash they hold) on next load. To migrate cleanly, withdraw cash from all wallets and drop the empty wallets before uninstalling.

## Credits

### 3D Models

All Sketchfab models are [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/). See `NOTICES.txt` in the .vmz for verbatim attributions.

- **"Wallet"** by apleesee — [source](https://skfb.ly/6UX8z)
- **"Ammo Case"** by Replexx — [source](https://skfb.ly/oL6sP)
- **"Case with money | Low poly"** by tasha.kosaykina — [source](https://skfb.ly/6SJ7u)
- **"Euro Banknote Stack Tied With Rubber"** by Dakta.Grower.Nzl — [source](https://skfb.ly/pCpXp)

### Tooling

In-game configuration via [Mod Configuration Menu](https://modworkshop.net/mod/53713) by DoinkOink. Mod-loader infrastructure by Metro.

## License

[MIT](https://opensource.org/license/mit) for the mod code. Third-party 3D models retain their own CC BY 4.0 license — see `NOTICES.txt` bundled in the `.vmz`.
