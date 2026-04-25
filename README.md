# Road to Vostok Modding

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

### VostokMods (Primary)
- **Repo:** https://github.com/Ryhon0/VostokMods
- **Wiki:** Has guides for decompilation, asset replacement, class overriding, autoloads, publishing
- Works by injecting `Injector.pck` via Steam launch options: `--main-pack Injector.pck`
- Mods packaged as `.VMZ` files (renamed ZIPs) in a `mods` folder

### vostok-mod-loader (Alternative)
- **Repo:** https://github.com/ametrocavich/vostok-mod-loader
- Launcher UI with load-priority system
- Two-pass loading (restart-required mods prefixed with `!`)
- Crash recovery (auto-resets after 2 consecutive crashes)
- Compatible with VostokMods `.VMZ` format

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

## Prerequisites & Tools

### Installed
- [x] **GDRE Tools v2.5.0-beta.5** — `F:\RoadToVostokMods\tools\GDRE_tools\gdre_tools.exe`
- [x] **Git** — Already installed
- [x] **VostokMods loader** — Already installed
- [x] **Decompiled game source** — `F:\RoadToVostokMods\reference\RTV_decompiled\` (176 scripts)

### Still Needed
- [ ] **Godot Editor 4.6.x** — Must match game version. Download from https://godotengine.org/download
- [ ] **VS Code + Godot GDScript extension** — For editing GDScript with syntax highlighting/autocomplete

## Community Resources

- **VostokMods Wiki** — Primary modding documentation (on GitHub)
- **ModWorkshop** — https://modworkshop.net/mod/49779
- **Godot Modding Wiki** — https://wiki.godotmodding.com (general Godot modding, covers GML framework)

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
F:\RoadToVostokMods\
├── README.md                          # This file
├── tools/
│   └── GDRE_tools/                    # Godot RE Tools v2.5.0-beta.5
│       ├── gdre_tools.exe
│       ├── gdre_tools.pck
│       └── GodotMonoDecompNativeAOT.dll
├── reference/
│   └── RTV_decompiled/                # Decompiled game source
│       ├── project.godot              # Game project file
│       ├── gdre_export.log            # Decompilation log
│       └── Scripts/                   # 176 GDScript files (30,153 lines)
├── mods/                              # Our mod projects (empty, ready to go)
└── notes/                             # Learning notes, ideas
```
