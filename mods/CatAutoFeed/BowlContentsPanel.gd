extends Control

# Modal panel for managing Cat Food Bowl contents.
#
# Two-column layout:
#   left  = bowl contents, with [Take] buttons per food type
#   right = player inventory cat-edibles, with [Add] buttons
# Built from Control nodes at runtime — no .tscn — so it survives mod
# packaging without import-cache fragility. Inherits the vanilla UI theme to
# match RTV's look-and-feel; adds icon thumbnails and hover effects.
#
# Input lock: gameData.freeze + MOUSE_MODE_VISIBLE while panel is open, then
# restored on close.

const FOOD_NAMES := ["Cat_Food", "Canned_Meat", "Canned_Tuna", "Perch"]
const VANILLA_THEME_PATH := "res://UI/Themes/Theme.tres"
const ICON_SIZE := 36

# Vanilla-ish palette pulled from UI/Themes/Theme.tres + tightened a little.
const COL_BG := Color(0.10, 0.10, 0.11, 0.97)
const COL_BORDER := Color(0.40, 0.40, 0.42)
const COL_ROW := Color(1, 1, 1, 0.04)
const COL_ROW_HOVER := Color(1, 1, 1, 0.10)
const COL_LABEL_DIM := Color(0.65, 0.65, 0.70)
const COL_EMPTY := Color(0.50, 0.50, 0.55)

var bowl: Pickup = null
var interface_: Node = null
var gameData = preload("res://Resources/GameData.tres")

var _bowl_list: VBoxContainer = null
var _inv_list: VBoxContainer = null
var _total_label: Label = null
var _pickup_btn: Button = null
var _prev_mouse_mode: int = Input.MOUSE_MODE_CAPTURED
var _prev_freeze: bool = false
var _prev_inspecting: bool = false


func _ready() -> void:
    name = "BowlContentsPanel"
    interface_ = get_tree().current_scene.get_node_or_null("/root/Map/Core/UI/Interface")
    var t = load(VANILLA_THEME_PATH)
    if t is Theme:
        theme = t
    _build_ui()
    _lock_input()


func open(bowl_node: Pickup) -> void:
    bowl = bowl_node
    _refresh()


# --- UI construction ---

func _build_ui() -> void:
    set_anchors_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP

    # Dim the rest of the screen so the panel feels modal.
    var dim := ColorRect.new()
    dim.color = Color(0, 0, 0, 0.65)
    dim.set_anchors_preset(Control.PRESET_FULL_RECT)
    dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(dim)

    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.custom_minimum_size = Vector2(720, 480)
    panel.add_theme_stylebox_override("panel", _make_stylebox(COL_BG, COL_BORDER, 14, 4))
    add_child(panel)
    panel.size = panel.custom_minimum_size
    panel.position = (get_viewport_rect().size - panel.size) / 2

    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 12)
    panel.add_child(vbox)

    var title := Label.new()
    title.text = "Cat Bowl"
    title.add_theme_font_size_override("font_size", 24)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title)

    vbox.add_child(HSeparator.new())

    var hbox := HBoxContainer.new()
    hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
    hbox.add_theme_constant_override("separation", 28)
    vbox.add_child(hbox)

    _bowl_list = _build_column(hbox, "IN BOWL")
    _inv_list = _build_column(hbox, "YOUR INVENTORY")

    vbox.add_child(HSeparator.new())

    # Footer.
    var footer := HBoxContainer.new()
    footer.add_theme_constant_override("separation", 12)
    vbox.add_child(footer)
    _total_label = Label.new()
    _total_label.text = "Total: 0"
    _total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _total_label.modulate = COL_LABEL_DIM
    footer.add_child(_total_label)

    _pickup_btn = Button.new()
    _pickup_btn.text = "Pick up bowl"
    _pickup_btn.tooltip_text = "Empty the bowl first to pick it up"
    _pickup_btn.pressed.connect(_on_pickup_bowl)
    footer.add_child(_pickup_btn)

    var close_btn := Button.new()
    close_btn.text = "Close [Esc]"
    close_btn.pressed.connect(_on_close)
    footer.add_child(close_btn)


