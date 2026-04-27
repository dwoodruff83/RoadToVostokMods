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
    _register_with_metro()
    _apply_gunsmith_gate()
    _log("debug", "CatAutoFeed loaded, threshold=%d, check every %ds" % [int(_threshold()), int(CHECK_INTERVAL)])


# Registers Cat_Bowl as a SCENES entry and adds it to LT_Master via the Metro
# registry. Metro v3.x's [registry] opt-in (declared in mod.txt) wraps
# Database.gd at loader startup, so SCENES registrations show up to vanilla
# code calling Database.get("Cat_Bowl"). Loot registration uses the same
# subsystem and survives reverts cleanly.
func _register_with_metro() -> void:
    var lib = Engine.get_meta("RTVModLib") if Engine.has_meta("RTVModLib") else null
    if lib == null:
        _log("error", "Metro Mod Loader not detected — Cat_Bowl will not be registered. Install Metro v3.x or newer.")
        return
    await lib.frameworks_ready

    var bowl_scene = preload("res://mods/CatAutoFeed/Cat_Bowl.tscn")
    var ok_scene: bool = lib.register(lib.Registry.SCENES, "Cat_Bowl", bowl_scene)
    if ok_scene:
        _log("debug", "Cat_Bowl registered with Metro (SCENES)")
    else:
        _log("warn", "Metro rejected Cat_Bowl SCENES registration (id collision?)")

    if !_loot_enabled():
        _log("debug", "Loot integration disabled via config")
        return

    var bowl_data = load("res://mods/CatAutoFeed/Cat_Bowl.tres")
    if bowl_data == null:
        _log("warn", "Cat_Bowl.tres failed to load; cannot register in LT_Master")
        return
    var ok_loot: bool = lib.register(lib.Registry.LOOT, "catautofeed_bowl_master", {
        "item": bowl_data,
        "table": "LT_Master",
    })
    if ok_loot:
        _log("debug", "Cat_Bowl registered in LT_Master (rarity=%d)" % int(bowl_data.rarity))
    else:
        _log("warn", "Metro rejected Cat_Bowl LOOT registration in LT_Master")


# Toggle Cat_Bowl.tres `gunsmith` flag at mod load based on the MCM setting.
# The Trader's FillTraderBucket runs once per trader spawn and reads the flag
# from the shared resource at that moment, so changes here apply on the
# player's next visit to the Gunsmith. Reload required for changes to take
# effect mid-session because already-spawned traders have their bucket fixed.
func _apply_gunsmith_gate() -> void:
    var bowl_data = load("res://mods/CatAutoFeed/Cat_Bowl.tres")
    if bowl_data == null:
        _log("warn", "Cat_Bowl.tres failed to load; cannot apply Gunsmith gate")
        return
    bowl_data.gunsmith = _gunsmith_enabled()
    _log("debug", "Cat_Bowl.gunsmith = %s" % bool(bowl_data.gunsmith))

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

    # Per-frame mental buff while the player is in the cat's shelter.
    # Runs separately from the auto-feed tick so the gain is smooth, like
    # the vanilla fire buff in Character.Mental().
    _maybe_buff_mental_from_cat(delta)

    _check_timer -= delta
    if _check_timer > 0.0:
        return
    _check_timer = CHECK_INTERVAL
    _try_auto_feed()


