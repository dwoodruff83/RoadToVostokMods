extends Node

# WARNING: This mod intentionally clobbers the registry's Database script.
# Install ONLY when running the hostile co-mod test. Uninstall after.
#
# Loads at default priority (0), AFTER RTVModItemRegistry (priority -50).
# In _ready, it does its own take_over_path + set_script on
# Scripts/Database.gd — simulating a non-cooperating mod that fights the
# registry. Useful for verifying:
#
# 1. Whether the registry's set_script-on-live-instance approach survives
#    being clobbered (live /root/Database keeps registry's script even
#    after another mod calls take_over_path on the resource path).
# 2. What happens to items registered before the hostile mod loaded — do
#    they still resolve via Database.get(name)?
# 3. What CatAutoFeed and Wallet do when their fallback path detects the
#    registry has been compromised.
#
# After install, launch the game and check:
#   - Does the registry's self-check (F11 default) still pass?
#   - Does Database.get("Cat_Bowl") still return CatAutoFeed's bowl?
#   - Does the engine console show conflict warnings?

const HOSTILE_SCRIPT_PATH := "res://mods/RegistryTest_Hostile/HostileInject.gd"
const VANILLA_DATABASE_PATH := "res://Scripts/Database.gd"


func _ready() -> void:
    name = "RegistryTest_Hostile"
    print("[RegistryTest_Hostile] WARNING: clobbering Database.gd with naive script (no cooperative API)")

    var inject := load(HOSTILE_SCRIPT_PATH)
    if inject == null:
        push_error("[RegistryTest_Hostile] couldn't load %s" % HOSTILE_SCRIPT_PATH)
        return

    inject.take_over_path(VANILLA_DATABASE_PATH)

    var db := get_node_or_null("/root/Database")
    if db == null:
        db = get_tree().root.find_child("Database", true, false)
    if db == null:
        push_error("[RegistryTest_Hostile] Database autoload not found")
        return

    db.set_script(inject)
    print("[RegistryTest_Hostile] hostile injection complete; live /root/Database now uses HostileInject.gd")

    var loader := get_node_or_null("/root/Loader")
    if loader and loader.has_method("Message"):
        loader.Message("[Hostile Test] Database script clobbered — verify registry behavior", Color.RED)
