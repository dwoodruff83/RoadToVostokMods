# Road to Vostok Modding

## Mod Releases

This monorepo houses multiple mods, each with its own independent version. GitHub's "Latest" release flag is repo-singular — only one release can hold it at a time — so promoting any single mod to "Latest" implicitly demotes every other mod's most recent release. We leave the flag unset across the board and use this table instead. For the full release history (including pre-releases and retired mods), see [the Releases page](https://github.com/dwoodruff83/RoadToVostokMods/releases).

| Mod | Version | Release tag | ModWorkshop |
|-----|---------|-------------|-------------|
| **Cat Auto Feed** | `1.1.8` | [CatAutoFeed-v1.1.8](https://github.com/dwoodruff83/RoadToVostokMods/releases/tag/CatAutoFeed-v1.1.8) | [56407](https://modworkshop.net/mod/56407) |
| **RTV Mod Logger** | `1.0.2` | [RTVModLogger-v1.0.2](https://github.com/dwoodruff83/RoadToVostokMods/releases/tag/RTVModLogger-v1.0.2) | [56406](https://modworkshop.net/mod/56406) |
| **RTV Wallets** | `1.0.2` | [RTVWallets-v1.0.2](https://github.com/dwoodruff83/RoadToVostokMods/releases/tag/RTVWallets-v1.0.2) | [56408](https://modworkshop.net/mod/56408) |
| **RTV Hideout Lights** | `1.0.1` | [RTVHideoutLights-v1.0.1](https://github.com/dwoodruff83/RoadToVostokMods/releases/tag/RTVHideoutLights-v1.0.1) | [56519](https://modworkshop.net/mod/56519) |
| **Punisher Guarantee** | `0.1.0` | [PunisherGuarantee-v0.1.0](https://github.com/dwoodruff83/RoadToVostokMods/releases/tag/PunisherGuarantee-v0.1.0) | — (not yet published) |

## Game Info

| Property | Value |
|----------|-------|
| **Game** | Road to Vostok (Early Access) |
| **Engine** | Godot 4.6.1 |
| **Game Version** | 0.1.0.0 |
| **Renderer** | Forward Plus, D3D12 |
| **Physics** | 120 ticks/sec |
| **PCK Version** | 3 |
| **PCK Size** | ~5.4 GB |
| **PCK Flags** | 2 |
| **Install Path** | `C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\` |
| **Mod Folder** | `<install>\mods\` |
| **User Data** | `%APPDATA%\Road to Vostok\` |

## Game Architecture (from decompiled source)

### Core Autoloads (singletons loaded at startup)
- **Loader** (`res://Resources/Loader.tscn`) — Scene loading, save/load system
- **Database** (`res://Resources/Database.tscn`) — Item/weapon/recipe database
- **Simulation** (`res://Resources/Simulation.tscn`) — Game simulation tick

### Global Shader Variables (weather/season system)
| Variable | Type | Purpose |
|----------|------|---------|
| `Winter` | bool | Toggle winter mode |
| `Snow` | float | Snow intensity |
| `Rain` | float | Rain intensity |
| `Wind` | float | Wind strength |
| `Player` | vec3 | Player world position |
| `Indoor` | float | Indoor detection |
| `Viewmodel` | float | Viewmodel FOV |
| `Occlusion` | bool | Occlusion culling toggle |

### Global Groups (node categories)
`Furniture`, `Interactable`, `Item`, `AI`, `Player`, `Transition`, `Switch`, `Display`, `Blocker`, `Trader`, `Radio`, `Well`, `Cat`

AI point types: `AI_CP`, `AI_PP`, `AI_HP`, `AI_SP`, `AI_WP`, `AI_GP`, `AI_VP`, `AI_BTR`

### All Game Scripts (176 files, 30,153 lines)

#### Major Systems (by size)
| Script | Lines | Purpose |
|--------|-------|---------|
| Interface.gd | 3,554 | UI, inventory, menus |
| AI.gd | 2,023 | Enemy AI behavior, combat, pathfinding |
| Settings.gd | 1,530 | Game settings/options |
| WeaponRig.gd | 1,299 | Weapon handling, attachments, firing, recoil |
| Loader.gd | 1,146 | Scene loading, save/load |
| World.gd | 753 | World state, weather, day/night cycle |
| Controller.gd | 738 | Player movement, input handling |
| Spawner.gd | 691 | Item/loot spawning system |
| BTR.gd | 643 | Armored vehicle (BTR) behavior |
| Item.gd | 578 | Item behavior, stacking, grid placement |
| Character.gd | 517 | Player character, health, stats |
| Border.gd | 465 | Border zone mechanics |
| RigManager.gd | 445 | Weapon rig management |
| Furniture.gd | 442 | Shelter furniture system |
| Database.gd | 420 | Item/recipe database |
| TreeRenderer.gd | 405 | Tree LOD/rendering |
| Inspect.gd | 393 | Item inspection view |
| Police.gd | 367 | Police/law enforcement AI |
| BorderPoles.gd | 353 | Border pole mechanics |

#### Combat & Weapons
| Script | Purpose |
|--------|---------|
| WeaponData.gd | Weapon stats/properties |
| WeaponRig.gd | Weapon handling, attachments |
| Recoil.gd | Recoil patterns |
| Handling.gd | Weapon sway, handling |
| Hit.gd | Hit detection/registration |
| Hitbox.gd | Hitbox components |
| Damage.gd | Damage calculation |
| MuzzleFlash.gd | Muzzle flash effects |
| Grenade.gd | Grenade behavior |
| GrenadeData.gd | Grenade stats |
| GrenadeRig.gd | Grenade handling |
| KnifeData.gd | Melee weapon stats |
| KnifeHandling.gd | Melee combat |
| KnifeRig.gd | Melee weapon rig |
| Explosion.gd | Explosion effects/damage |
| Mine.gd | Landmine behavior |

#### AI & NPCs
| Script | Purpose |
|--------|---------|
| AI.gd | Core AI behavior |
| AIPoint.gd | AI navigation points |
| AISpawner.gd | AI spawn system |
| AIWeaponData.gd | AI weapon configuration |
| Hider.gd | AI hiding behavior |
| Police.gd | Police faction AI |
| BTR.gd | Armored vehicle AI |
| Follow.gd | AI follow behavior |
| Waypoints.gd | AI waypoint navigation |

#### Player & Movement
| Script | Purpose |
|--------|---------|
| Character.gd | Player character core |
| Controller.gd | Movement/input |
| Camera.gd | Camera system |
| CameraNoise.gd | Camera shake/noise |
| Lean.gd | Lean mechanics |
| Tilt.gd | Camera tilt |
| Sway.gd | Weapon/camera sway |
| NVG.gd | Night vision goggles |
| Flashlight.gd | Flashlight |
| Headlamp.gd | Headlamp |
| Laser.gd | Laser sight |
| Optic.gd | Optic/scope system |
| PIP.gd | Picture-in-picture scopes |

#### World & Environment
| Script | Purpose |
|--------|---------|
| World.gd | World state management |
| Area.gd | Area/zone definitions |
| EventSystem.gd | World events (crashes, airdrops) |
| Event.gd | Individual event logic |
| EventData.gd | Event configuration |
| Events.gd | Event collection |
| Helicopter.gd | Helicopter flyovers |
| Jet.gd | Fighter jet flyovers |
| CASA.gd | CASA aircraft |
| MissileSpawner.gd | Missile/rocket events |
| RocketGrad.gd | Grad rocket system |
| RocketHelicopter.gd | Helicopter rockets |
| DynamicAmbient.gd | Dynamic ambient audio |
| Water.gd | Water system |
| Fire.gd | Fire effects |
| Light.gd | Dynamic lighting |
| Flicker.gd | Light flicker effects |

#### Items & Inventory
| Script | Purpose |
|--------|---------|
| Item.gd | Item behavior |
| ItemData.gd | Item properties |
| ItemSave.gd | Item serialization |
| Grid.gd | Inventory grid system |
| Slot.gd | Inventory slot |
| SlotData.gd | Slot data |
| Sorter.gd | Inventory sorting |
| Pickup.gd | Item pickup |
| LootContainer.gd | Loot containers |
| LootTable.gd | Loot tables/drop rates |
| LootSimulation.gd | Loot simulation |
| AttachmentData.gd | Weapon attachment data |
| InstrumentData.gd | Tool/instrument data |
| Instrument.gd | Tool behavior |

#### Shelter & Crafting
| Script | Purpose |
|--------|---------|
| Furniture.gd | Furniture placement/behavior |
| FurnitureData.gd | Furniture properties |
| FurnitureSave.gd | Furniture serialization |
| DecorMode.gd | Decoration placement mode |
| Placer.gd | Object placement system |
| Recipe.gd | Crafting recipe logic |
| RecipeData.gd | Recipe definitions |
| Recipes.gd | Recipe collection |
| Fuel.gd | Fuel system |
| Bed.gd | Bed/sleeping |

#### Cats & Fishing
| Script | Purpose |
|--------|---------|
| Cat.gd | Cat companion behavior |
| CatBox.gd | Cat carrier |
| CatData.gd | Cat stats/properties |
| CatFeeder.gd | Cat feeding |
| CatRescue.gd | Cat rescue events |
| CatVital.gd | Cat health |
| Fish.gd | Fish behavior |
| FishPool.gd | Fishing locations |
| FishingData.gd | Fishing stats |
| FishingRig.gd | Fishing rod mechanics |
| Lure.gd | Fishing lure |

#### Trading & Economy
| Script | Purpose |
|--------|---------|
| Trader.gd | Trader NPC |
| TraderData.gd | Trader inventory/prices |
| TraderDisplay.gd | Trader UI |
| TraderSave.gd | Trader state persistence |

#### UI & HUD
| Script | Purpose |
|--------|---------|
| Interface.gd | Main UI system |
| HUD.gd | In-game HUD |
| UIManager.gd | UI state management |
| UIPosition.gd | UI element positioning |
| Menu.gd | Main menu |
| Tooltip.gd | Item tooltips |
| Context.gd | Context menu |
| Info.gd | Info panels |
| Message.gd | Message system |
| ProgressBar.gd | Progress bar UI |

#### Save/Load & Data
| Script | Purpose |
|--------|---------|
| Loader.gd | Scene/save management |
| CharacterSave.gd | Character save data |
| ContainerSave.gd | Container save data |
| ShelterSave.gd | Shelter save data |
| WorldSave.gd | World state save |
| SwitchSave.gd | Switch state save |
| ItemSave.gd | Item save data |
| FurnitureSave.gd | Furniture save data |
| TraderSave.gd | Trader save data |

#### Audio
| Script | Purpose |
|--------|---------|
| Audio.gd | Audio management |
| AudioEvent.gd | Audio event system |
| AudioInstance2D.gd | 2D audio source |
| AudioInstance3D.gd | 3D positional audio |
| AudioLibrary.gd | Audio asset library |
| CasettePlayer.gd | Cassette tape player |
| CasetteData.gd | Cassette data |
| Radio.gd | Radio system |
| Television.gd | Television |

#### Other Systems
| Script | Purpose |
|--------|---------|
| GameData.gd | Global game state resource |
| Preferences.gd | Player preferences |
| Simulation.gd | Game simulation |
| Compiler.gd | Resource compiler |
| Condition.gd | Condition/status effects |
| Vital.gd | Vital signs/health system |
| Detector.gd | Anomaly/metal detector |
| Map.gd | In-game map |
| MapTool.gd | Map tool |
| Task.gd | Quest/task system |
| TaskData.gd | Quest data |
| Progress.gd | Progress tracking |
| Transition.gd | Scene transitions |
| Loading.gd | Loading screen |
| Intro.gd | Intro sequence |
| Death.gd | Death screen |
| Profiler.gd | Performance profiler |
| Optimizer.gd | Runtime optimization |
| Validator.gd | Data validation |
| Cache.gd | Resource caching |
| Noise.gd | Noise generation |
| Killbox.gd | Kill zone |
| Impulse.gd | Physics impulses |
| Ragdoll.gd | Ragdoll physics |
| Surface.gd | Surface material types |
| Track.gd | Track/trail system |
| TrackData.gd | Track data |
| Grabber.gd | Object grabbing |
| Interactor.gd | Interaction system |
| Door.gd | Door mechanics |
| Switch.gd | Switch/lever mechanics |
| Cables.gd | Cable rendering |
| Pole.gd | Utility poles |
| PoleSnapper.gd | Pole snapping |
| LineSpawner.gd | Power line spawning |
| Spinner.gd | Rotating objects |
| Turntable.gd | Turntable rotation |
| Riser.gd | Rising/lowering platforms |
| Field.gd | Field areas |
| ParticleInstance.gd | Particle effects |
| Effects.gd | Visual effects |
| Layouts.gd | Layout management |
| Mode.gd | Game mode |
| Actions.gd | Player actions |
| Inputs.gd | Input handling |
| SpineData.gd | Spine/skeletal data |
| SpawnerData.gd | Spawner configuration |
| SpawnerChunkData.gd | Chunk-based spawning |
| SpawnerSceneData.gd | Scene spawner data |

### Key Resource Paths
| Path | Purpose |
|------|---------|
| `res://Resources/GameData.tres` | Global game state (FOV, sensitivity, aiming, scoped, running, PIP) |
| `res://Resources/Preferences.tres` | Player preferences (saved to `user://Preferences.tres`) |
| `res://Resources/Loader.tscn` | Loader autoload scene |
| `res://Resources/Database.tscn` | Database autoload scene |
| `res://Resources/Simulation.tscn` | Simulation autoload scene |
| `res://Scripts/` | All game scripts (176 files) |
| `res://Editor/RTV_Icon.png` | Game icon |

### Input Actions
Movement: `forward`, `backward`, `left`, `right`, `sprint`, `jump`, `crouch`
Combat: `fire`, `aim`, `reload`, `firemode`, `inspect`, `ammo_check`
Weapons: `primary`, `secondary`, `knife`, `grenade_1`, `grenade_2`, `canted`, `secondary_optic`
Melee: `slash`, `stab`, `prepare_throw`, `throw`
Equipment: `flashlight`, `nvg`, `laser`, `headlamp` (via context)
UI: `interface`, `settings`, `escape`, `context`, `insert`
Interaction: `interact`, `item_rotate`, `item_drop`, `item_transfer`, `item_equip`
Other: `lean_L`, `lean_R`, `weapon_low`, `weapon_high`, `place`, `decor`, `ragdoll`, `rail_movement`, `aimlock`, `prepare`

## Mod Loaders

### Metro Mod Loader (Primary — what we develop and test against)
- **ModWorkshop:** https://modworkshop.net/mod/55623
- **Repo:** https://github.com/ametrocavich/vostok-mod-loader (published as "Metro Mod Loader" by `metro` / `ametrocavich`)
- **Currently installed locally:** v3.1.1 (April 2026). Mods built in this workspace require Metro v3.0+ (they use the `[registry]` opt-in and `Engine.get_meta("RTVModLib").register(...)` API introduced in 3.0).
- **How v3.1.1 installs:** `modloader.gd` lives at `res://modloader.gd` (bundled in the game install, e.g. `C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\modloader.gd`) and is wired in via `override.cfg`'s `[autoload_prepend] ModLoader="*res://modloader.gd"`. No Steam launch options needed. Mod `.vmz` files go in `<game>\mods\`.
- **Features:** pre-game launcher window with mod list and per-mod toggles; conflict detection (writes `modloader_conflicts.txt` to user data); built-in ModWorkshop integration for downloads/updates; `.vmz` mounting via `vmz_mount_cache/`.

### VostokMods (Alternative)
- **ModWorkshop:** https://modworkshop.net/mod/49779
- **Repo:** https://github.com/Ryhon0/VostokMods (by `Ryhon`)
- **Wiki:** has guides for decompilation, asset replacement, class overriding, autoloads, publishing — useful reference even if you use Metro
- Works by injecting `Injector.pck` via Steam launch options: `--main-pack Injector.pck`
- Mods packaged as `.VMZ` files (renamed ZIPs) — the same format Metro uses, so any of our mods will load under either loader.

### Mod Configuration Menu (MCM)
- By DoinkOink (v2.6.3)
- Provides in-game settings UI for mods with typed config values (bool, float, int, string, color, dropdown, keycode)
- ModWorkshop ID: 53713

## VMZ Mod Structure

A `.vmz` file is a renamed ZIP containing:

```
MyMod.vmz
├── mod.txt                    # Required: mod metadata & autoloads
├── mods/MyMod/Main.gd        # Entry point script (autoloaded)
├── mods/MyMod/OtherScript.gd  # Additional scripts
├── mods/MyMod/assets/         # Audio, textures, etc.
├── .godot/imported/           # Godot-imported assets (.ctex, .mp3str, etc.)
└── .godot/exported/           # Exported scenes (.scn)
```

### mod.txt Format

```ini
[mod]
name="My Mod Name"
id="my-mod-id"
version="1.0.0"
priority=-100              # Optional: lower = loads earlier (MCM uses -100)
replace_files=false        # Optional: whether to replace existing game files

[autoload]
MyModMain="res://mods/MyMod/Main.gd"    # Autoloaded scripts (run on game start)
MyModConfig="res://mods/MyMod/Config.gd" # Can have multiple autoloads

[updates]
modworkshop=12345          # Optional: ModWorkshop ID for auto-updates
```

## Modding Patterns (from installed mods)

### Pattern 1: Script Override (HeliGoBoom)
Override an existing game script with a new one that extends it:
```gdscript
# Main.gd - entry point, runs once then removes itself
extends Node
func _ready():
    var new_script = load('res://mods/MyMod/my_override.gd')
    new_script.take_over_path("res://Scripts/OriginalScript.gd")
    queue_free()

# my_override.gd - extends the original, overrides specific functions
extends "res://Scripts/OriginalScript.gd"
func SomeFunction():
    # Your custom logic here
```

### Pattern 2: MCM Config Integration (ZoomOverhaulMod)
Register configurable settings with the Mod Configuration Menu:
```gdscript
var McmHelpers = preload("res://ModConfigurationMenu/Scripts/Doink Oink/MCM_Helpers.tres")
const MOD_ID = "MyMod"
const FILE_PATH = "user://MCM/MyMod"

func _ready():
    var _config = ConfigFile.new()
    _config.set_value("Float", "MySetting", {
        "name" = "My Setting",
        "tooltip" = "Description here",
        "default" = 1.0,
        "value" = 1.0,
        "minRange" = 0.0,
        "maxRange" = 10.0,
        "category" = "General"
    })
    # Save defaults if no config exists
    if !FileAccess.file_exists(FILE_PATH + "/config.ini"):
        DirAccess.make_dir_recursive_absolute(FILE_PATH)
        _config.save(FILE_PATH + "/config.ini")
    else:
        McmHelpers.CheckConfigurationHasUpdated(MOD_ID, _config, FILE_PATH + "/config.ini")
    McmHelpers.RegisterConfiguration(MOD_ID, "Display Name", FILE_PATH, "Description", {
        "config.ini": OnConfigUpdated
    })
```

### Pattern 3: Runtime Node Injection (ZoomOverhaulMod)
Watch for nodes being added and attach custom behavior:
```gdscript
func _ready():
    get_tree().node_added.connect(_on_node_added)

func _on_node_added(node):
    if node.name == "SomeNode":
        var custom = load("res://mods/MyMod/CustomBehavior.gd").new()
        node.add_child(custom)
```

### Pattern 4: Persistent Autoload + Debug Overlay (Faction Warfare)
Stay loaded, track game state, provide debug UI:
```gdscript
extends Node
func _ready():
    name = "MyModMain"
    _override_script("res://mods/MyMod/OverriddenScript.gd")
func _process(delta):
    # Runs every frame, can monitor game state
```

## Installed Mods (Reference)

| Mod | ID | Version | What it does |
|-----|----|---------|-------------|
| Mod Configuration Menu | doinkoink-mcm | 2.6.3 | In-game settings framework |
| Cat Food Shelter | CatFoodShelter | 0.1.6 | Compiled .gdc (not readable) |
| Heli go Boom | heli-go-boom | 1.0.0 | Adds crash sound to helicopter events |
| Red Smoke Airdrop | red-smoke-airdrop | 0.0.3 | Visual airdrop indicator |
| Zoom Overhaul | Zoom_Overhaul_Mod | 2.2.3 | Focus eye zoom with MCM config |
| Day & Night MCM | day&night_MCM | 0.0.2 | Day/night cycle settings |
| Faction Warfare | road-to-vostok-enemy-ai | 1.2.3 | Enhanced enemy AI + spawning |

## Prerequisites & External Tools

### At-a-glance checklist

| Tool | Required? | Status | Purpose |
|------|-----------|--------|---------|
| Python 3.11+ | required | installed (3.13.1) | runs version_tracker, save_backup, sync_logger |
| Git | required | installed | RTV_history snapshot repo + general workflow |
| Godot Editor 4.6.x | required | installed (4.6.2) | edit/build mods, run them from source |
| GDRE Tools | required | installed (v2.5.0-beta.5) | decompile RTV.pck into readable GDScript |
| Metro Mod Loader | required | installed (v3.1.1) | actually loads `.vmz` mods at game start |
| DepotDownloader | optional | installed | grab specific historical RTV builds from Steam (for backfilling old snapshots) |
| VS Code + GDScript extension | recommended | check IDE | syntax highlighting + autocomplete |
| `uv` (Astral) | optional | check `uv --version` | runs the local `godot-docs` MCP server; required only if you use AI assistants with MCP support |

### Python 3.11+

Required for all workspace utilities (`snapshot.bat`, `analyze_mods.bat`, `changelog.bat`, `tools/save_backup.py`, `tools/sync_logger.py`). Python 3.11+ specifically because the tracker scripts use `tomllib`.

- **Get it:** https://www.python.org/downloads/ — install the latest 3.13.x
- **Verify:** `python --version` should report 3.11 or newer
- **Note:** Make sure to check "Add python.exe to PATH" during the installer

### Git

Required by the version tracker (its history repo lives in git) and for general workflow.

- **Get it:** https://git-scm.com/download/win
- **Verify:** `git --version`
- Already installed and configured.

### Godot Editor 4.6.x

Must match the game's engine version exactly. The game ships with Godot 4.6.1; we have 4.6.2 installed which is binary-compatible for modding purposes.

- **Get it:** https://godotengine.org/download/archive (look for 4.6.x stable)
- **Installed at:** `F:\RoadToVostokMods\tools\Godot\Godot_v4.6.2-stable_win64.exe`
- **Console version** (useful for stdout when debugging GDScript): `Godot_v4.6.2-stable_win64_console.exe`
- **Usage:** Open the editor and import a mod's project (or the decompiled `RTV_decompiled/project.godot`) to edit/run from source.

### GDRE Tools

Godot Reverse Engineering Tools — decompiles `.pck` files back to readable GDScript.

- **Source:** https://github.com/bruvzg/gdsdecomp
- **Installed at:** `F:\RoadToVostokMods\tools\GDRE_tools\gdre_tools.exe`
- **GUI usage:** Launch `gdre_tools.exe`, point it at the game's PCK, choose "Recover Project."
- **CLI usage** (for re-decompiling after a game patch):
  ```bash
  # List files in PCK
  gdre_tools.exe --headless --list-files="C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\RTV.pck"

  # Recover scripts only (fast, ~30K lines of GDScript)
  gdre_tools.exe --headless --recover="C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\RTV.pck" --output="F:\RoadToVostokMods\reference\RTV_decompiled" --scripts-only

  # Full recovery (everything — large, ~5GB)
  gdre_tools.exe --headless --recover="...\RTV.pck" --output="output\dir"
  ```

### DepotDownloader

Steam tool for downloading specific app/depot builds — useful for **backfilling historical RTV versions** when we want to add older snapshots to the version tracker history.

- **Source:** https://github.com/SteamRE/DepotDownloader
- **Installed at:** `F:\RoadToVostokMods\tools\DepotDownloader\DepotDownloader.exe`
- **Auth:** Requires Steam credentials (or anonymous for free apps); RTV is paid so we'd use our own login.
- **Example usage** (download a specific build of RTV):
  ```bash
  DepotDownloader.exe -app 1963610 -depot 1963611 -manifest <manifest_id> -username <steam_user>
  ```
  Manifest IDs come from SteamDB or Steam's `appmanifest_*.acf` `buildid` field. Output goes to a `depots/` subfolder by default.
- **When to use:** Only if we want to snapshot a game version older than our most recent decompile. Day-to-day modding doesn't need it.

### Metro Mod Loader

The actual mod loader that runs at game launch. We have v3.1.1 installed.

- **ModWorkshop:** https://modworkshop.net/mod/55623
- **Source:** https://github.com/ametrocavich/vostok-mod-loader (published as "Metro Mod Loader")
- **Setup (v3.1.1):** install via the loader's bundled installer (or copy `modloader.gd` to `C:\Program Files (x86)\Steam\steamapps\common\Road to Vostok\modloader.gd` and drop `override.cfg` in the same directory with `[autoload_prepend] ModLoader="*res://modloader.gd"`). Mod `.vmz` files go into `<game>\mods\`. No Steam launch options needed.
- **Mods built in this workspace require Metro v3.0+.** They use the `[registry]` opt-in in `mod.txt` and call `Engine.get_meta("RTVModLib").register(SCENES, ...)` for cooperative item registration. Earlier loader versions don't expose that API.
- **Verifying which version is installed:** v3.x lives at `res://modloader.gd` (in the game install directory, ~500KB). The older v2.0.0 lived at `%APPDATA%\Road to Vostok\modloader.gd` (67,141 bytes) and is no longer compatible with mods built here.
- See the "Mod Loaders" section above for the VostokMods alternative.

### VS Code + Godot GDScript extension (recommended)

Not strictly required, but invaluable for editing GDScript.

- **Get VS Code:** https://code.visualstudio.com/
- **Extension:** search "godot-tools" in VS Code's extensions panel, or:
  https://marketplace.visualstudio.com/items?itemName=geequlim.godot-tools
- **Setup:** Open the editor settings in Godot → Editor Settings → Network → Language Server. Enable "Use Language Server" and note the port (default 6008). VS Code's extension connects to this for autocomplete/hover.

### MCP servers (optional, for AI assistants)

Two Model Context Protocol servers ship with the workspace, giving any MCP-aware AI assistant (Claude Code, Cursor, Cline, VS Code Copilot Chat, etc.) compiler-accurate knowledge of GDScript and the Godot 4.6 API. Both are registered in `.mcp.json` (Claude Code) and `.vscode/mcp.json` (VS Code MCP extensions); both files are committed and contain no secrets.

**One-time setup:**

1. Install [`uv`](https://docs.astral.sh/uv/) (Astral's Python runner). The local `godot-docs` server uses it to resolve its `mcp` dependency on first run.
2. Bootstrap the Godot 4.6 docs clone (~440 MB, gitignored):
   ```bash
   download_godot_docs.bat
   ```
3. Restart your AI assistant so it picks up the MCP config.

**`godotlens` — live LSP queries**

Third-party MCP ([godotlens-mcp](https://github.com/pzalutski-pixel/godotlens-mcp), MIT) that bridges Godot's built-in language server. Gives `find-definition`, `find-references`, `symbols`, `rename`, etc. — compiler-accurate, no false positives from string/comment matches.

- **Best target:** open `reference/RTV_decompiled/project.godot` in Godot Editor so vanilla game code is queryable.
- **Requires:** Godot Editor running with a project open and the LSP enabled (Editor Settings → Network → Language Server, port 6005, "Enable Smart Resolve" on).
- **Limitation:** the LSP indexes only files inside the loaded project. Mod folders without a `project.godot` resolve single-file lookups but not cross-file `references` — grep stays the right tool there.

**`godot-docs` — Godot 4.6 reference**

Workspace-local server (`tools/godot_docs_mcp/server.py`, FastMCP, ~150 lines) exposing three tools:

- `godot_search(query, limit=10)` — full-text search across class references and tutorials.
- `godot_class(name)` — fetch a class reference page (e.g. `ResourceLoader`, `HTTPRequest`) as raw RST.
- `godot_method(class_name, method_name)` — extract a single method's section from a class reference.

Reads from a local shallow clone of [godotengine/godot-docs](https://github.com/godotengine/godot-docs) at the `4.6` branch (`reference/godot_docs/`, gitignored). Pinned to 4.6 so docs match the game's engine version — no drift to 4.7 when "stable" advances. Refresh with `download_godot_docs.bat --refresh`, or pin a different version with `download_godot_docs.bat --branch X.Y`.

See [`tools/godot_docs_mcp/README.md`](tools/godot_docs_mcp/README.md) for the server's full reference.

### Workspace utilities (already in `tools/`)

These are local helper scripts, not external tools:

- **`tools/save_backup.py`** — backs up `%APPDATA%\Road to Vostok\` save files to `save_backups/`. Subcommands: `backup`, `list`, `restore`, `delete`.
- **`tools/sync_logger.py`** — syncs `shared/Logger.gd` (canonical) into each mod's `Logger.gd`, preserving the mod's identity values. Run before building if you've updated the shared logger.
- **`tools/modworkshop.py`** (`modworkshop.bat`) — read-only client for the public ModWorkshop API. Browse, search, and inspect mods on https://modworkshop.net without leaving the terminal. See "ModWorkshop Browse & Publish" below.
- **`tools/publish.py`** (`publish.bat`) — one-shot mod publish workflow: bumps the version in `mod.txt`, runs the mod's `build.py` to zip a `.vmz` and install it to the game folder, then opens the browser at the right ModWorkshop page so the file can be uploaded by hand. See "ModWorkshop Browse & Publish" below.
- **`tools/godot_docs_mcp/`** (`download_godot_docs.bat`) — local MCP server exposing the Godot 4.6 docs as queryable tools for AI assistants. See "MCP servers" above and `tools/godot_docs_mcp/README.md` for setup.

## Community Resources

- **VostokMods Wiki** — https://github.com/Ryhon0/VostokMods/wiki — best general modding reference even though we use Metro to load
- **Metro Mod Loader on ModWorkshop** — https://modworkshop.net/mod/55623 (the loader we use)
- **VostokMods on ModWorkshop** — https://modworkshop.net/mod/49779 (alternative loader)
- **Godot Modding Wiki** — https://wiki.godotmodding.com (general Godot modding, covers GML framework)

## Version Tracking & Mod Impact Analysis

The `rtv-mod-impact-tracker` tool keeps a git history of decompiled scripts and tells us which of our mods will break on each game patch. It lives in its own repo at `F:\rtv-mod-impact-tracker\` and is driven from this workspace via `mod_tracker.toml` and the `snapshot.bat` / `analyze_mods.bat` wrappers.

For the tool's own documentation (install, full CLI reference, contribution notes) see the tracker's own repo — it's a separate clone at `F:\rtv-mod-impact-tracker\` on this workspace and is not bundled here. Public link TBD if/when that repo is opened.

### How it works

1. **`snapshot.bat`** copies `reference/RTV_decompiled/` into `reference/RTV_history/` (a git repo), commits it, and tags it `game-v<version>-build<buildid>`. Excludes `mods/`, `.godot/`, and `gdre_export.log`.
2. **`analyze_mods.bat`** walks `mods/`, parses each mod's `take_over_path()` calls (string-literal *and* `const`-referenced paths) plus `mod.txt` autoloads, then diffs the overridden files between two snapshot tags and classifies each mod:
   - 🟢 **safe** — mod's overrides aren't touched by the patch
   - 🟡 **review** — overridden file changed in body only (signatures stable, override likely still works)
   - 🔴 **broken** — overridden file deleted, or function signatures / `class_name` / `extends` declarations changed
3. **`changelog.bat`** walks consecutive snapshot tags and emits a Markdown changelog of game-side changes: added/deleted/renamed files plus per-modified-`.gd`-file breakdowns of added/removed functions and signature changes.
4. **`fetch_version.bat`** downloads a specific historical Steam build via DepotDownloader, decompiles it with GDRE_Tools, and snapshots it — all in one shot. Manifest registry lives at `manifests.json` (workspace root). Subcommands: `list`, `add`, `bootstrap`, `fetch`, `backfill`.

The git repo *is* the diff engine — VS Code's built-in git diff browser works directly against `reference/RTV_history/`.

### Per-patch workflow

When a new game version drops:

```bash
# 1. Refresh decompile (currently manual via GDRE; auto-CLI wiring deferred).
#    See "GDRE Tools Usage" section below for commands.
#    Refresh F:\RoadToVostokMods\reference\RTV_decompiled\ from the new RTV.pck.

# 2. Capture a new snapshot (auto-detects version + Steam buildid)
snapshot.bat

# 3. See what changed and what it broke
analyze_mods.bat --from game-v0.1.0.0-build22674175 --to HEAD --output diff_reports/v0.1.0.0_to_next.html

# 4. (Optional) Generate a Markdown changelog of game-side changes
changelog.bat --output diff_reports/CHANGELOG.md
```

### Useful commands

```bash
# List all snapshots
analyze_mods.bat --list-tags

# Compare any two refs (no --from defaults to "second-most-recent tag → most-recent")
analyze_mods.bat --from <tagA> --to <tagB>

# Dry-run a snapshot to preview what would happen
snapshot.bat --dry-run

# Override version detection (e.g. when re-snapshotting an older decompile)
snapshot.bat --label 0.1.0.0 --build 22674175

# Generate a changelog for everything since a given snapshot
changelog.bat --since game-v0.1.0.0-build22674175 --output CHANGELOG.md
```

### Configuration

`mod_tracker.toml` at the workspace root tells the tool where things are:

```toml
[paths]
decompiled = "reference/RTV_decompiled"
history    = "reference/RTV_history"
mods       = "mods"

[steam]
app_id = 1963610   # Road to Vostok full game

[snapshot]
exclude_toplevel = ["mods", ".godot", "gdre_export.log"]
```

The tool finds this file by walking up from the current working directory.

### Detection rules

- **Game version**: parsed from `RTV_decompiled/project.godot` (`config/version=...`)
- **Steam build id**: parsed from `C:\Program Files (x86)\Steam\steamapps\appmanifest_1963610.acf` (`buildid` field)
- **Mod overrides**: regex on `take_over_path("res://...")` literal calls + `take_over_path(IDENT)` where `IDENT` is a same-file `const IDENT := "res://..."`
- **Signature change**: function name + arg list (whitespace-normalized), plus `extends` and `class_name` lines

### Known gaps

- **GDRE auto-decompile** isn't wired into `snapshot.py` yet. The CLI commands are documented in the GDRE Tools Usage section below — wire them up when this becomes annoying.
- **Migration suggestions** for broken mods aren't generated automatically. The analyzer reports *what* changed, not *how* to adapt.

## ModWorkshop Browse & Publish

Two workspace tools for working with [ModWorkshop](https://modworkshop.net), the primary host for Road to Vostok mods.

### `modworkshop.bat` — browse the catalog

Read-only client for the public ModWorkshop API at https://api.modworkshop.net. Stdlib-only Python, no dependencies. Defaults all queries to the Road to Vostok game section (`game_id=864`).

```bash
# Find a game's id (only needed once for new games)
modworkshop.bat find-game vostok
# id   name            mods  short_name
# 864  Road to Vostok  329   roadtovostok

# Top RTV mods by downloads
modworkshop.bat top --limit 10

# Most recent uploads/updates
modworkshop.bat browse --sort latest --limit 20
modworkshop.bat browse --sort popular --limit 10
modworkshop.bat browse --sort likes   --limit 10

# Search by name
modworkshop.bat search "mod loader"

# Full info on a single mod (author, version, downloads, tags, repo URL...)
modworkshop.bat info 55623

# Version history (each .vmz upload, with size + downloads per file)
modworkshop.bat files 55623

# Target a different game (Payday 2 = 1, etc.)
modworkshop.bat --game 1 top --limit 5
```

### `publish.bat` — build, install, and open ModWorkshop

Drives a mod's existing `build.py` to produce a `.vmz`, copies it into the game's `mods/` folder, then opens the browser to the right ModWorkshop page so you can drop the `.vmz` into the upload form.

```bash
# Build and install only (skip browser)
publish.bat CatAutoFeed --no-open

# Bump version, build, install, and open the upload/edit page
publish.bat CatAutoFeed --version 0.4.0

# Build and open browser, but don't install to the game
publish.bat CatAutoFeed --no-install

# Preview what would be done
publish.bat CatAutoFeed --version 0.4.0 --dry-run
```

**Per-mod ModWorkshop id (`.publish` file).** After publishing a mod for the first time, write its ModWorkshop id into `mods/<ModName>/.publish` as a single integer line:

```
56123
```

Subsequent `publish.bat <ModName>` runs will then open `https://modworkshop.net/mod/56123/edit` directly. If the file is absent, the generic `https://modworkshop.net/upload` page is opened instead.

### Why the upload step is still manual

ModWorkshop's API spec at https://api.modworkshop.net documents `POST /games/{game_id}/mods` (create) and `POST /mods/{mod_id}/files` (upload), but the docs explicitly state:

> At the moment, the API only supports GET requests. More support will come in the future, but will require the use of API keys.

So `publish.bat` does everything up to and including "browser open on the correct page with the freshly-built `.vmz` ready to drag in." The final click is yours. When the API gains write support and starts issuing keys, `publish.py` is the right place to wire it up.

## GDRE Tools Usage

```bash
# List files in PCK
gdre_tools.exe --headless --list-files="path/to/RTV.pck"

# Full recovery (scripts only)
gdre_tools.exe --headless --recover="path/to/RTV.pck" --output="output/dir" --scripts-only

# Full recovery (everything - large!)
gdre_tools.exe --headless --recover="path/to/RTV.pck" --output="output/dir"

# Create PCK from directory
gdre_tools.exe --headless --pck-create="dir" --pck-version=3 --pck-engine-version=4.6.1
```

## Next Steps

1. Install Godot Editor 4.6.x
2. Browse decompiled scripts to understand game systems
3. Pick a mod idea and start building
4. Package as .vmz and test in-game

## Project Structure

```
F:\RoadToVostokMods\                   # this workspace
├── README.md                          # This file
├── CLAUDE.md                          # Quick reference for Claude
├── mod_tracker.toml                   # Config consumed by rtv-mod-impact-tracker
├── manifests.json                     # Steam manifest registry (consumed by fetch_version)
├── snapshot.bat / analyze_mods.bat / changelog.bat / fetch_version.bat
│                                      # Wrappers -> F:\rtv-mod-impact-tracker\*.py (game-tracking)
├── deps_fetch.bat / deps_diff.bat / deps_audit.bat / deps_changelog.bat
│                                      # Wrappers -> F:\rtv-mod-impact-tracker\deps_*.py (Metro/MCM dep tracking)
├── publish.bat                        # Wrapper -> tools\publish.py (build + install + open ModWorkshop)
├── modworkshop.bat                    # Wrapper -> tools\modworkshop.py (browse the API)
├── scaffold.bat                       # Wrapper -> tools\scaffold_mod.py (scaffold a new mod)
├── shared/
│   ├── Logger.gd                      # Canonical Logger source (synced into each mod)
│   ├── ADDING_ITEMS.md                # Modder guide for adding items to the Database
│   └── README.md                      # Index of shared/ contents
├── tools/
│   ├── publish.py                     # Mod publish workflow (build/install/open)
│   ├── scaffold_mod.py                # Generate a new mod folder from templates
│   ├── modworkshop.py                 # ModWorkshop API client (read-only)
│   ├── save_backup.py                 # Backup/restore RTV save files
│   ├── sync_logger.py                 # Sync shared/Logger.gd into each mod
│   ├── GDRE_tools/                    # Godot RE Tools v2.5.0-beta.5 (decompiler)
│   ├── Godot/                         # Godot Editor 4.6.2
│   └── DepotDownloader/               # Steam depot tool (historical builds)
├── reference/                         # gitignored
│   ├── RTV_decompiled/                # Working copy of decompiled game source
│   ├── RTV_history/                   # Git repo: one commit per game version
│   ├── MetroModLoader_source/         # Local mirror clone of Metro upstream
│   └── MCM_source/                    # Local mirror clone of MCM upstream
├── mods/                              # Our mod projects
│   ├── CatAutoFeed/                   # Auto-feeds the cat from a placeable bowl
│   ├── PunisherGuarantee/             # Removes RNG gates on the Punisher boss event
│   ├── RTVModLogger/                  # Demo + reusable logging library (Logger.gd + LOGGER.md)
│   └── RTVWallets/                    # Lootable wallet items that hold cash
├── docs/
│   └── archive/                       # Historical workspace docs (design plans, retired mods incl. RTVModItemRegistry)
└── diff_reports/                      # gitignored — HTML output from analyze_mods.bat

F:\rtv-mod-impact-tracker\             # standalone tool repo (separate)
├── README.md                          # Tool documentation
├── LICENSE                            # MIT
├── snapshot.py                        # Capture decompile, tag the commit
├── analyze_mods.py                    # Diff two tags, classify mod impact (HTML w/ inline diffs)
├── changelog.py                       # Markdown changelog across snapshot tags
├── fetch_version.py                   # Pull historical Steam builds, decompile, snapshot
└── examples/
    └── road-to-vostok.toml            # Template config
```
