extends "res://Scripts/Item.gd"

# Item.gd subclass — was used to add wallet-cash to Value()/Weight() while
# wallets had a custom subtype="Wallet". Now that wallets use
# subtype="Magazine" with compatible=[Cash, Cash_Big], the vanilla
# Item.Value() / Item.Weight() Magazine math already does:
#   value  += slotData.amount * (Cash.value / Cash.defaultAmount)         = amount
#   weight += slotData.amount * (Cash.weight / Cash.defaultAmount)        = amount * 0.0001
# which is exactly what we want — so this script is now a pass-through.
# Kept in place because Main.gd's take_over_path expects the script to load.
