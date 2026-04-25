# Cat Auto Feed

Automatically feeds your cat from its shelter's food stash when hunger drops
below the configured threshold, regardless of where you are on the map. No more
returning to base every 40 minutes to drop a can of tuna in the feeder.

## Installation

1. Drop `CatAutoFeed.vmz` into the game's `mods/` folder:
   `...\steamapps\common\Road to Vostok\mods\`
2. Ensure a compatible mod loader is installed (VostokMods / vostok-mod-loader).
3. **Recommended:** also install Mod Configuration Menu (MCM) — the mod runs
   without it, but settings can only be tweaked in-game when MCM is present.
4. Launch the game. The mod auto-detects which shelter your cat lives in
   (by the CatBox item) on the first check.

## Features

- **Auto-feed from anywhere** — when cat hunger drops below the threshold and
  you are outside the cat's shelter, one food item is consumed from the
  shelter save and the cat is fed to 100%.
- **Hunger warning** — orange on-screen message when the cat drops below the
  threshold, shown once per hunger cycle. Lets you feed manually if preferred.
- **Manual feeding preserved** — when you are inside the cat's shelter, the
  mod defers to the vanilla CatFeeder; no save-file edits while the scene is
  live.
- **Shelter-agnostic** — works with Cabin, Attic, Classroom, Tent, or Bunker.
  Move the CatBox to a different shelter and the mod follows it on the next
  check. Food must be in the same shelter as the CatBox.
- **Eats what the vanilla feeder eats** — Cat Food, Canned Meat, Canned Tuna,
  and Perch. Priority: loose/placed items first, then container storage.

## Configuration (MCM)

| Setting | Default | Description |
|---|---|---|
| Enable Auto-Feed | On | Master toggle for the mod |
| Feed Threshold | 25 | Cat hunger % below which the mod acts (25 matches when the stat turns red in the HUD) |
| Show Fed Notification | On | Green "Cat Auto-Fed: ..." message |
| Show Hunger Warning | On | Orange "Cat is hungry (X%)" message |

## Compatibility

- **Incompatible with** other cat-feeding mods (e.g. *Cat Food Shelter*). Remove
  them before installing to avoid double-feeding.
- **MCM is optional** — the mod runs with sensible defaults if MCM is absent.
  It is only required for in-game configuration.

## How it works

On every 5-second tick during active gameplay, the mod:

1. Checks cat state (rescued, not dead, hunger below threshold).
2. Finds the cat's shelter by scanning all 5 shelter save files
   (`user://*.tres`) for an item named "Cat" (the CatBox). Result is cached.
3. If you are in that shelter, shows the warning (if enabled) and stops — the
   vanilla feeder takes over.
4. Otherwise, loads the shelter save, consumes one food item from the CatBox's
   shelter (loose items first, then containers), sets cat hunger to 100, and
   patches `Character.tres` directly so the value survives the next
   `LoadCharacter()` call.

## Credits

Built with the VostokMods framework and the Mod Configuration Menu by
DoinkOink.

### 3D Models

- **"Cat bowl"** by Justyna.sliwinska — [source](https://skfb.ly/otWXJ) —
  licensed under
  [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/). Model imported
  into Godot as a `.tres` resource; no geometry or texture edits.

See [NOTICES.txt](NOTICES.txt) for the verbatim attributions.

## Source & Issues

Built in the [RoadToVostokMods workspace](https://github.com/dwoodruff83/RoadToVostokMods).
