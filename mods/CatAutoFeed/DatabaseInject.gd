extends "res://Scripts/Database.gd"

# Database injection — adds our mod's scenes to the vanilla Database so the
# game's Interface.Drop(), Loader.LoadShelter(), and anything else that does
# Database.get(item.itemData.file) can resolve our items by file name.
#
# Extends the vanilla Database and appends our own consts. `take_over_path`
# from Main.gd replaces the loaded script globally so every reference to
# `Database` (including the autoload singleton) gets our constants.

const Cat_Bowl = preload("res://mods/CatAutoFeed/Cat_Bowl.tscn")
