extends Node

# RTVModLogger demo entry point.
#
# Listens for the configured test hotkey and fires the test sequence so users
# can see what each log level / notify call looks like in-game. Read the
# accompanying LOGGER.md for the embed/reuse guide for your own mod.

var _log_node: Node = null
var _config_node: Node = null
var _ready_announced := false

func _ready() -> void:
    name = "RTVModLogger"
    _log("info", "RTVModLogger demo loaded")
    set_process_unhandled_input(true)

    # Defer the welcome notify by one frame so Loader is ready.
    call_deferred("_announce_ready")

func _announce_ready() -> void:
    if _ready_announced:
        return
    _ready_announced = true
    var cfg = _config()
    if cfg and !cfg.welcome_on_start:
        return
    var logger = _logger()
    if logger:
        logger.notify("RTVModLogger ready — press your Test Hotkey to fire the test sequence.", Color.CYAN)

func _unhandled_input(event: InputEvent) -> void:
    if !(event is InputEventKey) or !event.pressed or event.echo:
        return
    var cfg = _config()
    if cfg == null:
        return
    if event.keycode != cfg.test_hotkey_keycode:
        return
    fire_test_sequence(cfg.test_action)

func fire_test_sequence(action: String) -> void:
    var logger = _logger()
    if logger == null:
        push_warning("[RTVModLogger] No logger node found")
        return

    match action:
        "Test Debug":   logger.debug("Test debug message — gray, dev-only diagnostics")
        "Test Info":    logger.info("Test info message — white, general state changes")
        "Test Success": logger.success("Test success message — green, positive outcomes (matches vanilla style)")
        "Test Warn":    logger.warn("Test warn message — orange, recoverable anomalies")
        "Test Error":   logger.error("Test error message — red, serious failures")
        "Test Notify":  logger.notify("Test notify — bypasses level/overlay filters", Color.MAGENTA)
        _:              _fire_all(logger)

func _fire_all(logger: Node) -> void:
    # Fire all six in sequence. Stagger via deferred timers so they appear as
    # distinct entries in the notification stack rather than overlapping.
    var calls := [
        ["debug", "Test DEBUG — gray, dev-only diagnostics", null],
        ["info", "Test INFO — white, general state changes", null],
        ["success", "Test SUCCESS — green, positive outcomes", null],
        ["warn", "Test WARN — orange, recoverable anomalies", null],
        ["error", "Test ERROR — red, serious failures", null],
        ["notify", "Test NOTIFY — always shows, bypasses filters", Color.MAGENTA],
    ]
    var delay := 0.0
    for c in calls:
        var method: String = c[0]
        var msg: String = c[1]
        var color = c[2]
        var t := get_tree().create_timer(delay, false)
        t.timeout.connect(func():
            if !is_instance_valid(logger):
                return
            if method == "notify":
                logger.notify(msg, color)
            else:
                logger.call(method, msg)
        )
        delay += 0.35

func _logger() -> Node:
    if _log_node and is_instance_valid(_log_node):
        return _log_node
    _log_node = get_node_or_null("/root/RTVModLoggerLog")
    if _log_node == null:
        _log_node = get_tree().root.find_child("RTVModLoggerLog", true, false)
    return _log_node

func _config():
    if _config_node and is_instance_valid(_config_node):
        return _config_node
    _config_node = get_node_or_null("/root/RTVModLoggerConfig")
    if _config_node == null:
        _config_node = get_tree().root.find_child("RTVModLoggerConfig", true, false)
    return _config_node

func _log(lvl: String, msg: String) -> void:
    var logger = _logger()
    if logger:
        logger.call(lvl, msg)
    else:
        print("[RTVModLogger] [", lvl.to_upper(), "] ", msg)