# Raises mental at the same rate as the vanilla fire buff (delta / 4.0)
# whenever the player is in the cat's shelter and the cat is alive. Skips
# when the mod is disabled, the cat company toggle is off, the cat isn't
# rescued / is dead, or the player is in a menu / settings / mid-transition
# (mirrors the gates on _try_auto_feed). No log output — vanilla's fire
# buff is silent and players see the gain through the mental HUD readout.
func _maybe_buff_mental_from_cat(delta: float) -> void:
    if !_enabled() or !_cat_company_enabled():
        return
    if gameData.settings or gameData.transition or gameData.isDead:
        return
    if !gameData.catFound or gameData.catDead:
        return
    var current_map := _current_map_name()
    if current_map == "":
        return
    var cat_shelter := _find_cat_shelter()
    if cat_shelter == "" or current_map != cat_shelter:
        return
    gameData.mental += delta / 4.0

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
        _log("debug", "Cat hunger below threshold (%d%% < %d%%)" % [int(gameData.cat), int(_threshold())])
        if _show_warning() and _log_node:
            _log_node.notify("Cat is hungry (%d%%)" % int(gameData.cat), Color.ORANGE)

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
            _log("debug", "Cat shelter detected: %s" % shelter_name)
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
                # Suppress the "is empty" warning when other bowls in the
                # same shelter still hold food — otherwise a multi-bowl
                # setup spams "Bowl A is empty" the moment Bowl A drains
                # even though the cat is fine. Only fire the warning when
                # THIS bowl just hit zero AND no sibling bowl has cat food.
                var bowls_empty: bool = (
                    _slot_storage_total(itemSave.slotData) == 0
                    and not _other_bowls_have_food(shelter, itemSave, foods)
                )
                if !_save_shelter(shelter, path):
                    return false
                _on_fed_from_bowl(food_name, bowl_name, bowls_empty)
                return true

    # If shelter fallback is disabled (default), stop here — bowl is the
    # only food source, and we just confirmed it's empty. Throttle the on-screen
    # message via _bowl_empty_warned so we don't spam every 5s tick; reset by
    # _on_fed_from_bowl when the player refills.
    if !fallback:
        _log("debug", "Cat hungry but bowl is empty (shelter fallback disabled)")
        if _notify() and !_bowl_empty_warned and _log_node:
            _bowl_empty_warned = true
            _log_node.notify("Cat hungry — fill the bowl in " + shelter_name, Color.ORANGE)
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
    if _notify() and _log_node:
        _log_node.notify("Cat still hungry — no food in " + shelter_name, Color.ORANGE)
    return false

func _slot_storage_total(slot_data: SlotData) -> int:
    if slot_data == null or slot_data.storage == null:
        return 0
    var total := 0
    for sd in slot_data.storage:
        if sd != null:
            total += int(sd.amount)
    return total

# Does any container in `shelter.items` other than `exclude` hold cat-edible
# food in its nested storage? Used to suppress the "bowl is empty" warning
# when multiple bowls coexist and the cat just drained the first one — there
# might still be food in another bowl, so the player doesn't need to panic.
func _other_bowls_have_food(shelter: ShelterSave, exclude, foods: Array) -> bool:
    if shelter == null or shelter.items == null:
        return false
    for itemSave in shelter.items:
        if itemSave == null or itemSave == exclude or itemSave.slotData == null:
            continue
        var inner = itemSave.slotData.storage
        if inner == null:
            continue
        for sd in inner:
            if sd == null or sd.itemData == null:
                continue
            if sd.itemData.file in foods and int(sd.amount) > 0:
                return true
    return false

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
    if _notify() and _log_node:
        _log_node.notify("Cat Auto-Fed: " + label, Color.GREEN)
    else:
        _log("success", "Auto-fed: " + label)

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
    if _notify() and _log_node:
        _log_node.notify("Cat ate from bowl: " + food_name, Color.GREEN)
    else:
        var emptied_marker: String = " — bowl empty" if bowl_now_empty else ""
        _log("success", "Fed from bowl: %s%s" % [food_name, emptied_marker])
    if bowl_now_empty and _show_warning() and _log_node:
        _log_node.notify(bowl_name + " is empty — refill it for the cat", Color.ORANGE)

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

func _gunsmith_enabled() -> bool:
    var cfg = _config()
    return cfg.bowl_at_gunsmith if cfg else false

func _cat_company_enabled() -> bool:
    var cfg = _config()
    return cfg.cat_company_buff if cfg else true

func _food_names() -> Array:
    return DEFAULT_FOOD
