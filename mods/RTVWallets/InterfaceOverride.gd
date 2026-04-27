extends "res://Scripts/Interface.gd"

# Interface.gd subclass with two extensions:
#   1. Instant Load/UnloadMagazine for Cash items (skip the slow vanilla
#      Progress animation tuned for individual rifle rounds).
#   2. A "Sell for €" button next to Accept on the Deal panel, enabled when
#      the player has selected items to offer but no items requested in
#      return — converts the offer into Cash items spawned in inventory,
#      split into ≤maxAmount stacks. Player can drag stacks into a wallet to
#      deposit. (Earlier versions auto-deposited into wallets first; that
#      hid the wallet's display amount until the trader UI re-opened.)

const RTV_CASH_SUBTYPE := "Cash"
const CASH_TRES_PATH := "res://mods/RTVWallets/Cash.tres"
const EURO_ICON_PATH := "res://mods/RTVWallets/assets/icons/Icon_Combine_Euro.png"

var _sell_for_cash_button: Button = null
var _button_injected: bool = false
var _euro_texture: Texture2D = null
var _bullet_texture_original: Texture2D = null

# Lazy inject on first Open(). We can't override _ready() — Godot 4 rejects
# overriding a virtual method whose base class doesn't declare it explicitly,
# and Interface.gd has no _ready of its own. Open() is called every time the
# inventory/trader UI opens and is guaranteed to fire after @onready binds.
func Open() -> void:
    super()
    if not _button_injected:
        _button_injected = true
        _inject_sell_for_cash_button()

# Swap the bullet "load" overlay (highlight.get_child(1)) for a € symbol when
# the dragged item is Cash. Vanilla shows a global Icon_Combine_Load.png (3
# bullets) on every Magazine-compatible drop target — fine for ammo, weird
# for cash. We restore the bullets when the drag changes back to ammo.
func Highlight() -> void:
    super()
    var load_node = _highlight_load_node()
    if load_node == null:
        return
    if _bullet_texture_original == null:
        _bullet_texture_original = load_node.texture
    if itemDragged != null and _is_cash(itemDragged):
        var euro := _get_euro_texture()
        if euro:
            load_node.texture = euro
    else:
        load_node.texture = _bullet_texture_original

func _highlight_load_node() -> TextureRect:
    if highlight == null or highlight.get_child_count() < 2:
        return null
    var node = highlight.get_child(1)
    return node as TextureRect

func _get_euro_texture() -> Texture2D:
    if _euro_texture != null:
        return _euro_texture
    var bytes := FileAccess.get_file_as_bytes(EURO_ICON_PATH)
    if bytes.is_empty():
        return null
    var img := Image.new()
    if img.load_png_from_buffer(bytes) != OK:
        return null
    _euro_texture = ImageTexture.create_from_image(img)
    return _euro_texture

# --- Loading: cash-stack -> wallet ----------------------------------------

func Load(targetItem, sourceItem):
    if _is_cash(sourceItem):
        _load_cash_instant(targetItem, sourceItem)
        return
    super(targetItem, sourceItem)

func _load_cash_instant(targetItem, sourceItem) -> void:
    var ammo_needed: int = int(targetItem.slotData.itemData.maxAmount) - int(targetItem.slotData.amount)
    var ammo_provided: int = int(sourceItem.slotData.amount)
    var ammo_to_load: int = min(ammo_needed, ammo_provided)

    # Capture drag-start grid/position before doing anything (vanilla
    # Load does the same — these are needed to put a leftover source
    # stack back where it came from).
    var return_grid = returnGrid
    var return_position = returnPosition

    targetItem.slotData.amount = int(targetItem.slotData.amount) + ammo_to_load
    targetItem.UpdateDetails()
    targetItem.UpdateSprite()

    if ammo_provided > ammo_to_load:
        # Source has leftover — re-anchor it in the inventory grid at the
        # original drag-start position. Without this the stack ends up
        # orphaned (visible but not in any grid → "stuck item" artifact).
        sourceItem.slotData.amount = ammo_provided - ammo_to_load
        sourceItem.UpdateDetails()
        sourceItem.show()
        if return_grid and return_grid.has_method("Place"):
            sourceItem.global_position = return_position
            return_grid.Place(sourceItem)
    else:
        sourceItem.queue_free()

    PlayAttach()
    UpdateStats(true)
    Reset()

# --- Unloading: wallet -> stack out into inventory ------------------------

func UnloadMagazine(targetItem, targetGrid):
    if _is_cash_holder(targetItem):
        _unload_cash_instant(targetItem, targetGrid)
        return
    super(targetItem, targetGrid)

