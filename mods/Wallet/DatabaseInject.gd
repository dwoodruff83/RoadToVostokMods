extends "res://Scripts/Database.gd"

# Database injection — adds every wallet tier to the vanilla Database so the
# game's Interface.Drop(), Loader.LoadShelter(), Spawner, Trader, etc. can
# resolve our items by their ItemData.file name.

const Wallet = preload("res://mods/Wallet/Wallet.tscn")
const Ammo_Tin = preload("res://mods/Wallet/Ammo_Tin.tscn")
const Money_Case = preload("res://mods/Wallet/Money_Case.tscn")
const Cash = preload("res://mods/Wallet/Cash.tscn")
