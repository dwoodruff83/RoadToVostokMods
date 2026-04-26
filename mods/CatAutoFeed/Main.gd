extends Node

var gameData = preload("res://Resources/GameData.tres")

const SHELTERS := ["Cabin", "Attic", "Classroom", "Tent", "Bunker"]
const DEFAULT_FOOD := [
    "Cat_Food",
    "Canned_Meat",
    "Canned_Tuna",
    "Perch",
]
const CATBOX_ITEM_NAME := "Cat"
const CHECK_INTERVAL := 5.0
const STARTUP_DELAY := 10.0

var _check_timer := STARTUP_DELAY
var _cached_cat_shelter := ""
var _hunger_warned := false
var _bowl_empty_warned := false
var _was_in_menu := true
var _log_node: Node = null

func _ready() -> void:
    name = "CatAutoFeed"
    _log_node = _resolve_log_node()
    print("[CatAutoFeed] Main._ready, log_node=", _log_node)
    _inject_database()
    _inject_loot_table()
    _log("info", "CatAutoFeed loaded, threshold=%d, check every %ds" % [int(_threshold()), int(CHECK_INTERVAL)])

func _inject_loot_table() -> void:
    # Add Cat_Bowl to LT_Master.items so it spawns naturally in civilian loot
    # containers. LT_Master is preloaded by LootContainer/LootSimulation/Trader,
    # but Resources are shared instances in Godot — mutating .items here is
    # visible to all three subsystems for the rest of the session.
    if !_loot_enabled():
        _log("debug", "Loot integration disabled via config")
        return

    var lt_master = load("res://Loot/LT_Master.tres")
    if lt_master == null or lt_master.get("items") == null:
        _log("warn", "LT_Master.tres failed to load; bowl will not spawn in loot")
        return

    var bowl_data = load("res://mods/CatAutoFeed/Cat_Bowl.tres")
    if bowl_data == null:
        _log("warn", "Cat_Bowl.tres failed to load; cannot inject into loot table")
        return

    # Idempotent — match by file string in case the resource instance differs
    # across loads.
    for existing in lt_master.items:
        if existing != null and String(existing.file) == String(bowl_data.file):
            _log("debug", "Cat_Bowl already in LT_Master, skipping inject")
            return
    lt_master.items.append(bowl_data)
    _log("info", "Injected Cat_Bowl into LT_Master (rarity=%d, %d items total)" % [int(bowl_data.rarity), lt_master.items.size()])

func _inject_database() -> void:
    # Prefer RTVModItemRegistry's coordinated registration if installed —
    # this lets CatAutoFeed coexist with other mods that add new items
    # (e.g. Wallet). Fall back to legacy direct injection in single-mod
    # setups so the bowl still works without the registry.
    # get_node_or_null sometimes misses cross-mod autoloads even when they
    # ARE in the tree (autoload-from-another-mod timing); fall back to
    # find_child the same way we look up /root/Database below.
    var registry = get_node_or_null("/root/ModItemRegistry")
    if registry == null:
        registry = get_tree().root.find_child("ModItemRegistry", true, false)
    if registry and registry.has_method("register"):
        var bowl_scene = preload("res://mods/CatAutoFeed/Cat_Bowl.tscn")
        var ok: bool = registry.register("Cat_Bowl", bowl_scene)
        if ok:
            _log("info", "Cat_Bowl registered with ModItemRegistry")
        else:
            _log("warn", "ModItemRegistry rejected Cat_Bowl registration; falling back to legacy")
            _inject_database_legacy()
        return

    _log("warn", "RTVModItemRegistry not installed — using legacy in-place injection (incompatible with sibling Database-extending mods)")
    _inject_database_legacy()


# Legacy direct take_over_path / set_script injection. Kept for users who
# install only this mod (no registry). Will fight other mods doing the same;
# install RTVModItemRegistry to coordinate.
func _inject_database_legacy() -> void:
    var inject = load("res://mods/CatAutoFeed/DatabaseInject.gd")
    if inject == null:
        _log("error", "Could not load DatabaseInject.gd")
        return
    inject.reload()
    inject.take_over_path("res://Scripts/Database.gd")

    var db = get_node_or_null("/root/Database")
    if db == null:
        db = get_tree().root.find_child("Database", true, false)
    if db:
        db.set_script(inject)
        var test = db.get("Cat_Bowl")
        _log("info", "Database script replaced (legacy), Cat_Bowl resolves to: %s" % str(test))
    else:
        _log("warn", "Database autoload not found; injection may be incomplete")