# Build one labeled column (header + scrollable list). Returns the inner
# VBoxContainer rows get added to.
func _build_column(parent: Container, header: String) -> VBoxContainer:
    var col := VBoxContainer.new()
    col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    col.add_theme_constant_override("separation", 8)
    parent.add_child(col)

    var hdr := Label.new()
    hdr.text = header
    hdr.add_theme_font_size_override("font_size", 12)
    hdr.modulate = COL_LABEL_DIM
    col.add_child(hdr)

    # Scroll container so a fridge full of perch doesn't blow out the layout.
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    col.add_child(scroll)

    var inner := VBoxContainer.new()
    inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    inner.add_theme_constant_override("separation", 4)
    scroll.add_child(inner)
    return inner


func _make_stylebox(bg: Color, border: Color, content_pad: int, radius: int) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.border_color = border
    sb.border_width_left = 1
    sb.border_width_right = 1
    sb.border_width_top = 1
    sb.border_width_bottom = 1
    sb.corner_radius_top_left = radius
    sb.corner_radius_top_right = radius
    sb.corner_radius_bottom_left = radius
    sb.corner_radius_bottom_right = radius
    sb.content_margin_left = content_pad
    sb.content_margin_right = content_pad
    sb.content_margin_top = max(content_pad - 4, 6)
    sb.content_margin_bottom = max(content_pad - 4, 6)
    return sb


# --- Refresh / data sync ---

func _refresh() -> void:
    # Bowl could be queue_freed mid-panel by an explosion, mod reload, etc.
    # is_instance_valid catches the freed-but-still-referenced case that a
    # plain `null` check would miss; close the panel cleanly if so.
    if not _bowl_alive():
        _on_close()
        return
    _refresh_bowl_list()
    _refresh_inv_list()
    if _total_label != null:
        var n: int = bowl.total_servings()
        var cap: int = bowl.capacity()
        _total_label.text = "%d / %d servings" % [n, cap]
        if bowl.is_full():
            _total_label.modulate = Color(1.0, 0.7, 0.4)  # warning amber
        else:
            _total_label.modulate = COL_LABEL_DIM
    if _pickup_btn != null:
        var empty: bool = bowl.is_empty()
        _pickup_btn.disabled = not empty
        _pickup_btn.tooltip_text = "" if empty else "Empty the bowl first to pick it up"


func _bowl_alive() -> bool:
    return bowl != null and is_instance_valid(bowl)


func _refresh_bowl_list() -> void:
    for c in _bowl_list.get_children():
        c.queue_free()
    if not _bowl_alive():
        return
    var entries: Array = bowl.contents_breakdown()
    if entries.is_empty():
        _bowl_list.add_child(_empty_label("(empty)"))
        return
    for entry in entries:
        var row := _make_food_row(entry["item_data"], int(entry["amount"]), "Take")
        var btn: Button = _row_button(row)
        btn.pressed.connect(_on_take.bind(entry["item_data"]))
        _bowl_list.add_child(row)


func _refresh_inv_list() -> void:
    for c in _inv_list.get_children():
        c.queue_free()
    if interface_ == null or interface_.get("inventoryGrid") == null:
        _inv_list.add_child(_empty_label("(no inventory)"))
        return
    # Aggregate cat-edibles by file. Stackable items (rare for these foods,
    # but possible) carry their count in slotData.amount; non-stackable
    # consumables count once per slot.
    #
    # is_queued_for_deletion filter is critical: when we Pick+queue_free an
    # inventory item from _on_add, queue_free is deferred to end-of-frame, so
    # the freed Item is still a child of inventoryGrid when we _refresh()
    # immediately after. Without this filter we'd both display ghost counts
    # AND attempt to decrement an already-removed item next click.
    var counts := {}
    var item_data_by_file := {}
    for item in interface_.inventoryGrid.get_children():
        if item == null or item.is_queued_for_deletion() or item.get("slotData") == null:
            continue
        var sd = item.slotData
        if sd == null or sd.itemData == null:
            continue
        var fname := String(sd.itemData.file)
        if not (fname in FOOD_NAMES):
            continue
        var qty: int = int(sd.amount) if bool(sd.itemData.stackable) else 1
        counts[fname] = int(counts.get(fname, 0)) + qty
        item_data_by_file[fname] = sd.itemData
    if counts.is_empty():
        _inv_list.add_child(_empty_label("(no cat food)"))
        return
    # Render in FOOD_NAMES priority order so layout is stable.
    var bowl_full: bool = _bowl_alive() and bowl.is_full()
    for fname in FOOD_NAMES:
        if not (fname in counts):
            continue
        var row := _make_food_row(item_data_by_file[fname], int(counts[fname]), "Add")
        var btn: Button = _row_button(row)
        btn.disabled = bowl_full
        if bowl_full:
            btn.tooltip_text = "Bowl is full"
        btn.pressed.connect(_on_add.bind(item_data_by_file[fname]))
        _inv_list.add_child(row)