func _unload_cash_instant(targetItem, targetGrid) -> void:
    var ammo_data = targetItem.slotData.itemData.compatible[0]
    var ammo_to_unload: int = int(targetItem.slotData.amount)
    if ammo_to_unload <= 0:
        return

    var grid = targetGrid if targetGrid else inventoryGrid
    var max_stack: int = int(ammo_data.maxAmount)

    # Drain in chunks of maxAmount. AutoStack tries to merge into an
    # existing partial Cash stack first; Create spawns a new one if not.
    # If Create fails (no inventory room), stop draining and leave the
    # remainder in the wallet.
    var unloaded: int = 0
    while unloaded < ammo_to_unload:
        var chunk: int = min(ammo_to_unload - unloaded, max_stack)
        var slot := SlotData.new()
        slot.itemData = ammo_data
        slot.amount = chunk
        if AutoStack(slot, grid):
            unloaded += chunk
            continue
        # Create returns true on successful placement, false if no room.
        if Create(slot, grid, true):
            PlayStack()
            unloaded += chunk
        else:
            # Inventory full — leave remainder in the wallet
            break

    targetItem.slotData.amount = ammo_to_unload - unloaded
    targetItem.UpdateDetails()
    targetItem.UpdateSprite()

    UpdateStats(true)
    Reset()

# --- Drop: Cash uses maxAmount-sized chunks ------------------------------
#
# Vanilla Drop() splits a stackable item into pickups of size defaultAmount
# (200 for Cash). A 500-cash drop becomes 200+200+100, all spawned at the
# same physics position — they collide on spawn, and at least one routinely
# tunnels through the floor or under furniture, looking like lost money.
# For Cash, use maxAmount (500) as the chunk size — one pickup per 500 €.
# We also stagger the spawn position slightly per chunk to keep physics sane
# in the rare overflow case.
func Drop(target):
    if not _is_cash(target):
        super(target)
        return
    _drop_cash(target)

func _drop_cash(target) -> void:
    var map = get_tree().current_scene.get_node("/root/Map")
    var file = Database.get(target.slotData.itemData.file)
    if file == null:
        target.queue_free()
        PlayDrop()
        return

    var drop_direction: Vector3
    var drop_position: Vector3
    var drop_rotation: Vector3
    var drop_force := 2.5
    if trader and hoverGrid == null:
        drop_direction = trader.global_transform.basis.z
        drop_position = (trader.global_position + Vector3(0, 1.0, 0)) + drop_direction / 2
        drop_rotation = Vector3(-25, trader.rotation_degrees.y + 180 + randf_range(-45, 45), 45)
    elif hoverGrid != null and hoverGrid.get_parent().name == "Container":
        drop_direction = container.global_transform.basis.z
        drop_position = (container.global_position + Vector3(0, 0.5, 0)) + drop_direction / 2
        drop_rotation = Vector3(-25, container.rotation_degrees.y + 180 + randf_range(-45, 45), 45)
    else:
        drop_direction = -camera.global_transform.basis.z
        drop_position = (camera.global_position + Vector3(0, -0.25, 0)) + drop_direction / 2
        drop_rotation = Vector3(-25, camera.rotation_degrees.y + 180 + randf_range(-45, 45), 45)

    var max_per_pickup: int = int(target.slotData.itemData.maxAmount)
    var amount_left: int = int(target.slotData.amount)
    var spawn_index := 0
    while amount_left > 0:
        var chunk: int = min(amount_left, max_per_pickup)
        amount_left -= chunk

        var pickup = file.instantiate()
        map.add_child(pickup)
        # Stagger position so chunks don't spawn inside each other and tunnel.
        var stagger := Vector3(randf_range(-0.05, 0.05), float(spawn_index) * 0.06, randf_range(-0.05, 0.05))
        pickup.position = drop_position + stagger
        pickup.rotation_degrees = drop_rotation
        pickup.linear_velocity = drop_direction * drop_force
        pickup.Unfreeze()

        var newSlot := SlotData.new()
        newSlot.itemData = target.slotData.itemData
        newSlot.amount = chunk
        pickup.slotData.Update(newSlot)
        spawn_index += 1

    target.reparent(self)
    target.queue_free()
    PlayDrop()
    UpdateStats(true)

# --- Sell for € button ----------------------------------------------------

