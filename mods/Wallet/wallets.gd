extends Node

# Wallet tier registry. Each tier becomes an ItemData registered at runtime.
#
# Fields map onto game ItemData (see reference/RTV_decompiled/Scripts/ItemData.gd):
#   capacity  -> maxAmount (shown as ammo-style count on the inventory icon)
#   weight    -> weight
#   value     -> value (trader base price for the wallet itself, empty)
#   rarity    -> ItemData.Rarity (0=Common, 1=Rare, 2=Legendary)
#   size      -> inventory grid size (Vector2)
#   model     -> path to the .glb used for the world / held mesh
#   loot.*    -> spawn flags matched against the game's loot tables
#
# To reuse one model across all tiers, point every entry at the same .glb and
# the tiers will differ by stats alone. Replace per-tier as art is sourced.

const TIERS := [
    {
        "id": "wallet",
        "name": "Wallet",
        "capacity": 1000,
        "weight": 0.15,
        "value": 100,
        "rarity": 0,
        "size": Vector2(1, 1),
        "model": "res://mods/Wallet/assets/models/Wallet.glb",
        "loot": {"civilian": true, "industrial": true, "military": false},
        "traders": {"generalist": false, "doctor": true, "gunsmith": false},
    },
    {
        "id": "ammo_tin",
        "name": "Ammo Tin",
        "capacity": 5000,
        "weight": 0.50,
        "value": 500,
        "rarity": 1,
        "size": Vector2(2, 2),
        "model": "res://mods/Wallet/assets/models/Ammo_Tin.glb",
        "loot": {"civilian": false, "industrial": true, "military": true},
        "traders": {"generalist": false, "doctor": false, "gunsmith": true},
    },
    {
        "id": "money_case",
        "name": "Money Case",
        "capacity": 10000,
        "weight": 1.20,
        "value": 2500,
        "rarity": 2,
        "size": Vector2(3, 2),
        "model": "res://mods/Wallet/assets/models/Money_Case.glb",
        "loot": {"civilian": false, "industrial": true, "military": true},
        "traders": {"generalist": false, "doctor": false, "gunsmith": false},
    },
]

static func get_tier(tier_id: String) -> Dictionary:
    for t in TIERS:
        if t.id == tier_id:
            return t
    return {}

static func ids() -> Array:
    var out: Array = []
    for t in TIERS:
        out.append(t.id)
    return out
