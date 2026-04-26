extends Node

const WALLET_SUBTYPE := "Wallet"

var _log_node: Node = null

const ITEM_PATHS := [
    "res://mods/Wallet/Wallet.tres",
    "res://mods/Wallet/Ammo_Tin.tres",
    "res://mods/Wallet/Money_Case.tres",
]

func _ready() -> void:
    name = "Wallet"
    _log("info", "Wallet mod loaded")
    _inject_database()
    _register_with_loot_master()
    set_process_unhandled_input(true)
    # TODO: hook trader open so Buy/Sell use the active wallet's balance.

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
    _log("info", "LT_Master registered %d wallet items (pool size now %d)" % [added, lt.items.size()])

func _unhandled_input(event: InputEvent) -> void:
    # Debug: F9 prints the stash totals to the logger (and overlay if enabled).
    if event is InputEventKey and event.pressed and !event.echo:
        if event.keycode == KEY_F9:
            _dump_stash()

func _dump_stash() -> void:
    var wallets := find_wallets()
    _log("info", "--- Stash report ---")
    _log("info", "Wallets carried: %d" % wallets.size())
    for slot in wallets:
        _log("info", "  %s: %d / %d ₽" % [slot.itemData.name, int(slot.amount), int(slot.itemData.maxAmount)])
    _log("info", "Total balance: %d ₽" % total_balance())
    _log("info", "Total free space: %d ₽" % total_free_capacity())

func _inject_database() -> void:
    # Prefer RTVModItemRegistry's coordinated registration if installed —
    # this lets Wallet coexist with other Database-extending mods (e.g.
    # CatAutoFeed). Fall back to legacy direct injection in single-mod
    # setups so Wallet still works without the registry.
    # get_node_or_null sometimes misses cross-mod autoloads even when they
    # ARE in the tree; fall back to find_child the same way we look up
    # /root/Database below.
    var registry = get_node_or_null("/root/ModItemRegistry")
    if registry == null:
        registry = get_tree().root.find_child("ModItemRegistry", true, false)
    if registry and registry.has_method("register"):
        registry.register("Wallet", preload("res://mods/Wallet/Wallet.tscn"))
        registry.register("Ammo_Tin", preload("res://mods/Wallet/Ammo_Tin.tscn"))
        registry.register("Money_Case", preload("res://mods/Wallet/Money_Case.tscn"))
        _log("info", "Wallet items registered with ModItemRegistry")
        return

    _log("warn", "RTVModItemRegistry not installed — using legacy in-place injection (incompatible with sibling Database-extending mods)")
    _inject_database_legacy()


# Legacy direct take_over_path / set_script injection. Kept for users who
# install only Wallet (no registry). Will fight other mods doing the same;
# install RTVModItemRegistry to coordinate.
func _inject_database_legacy() -> void:
    var inject = load("res://mods/Wallet/DatabaseInject.gd")
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
        var test = db.get("Wallet")
        _log("info", "Database injected (legacy) — Wallet resolves to: %s" % str(test))
    else:
        _log("warn", "Database autoload not found; items may not resolve until next load")

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

# Drains `amount` ₽ across wallets, fullest first. Returns total drawn.
# If can_pay(amount) is false, draws nothing and returns 0.
func pay(amount: int) -> int:
    if amount <= 0:
        return 0
    if !can_pay(amount):
        _log("warn", "pay(%d) blocked: only %d ₽ available" % [amount, total_balance()])
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
    _log("info", "Paid %d ₽ (across %d wallets)" % [taken, wallets.size()])
    return taken

# Distributes `amount` ₽ across wallets, fullest first (concentrates cash).
# Returns total deposited; 0 if can_receive(amount) is false.
func receive(amount: int) -> int:
    if amount <= 0:
        return 0
    if !can_receive(amount):
        _log("warn", "receive(%d) blocked: only %d ₽ free space" % [amount, total_free_capacity()])
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
    _log("info", "Received %d ₽ (across %d wallets)" % [deposited, wallets.size()])
    return deposited

func _is_wallet(slot) -> bool:
    if slot == null or slot.itemData == null:
        return false
    return String(slot.itemData.subtype) == WALLET_SUBTYPE

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
    return get_tree().current_scene.get_node_or_null("/root/Map/Core/UI/Interface")

# --- Config access ---

func _config():
    return get_node_or_null("/root/WalletConfig")

func _log(lvl: String, msg: String) -> void:
    if _log_node == null or !is_instance_valid(_log_node):
        _log_node = get_node_or_null("/root/WalletLog")
        if _log_node == null:
            _log_node = get_tree().root.find_child("WalletLog", true, false)
    if _log_node:
        _log_node.call(lvl, msg)
    else:
        print("[Wallet] [", lvl.to_upper(), "] ", msg)