# Adds a sibling button to Reset/Accept that lets the player sell offered
# items for cash without needing to fill the Request side. Vanilla Deal
# requires Offer == Request to enable Accept — our button skips that gate
# and pays out in cash.
func _inject_sell_for_cash_button() -> void:
    print("[RTVWallets/InterfaceOverride] _inject_sell_for_cash_button — acceptButton=", acceptButton, " valid=", is_instance_valid(acceptButton))
    if not is_instance_valid(acceptButton):
        print("[RTVWallets/InterfaceOverride] acceptButton not valid — bailing")
        return
    var parent: Node = acceptButton.get_parent()
    if parent == null:
        print("[RTVWallets/InterfaceOverride] acceptButton has no parent — bailing")
        return
    print("[RTVWallets/InterfaceOverride] injecting button into ", parent.get_path())

    # Duplicate Accept button to inherit styling, theme, layout
    var btn: Button = acceptButton.duplicate()
    btn.name = "SellForCash"
    btn.text = "Sell for €"
    btn.disabled = true

    # Disconnect any duplicated _on_accept_pressed binding before wiring ours
    for conn in btn.pressed.get_connections():
        btn.pressed.disconnect(conn["callable"])
    btn.pressed.connect(_on_sell_for_cash_pressed)

    parent.add_child(btn)
    parent.move_child(btn, acceptButton.get_index())  # place just before Accept
    _sell_for_cash_button = btn

func CalculateDeal() -> void:
    super()
    _refresh_sell_for_cash_button()

# Match vanilla barter: enable whenever there's something to sell and nothing
# requested. Overflow cash drops on the ground via our Drop() override — same
# behaviour as vanilla item-for-item trades when the bought item won't fit.
func _refresh_sell_for_cash_button() -> void:
    if not is_instance_valid(_sell_for_cash_button):
        return
    var offer_value: int = _selected_offer_value()
    var request_count: int = _selected_request_count()
    _sell_for_cash_button.disabled = not (offer_value > 0 and request_count == 0)

func _selected_offer_value() -> int:
    var total: int = 0
    if inventoryGrid:
        for element in inventoryGrid.get_children():
            if element.selected:
                total += int(element.Value())
    return total

func _selected_request_count() -> int:
    var n: int = 0
    if supplyGrid:
        for element in supplyGrid.get_children():
            if element.selected:
                n += 1
    return n

func _on_sell_for_cash_pressed() -> void:
    var offer_value: int = _selected_offer_value()
    if offer_value <= 0:
        return

    # Drain offered items FIRST so freed cells are available before we spawn
    # cash. Mirrors vanilla barter order: sold item disappears, payment fills
    # the freed slot, leftover drops on the ground.
    for element in inventoryGrid.get_children():
        if element.selected:
            inventoryGrid.Pick(element)
            element.queue_free()

    _spill_cash_into_inventory(offer_value)

    if is_instance_valid(trader):
        trader.PlayTraderTrade()
    ResetTrading()
    Loader.Message("Sold for %d €" % offer_value, Color.GREEN)

# Spawn Cash items in inventory split into ≤maxAmount stacks. AutoStack tops
# up existing partial stacks; Create places fresh stacks; if Create can't
# fit, vanilla AutoPlace falls through to our Drop() override and spawns the
# pickup at the player's feet. Always advances `spilled` so we don't loop.
func _spill_cash_into_inventory(amount: int) -> void:
    if amount <= 0:
        return
    var cash_data = load(CASH_TRES_PATH)
    if cash_data == null:
        return
    var max_stack: int = int(cash_data.maxAmount)
    var spilled: int = 0
    while spilled < amount:
        var chunk: int = min(amount - spilled, max_stack)
        var slot := SlotData.new()
        slot.itemData = cash_data
        slot.amount = chunk
        if AutoStack(slot, inventoryGrid):
            spilled += chunk
            continue
        # Create with useDrop=true: placed in grid OR dropped on ground.
        Create(slot, inventoryGrid, true)
        PlayStack()
        spilled += chunk

# --- Helpers ---------------------------------------------------------------

func _is_cash(item) -> bool:
    if item == null or item.slotData == null or item.slotData.itemData == null:
        return false
    return String(item.slotData.itemData.subtype) == RTV_CASH_SUBTYPE

# A wallet is what we Unload — its compatible[0] should be a Cash ItemData
func _is_cash_holder(item) -> bool:
    if item == null or item.slotData == null or item.slotData.itemData == null:
        return false
    var compat = item.slotData.itemData.compatible
    if compat == null or compat.is_empty():
        return false
    var first: ItemData = compat[0]
    return first != null and String(first.subtype) == RTV_CASH_SUBTYPE
