extends Node

# Wallet items detected by file name (not subtype) since we now use
# subtype="Magazine" so vanilla magazine-load UI works for cash drops.
const WALLET_FILES := ["Leather_Wallet", "Ammo_Tin", "Money_Case"]

var _log_node: Node = null

const ITEM_PATHS := [
    "res://mods/RTVWallets/Leather_Wallet.tres",
    "res://mods/RTVWallets/Ammo_Tin.tres",
    "res://mods/RTVWallets/Money_Case.tres",
    "res://mods/RTVWallets/Cash.tres",
]

func _ready() -> void:
    name = "RTVWallets"
    _log("debug", "RTV Wallets mod loaded")
    _register_with_metro()
    _register_with_loot_master()
    _override_item_value()
    _override_interface()
    set_process_unhandled_input(true)


# Registers each wallet tier as a SCENES entry via Metro's registry API.
# Metro v3.x wraps Database.gd at loader startup when [registry] is declared
# in mod.txt, so Database.get("Leather_Wallet") etc. resolves to our scenes.
func _register_with_metro() -> void:
    var lib = Engine.get_meta("RTVModLib") if Engine.has_meta("RTVModLib") else null
    if lib == null:
        _log("error", "Metro Mod Loader not detected — wallet items will not be registered. Install Metro v3.x or newer.")
        return
    await lib.frameworks_ready

    var ok_w: bool = lib.register(lib.Registry.SCENES, "Leather_Wallet", preload("res://mods/RTVWallets/Leather_Wallet.tscn"))
    var ok_t: bool = lib.register(lib.Registry.SCENES, "Ammo_Tin", preload("res://mods/RTVWallets/Ammo_Tin.tscn"))
    var ok_c: bool = lib.register(lib.Registry.SCENES, "Money_Case", preload("res://mods/RTVWallets/Money_Case.tscn"))
    var ok_cash: bool = lib.register(lib.Registry.SCENES, "Cash", preload("res://mods/RTVWallets/Cash.tscn"))
    if ok_w and ok_t and ok_c and ok_cash:
        _log("debug", "RTV Wallets items registered with Metro (SCENES)")
    else:
        _log("warn", "Metro rejected one or more wallet SCENES registrations (Leather_Wallet=%s Ammo_Tin=%s Money_Case=%s Cash=%s)" % [ok_w, ok_t, ok_c, ok_cash])

# Swaps res://Scripts/Item.gd with our subclass so inventory/container/supply
# totals include wallet cash via the overridden Value() method.
func _override_item_value() -> void:
    var override = load("res://mods/RTVWallets/ItemOverride.gd")
    if override == null:
        _log("error", "Could not load ItemOverride.gd")
        return
    override.take_over_path("res://Scripts/Item.gd")
    _log("debug", "Item.gd overridden — wallet cash now counted in inventory totals")

# Replaces Interface.gd with InterfaceOverride so Load() / UnloadMagazine()
# do an instant transfer when the source/target is Cash (skipping the slow
# vanilla Progress animation tuned for ammo rounds).
func _override_interface() -> void:
    var override = load("res://mods/RTVWallets/InterfaceOverride.gd")
    if override == null:
        _log("error", "Could not load InterfaceOverride.gd")
        return
    override.take_over_path("res://Scripts/Interface.gd")
    _log("debug", "Interface.gd overridden — cash load/unload is now instant")

# Appends our ItemData resources to res://Loot/LT_Master.tres so the vanilla
# LootContainer + Trader fill loops include wallets. Each ItemData's own
# civilian/industrial/military and trader booleans then drive where exactly
# it can spawn or be sold.
func _register_with_loot_master() -> void:
    var lt = load("res://Loot/LT_Master.tres")
    if lt == null:
        _log("error", "Could not load LT_Master.tres — wallets won't spawn in loot")
        return
    var added := 0
    for path in ITEM_PATHS:
        var item = load(path)
        if item == null:
            _log("warn", "Could not load %s — skipping loot registration" % path)
            continue
        if not lt.items.has(item):
            lt.items.append(item)
            added += 1
            # Cash gets injected 3× total to triple its drop frequency
            # without changing rarity (still Common loot).
            if path.ends_with("/Cash.tres"):
                lt.items.append(item)
                lt.items.append(item)
                added += 2
    _log("debug", "LT_Master registered %d wallet items (pool size now %d)" % [added, lt.items.size()])

func _unhandled_input(event: InputEvent) -> void:
    # Stash Report hotkey: prints every wallet you're carrying + its balance
    # to the logger (and overlay if enabled). Default F9, configurable in MCM.
    if !(event is InputEventKey) or !event.pressed or event.echo:
        return
    var cfg = _config()
    var key: int = cfg.stash_report_keycode if cfg else KEY_F9
    if event.keycode == key:
        _dump_stash()


