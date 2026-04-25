extends Node

var _log_node: Node = null

func _ready() -> void:
    name = "Wallet"
    _log("info", "Wallet mod loaded")
    _inject_database()
    # TODO: hook trader open so Buy/Sell use the active wallet's balance.
    # TODO: hook loot tables so wallets spawn on civilians / in containers per tier flags.

func _inject_database() -> void:
    var inject = load("res://mods/Wallet/DatabaseInject.gd")
    if inject == null:
        _log("error", "Could not load DatabaseInject.gd")
        return
    inject.reload()
    inject.take_over_path("res://Scripts/Database.gd")

    # take_over_path only affects future load() calls — the already-running
    # Database autoload keeps its original script. Swap our extended script
    # onto the live instance so Database.get("Wallet") etc. resolve now.
    var db = get_node_or_null("/root/Database")
    if db == null:
        db = get_tree().root.find_child("Database", true, false)
    if db:
        db.set_script(inject)
        _log("info", "Database injected with wallet tiers")
    else:
        _log("warn", "Database autoload not found; items may not resolve until next load")

# --- Balance helpers (wallet uses ItemData amount per instance, like a magazine) ---

# Locate an equipped wallet on the player. Returns a SlotData or null.
# TODO: walk player equipment slots and return the highest-capacity wallet with room.
func active_wallet_slot():
    return null

func balance_of(slot) -> int:
    if slot == null or slot.itemData == null:
        return 0
    return int(slot.amount)

func deposit(slot, amount: int) -> int:
    if slot == null or slot.itemData == null:
        _log("warn", "deposit called with null slot or itemData")
        return 0
    if amount < 0:
        _log("warn", "deposit called with negative amount %d" % amount)
        return 0
    var room: int = int(slot.itemData.maxAmount) - int(slot.amount)
    var take: int = min(amount, room)
    slot.amount = int(slot.amount) + take
    if take < amount:
        _log("info", "Wallet full — deposited %d of %d (discarded %d)" % [take, amount, amount - take])
    else:
        _log("debug", "Deposited %d, new balance=%d" % [take, slot.amount])
    return take

func withdraw(slot, amount: int) -> int:
    if slot == null or slot.itemData == null:
        _log("warn", "withdraw called with null slot or itemData")
        return 0
    if amount < 0:
        _log("warn", "withdraw called with negative amount %d" % amount)
        return 0
    var give: int = min(amount, int(slot.amount))
    slot.amount = int(slot.amount) - give
    if give < amount:
        _log("info", "Insufficient funds — gave %d of %d requested" % [give, amount])
    else:
        _log("debug", "Withdrew %d, new balance=%d" % [give, slot.amount])
    return give

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
