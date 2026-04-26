extends Node

# Tests the early-load consumer pattern: this mod has priority=-100, so its
# _ready runs BEFORE RTVModItemRegistry's (priority=-50). The registry's
# autoload Node doesn't yet exist at our _ready time — the mod loader
# processes priorities strictly in order.
#
# A realistic early-load consumer must therefore POLL for the registry
# to appear in the tree, then call register(). This stub verifies that
# pattern works end-to-end:
#
#   1. _ready confirms registry is absent at -100
#   2. Defer to a frame-poll loop that waits up to POLL_TIMEOUT_FRAMES
#   3. Once registry appears, call register() and verify the item resolves

const TEST_ITEM_NAME := "RegistryTest_Early_Item"
const POLL_TIMEOUT_FRAMES := 120  # 2s at 60fps — well past any reasonable registry init


func _ready() -> void:
    name = "RegistryTest_Early"
    print("[RegistryTest_Early] _ready — at priority=-100, registry should not yet exist")
    var initial := _resolve_registry()
    if initial == null:
        print("[RegistryTest_Early]   confirmed: registry absent at _ready time (expected)")
    else:
        print("[RegistryTest_Early]   surprise: registry already present at priority -100")

    call_deferred("_poll_and_register")


func _poll_and_register() -> void:
    var frames: int = 0
    var registry: Node = null
    while frames < POLL_TIMEOUT_FRAMES:
        registry = _resolve_registry()
        if registry != null:
            break
        await get_tree().process_frame
        frames += 1

    if registry == null:
        print("[RegistryTest_Early] FAIL — registry never appeared after %d frames" % frames)
        _notify("Registry never appeared (RTVModItemRegistry installed?)", Color.RED)
        return

    print("[RegistryTest_Early] registry appeared after %d frame(s); attempting register()" % frames)
    var stub := _make_stub("Early_StubItem")
    var ok = registry.register(TEST_ITEM_NAME, stub)
    print("[RegistryTest_Early] register() returned %s" % ok)

    if not ok:
        _notify("Early register() returned false", Color.RED)
        return

    # Give the registry a couple frames to settle before verifying
    await get_tree().process_frame
    await get_tree().process_frame

    var found: bool = registry.is_registered(TEST_ITEM_NAME)
    var msg := "Early item resolves: %s (waited %d frame(s))" % [found, frames]
    print("[RegistryTest_Early] ", msg)
    _notify(msg, Color.GREEN if found else Color.RED)


func _make_stub(node_name: String) -> PackedScene:
    var scene := PackedScene.new()
    var n := Node.new()
    n.name = node_name
    scene.pack(n)
    return scene


func _resolve_registry() -> Node:
    var n := get_node_or_null("/root/ModItemRegistry")
    if n == null:
        n = get_tree().root.find_child("ModItemRegistry", true, false)
    return n


func _notify(msg: String, color: Color) -> void:
    var loader := get_node_or_null("/root/Loader")
    if loader and loader.has_method("Message"):
        loader.Message("[Early Test] " + msg, color)
