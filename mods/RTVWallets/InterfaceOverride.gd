extends "res://Scripts/Interface.gd"

# Interface.gd subclass — intercepts Load()/UnloadMagazine() when the source/
# target is one of our Cash items (subtype == "Cash") and does the transfer
# instantly. The vanilla path uses Progress.Load(amount) which has wait_time
# = amount / 5 seconds — fine for a 30-round rifle mag (6s) but unbearable
# for a 500€ cash stack (100s).

const RTV_CASH_SUBTYPE := "Cash"

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

    targetItem.slotData.amount = int(targetItem.slotData.amount) + ammo_to_load
    targetItem.UpdateDetails()
    targetItem.UpdateSprite()

    if ammo_provided > ammo_to_load:
        # Source has leftover — keep it where it was
        sourceItem.slotData.amount = ammo_provided - ammo_to_load
        sourceItem.UpdateDetails()
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

    # Drain the wallet
    targetItem.slotData.amount = 0
    targetItem.UpdateDetails()
    targetItem.UpdateSprite()

    # Spawn a fresh Cash slot in the target grid via Interface helpers
    # (matches vanilla UnloadMagazine final block at Scripts/Interface.gd:2691)
    var new_slot := SlotData.new()
    new_slot.itemData = ammo_data
    new_slot.amount = ammo_to_unload

    var grid = targetGrid if targetGrid else inventoryGrid
    if !AutoStack(new_slot, grid):
        Create(new_slot, grid, true)
        PlayStack()

    UpdateStats(true)
    Reset()

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