func _resolve_log_node() -> Node:
    var node = get_node_or_null("/root/CatAutoFeedLog")
    if node:
        return node
    node = get_tree().root.find_child("CatAutoFeedLog", true, false)
    return node

func _log(lvl: String, msg: String) -> void:
    if _log_node == null:
        _log_node = _resolve_log_node()
    if _log_node:
        _log_node.call(lvl, msg)
    else:
        print("[CatAutoFeed] [", lvl.to_upper(), "] ", msg)

func _process(delta: float) -> void:
    if gameData.menu:
        _was_in_menu = true
        return
    if _was_in_menu:
        _was_in_menu = false
        _check_timer = STARTUP_DELAY
    _check_timer -= delta
    if _check_timer > 0.0:
        return
    _check_timer = CHECK_INTERVAL
    _try_auto_feed()

func _try_auto_feed() -> void:
    if !_enabled():
        _log("debug", "Tick: mod disabled")
        return
    if gameData.menu or gameData.settings:
        _log("debug", "Tick: in menu/settings, skip")
        return
    if gameData.transition:
        # Avoid racing Loader.SaveShelter / LoadCharacter writes on .tres files
        # while a scene transition is mid-flight.
        _log("debug", "Tick: scene transitioning, skip")
        return
    if gameData.isDead:
        _log("debug", "Tick: player dead, skip")
        return
    if !gameData.catFound:
        _log("debug", "Tick: cat not rescued yet")
        return
    if gameData.catDead:
        _log("debug", "Tick: cat is dead")
        return

    var current_map := _current_map_name()
    _log("debug", "Tick: cat=%d/%d map=%s cat_shelter=%s warned=%s" % [
        int(gameData.cat),
        int(_threshold()),
        current_map if current_map != "" else "?",
        _cached_cat_shelter if _cached_cat_shelter != "" else "?",
        str(_hunger_warned)
    ])

    if gameData.cat > _threshold():
        _hunger_warned = false
        return

    if current_map == "":
        _log("debug", "Scene not ready (no /root/Map), skip")
        return

    var shelter_name := _find_cat_shelter()
    if shelter_name == "":
        _log("warn", "Cat shelter unknown: no CatBox found in any shelter save")
        return

    if !_hunger_warned:
        _hunger_warned = true
        _log("info", "Cat hunger below threshold (%d%% < %d%%)" % [int(gameData.cat), int(_threshold())])
        if _show_warning():
            Loader.Message("Cat is hungry (%d%%)" % int(gameData.cat), Color.ORANGE)

    if current_map == shelter_name:
        _log("debug", "In cat's shelter (%s), deferring to vanilla feeder" % shelter_name)
        return

    var path := "user://" + shelter_name + ".tres"
    if !FileAccess.file_exists(path):
        _log("warn", "Shelter save missing: %s" % path)
        return
    # CACHE_MODE_REPLACE forces a fresh disk read AND updates Godot's resource
    # cache with the new instance — so when Loader.LoadShelter (the next time
    # the player visits) loads the same path, it gets our just-mutated version
    # instead of a stale cached resource.
    var shelter = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE) as ShelterSave
    if shelter == null:
        _log("error", "Failed to load shelter save: %s" % path)
        return

    _log("debug", "Scanning %s for cat food (player in %s)" % [shelter_name, current_map])
    _feed_from_shelter(shelter, path, shelter_name)

func _current_map_name() -> String:
    var scene = get_tree().current_scene
    if scene == null:
        return ""
    var map_node = scene.get_node_or_null("/root/Map")
    if map_node == null:
        return ""
    var m = map_node.get("mapName")
    return String(m) if m != null else ""

