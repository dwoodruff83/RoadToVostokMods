extends Node

# ==============================================================
# ModLogger — reusable logging framework for Road to Vostok mods.
# See LOGGER.md for the embeddable/reuse guide.
# To reuse in another mod: copy this file, edit the three vars
# in _init() (mod_id, mod_display_name, log_filename), and autoload it.
# ==============================================================

enum Level { DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3, OFF = 4 }

# --- Per-mod identity (edit when reusing in another mod) ---

var mod_id: String
var mod_display_name: String
var log_filename: String

# --- Optional overrides ---

var log_dir: String = ""
var overlay_position: Vector2 = Vector2(12, 12)
var overlay_size: Vector2 = Vector2(700, 400)
var overlay_max_lines: int = 10
var overlay_message_ttl: float = 12.0
var overlay_font_size: int = 14

# --- Runtime settings (driven by apply_settings) ---

var level: int = Level.INFO
var to_file := false
var to_overlay := false

# --- Internal state ---

var _overlay_layer: CanvasLayer
var _overlay_label: RichTextLabel
var _overlay_messages: Array = []
var _file: FileAccess = null

func _init() -> void:
    mod_id = "PunisherGuarantee"
    mod_display_name = "Punisher Guarantee"
    log_filename = "punisher_guarantee.log"

func _ready() -> void:
    name = mod_id + "Log"
    print("[", mod_id, "] Logger ready at /root/", name, " (to_file=", to_file, " to_overlay=", to_overlay, ")")

func debug(msg: String) -> void:
    _write(Level.DEBUG, msg, "gray")

func info(msg: String) -> void:
    _write(Level.INFO, msg, "white")

func warn(msg: String) -> void:
    _write(Level.WARN, msg, "orange")

func error(msg: String) -> void:
    _write(Level.ERROR, msg, "red")

func apply_settings(new_level: int, file_enabled: bool, overlay_enabled: bool) -> void:
    print("[", mod_id, "] Logger.apply_settings(level=", new_level, ", file=", file_enabled, ", overlay=", overlay_enabled, ")")
    level = new_level
    _set_file_output(file_enabled)
    _set_overlay_output(overlay_enabled)

# ==============================================================
# MCM integration helpers — call these from your mod's config.gd
# so the logger contributes its settings to a "Logging" category
# under the same MCM page as your mod.
# ==============================================================

func attach_to_mcm_config(config: ConfigFile, category: String = "Logging", base_menu_pos: int = 10, category_menu_pos: int = 999) -> void:
    # Position this category at the bottom of the mod's MCM page by default.
    # MCM sorts categories alphabetically unless each has an explicit menu_pos.
    config.set_value("Category", category, { "menu_pos": category_menu_pos })

    config.set_value("Dropdown", "log_level", {
        "name" = "Log Level",
        "tooltip" = "Minimum severity to log. Debug is verbose; Error logs only failures.",
        "default" = 1,
        "value" = 1,
        "options" = ["Debug", "Info", "Warn", "Error", "Off"],
        "category" = category,
        "menu_pos" = base_menu_pos,
    })
    config.set_value("Bool", "log_to_file", {
        "name" = "Log to File",
        "tooltip" = "Write log entries to user://MCM/" + mod_id + "/" + log_filename + ".",
        "default" = false,
        "value" = false,
        "category" = category,
        "menu_pos" = base_menu_pos + 1,
    })
    config.set_value("Bool", "log_to_overlay", {
        "name" = "Log to In-Game Overlay",
        "tooltip" = "Show recent log messages as on-screen notifications.",
        "default" = false,
        "value" = false,
        "category" = category,
        "menu_pos" = base_menu_pos + 2,
    })

func apply_from_config(config: ConfigFile) -> void:
    var lvl: int = int(config.get_value("Dropdown", "log_level", {"value": 1})["value"])
    var file_enabled: bool = bool(config.get_value("Bool", "log_to_file", {"value": false})["value"])
    var overlay_enabled: bool = bool(config.get_value("Bool", "log_to_overlay", {"value": false})["value"])
    apply_settings(lvl, file_enabled, overlay_enabled)

