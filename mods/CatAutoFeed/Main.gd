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
var _was_in_menu := true
var _log_node: Node = null

func _ready() -> void:
    name = "CatAutoFeed"
    _log_node = _resolve_log_node()
    print("[CatAutoFeed] Main._ready, log_node=", _log_node)
    _inject_database()
    _log("info", "CatAutoFeed loaded, threshold=%d, check every %ds" % [int(_threshold()), int(CHECK_INTERVAL)])

func _inject_database() -> void:
    # Inject our PackedScenes into the vanilla Database so Drop / LoadShelter
    # / Spawner can resolve Cat_Bowl by file name.
    var inject = load("res://mods/CatAutoFeed/DatabaseInject.gd")
    if inject == null:
        _log("error", "Could not load DatabaseInject.gd")
        return
    inject.reload()
    inject.take_over_path("res://Scripts/Database.gd")

    # take_over_path only affects future load() calls; the running Database
    # autoload still points at the vanilla script. Swap our extended script
    # onto the live instance so Database.Cat_Bowl / Database.get("Cat_Bowl")
    # resolve immediately.
    var db = get_node_or_null("/root/Database")
    if db == null:
        db = get_tree().root.find_child("Database", true, false)
    if db:
        db.set_script(inject)
        var test = db.get("Cat_Bowl")
        _log("info", "Database script replaced, Cat_Bowl resolves to: %s" % str(test))
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
    var shelter = load(path) as ShelterSave
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

    for i in range(shelter.items.size()):
        var itemSave: ItemSave = shelter.items[i]
        if itemSave == null or itemSave.slotData == null or itemSave.slotData.itemData == null:
            continue
        if itemSave.slotData.itemData.file in foods:
            var label: String = String(itemSave.slotData.itemData.name) + " (" + shelter_name + ")"
            shelter.items.remove_at(i)
            if !_save_shelter(shelter, path):
                return false
            _on_fed(label)
            return true

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

func _food_names() -> Array:
    return DEFAULT_FOOD
