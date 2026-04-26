extends "res://Scripts/Database.gd"

# Database injection — adds every wallet tier to the vanilla Database so the
# game's Interface.Drop(), Loader.LoadShelter(), Spawner, Trader, etc. can
# resolve our items by their ItemData.file name.

const Leather_Wallet = preload("res://mods/RTVWallets/Leather_Wallet.tscn")
const Ammo_Tin = preload("res://mods/RTVWallets/Ammo_Tin.tscn")
const Money_Case = preload("res://mods/RTVWallets/Money_Case.tscn")
const Cash = preload("res://mods/RTVWallets/Cash.tscn")