func _find_cat_shelter() -> String:
    if _cached_cat_shelter != "" and _shelter_has_catbox(_cached_cat_shelter):
        return _cached_cat_shelter
    _cached_cat_shelter = ""
    for shelter_name in SHELTERS:
        if _shelter_has_catbox(shelter_name):
            _cached_cat_shelter = shelter_name
            _log("info", "Cat shelter detected: %s" % shelter_name)
            return shelter_name
    return ""

func _shelter_has_catbox(shelter_name: String) -> bool:
    var path := "user://" + shelter_name + ".tres"
    if !FileAccess.file_exists(path):
        return false
    var shelter = load(path) as ShelterSave
    if shelter == null:
        return false
    return _has_catbox(shelter)

func _has_catbox(shelter: ShelterSave) -> bool:
    for itemSave in shelter.items:
        if itemSave != null and itemSave.name == CATBOX_ITEM_NAME:
            return true
    return false

func _feed_from_shelter(shelter: ShelterSave, path: String, shelter_name: String) -> bool:
    var foods := _food_names()
    var fallback := _shelter_fallback()

    # PASS 1: items' nested storage (e.g., Cat Bowl). Highest priority so the
    # cat eats from a deliberately-filled bowl before any raw food lying around.
    # Returns the source itemSave on success so we can announce the bowl by name.
    for itemSave in shelter.items:
        if itemSave == null or itemSave.slotData == null:
            continue
        var inner = itemSave.slotData.storage
        if inner == null or inner.size() == 0:
            continue
        for j in range(inner.size()):
            var sd: SlotData = inner[j]
            if sd == null or sd.itemData == null:
                continue
            if sd.itemData.file in foods:
                var bowl_name: String = String(itemSave.slotData.itemData.name) if itemSave.slotData.itemData else "container"
                var food_name: String = String(sd.itemData.name)
                sd.amount = int(sd.amount) - 1
                if sd.amount <= 0:
                    inner.remove_at(j)
                _sync_item_amount(itemSave.slotData)
                # Detect "this was the last bite in the bowl" to give the
                # player a heads-up that they need to refill it.
                var bowl_now_empty := _slot_storage_total(itemSave.slotData) == 0
                if !_save_shelter(shelter, path):
                    return false
                _on_fed_from_bowl(food_name, bowl_name, bowl_now_empty)
                return true

    # If shelter fallback is disabled (default), stop here — bowl is the
    # only food source, and we just confirmed it's empty. Throttle the on-screen
    # message via _bowl_empty_warned so we don't spam every 5s tick; reset by
    # _on_fed_from_bowl when the player refills.
    if !fallback:
        _log("info", "Cat hungry but bowl is empty (shelter fallback disabled)")
        if _notify() and !_bowl_empty_warned:
            _bowl_empty_warned = true
            Loader.Message("Cat hungry — fill the bowl in " + shelter_name, Color.ORANGE)
        return false

    # PASS 2: top-level shelter items (raw food sitting on the floor).
    for i in range(shelter.items.size()):
        var itemSave: ItemSave = shelter.items[i]
        if itemSave == null or itemSave.slotData == null or itemSave.slotData.itemData == null:
            continue
        if itemSave.slotData.itemData.file in foods:
            var label: String = String(itemSave.slotData.itemData.name) + " (" + shelter_name + " floor)"
            shelter.items.remove_at(i)
            if !_save_shelter(shelter, path):
                return false
            _on_fed(label)
            return true

    # PASS 3: furniture storage (food in cabinets / fridges).
    for furnitureSave in shelter.furnitures:
        if furnitureSave == null or furnitureSave.storage == null:
            continue
        for i in range(furnitureSave.storage.size()):
            var sd: SlotData = furnitureSave.storage[i]
            if sd == null or sd.itemData == null:
                continue
            if sd.itemData.file in foods:
                var containerName: String = String(furnitureSave.itemData.name) if furnitureSave.itemData else "storage"
                var label: String = String(sd.itemData.name) + " (" + shelter_name + " / " + containerName + ")"
                furnitureSave.storage.remove_at(i)
                if !_save_shelter(shelter, path):
                    return false
                _on_fed(label)
                return true

    _log("warn", "No food available in %s" % shelter_name)
    if _notify():
        Loader.Message("Cat still hungry — no food in " + shelter_name, Color.ORANGE)
    return false

