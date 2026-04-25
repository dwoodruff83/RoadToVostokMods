extends Node

const POLICE_OVERRIDE := "res://mods/PunisherGuarantee/PoliceOverride.gd"
const ORIGINAL_POLICE := "res://Scripts/Police.gd"
const EVENTS_PATH := "res://Events/Events.tres"

var _log_node: Node = null

func _ready() -> void:
    name = "PunisherGuarantee"

    _log("info", "Startup")

    var cfg = _config()
    if cfg and !cfg.enabled:
        _log("info", "Disabled via config; skipping all patches")
        return

    _bump_event()
    _override_police()

    set_process_unhandled_input(true)
    _log("info", "Ready")

func _log(lvl: String, msg: String) -> void:
    if _log_node == null or !is_instance_valid(_log_node):
        _log_node = get_node_or_null("/root/PunisherGuaranteeLog")
        if _log_node == null:
            _log_node = get_tree().root.find_child("PunisherGuaranteeLog", true, false)
    if _log_node:
        _log_node.call(lvl, msg)
    else:
        print("[PunisherGuarantee] [", lvl.to_upper(), "] ", msg)

func _bump_event() -> void:
    var cfg = _config()
    if cfg and !cfg.guarantee_event:
        return

    var events = load(EVENTS_PATH)
    if events == null:
        _log("error", "Could not load " + EVENTS_PATH)
        return

    for event in events.events:
        if event == null or event.function != "Police":
            continue
        event.possibility = 100
        if cfg and cfg.bypass_day_gate:
            event.day = 0
        event.instant = true
        _log("info", "Boosted '" + event.name + "' to 100% (day>=" + str(event.day) + ")")

func _override_police() -> void:
    var cfg = _config()
    if cfg and !cfg.force_boss_mode:
        return

    var script = load(POLICE_OVERRIDE)
    if script == null:
        _log("error", "Override script missing at " + POLICE_OVERRIDE)
        return
    script.take_over_path(ORIGINAL_POLICE)
    _log("info", "Police.gd overridden (forcing Boss mode)")

func _unhandled_input(event: InputEvent) -> void:
    var cfg = _config()
    if cfg == null or !cfg.hotkey_enabled:
        return
    if event is InputEventKey and event.pressed and !event.echo:
        if event.keycode == cfg.hotkey_keycode:
            _force_spawn_now()

func _force_spawn_now() -> void:
    var spawner = _find_ai_spawner()
    if spawner == null:
        _log("warn", "Hotkey pressed but no AISpawner in this scene")
        Loader.Message("PunisherGuarantee: no AISpawner in this scene", Color.ORANGE)
        return

    var gameData = preload("res://Resources/GameData.tres")
    var spawn_pos: Vector3 = gameData.playerPosition + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))

    spawner.SpawnBoss(spawn_pos)
    _log("info", "Hotkey spawn at " + str(spawn_pos))
    Loader.Message("Punisher: spawned near player", Color.RED)

func _find_ai_spawner() -> Node:
    for n in get_tree().get_nodes_in_group("AI"):
        if n.has_method("SpawnBoss"):
            return n
    var map = get_tree().current_scene.get_node_or_null("/root/Map/AI")
    if map and map.has_method("SpawnBoss"):
        return map
    return null

func _config():
    return get_node_or_null("/root/PunisherGuaranteeConfig")
