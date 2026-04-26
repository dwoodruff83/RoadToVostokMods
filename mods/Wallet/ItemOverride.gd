extends "res://Scripts/Item.gd"

# Item.gd subclass: adds wallet cash (slotData.amount on subtype=="Wallet")
# to the Value() computation so the inventory header total — and any other
# UI that reads Value() — reflects the rubles inside each wallet, not just
# the wallet shell's base value.
#
# Take_over_path'd in Wallet/Main.gd._ready() so all newly-instanced Item
# scripts use this version. Vanilla Ammo / Matches / Magazine handling is
# preserved via super().

func Value() -> int:
    var value: int = super()
    if slotData and slotData.itemData and String(slotData.itemData.subtype) == "Wallet":
        value += int(slotData.amount)
    return value