func _write(lvl: int, msg: String, color: String) -> void:
    if lvl < level:
        return
    var prefix: String = ["DEBUG", "INFO", "WARN", "ERROR"][lvl]
    var line := "[%s] [%s] %s" % [_timestamp(), prefix, msg]
    print("[", mod_id, "] ", line)
    if to_file:
        _write_file(line)
    if to_overlay:
        _send_to_game_messages(lvl, line)

func _send_to_game_messages(lvl: int, text: String) -> void:
    # Uses RTV's Loader.Message system so logs match vanilla notification style.
    # Color by level: DEBUG=gray, INFO=white, WARN=orange, ERROR=red.
    var loader = get_node_or_null("/root/Loader")
    if loader == null or !loader.has_method("Message"):
        _append_overlay(text, _color_name_for_level(lvl))
        return
    var color: Color
    match lvl:
        Level.DEBUG: color = Color.GRAY
        Level.INFO: color = Color.WHITE
        Level.WARN: color = Color.ORANGE
        Level.ERROR: color = Color.RED
        _: color = Color.WHITE
    loader.Message(text, color)

func _color_name_for_level(lvl: int) -> String:
    match lvl:
        Level.DEBUG: return "gray"
        Level.INFO: return "white"
        Level.WARN: return "orange"
        Level.ERROR: return "red"
    return "white"

func _timestamp() -> String:
    var t := Time.get_time_dict_from_system()
    return "%02d:%02d:%02d" % [t.hour, t.minute, t.second]

func _get_log_dir() -> String:
    if log_dir != "":
        return log_dir
    return "user://MCM/" + mod_id

func _get_log_path() -> String:
    return _get_log_dir() + "/" + log_filename

func _set_file_output(enabled: bool) -> void:
    if enabled == to_file:
        return
    to_file = enabled
    if !enabled and _file:
        _file.close()
        _file = null
        return
    if enabled:
        var dir := _get_log_dir()
        if !DirAccess.dir_exists_absolute(dir):
            DirAccess.make_dir_recursive_absolute(dir)
        var path := _get_log_path()
        _file = FileAccess.open(path, FileAccess.WRITE)
        if _file:
            _file.store_line("=== %s log opened %s ===" % [mod_display_name, _timestamp()])
            _file.flush()
            print("[", mod_id, "] Log file opened: ", path)
        else:
            print("[", mod_id, "] ERROR: could not open log file ", path, " (err=", FileAccess.get_open_error(), ")")

func _write_file(line: String) -> void:
    if _file == null:
        return
    _file.store_line(line)
    _file.flush()

func _set_overlay_output(enabled: bool) -> void:
    if enabled == to_overlay:
        return
    to_overlay = enabled
    if !enabled:
        if is_instance_valid(_overlay_layer):
            _overlay_layer.queue_free()
        _overlay_layer = null
        _overlay_label = null
        _overlay_messages.clear()

func _ensure_overlay() -> void:
    if is_instance_valid(_overlay_layer):
        return
    _overlay_layer = CanvasLayer.new()
    _overlay_layer.layer = 100
    add_child(_overlay_layer)
    _overlay_label = RichTextLabel.new()
    _overlay_label.bbcode_enabled = true
    _overlay_label.fit_content = true
    _overlay_label.position = overlay_position
    _overlay_label.size = overlay_size
    _overlay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _overlay_label.add_theme_font_size_override("normal_font_size", overlay_font_size)
    _overlay_layer.add_child(_overlay_label)
    print("[", mod_id, "] Overlay created")

func _append_overlay(text: String, color: String) -> void:
    _ensure_overlay()
    var expires := Time.get_ticks_msec() + int(overlay_message_ttl * 1000.0)
    _overlay_messages.append({"text": text, "color": color, "expires_at": expires})
    while _overlay_messages.size() > overlay_max_lines:
        _overlay_messages.pop_front()
    _refresh_overlay()

func _process(_delta: float) -> void:
    if !to_overlay or _overlay_messages.is_empty():
        return
    var now := Time.get_ticks_msec()
    var changed := false
    while _overlay_messages.size() > 0 and _overlay_messages[0]["expires_at"] <= now:
        _overlay_messages.pop_front()
        changed = true
    if changed:
        _refresh_overlay()

func _refresh_overlay() -> void:
    if _overlay_label == null:
        return
    var lines: Array[String] = []
    for m in _overlay_messages:
        lines.append("[color=%s]%s[/color]" % [m["color"], m["text"]])
    _overlay_label.text = "\n".join(lines)
