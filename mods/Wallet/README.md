# Wallet

Adds lootable, tradeable wallets that hold cash like a magazine holds rounds.
Find one on a bandit, keep your rubles in it, spend at traders. Die with it and
it is lost — cash doesn't persist through death, only what's in the wallet on
your body.

Three tiers scale with risk and loot location:

| Tier | Capacity | Rarity | Where it spawns |
|------|----------|--------|-----------------|
| Wallet | 5,000 ₽ | Common | Civilian loot, bandits, Grandma |
| Ammo Tin | 25,000 ₽ | Rare | Industrial / military, Gunsmith |
| Money Case | 150,000 ₽ | Legendary | Military crates, end-game events |

## Installation

1. Drop `Wallet.vmz` into the game's `mods/` folder:
   `...\steamapps\common\Road to Vostok\mods\`
2. Ensure a compatible mod loader is installed (VostokMods / vostok-mod-loader).
3. **Recommended:** also install Mod Configuration Menu (MCM). The mod runs
   without it, but tier toggles can only be tweaked in-game when MCM is present.
4. Launch the game.

## Features

- **Wallet-as-magazine model** — each wallet instance has its own cash balance,
  shown as an ammo-style count on the inventory icon. No separate currency
  inventory; the wallet *is* the currency.
- **Three tiers** — different capacities, loot-spawn flags, and trader stocking
  rules so progression feels earned.
- **Trader Buy/Sell with cash** — at a trader, the active wallet on your body
  is used for payment; cash is transferred in and out without physical notes.
  *(In development — see Status.)*
- **Lootable & losable** — wallets are regular inventory items. They drop on
  death with the rest of your gear. Someone else can pick yours up.
- **Per-tier MCM toggles** — disable any tier you don't want registered.

## Status

Early scaffold. Working:

- Tier registry with three configured wallet types.
- Per-tier `ItemData` builder at runtime.
- MCM configuration scaffolding.

In progress (stubbed with TODOs in `Main.gd`):

- Injecting wallet `ItemData` into the game's Database so loot spawners and
  traders see them.
- Hooking Trader UI to surface Buy/Sell-with-cash using the equipped wallet.
- Wiring the `.glb` meshes and inventory icons into packaged `.tscn` scenes.

## Configuration (MCM)

| Setting | Default | Description |
|---|---|---|
| Enable Wallet | On | Master toggle |
| Notify On Transfer | On | On-screen message when cash moves to/from a wallet |
| Enable: Wallet | On | Registers the common-tier Wallet |
| Enable: Ammo Tin | On | Registers the rare-tier Ammo Tin |
| Enable: Money Case | On | Registers the legendary-tier Money Case |

## Credits

Built with the VostokMods framework and the Mod Configuration Menu by
DoinkOink.

### 3D Models

- **"Wallet"** by apleesee — [source](https://skfb.ly/6UX8z) — licensed under
  [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).
- **"Ammo Case"** by Replexx — [source](https://skfb.ly/oL6sP) — licensed
  under [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).
- **"Case with money | Low poly"** by tasha.kosaykina —
  [source](https://skfb.ly/6SJ7u) — licensed under
  [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).

See [NOTICES.txt](NOTICES.txt) for the verbatim attributions.

## Source & Issues

Built in the [RoadToVostokMods workspace](https://github.com/dwoodruff83/RoadToVostokMods).