func _config():
    var n = get_node_or_null("/root/RTVWalletsConfig")
    if n == null:
        n = get_tree().root.find_child("RTVWalletsConfig", true, false)
    return n

func _dump_stash() -> void:
    var wallets := find_wallets()
    _log("info", "--- Stash report ---")
    _log("info", "Wallets carried: %d" % wallets.size())
    for slot in wallets:
        _log("info", "  %s: %d / %d €" % [slot.itemData.name, int(slot.amount), int(slot.itemData.maxAmount)])
    _log("info", "Total balance: %d €" % total_balance())
    _log("info", "Total free space: %d €" % total_free_capacity())

# --- Stash API: aggregates across every wallet the player is carrying ----------
#
# Wallets store their balance per-instance in slotData.amount (magazine
# pattern). These helpers sum / draw / deposit across all of them so the
# trader integration can treat the player's pocket as a single pool.

# Walks the player's inventory grid + equipped rig storage and returns every
# SlotData whose item is a wallet (any tier). Returns [] if interface isn't
# resolvable yet.
func find_wallets() -> Array:
    var found: Array = []
    var iface = _interface()
    if iface == null:
        return found

    if iface.inventoryGrid:
        for element in iface.inventoryGrid.get_children():
            var slot = _slot_of(element)
            if _is_wallet(slot):
                found.append(slot)

    var rig_slot = _equipped_rig_slot()
    if rig_slot and rig_slot.storage is Array:
        for inner in rig_slot.storage:
            if _is_wallet(inner):
                found.append(inner)

    return found

func total_balance() -> int:
    var total := 0
    for slot in find_wallets():
        total += int(slot.amount)
    return total

func total_free_capacity() -> int:
    var total := 0
    for slot in find_wallets():
        total += int(slot.itemData.maxAmount) - int(slot.amount)
    return total

func can_pay(amount: int) -> bool:
    return amount >= 0 and total_balance() >= amount

func can_receive(amount: int) -> bool:
    return amount >= 0 and total_free_capacity() >= amount

# Drains `amount` € across wallets, fullest first. Returns total drawn.
# If can_pay(amount) is false, draws nothing and returns 0.
func pay(amount: int) -> int:
    if amount <= 0:
        return 0
    if !can_pay(amount):
        _log("warn", "pay(%d) blocked: only %d € available" % [amount, total_balance()])
        return 0
    var wallets := find_wallets()
    wallets.sort_custom(func(a, b): return int(a.amount) > int(b.amount))
    var taken := 0
    for slot in wallets:
        if taken >= amount:
            break
        var take: int = min(int(slot.amount), amount - taken)
        slot.amount = int(slot.amount) - take
        taken += take
    _log("success", "Paid %d € (across %d wallets)" % [taken, wallets.size()])
    return taken

# Distributes `amount` € across wallets, fullest first (concentrates cash).
# Returns total deposited; 0 if can_receive(amount) is false.
func receive(amount: int) -> int:
    if amount <= 0:
        return 0
    if !can_receive(amount):
        _log("warn", "receive(%d) blocked: only %d € free space" % [amount, total_free_capacity()])
        return 0
    var wallets := find_wallets()
    wallets.sort_custom(func(a, b): return int(a.amount) > int(b.amount))
    var deposited := 0
    for slot in wallets:
        if deposited >= amount:
            break
        var room: int = int(slot.itemData.maxAmount) - int(slot.amount)
        var add: int = min(room, amount - deposited)
        slot.amount = int(slot.amount) + add
        deposited += add
    _log("success", "Received %d € (across %d wallets)" % [deposited, wallets.size()])
    return deposited

func _is_wallet(slot) -> bool:
    if slot == null or slot.itemData == null:
        return false
    return WALLET_FILES.has(String(slot.itemData.file))

func _slot_of(element) -> Variant:
    # Inventory grid children expose slotData directly (Pickup-style nodes).
    if element == null:
        return null
    if "slotData" in element:
        return element.slotData
    return null

func _equipped_rig_slot():
    var iface = _interface()
    if iface == null or iface.character == null:
        return null
    var equipment = iface.character.get("equipment")
    if equipment == null:
        return null
    for slot in equipment:
        if slot != null and String(slot.slot) == "Rig":
            return slot
    return null

func _interface():
    var scene = get_tree().current_scene
    if scene == null:
        return null
    return scene.get_node_or_null("/root/Map/Core/UI/Interface")

func _log(lvl: String, msg: String) -> void:
    if _log_node == null or !is_instance_valid(_log_node):
        _log_node = get_node_or_null("/root/RTVWalletsLog")
        if _log_node == null:
            _log_node = get_tree().root.find_child("RTVWalletsLog", true, false)
    if _log_node:
        _log_node.call(lvl, msg)
    else:
        print("[RTVWallets] [", lvl.to_upper(), "] ", msg)
