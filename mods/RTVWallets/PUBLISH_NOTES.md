# RTV Wallets — publish notes

> Notes for whichever session/agent picks up the ModWorkshop publish work for this mod.
> Captures competitive analysis, positioning, and the metadata to put in the upload form.

## Status

**Recommended sequence:** publish FOURTH (last). Hardest competitive fight; benefits from
RTVModItemRegistry being established first since the registry resolves the kind of
"two trader-modifying mods clobber each other" problems users will worry about.

## TL;DR pitch

> Wallet & Cash, but as physical containers. Find a fat money case in a military crate
> instead of picking up 47 stacks of euros. Three tiers tied to loot rarity and trader
> unlocks.

## Competitor landscape

**Direct competitor — heavy hitter:**

| Mod | Author | DL | Approach |
|---|---|---|---|
| [Wallet & Cash (55951)](https://modworkshop.net/mod/55951) | domfrags | **6,026** (top-10 RTV mod) | v2.9.1, mature, polished. Has a Signals API for mod devs, MCM support, reset-on-death toggle. |

**Their model:**
- Cash as separate **1×1 stackable inventory items** with custom 3D model + icon
- "Wallet" is a UI row in the Deal panel showing balance, NOT a container item
- Trader Sell/Buy with cash; cash spawns in loot (1-200 per stack)
- Cash resets on death (configurable)
- **Backed by a Signals API** for other mod devs to hook into
- Repo: https://github.com/Dominicode-s/vostok-cash

**Read on the field:** Wallet & Cash owns the "cash economy" niche. Trying to be a better
generalist version is a losing fight. Our angle has to be a different *aesthetic* — physical
containers vs abstract balances — for a different player.

## Positioning

Don't pitch as "better than Wallet & Cash." Pitch as a different fantasy.

> "Cash, but as a physical container instead of stacks. Three tiers — pickpocket Wallet
> (1k€), industrial Ammo Tin (5k€), military Money Case (10k€) — each found in different
> loot tiers and sold by different traders. The wallet IS the currency: lose it on death
> and your cash is gone with it. No abstract balance, no euros cluttering your inventory.
> If you preferred Tarkov's wallets/document cases over abstract gold, this is for you."

**Where we differ (positioning, not strict 'wins'):**
- Wallet is a **physical container item** that holds cash like a magazine holds rounds
- **3 tiers** (1k / 5k / 10k) tied to loot rarity AND trader unlock progression
- Cash is *inside* the wallet — no separate cash items in inventory
- Death drops the wallet with whatever's in it (no "reset" toggle needed; physical model)
- More compact inventory footprint (one wallet vs N stacks of euros)
- More immersive/looter-aesthetic for survival-RP players

**Where Wallet & Cash wins:**
- 6,026 downloads of mindshare and trust
- Mature (v2.9.1) with bugfix history
- Signals API for ecosystem extension
- Compatible with XP & Skills System (their note)
- Heavy promotion / community presence

## Recommended ModWorkshop metadata

| Field | Value |
|---|---|
| **Category** | `Fixes/Tweaks` (matches Wallet & Cash's choice) |
| **Tags** | `Quality of Life (#12)`, `Add-on (#13)`, `Lorefriendly (#3)` |
| **Dependencies** | `Metro Mod Loader (#55623)` required; `MCM (#53713)` recommended; **soft dep on RTVModItemRegistry once published** |
| **Repo URL** | (set when public) |
| **License** | MIT (mod code) + CC BY 4.0 attribution for 3 third-party 3D models — see NOTICES.txt |

## Conflict callout (be explicit and friendly)

This is the most important paragraph in the listing. Users who want cash *will* try both
mods and we don't want angry comments.

> "**Incompatible with Wallet & Cash by domfrags.** Both mods rewire the trader Buy/Sell
> flow and only one can win. Pick the model that fits your taste:
> - **Wallet & Cash** — abstract balance, cash as separate stackable items, mature ecosystem
> - **This mod (RTV Wallets)** — physical container items, three rarity tiers, lose-on-death-as-loot
>
> Don't install both. If you want to switch, uninstall the other first to avoid trader UI
> double-injection."

## ModWorkshop description outline

```markdown
# RTV Wallets

> Lootable, tradeable wallets that hold cash like a magazine holds rounds.

Find a wallet on a bandit, keep your rubles in it, spend at traders. Die with it and it's
lost — cash doesn't persist through death, only what's in the wallet on your body.

## Three tiers

| Tier | Capacity | Rarity | Where it spawns |
|------|----------|--------|-----------------|
| Wallet | 1,000 € | Common | Civilian / industrial loot — sold by Doctor |
| Ammo Tin | 5,000 € | Rare | Industrial / military loot — sold by Gunsmith |
| Money Case | 10,000 € | Legendary | Military crates only — not sold by any trader |

## Features

- **Wallet-as-magazine model** — each wallet instance has its own cash balance, shown as
  an ammo-style count on the inventory icon. The wallet IS the currency.
- **Three tiers** with different capacities, loot-spawn flags, and trader stocking rules.
- **Trader Buy/Sell with cash** — at a trader, the active wallet on your body is used for
  payment.
- **Lootable & losable** — wallets are regular inventory items that drop on death.
- **Per-tier MCM toggles** — disable any tier you don't want registered.

## Configuration (MCM)

Five toggles: Enable Wallet (master), Notify On Transfer, Enable: Leather Wallet, Enable: Ammo Tin,
Enable: Money Case. Plus the standard Logger category.

## Compatibility

**Incompatible with [Wallet & Cash by domfrags](https://modworkshop.net/mod/55951).** Both
mods rewire trader Buy/Sell. Pick one:
- *Wallet & Cash* — abstract cash balance, separate stackable cash items, mature ecosystem
- *This mod* — physical container items, three rarity tiers, lose-on-death-with-the-wallet

If you want to switch, uninstall the other first.

**Compatible with** mods that don't touch trader Buy/Sell or the master loot table.

## Requires
- **Metro Mod Loader** (or any compatible .vmz loader)

## Recommended
- **Mod Configuration Menu (MCM)** — for the per-tier toggles

## Optional
- **RTV Mod Item Registry** — cooperative item registration when installed; otherwise the
  mod falls back to direct in-place Database injection.

## Credits

- 3D model: "Wallet" by apleesee — CC BY 4.0
- 3D model: "Ammo Case" by Replexx — CC BY 4.0
- 3D model: "Case with money | Low poly" by tasha.kosaykina — CC BY 4.0

See NOTICES.txt in the .vmz for verbatim attribution.
```

## TODO before publish

- [ ] Verify `mods/RTVWallets/build.py` builds: `publish.bat RTVWallets --no-open`
- [ ] Bump version to 1.0.0 if features are stable
- [ ] **Test side-by-side with Wallet & Cash** — install both, document exact failure mode
      so the description's incompatibility callout is accurate (currently educated guess)
- [ ] Capture screenshots: (a) all three wallet tiers in inventory, (b) wallet at a trader
      showing Buy/Sell, (c) all three 3D models on the ground or in containers
- [ ] Confirm NOTICES.txt is current with all three model attributions
- [ ] Update Main.gd to detect the registry and prefer it (`get_node_or_null("/root/ModItemRegistry")`)
      with fallback to current direct injection — only do this AFTER RTVModItemRegistry is
      published so users can install both
- [ ] First publish via web form
- [ ] **Post-publish:** write assigned mod id into `mods/RTVWallets/.publish` AND add
      `[updates]\nmodworkshop=<id>` to `mod.txt`, then rebuild + re-upload so the shipped
      `.vmz` is update-aware (see "Update flow" section below)
- [ ] Comment on Wallet & Cash's mod page (friendly, link our mod, frame as "alternative
      for the physical-container crowd" not as competition) — this is goodwill insurance

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

- User-facing docs: [README.md](README.md)
- Changelog: [CHANGELOG.md](CHANGELOG.md)
- Asset attribution: [NOTICES.txt](NOTICES.txt) — three CC BY 4.0 attributions required
- Source: [Main.gd](Main.gd), [WalletPickup.gd](WalletPickup.gd), [wallets.gd](wallets.gd)
- Direct competitor for comparison reading: https://modworkshop.net/mod/55951
- Their repo (worth a look for the Signals API pattern): https://github.com/Dominicode-s/vostok-cash