func _empty_label(text: String) -> Label:
    var lbl := Label.new()
    lbl.text = text
    lbl.modulate = COL_EMPTY
    return lbl


# Construct a styled row: icon, name, count, action button. Wrapped in a
# PanelContainer so we can apply hover modulation per-row.
func _make_food_row(item_data, count: int, button_text: String) -> PanelContainer:
    var wrapper := PanelContainer.new()
    wrapper.add_theme_stylebox_override("panel", _make_row_stylebox(COL_ROW))
    wrapper.mouse_filter = Control.MOUSE_FILTER_STOP
    wrapper.mouse_entered.connect(_on_row_hover.bind(wrapper, true))
    wrapper.mouse_exited.connect(_on_row_hover.bind(wrapper, false))

    var hbox := HBoxContainer.new()
    hbox.add_theme_constant_override("separation", 12)
    wrapper.add_child(hbox)

    var icon := TextureRect.new()
    icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.texture = item_data.icon if item_data and item_data.icon else null
    hbox.add_child(icon)

    var label_box := VBoxContainer.new()
    label_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label_box.add_theme_constant_override("separation", 0)
    hbox.add_child(label_box)

    var name_label := Label.new()
    name_label.text = String(item_data.name)
    name_label.add_theme_font_size_override("font_size", 14)
    label_box.add_child(name_label)

    var count_label := Label.new()
    count_label.text = "× %d" % count
    count_label.add_theme_font_size_override("font_size", 12)
    count_label.modulate = COL_LABEL_DIM
    label_box.add_child(count_label)

    var btn := Button.new()
    btn.text = button_text
    btn.custom_minimum_size = Vector2(80, 0)
    hbox.add_child(btn)

    return wrapper


# Returns the inner Button created by _make_food_row so callers can wire its
# pressed signal without poking at child indices.
func _row_button(row: PanelContainer) -> Button:
    var hbox: HBoxContainer = row.get_child(0)
    return hbox.get_child(hbox.get_child_count() - 1)


func _make_row_stylebox(bg: Color) -> StyleBoxFlat:
    var sb := StyleBoxFlat.new()
    sb.bg_color = bg
    sb.corner_radius_top_left = 3
    sb.corner_radius_top_right = 3
    sb.corner_radius_bottom_left = 3
    sb.corner_radius_bottom_right = 3
    sb.content_margin_left = 8
    sb.content_margin_right = 8
    sb.content_margin_top = 4
    sb.content_margin_bottom = 4
    return sb


func _on_row_hover(row: PanelContainer, entered: bool) -> void:
    var col: Color = COL_ROW_HOVER if entered else COL_ROW
    row.add_theme_stylebox_override("panel", _make_row_stylebox(col))


# --- Actions ---

func _on_take(item_data) -> void:
    if not _bowl_alive():
        return
    var taken: SlotData = bowl.take_food(item_data)
    if taken == null:
        return
    var added := false
    if interface_ != null and interface_.has_method("AutoStack"):
        added = interface_.AutoStack(taken, interface_.inventoryGrid)
    if not added and interface_ != null and interface_.has_method("Create"):
        added = interface_.Create(taken, interface_.inventoryGrid, false)
    if not added:
        # Inventory full — restore to bowl and tell the player why nothing
        # happened. PlayError() alone left players guessing.
        bowl.add_food(item_data)
        if interface_ != null and interface_.has_method("PlayError"):
            interface_.PlayError()
        Loader.Message("Inventory full — make space to take food out", Color.ORANGE)
    elif interface_ != null and interface_.has_method("UpdateStats"):
        interface_.UpdateStats(false)
    _refresh()


