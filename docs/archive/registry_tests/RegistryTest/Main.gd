extends Node

# Comprehensive registry test mod — exercises the public RTVModItemRegistry
# API on game start and reports per-test PASS/FAIL via the engine console
# and the in-game notification overlay.
#
# Tests covered (all safe — no destructive state changes):
#   T1: clean register
#   T2: collision rejected without overwrite
#   T3: collision accepted with overwrite=true
#   T4: vanilla const shadow rejected without force
#   T5: empty file_name rejected
#   T6: null scene rejected
#
# NOT covered here (manual verification needed):
#   - vanilla shadow with force=true (destructive — leaks until restart)
#   - hostile co-mod conflict (use RegistryTest_Hostile)
#   - early-load deferred register (use RegistryTest_Early)
#
# Hotkey F8 re-runs the suite. Auto-runs once on game start.

const TEST_HOTKEY := KEY_F8


func _ready() -> void:
    name = "RegistryTest"
    set_process_unhandled_input(true)
    # Defer one frame so the registry has finished its own _ready and
    # flushed any deferred-register entries from priority<-50 mods.
    call_deferred("_run_tests")


func _unhandled_input(event: InputEvent) -> void:
    if !(event is InputEventKey) or !event.pressed or event.echo:
        return
    if event.keycode == TEST_HOTKEY:
        _run_tests()


func _run_tests() -> void:
    var registry := _resolve_registry()
    if registry == null:
        push_warning("[RegistryTest] /root/ModItemRegistry not found — install RTVModItemRegistry first")
        _notify("Registry not found — install RTVModItemRegistry", Color.RED)
        return

    var stub_a := _make_stub("RegistryTest_StubA")
    var stub_b := _make_stub("RegistryTest_StubB")

    var passed := 0
    var failed := 0

    if _expect(registry.register("RegistryTest_Alpha", stub_a), true,
            "T1 clean register"):
        passed += 1
    else:
        failed += 1

    if _expect(registry.register("RegistryTest_Alpha", stub_b), false,
            "T2 collision rejected without overwrite"):
        passed += 1
    else:
        failed += 1

    if _expect(registry.register("RegistryTest_Alpha", stub_b, true), true,
            "T3 collision accepted with overwrite=true"):
        passed += 1
    else:
        failed += 1

    if _expect(registry.register("Cat", stub_a), false,
            "T4 vanilla shadow rejected without force"):
        passed += 1
    else:
        failed += 1

    if _expect(registry.register("", stub_a), false,
            "T5 empty file_name rejected"):
        passed += 1
    else:
        failed += 1

    if _expect(registry.register("Whatever", null), false,
            "T6 null scene rejected"):
        passed += 1
    else:
        failed += 1

    var total := passed + failed
    var msg := "RegistryTest: %d/%d passed" % [passed, total]
    print("[RegistryTest] === ", msg, " ===")
    _notify(msg, Color.GREEN if failed == 0 else Color.RED)


func _expect(actual: bool, expected: bool, label: String) -> bool:
    var ok: bool = actual == expected
    var icon: String = "PASS" if ok else "FAIL"
    print("[RegistryTest]   %s  %s (got %s, expected %s)" % [icon, label, actual, expected])
    return ok


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
        loader.Message("[RegistryTest] " + msg, color)
