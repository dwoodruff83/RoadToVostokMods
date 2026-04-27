# RTV Wallets

> Lootable, tradeable wallets that hold cash like a magazine holds rounds.

Find a wallet on a bandit, keep your rubles in it, spend at traders. Die with it and it is lost — cash doesn't persist through death, only what's in the wallet on your body. Three tiers scale with risk and loot location.

| Tier | Capacity | Rarity | Where it spawns |
|------|----------|--------|-----------------|
| Leather Wallet | 1,000 € | Common | Civilian / industrial loot — sold by Doctor |
| Ammo Tin | 5,000 € | Rare | Industrial / military loot — sold by Gunsmith |
| Money Case | 10,000 € | Legendary | Military crates only — not sold by any trader |

## Installation

1. Drop `RTVWallets.vmz` into the game's `mods/` folder:
   `...\steamapps\common\Road to Vostok\mods\`
2. **Required:** [Metro Mod Loader](https://modworkshop.net/mod/55623) v3.0.0 or later. The mod uses Metro's built-in registry API (`[registry]` opt-in in mod.txt) to add wallet items to the game's database — earlier loaders without the registry won't recognise them.
3. **Recommended:** also install [Mod Configuration Menu (MCM)](https://modworkshop.net/mod/53713) — needed to toggle individual tiers in-game.
4. Launch the game.

## Features

- **Wallet-as-magazine model** — each wallet instance has its own cash balance, shown as an ammo-style count on the inventory icon. The wallet *is* the currency.
- **Three tiers** with different capacities, loot-spawn flags, and trader stocking rules.
- **Trader Buy/Sell with cash** — at a trader, the active wallet on your body is used for payment.
- **Lootable & losable** — wallets are regular inventory items that drop on death.

## Configuration (MCM)

| Setting | Default | Description |
|---|---|---|
| Stash Report Hotkey | F9 | Press in-game to log every wallet you're carrying with its balance. Useful for a quick "what's my total cash" answer when split across tiers. |

Plus the standard Logger category (level, file output, overlay output). See [the RTV Mod Logger reference](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/RTVModLogger/LOGGER.md) for details.

## Compatibility

- **Metro Mod Loader v3.0.0+ required.** Wallet items are added via Metro's registry (`lib.register(SCENES, ...)`), so they coexist cleanly with any other mod also using the registry — no `take_over_path` collisions on Database.gd.
- **MCM is optional.** The mod runs with sensible defaults if MCM is absent — only used to rebind the Stash Report hotkey.
- **Conflicts with other "cash economy" mods** (e.g. *Wallet & Cash*). Pick one or the other; both replace the same Trader Buy/Sell flow.
- **Uninstalling drops wallets and cash.** Save files reference wallet items via `res://mods/RTVWallets/<Tier>.tres`. If you remove the .vmz, the game silently strips wallets (and any cash they hold) from saves on next load. To migrate, withdraw cash from all wallets and drop the empty wallets before uninstalling.

## Credits

Built for the Road to Vostok modding ecosystem. In-game configuration via the [Mod Configuration Menu](https://modworkshop.net/mod/53713) by DoinkOink.

### 3D Models

- **"Wallet"** by apleesee — [source](https://skfb.ly/6UX8z) — [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).
- **"Ammo Case"** by Replexx — [source](https://skfb.ly/oL6sP) — [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).
- **"Case with money | Low poly"** by tasha.kosaykina — [source](https://skfb.ly/6SJ7u) — [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).
- **"Euro Banknote Stack Tied With Rubber"** by Dakta.Grower.Nzl — [source](https://skfb.ly/pCpXp) — [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).

See [NOTICES.txt](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/RTVWallets/NOTICES.txt) for the verbatim attributions.

## License

[MIT](https://github.com/dwoodruff83/RoadToVostokMods/blob/main/mods/RTVWallets/LICENSE) (mod code only — third-party 3D models retain their own CC BY 4.0 license; see NOTICES.txt).

## Source & Issues

Built in the [RoadToVostokMods workspace](https://github.com/dwoodruff83/RoadToVostokMods).