func _on_add(item_data) -> void:
    if not _bowl_alive() or interface_ == null:
        return
    # Reject up front if the bowl is at capacity — otherwise we'd consume an
    # inventory item without anywhere to put it.
    if bowl.is_full():
        if interface_.has_method("PlayError"):
            interface_.PlayError()
        Loader.Message("Bowl is full (%d/%d)" % [bowl.total_servings(), bowl.capacity()], Color.ORANGE)
        return
    if not _decrement_inventory(item_data):
        if interface_.has_method("PlayError"):
            interface_.PlayError()
        return
    bowl.add_food(item_data)
    if interface_.has_method("UpdateStats"):
        interface_.UpdateStats(false)
    _refresh()


# Pull one unit of item_data out of the player inventory. Stackable items
# get their amount decremented (slot removed only when it hits zero);
# non-stackable consumables are removed wholesale, since each instance
# occupies its own slot with amount=0.
func _decrement_inventory(item_data) -> bool:
    if interface_ == null or interface_.get("inventoryGrid") == null or item_data == null:
        return false
    var grid = interface_.inventoryGrid
    var key := String(item_data.file)
    var stackable := bool(item_data.stackable)
    for item in grid.get_children():
        # Skip ghost items already queued for deletion (Pick+queue_free is
        # deferred to end-of-frame; without this filter we'd keep "removing"
        # phantom items and the bowl would gain more than the inventory loses).
        if item == null or item.is_queued_for_deletion() or item.get("slotData") == null:
            continue
        var sd = item.slotData
        if sd == null or sd.itemData == null or String(sd.itemData.file) != key:
            continue
        if stackable:
            if sd.amount <= 0:
                continue
            sd.amount = int(sd.amount) - 1
            if sd.amount <= 0:
                # Vanilla pattern: Pick removes from the grid's items[] tracking,
                # queue_free removes the actual Item node — both required.
                if grid.has_method("Pick"):
                    grid.Pick(item)
                item.queue_free()
            elif item.has_method("UpdateAmount"):
                item.UpdateAmount()
        else:
            if grid.has_method("Pick"):
                grid.Pick(item)
            item.queue_free()
        return true
    return false


# --- Input lock + close ---

func _lock_input() -> void:
    _prev_mouse_mode = Input.mouse_mode
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if gameData != null:
        _prev_freeze = bool(gameData.get("freeze")) if gameData.get("freeze") != null else false
        gameData.set("freeze", true)
        if gameData.get("isOccupied") != null:
            gameData.set("isOccupied", true)
        # UIManager.gd gates Tab on `gameData.isInspecting`, not isOccupied or
        # freeze. Set it so the player can't toggle the inventory while our
        # modal panel is open.
        if gameData.get("isInspecting") != null:
            _prev_inspecting = bool(gameData.get("isInspecting"))
            gameData.set("isInspecting", true)


func _unlock_input() -> void:
    Input.mouse_mode = _prev_mouse_mode
    if gameData != null:
        gameData.set("freeze", _prev_freeze)
        if gameData.get("isOccupied") != null:
            gameData.set("isOccupied", false)
        if gameData.get("isInspecting") != null:
            gameData.set("isInspecting", _prev_inspecting)


func _on_pickup_bowl() -> void:
    if not _bowl_alive() or not bowl.is_empty():
        return
    # bowl.Interact() would re-open the panel — use the direct pickup path.
    bowl.do_pickup()
    _on_close()


func _on_close() -> void:
    _unlock_input()
    var p = get_parent()
    if p is CanvasLayer and String(p.name) == "BowlContentsPanelLayer":
        p.queue_free()
    else:
        queue_free()


func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        _on_close()
        get_viewport().set_input_as_handled()
