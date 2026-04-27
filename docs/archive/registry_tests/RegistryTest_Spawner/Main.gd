extends Node

# Hotkey-triggered item spawner — verifies the registry's items still
# resolve AND function in inventory after the hostile clobber test.
#
# Press F5 in-game (during gameplay, not main menu) to:
#   1. Database.get(<name>) for each registered mod item — tests the
#      registry's _get override survived the hostile script swap.
#   2. Spawn one of each item into the player's inventory via the same
#      Interface.Create() call vanilla Cat Rescue uses for the cat carrier.
#
# Console + on-screen notification reports per-item PASS/FAIL.
#
# This is a TEST mod — uninstall after publish-prep is done.

const SPAWN_HOTKEY := KEY_F5

# (registered name on the registry, .tres path for direct loading)
const TEST_ITEMS := [
    ["Cat_Bowl",       "res://mods/CatAutoFeed/Cat_Bowl.tres"],
    ["Leather_Wallet", "res://mods/RTVWallets/Leather_Wallet.tres"],
    ["Ammo_Tin",       "res://mods/RTVWallets/Ammo_Tin.tres"],
    ["Money_Case",     "res://mods/RTVWallets/Money_Case.tres"],
    ["Cash",           "res://mods/RTVWallets/Cash.tres"],
]


func _ready() -> void:
    name = "RegistryTest_Spawner"
    set_process_unhandled_input(true)
    print("[RegistryTest_Spawner] ready — press F5 in-game to spawn the test set")


func _unhandled_input(event: InputEvent) -> void:
    if !(event is InputEventKey) or !event.pressed or event.echo:
        return
    if event.keycode == SPAWN_HOTKEY:
        _spawn_all()


func _spawn_all() -> void:
    var interface := _resolve_interface()
    if interface == null:
        print("[RegistryTest_Spawner] FAIL — Interface not found (must be in-game, not main menu)")
        _notify("Spawner: be in-game (not menu) and try F5 again", Color.RED)
        return
    if interface.inventoryGrid == null:
        print("[RegistryTest_Spawner] FAIL — Interface.inventoryGrid is null")
        _notify("Spawner: inventoryGrid missing", Color.RED)
        return

    var db := _resolve_database()

    var resolved_ok := 0
    var resolved_fail := 0
    var spawned_ok := 0
    var spawned_fail := 0

    print("[RegistryTest_Spawner] === spawn test ===")
    for entry in TEST_ITEMS:
        var name_str: String = entry[0]
        var tres_path: String = entry[1]

        # Test 1: Database.get() resolution (tests the registry's _get override)
        var via_db = db.get(name_str) if db else null
        if via_db != null:
            print("[RegistryTest_Spawner]   PASS  Database.get('%s') -> %s" % [name_str, str(via_db)])
            resolved_ok += 1
        else:
            print("[RegistryTest_Spawner]   FAIL  Database.get('%s') returned null" % name_str)
            resolved_fail += 1

        # Test 2: actually spawn it into inventory
        var item_data = load(tres_path)
        if item_data == null:
            print("[RegistryTest_Spawner]   FAIL  could not load %s" % tres_path)
            spawned_fail += 1
            continue

        var sd := SlotData.new()
        sd.itemData = item_data
        sd.amount = 1
        var ok: bool = interface.Create(sd, interface.inventoryGrid, false)
        if ok:
            print("[RegistryTest_Spawner]   PASS  spawned %s into inventory" % name_str)
            spawned_ok += 1
        else:
            print("[RegistryTest_Spawner]   FAIL  Interface.Create rejected %s (inventory full?)" % name_str)
            spawned_fail += 1

    var summary := "Resolve: %d/%d  |  Spawn: %d/%d" % [
        resolved_ok, resolved_ok + resolved_fail,
        spawned_ok, spawned_ok + spawned_fail,
    ]
    print("[RegistryTest_Spawner] === ", summary, " ===")

    var color := Color.GREEN
    if resolved_fail > 0 or spawned_fail > 0:
        color = Color.YELLOW if (resolved_ok + spawned_ok) > 0 else Color.RED
    _notify(summary, color)


func _resolve_interface() -> Node:
    var scene := get_tree().current_scene
    if scene == null:
        return null
    return scene.get_node_or_null("/root/Map/Core/UI/Interface")


func _resolve_database() -> Node:
    var n := get_node_or_null("/root/Database")
    if n == null:
        n = get_tree().root.find_child("Database", true, false)
    return n


func _notify(msg: String, color: Color) -> void:
    var loader := get_node_or_null("/root/Loader")
    if loader and loader.has_method("Message"):
        loader.Message("[Spawner] " + msg, color)