func _slot_storage_total(slot_data: SlotData) -> int:
    if slot_data == null or slot_data.storage == null:
        return 0
    var total := 0
    for sd in slot_data.storage:
        if sd != null:
            total += int(sd.amount)
    return total

# Items that use slotData.storage as the source of truth for "how much is
# inside" (Cat Bowl) need slotData.amount kept in sync so the inventory badge
# stays accurate when the bowl is later picked up.
func _sync_item_amount(slot_data: SlotData) -> void:
    if slot_data == null or slot_data.storage == null:
        return
    var total := 0
    for sd in slot_data.storage:
        if sd != null:
            total += int(sd.amount)
    slot_data.amount = total

func _save_shelter(shelter: ShelterSave, path: String) -> bool:
    var err := ResourceSaver.save(shelter, path)
    if err != OK:
        _log("error", "Failed to save shelter %s (code %d)" % [path, err])
        return false
    return true

func _on_fed(label: String) -> void:
    gameData.cat = 100.0
    _persist_cat_value()
    _log("info", "Fed: %s" % label)
    if _notify():
        Loader.Message("Cat Auto-Fed: " + label, Color.GREEN)

# Bowl-sourced feeds get a distinct prefix in the message so the player can
# tell at a glance whether their bowl-prep paid off vs the cat raiding the
# shelter. We also warn separately when the bowl just emptied so they know
# to top it up.
func _on_fed_from_bowl(food_name: String, bowl_name: String, bowl_now_empty: bool) -> void:
    gameData.cat = 100.0
    _persist_cat_value()
    # Reset both warning flags now that the cat has eaten — next hunger cycle
    # will warn fresh, and a refill resets the empty-bowl alert.
    _hunger_warned = false
    _bowl_empty_warned = false
    var emptied_marker: String = " — bowl empty" if bowl_now_empty else ""
    _log("info", "Fed from bowl: %s%s" % [food_name, emptied_marker])
    if _notify():
        Loader.Message("Cat ate from bowl: " + food_name, Color.GREEN)
    if bowl_now_empty and _show_warning():
        Loader.Message(bowl_name + " is empty — refill it for the cat", Color.ORANGE)

func _persist_cat_value() -> void:
    var path := "user://Character.tres"
    if !FileAccess.file_exists(path):
        return
    var f := FileAccess.open(path, FileAccess.READ)
    if f == null:
        return
    var text := f.get_as_text()
    f.close()

    var regex := RegEx.new()
    regex.compile("(?m)^cat\\s*=\\s*[0-9eE.+-]+$")
    var result := regex.sub(text, "cat = 100.0")
    if result == text:
        _log("warn", "Could not patch cat= field in Character.tres (regex miss)")
        return

    f = FileAccess.open(path, FileAccess.WRITE)
    if f == null:
        _log("error", "Could not open Character.tres for writing")
        return
    f.store_string(result)
    f.close()
    _log("debug", "Persisted cat=100 to Character.tres")

var _config_node: Node = null

func _config():
    if _config_node == null or !is_instance_valid(_config_node):
        _config_node = get_node_or_null("/root/CatAutoFeedConfig")
        if _config_node == null:
            _config_node = get_tree().root.find_child("CatAutoFeedConfig", true, false)
    return _config_node

func _enabled() -> bool:
    var cfg = _config()
    return cfg.enabled if cfg else true

func _threshold() -> float:
    var cfg = _config()
    return cfg.feed_threshold if cfg else 25.0

func _notify() -> bool:
    var cfg = _config()
    return cfg.show_notification if cfg else true

func _show_warning() -> bool:
    var cfg = _config()
    return cfg.show_hunger_warning if cfg else true

func _shelter_fallback() -> bool:
    var cfg = _config()
    return cfg.allow_shelter_fallback if cfg else false

func _loot_enabled() -> bool:
    var cfg = _config()
    return cfg.bowl_in_loot if cfg else true

func _food_names() -> Array:
    return DEFAULT_FOOD
