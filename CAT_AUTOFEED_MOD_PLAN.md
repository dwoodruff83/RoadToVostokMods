# Cat Auto-Feed Mod Plan

## Goal
Automatically feed the cat from anywhere on the map, consuming food from shelter storage — not just when physically present in the shelter interacting with the CatFeeder node.

## Problem with Vanilla
- `CatFeeder.gd` requires player to be in the shelter, interact with the feeder node, and have food in **personal inventory**
- Cat hunger drains continuously via `Character.gd`: `gameData.cat -= delta / 40.0` (~67 min real-time to empty)
- If `gameData.cat <= 0`, cat dies permanently (`catDead = true`)
- Existing CatFoodShelter mod only works while `gameData.shelter == true` (player inside shelter)

## How Vanilla Feeding Works
```
CatFeeder.gd:
  feedItems: Array[ItemData] = []   # Set in scene inspector (editor), not code
  TryFeeding():
    for child in interface.inventoryGrid.get_children():
      if child.slotData.itemData in feedItems:
        gameData.cat = 100.0        # Full restore
        interface.inventoryGrid.Pick(child)  # Remove from inventory
        child.queue_free()
```
- `feedItems` array is populated in the Godot editor — we can't see the exact items, but based on the tooltip display and game context, these are consumable food items (Canned Meatballs, Canned Meat, Canned Pea Soup, etc.)

## Key Game Systems

### Cat State (`GameData.gd`)
- `cat: float` — 0 to 100, hunger level
- `catFound: bool` — whether player has rescued the cat
- `catDead: bool` — permanent death flag

### Cat Drain (`Character.gd` line ~140)
```gdscript
func Cat(delta):
    if gameData.catFound && !gameData.catDead:
        gameData.cat -= delta / 40.0    # ~2.5 per 100 seconds
        if gameData.cat <= 0:
            gameData.catDead = true
```

### Shelter Save Format (`ShelterSave.gd`)
- `items: Array[ItemSave]` — placed items in shelter
- Each `ItemSave` has: `name: String`, `slotData: SlotData`, `position: Vector3`, `rotation: Vector3`
- `SlotData.itemData` references the `ItemData` resource

### Save Persistence
- Cat state saved in `Character.tres` (cat, catFound, catDead fields)
- Shelter items saved in `{ShelterName}.tres` (e.g., Attic.tres, Cabin.tres)
- Both use `ResourceSaver.save()` to `user://` path

## Mod Design

### Architecture: Persistent Autoload
The mod will be an autoloaded script that:
1. Runs every frame (or on a timer) regardless of location
2. Monitors `gameData.cat` level
3. When below a threshold, loads the shelter save file, finds food items, consumes one, re-saves
4. Sets `gameData.cat = 100.0`

### Approach A: Direct Save File Manipulation (Recommended)
```
_process(delta):
  if !gameData.catFound or gameData.catDead: return
  if gameData.cat > feedThreshold: return  # e.g., threshold = 50.0

  # Find food in shelter saves
  for shelterName in ["Cabin", "Attic", "Classroom", "Tent", "Bunker"]:
    var path = "user://" + shelterName + ".tres"
    if !FileAccess.file_exists(path): continue
    var shelter = load(path) as ShelterSave
    for itemSave in shelter.items:
      if is_cat_food(itemSave.slotData.itemData):
        shelter.items.erase(itemSave)
        ResourceSaver.save(shelter, path)
        gameData.cat = 100.0
        # Show message
        return
```

**Pros:** Works from anywhere, no scene dependency
**Cons:** Modifying save files at runtime could conflict with shelter load/save if player is in that shelter. Need to skip the current shelter if player is in it (use `gameData.shelter` flag).

### Approach B: Inventory + Save Hybrid
- If player is in shelter: use vanilla CatFeeder approach (scan inventoryGrid)
- If player is in the field: scan shelter save files for food

### Food Item Identification
Since `feedItems` is set in the editor and we can't extract it:
- **Option 1:** Match by item name strings: "Canned Meatballs", "Canned Meat", "Canned Pea Soup", etc.
- **Option 2:** Match by ItemData resource path: `res://Items/Consumables/Canned_*/`
- **Option 3:** Match by `itemData.subtype` if consumables share a subtype value
- **Option 4:** Hardcode known resource paths from Database.gd

Best bet is Option 1 or 2 — name matching or path matching from `itemData.file` field.

### MCM Integration
Register with Mod Configuration Menu for user settings:
- **Enable/Disable** auto-feed
- **Feed threshold** (0-100, default 50) — cat level below which auto-feed triggers
- **Feed source** — which shelters to draw food from
- **Feed cooldown** — minimum seconds between auto-feeds (prevent rapid consumption)
- **Notification** — show/hide "Cat Fed" message

### File Structure
```
mods/CatAutoFeed/
  mod.txt           # Mod metadata + autoload declaration
  Main.gd           # Autoload entry point
  CatAutoFeed.gd    # Core auto-feed logic
  config.gd         # MCM configuration (if MCM present)
  Settings.gd       # Settings resource script
  Settings.tres     # Default settings
```

### mod.txt
```ini
[mod]
name="Cat Auto Feed"
id="CatAutoFeed"
version="1.0.0"

[autoload]
CatAutoFeed="res://mods/CatAutoFeed/Main.gd"
CatAutoFeedConfig="res://mods/CatAutoFeed/config.gd"
```

## Edge Cases to Handle
1. **Player in shelter** — don't modify that shelter's save file while loaded in scene; let vanilla CatFeeder handle it, or scan the live inventoryGrid instead
2. **No food anywhere** — graceful fallback, maybe warn player ("Cat is hungry, no food in shelters!")
3. **Frozen food** — items with `slotData.state == "Frozen"` should probably not count (or should they? design choice)
4. **Save file locking** — Godot's ResourceSaver may not have file locking issues, but test concurrent access
5. **Cat already dead** — skip everything if `catDead == true`
6. **Multiple feeds per frame** — use cooldown timer to prevent draining all food instantly

## Testing Plan
1. Place food in shelter, leave shelter, verify cat gets fed when threshold is reached
2. Verify food is actually removed from shelter save
3. Re-enter shelter, confirm the food item is gone from its surface
4. Test with cat at various hunger levels
5. Test with no food available
6. Test MCM settings changes mid-game
7. Test save/load cycle with mod active

## Prerequisites
- [ ] Install Godot Editor 4.6.x (match game version)
- [ ] Install VS Code GDScript extension
- [ ] Build VMZ packaging script
- [ ] Test basic autoload mod (hello world) before implementing full logic
